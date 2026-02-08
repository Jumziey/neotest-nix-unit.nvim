require('plenary.busted') -- for lsp to load signatures
 local adapter = require("neotest-nix-unit")

describe("is_test_file", function()
  it("should identify .test.nix files as test files", function()
    assert.is_true(adapter.is_test_file("/path/to/example.test.nix"))
  end)

  it("should identify .tests.nix files as test files", function()
    assert.is_true(adapter.is_test_file("/path/to/example.tests.nix"))
  end)

  it("should not identify regular .nix files as test files", function()
    assert.is_false(adapter.is_test_file("/path/to/default.nix"))
  end)
end)
