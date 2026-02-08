local lib = require("neotest.lib")

local M = {}

local function get_match_type(captured_nodes)
  if captured_nodes["test.name"] then
    return "test"
  end
  if captured_nodes["namespace.name"] then
    return "namespace"
  end
end

local function build_position(file_path, source, captured_nodes)
  local match_type = get_match_type(captured_nodes)
  if match_type then
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
    local definition = captured_nodes[match_type .. ".definition"]

    return {
      type = match_type,
      path = file_path,
      name = name,
      range = { definition:range() },
    }
  end
end

local function collect(file_path, query, source, root)
  local sep = lib.files.sep
  local path_elems = vim.split(file_path, sep, { plain = true })
  local nodes = {
    {
      type = "file",
      path = file_path,
      name = path_elems[#path_elems],
      range = { root:range() },
    },
  }

  for _, match, _ in query:iter_matches(root, source, nil, nil, { all = false }) do
    local captured_nodes = {}
    for i, capture in ipairs(query.captures) do
      captured_nodes[capture] = match[i]
    end

    local match_type = get_match_type(captured_nodes)
    if not match_type then
      goto continue
    end

    local res = build_position(file_path, source, captured_nodes)
    nodes[#nodes + 1] = res

    ::continue::
  end

  return nodes
end

local function add_path_to_node_name(node, parent_path)
  if not node then
    return
  end

  local data = node:data()
  local current_path = parent_path

  if data.type == "namespace" then
    current_path = (parent_path and parent_path .. "." or "") .. data.name
    data.name = current_path
  elseif data.type == "test" then
    if parent_path then
      data.name = parent_path .. "." .. data.name
    end
  end

  local children = node:children()
  if children then
    for _, child in ipairs(children) do
      add_path_to_node_name(child, current_path)
    end
  end
end

local function remove_duplicate_nodes(positions)
  local unique_positions = {}
  local seen_ranges = {}
  for _, position in ipairs(positions) do
    -- Serialize range to string for use as table key
    local range_key =
      string.format("%d-%d-%d-%d", position.range[1], position.range[2], position.range[3], position.range[4])
    -- Only add if we haven't seen this range before
    if not seen_ranges[range_key] then
      seen_ranges[range_key] = true
      table.insert(unique_positions, position)
    end
  end
  return unique_positions
end

function M.nix_unit_tests(query, path)
  local content = lib.files.read(path)
  local root, lang = lib.treesitter.get_parse_root(path, content, {})
  local parsed_query = lib.treesitter.normalise_query(lang, query)
  local positions = collect(path, parsed_query, content, root)
  -- Duplication of nodes happens due to some namespace
  -- queries. So far I haven't been able to create a treesitter
  -- query for namespaces that does not trigger on each child.
  -- Thus we remove them here as a workaround. Feel free
  -- to try and fix the treesitter query in discover_positions!
  positions = remove_duplicate_nodes(positions)
  -- Here is the key to get parse_tree working.
  --
  -- parse_tree assumes all matches are ordered
  -- by the first line the match comes in. This is
  -- _not_ the case for the nix language.
  --
  -- TODO: make an issue with neotest
  -- although I expect it not to be a high priority
  -- since this is just support functions.
  table.sort(positions, function(a, b)
    return a.range[1] < b.range[1]
  end)
  local tree = lib.positions.parse_tree(positions, {})
  add_path_to_node_name(tree, nil)
  return tree
end

return M
