require('plenary.busted') -- for lsp to load signatures
local adapter = require("neotest-nix-unit")
describe("neotest-nix-unit.build_spec", function()
  describe("build_spec", function()
    it("runs a single test", function()
      local args = {
        tree = {
          data = function()
            return {
              type = "test",
              path = "/project/path/something.test.nix",
              name = "testExample",
            }
          end
        }
      }

      local spec = adapter.build_spec(args)

      assert.are.same({ "nix-unit", "--expr",  "{ testExample = (import ./something.test.nix).testExample; }",  "--arg",  "lib", "(import <nixpkgs> {}).lib"}, spec.command)
      assert.are.equal("/project/path", spec.cwd)
    end)

    it("runs a test file", function()
      local args = {
        tree = {
          data = function()
            return {
              type = "file",
              path = "/project/path/something.test.nix",
              name = "testExample",
            }
          end
        }
      }

      local spec = adapter.build_spec(args)

      assert.are.same({ "nix-unit", "something.test.nix", "--arg",  "lib", "(import <nixpkgs> {}).lib"}, spec.command)
      assert.are.equal("/project/path", spec.cwd)
    end)

    it("runs all tests in a  directory", function()
      local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
      local mock_test_dir = test_dir .. "/build_spec/tests"
      local args = {
        tree = {
          data = function()
            return {
              type = "dir",
              path = mock_test_dir,
              name = "nested.yetAnotherNest",
            }
          end
        }
      }

      local spec = adapter.build_spec(args)

      assert.are.same({ "nix-unit", "first.tests.nix", "--arg",  "lib", "(import <nixpkgs> {}).lib"}, spec[1].command)
      assert.are.same({ "nix-unit", "second.tests.nix", "--arg",  "lib", "(import <nixpkgs> {}).lib"}, spec[2].command)
      assert.are.equal(mock_test_dir, spec[1].cwd)
      assert.are.equal(mock_test_dir, spec[2].cwd)
    end)

    it("runs all tests in a directory with mixed extensions (.test.nix and .tests.nix)", function()
      local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
      local mock_test_dir = test_dir .. "/build_spec/mixed_extensions"
      local args = {
        tree = {
          data = function()
            return {
              type = "dir",
              path = mock_test_dir,
            }
          end
        }
      }

      local spec = adapter.build_spec(args)

      assert.are.equal(2, #spec)
      local commands = {}
      for _, s in ipairs(spec) do
        table.insert(commands, s.command[2])
      end
      table.sort(commands)
      assert.are.same({ "example.test.nix", "example.tests.nix" }, commands)
    end)

    it("runs all tests in a nest/namespace", function()
      local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
      local dir = "/project/path"
      local file_name = "something.test.nix"
      local file_path = dir .. "/" .. file_name
      local namespace = "nested.yetAnotherTest"
      local args = {
        tree = {
          data = function()
            return {
              type = "namespace",
              path = file_path,
              name = namespace,
            }
          end
        }
      }

      local spec = adapter.build_spec(args)
      assert.are.same({ "nix-unit", "--expr","(import ./".. file_name ..")." .. namespace, "--arg",  "lib", "(import <nixpkgs> {}).lib"}, spec.command)
      assert.are.equal(dir, spec.cwd)
    end)
  end)
end)
