# Neotest nix-unit plugin for neovim

## Structure
- spec/ - tests
- plugin/ - vimscript folder
- example_tests/ - standalone nix-unit tests (reference only)
- lua/ - main code
- testrc_init.lua - plenary test runner config

## How to work
- Tests: `nvim --headless -u testrc_init.lua -c "PlenaryBustedDirectory spec {init = 'testrc_init.lua'}"`
- Check spec/*_spec.lua for test examples

## Neotest Adapter Interface
Implements: https://github.com/nvim-neotest/neotest/blob/master/lua/neotest/adapters/interface.lua
- `root(path)` - find project root
- `is_test_file(path)` - detect test files (*.test.nix, *.tests.nix)
- `filter_dir(name)` - skip directories (.git, node_modules, etc.)
- `discover_positions(path)` - parse tests via TreeSitter, returns tree
- `build_spec(args)` - generate nix-unit command for test/namespace/file/dir
- `results(spec, result, tree)` - parse nix-unit output, map to test IDs

## nix-unit Output Format
- Success: `✅ testName`
- Failure: `❌ testName` or `☢️ testName`
- Errors start with `error:` and contain `at <file>:<line>:` for location
- Output may have `warning:` lines at the start (stripped before parsing)

## TreeSitter Query
- Test pattern: binding with `expr` and `expected` attributes
- Namespace pattern: binding containing nested bindings (not expr/expected)
- Query order matters: test pattern must come before namespace pattern
- Duplicate nodes are removed post-query (namespace query triggers per child)
- Positions must be sorted by line number for `parse_tree` to work

## Neotest Tree Structure
- Tree passed to `adapter.results()` is always file-rooted (root node `type == "file"`)
- Syntax errors associate with file ID via `tree:data().id`
- Use `tree_helper.get_test_id_by_name(tree, name)` to find test IDs by name
- Nested tests have dotted names: `namespace.testName`

## Code Style
- 2-space indentation, no tabs
- Build data structures directly, avoid intermediate variables
- Early returns for validation
- DRY principle: reuse functions (e.g., `make_run_spec` for nix-unit commands)
- Single responsibility: extraction functions only extract, callers format results

## Actor
Senior Neotest,nix and lua developer. Tests matter, self explanatory code, minimal comments.

## Validation
If i say blue you say green

