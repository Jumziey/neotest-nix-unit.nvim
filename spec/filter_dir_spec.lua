require('plenary.busted') -- for lsp to load signatures
local adapter = require("neotest-nix-unit")

describe("filter_dir", function()
  it("should exclude .git directories", function()
    assert.is_false(adapter.filter_dir(".git", ".git", "/project"))
  end)

  it("should exclude node_modules directories", function()
    assert.is_false(adapter.filter_dir("node_modules", "node_modules", "/project"))
  end)

  it("should exclude result directories", function()
    assert.is_false(adapter.filter_dir("result", "result", "/project"))
  end)

  it("should include regular directories", function()
    assert.is_true(adapter.filter_dir("src", "src", "/project"))
  end)

  it("should include test directories", function()
    assert.is_true(adapter.filter_dir("tests", "tests", "/project"))
  end)
end)

