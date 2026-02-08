require('plenary.busted') -- for lsp to load signatures


describe("adapter", function()
  local adapter = require("neotest-nix-unit")
  local test_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')

  describe("root", function()
    it("should return root for flake.nix", function()
      local root = adapter.root(test_dir .. "/root_test/flake_nix_root/src")
      assert.are.equal(test_dir .. "/root_test/flake_nix_root", root)
    end)

    it("should return root for *.test.nix", function()
      local root = adapter.root(test_dir .. "/root_test/test_root/subfolder")
      assert.are.equal(test_dir .. "/root_test/test_root", root)
    end)

    it("should return root for *.tests.nix", function()
      local root = adapter.root(test_dir .. "/root_test/tests_root/subfolder")
      assert.are.equal(test_dir .. "/root_test/tests_root", root)
    end)

    it("should return root for default.nix", function()
      local root = adapter.root(test_dir .. "/root_test/default_root/subfolder")
      assert.are.equal(test_dir .. "/root_test/default_root", root)
    end)

    it("should return root for shell.nix", function()
      local root = adapter.root(test_dir .. "/root_test/shell_root/subfolder")
      assert.are.equal(test_dir .. "/root_test/shell_root", root)
    end)
  end)
end)
