local lib = require("neotest.lib")
local positions_parse = require("neotest-nix-unit.positions_parse")
local tree_helper = require("neotest-nix-unit.tree_helper")

local adapter = { name = "neotest-nix-unit" }

-- See: https://github.com/nvim-neotest/neotest/blob/master/lua/neotest/adapters/interface.lua

function adapter.root(path)
  return lib.files.match_root_pattern("*.test.nix", "*.tests.nix", "flake.nix", "default.nix", "shell.nix")(path)
end

function adapter.is_test_file(file_path)
  return vim.endswith(file_path, ".test.nix") or vim.endswith(file_path, ".tests.nix")
end

function adapter.filter_dir(name, _, _)
  return not vim.tbl_contains({
    ".git",
    "node_modules",
    "result",
    ".direnv",
  }, name)
end

function adapter.discover_positions(path)
  local query = [[
    ; Test pattern - matches bindings with expr and expected attributes
    ; This pattern MUST come first to take priority over namespace pattern
    (binding
      (attrpath
        (identifier) @test.name
      )
      (attrset_expression
        (binding_set
          (binding
            (attrpath
              (identifier) @_expr
              (#eq? @_expr "expr")
            )
          )
          (binding
            (attrpath
              (identifier) @_expected
              (#eq? @_expected "expected")
            )
          )
        )
      )
    ) @test.definition

    ; Namespace pattern - matches bindings with nested bindings
    ; EXCLUDES test bindings by ensuring they don't have both "expr" and "expected"
    (binding
      (attrpath
        (identifier) @namespace.name
      )
      (attrset_expression
        (binding_set
          ; Must have a nested binding (not expr/expected) that itself contains a binding_set
          ; This indicates nested structure, not a test case
          (binding
            (attrpath
              (identifier) @_child_name
            )
            (#not-eq? @_child_name "expr")
            (#not-eq? @_child_name "expected")
            (attrset_expression
              (binding_set)
            )
          )
        )
      )
    ) @namespace.definition
  ]]

  return positions_parse.nix_unit_tests(query, path)
end

local function make_run_spec(cwd, nix_unit_args)
  local command = vim.list_extend({ "nix-unit" }, nix_unit_args)
  vim.list_extend(command, { "--arg", "lib", "(import <nixpkgs> {}).lib" })

  return {
    command = command,
    cwd = cwd,
    env = { NO_COLOR = "1" },
  }
end

function adapter.build_spec(args)
  local tree = args.tree
  local data = tree:data()

  if data.type == "test" then
    local file_path = data.path
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local test_name = data.name
    local expr = string.format("{ %s = (import ./%s).%s; }", test_name, file_name, test_name)
    return make_run_spec(vim.fn.fnamemodify(file_path, ":h"), { "--expr", expr })
  elseif data.type == "namespace" then
    local file_path = data.path
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local namespace = data.name
    local expr = string.format("(import ./%s).%s", file_name, namespace)
    return make_run_spec(vim.fn.fnamemodify(file_path, ":h"), { "--expr", expr })
  elseif data.type == "file" then
    local file_path = data.path
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    return make_run_spec(vim.fn.fnamemodify(file_path, ":h"), { file_name })
  elseif data.type == "dir" then
    local run_specs = {}
    local test_files = vim.list_extend(
      vim.fn.glob(data.path .. "/*.tests.nix", false, true),
      vim.fn.glob(data.path .. "/*.test.nix", false, true)
    )
    for _, file_path in ipairs(test_files) do
      local fn = vim.fn.fnamemodify(file_path, ":t")
      table.insert(run_specs, make_run_spec(data.path, { fn }))
    end
    return run_specs
  end

  return nil
end

local function parse_test_specific_status_line(line, status, regexp)
  local test_name = line:match(regexp)
  if not test_name then
    return false
  end
  return {
    status = status,
    test_name = test_name,
  }
end

local function parse_test_status_line(line)
  if not line then
    return false
  end
  return parse_test_specific_status_line(line, "passed", "^✅%s+(.+)$")
    or parse_test_specific_status_line(line, "failed", "^❌%s+(.+)$")
    or parse_test_specific_status_line(line, "failed", "^☢️%s+(.+)$")
end

local function remove_initial_nix_warnings(lines)
  while #lines > 0 and lines[1]:match("^warning:") do
    table.remove(lines, 1)
  end
end

local function remove_empty_lines_to_next_entry(lines)
  while #lines > 0 and lines[1]:len() == 0 do
    table.remove(lines, 1)
  end
end

local function parse_failed_test_short(lines)
  local short_lines = {}
  while #lines > 0 and not parse_test_status_line(lines[1]) and lines[1]:len() > 0 do
    table.insert(short_lines, lines[1])
    table.remove(lines, 1)
  end
  remove_empty_lines_to_next_entry(lines)
  return table.concat(short_lines, "\n")
end

local function extract_error_info(error_output)
  local error_message = error_output:match("^error:%s*([^\n]+)")
  local line_number = error_output:match("at [^:]+:(%d+):")

  if error_message and line_number then
    return {
      message = error_message,
      line = tonumber(line_number),
    }
  end

  return nil
end

local function parse_test_error(lines)
  local error_output = table.concat(lines, "\n")
  local error_info = extract_error_info(error_output)
  return error_info
end

function adapter.results(_, result, tree)
  -- TODO: Rewrite so the function goes line by line reading
  -- instead of reading the whole file and then loop through again.
  local lines = vim.fn.readfile(result.output)
  local test_results = {}

  remove_initial_nix_warnings(lines)

  if #lines == 0 then
    return test_results
  end

  if lines[1]:match("^error:") then
    local errors = parse_test_error(lines)
    return {
      [tree:data().id] = {
        status = "failed",
        errors = { errors },
      },
    }
  end

  while #lines > 0 do
    local test_status_line = parse_test_status_line(lines[1])
    if not test_status_line then
      break
    end

    local current_test = tree_helper.get_test_id_by_name(tree, test_status_line.test_name)
    test_results[current_test] = {
      status = test_status_line.status,
    }
    table.remove(lines, 1)

    if test_results[current_test].status == "failed" then
      local error = parse_test_error(lines)
      if error then
        test_results[current_test].errors = { error }
      else
        test_results[current_test].short = parse_failed_test_short(lines)
      end
    end
    remove_empty_lines_to_next_entry(lines)
  end

  return test_results
end

return adapter
