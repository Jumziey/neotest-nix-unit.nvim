local tempdir = os.getenv("NEOTEST_NIX_UNIT_PLUGIN_DIR") or "/tmp/neotest-nix-unit-test"
vim.fn.mkdir(tempdir, "p")

local function get_repo_name(url)
  return url:match(".*/(.*)")
end

local function install_plugin(git_repo_url, tag)
  local repo_name = get_repo_name(git_repo_url)
  local path = tempdir .. "/" .. repo_name
  -- Auto-install lazy.nvim if not present
  if not vim.uv.fs_stat(path) then
    print("Installing " .. repo_name .. "...")
    vim.fn.system({
      "git",
      "clone",
      git_repo_url,
      "--branch=" .. tag,
      path,
    })
  end
  vim.opt.rtp:prepend(path)
  package.path = package.path .. ";" .. path .. "/lua/?.lua"
  package.path = package.path .. ";" .. path .. "/lua/?/init.lua"
end

local function register_local_plugin()
  local this_file = debug.getinfo(1, 'S').source:sub(2)
  local plugin_root = vim.fn.fnamemodify(this_file, ':h')

  vim.opt.rtp:append(plugin_root)
end

install_plugin("https://github.com/nvim-lua/plenary.nvim", "master")
install_plugin("https://github.com/nvim-neotest/neotest", "v5.11.1")
install_plugin("https://github.com/nvim-neotest/nvim-nio", "v1.10.1")
install_plugin("https://github.com/nvim-treesitter/nvim-treesitter", "v0.10.0")

register_local_plugin()

-- Ensure nix treesitter parser is installed
local parser_dir = tempdir .. "/treesitter-parsers"
vim.fn.mkdir(parser_dir, "p")
vim.opt.runtimepath:append(parser_dir)

local function ensure_nix_parser()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end

  local parser_config = parsers.get_parser_configs()
  if not parser_config.nix then
    return
  end

  -- Check if parser is already available
  local has_parser = pcall(vim.treesitter.language.inspect, "nix")
  if has_parser then
    return
  end

  -- Install the nix parser
  print("Installing nix treesitter parser...")
  vim.cmd("TSInstallSync! nix")
end

ensure_nix_parser()



