# neotest-nix-unit

A [neotest](https://github.com/nvim-neotest/neotest) adapter for the [nix-unit](https://github.com/nix-community/nix-unit) testing framework.

## Requirements

- [neotest](https://github.com/nvim-neotest/neotest)
- [nix-unit](https://github.com/nix-community/nix-unit) (must be in PATH)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with the Nix parser installed

## Installation

### NixVim (with Flakes)

Add the input to your flake:

```nix
{
  inputs = {
    neotest-nix-unit.url = "github:jumziey/neotest-nix-unit.nvim";
  };
}
```

Then add the plugin to extraPlugins:

```nix
extraPlugins = [
  inputs.neotest-nix-unit.packages.${system}.default
];
```

### Using the Overlay

```nix
{
  inputs = {
    neotest-nix-unit.url = "github:jumziey/neotest-nix-unit.nvim";
  };

  outputs = { nixpkgs, neotest-nix-unit, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ neotest-nix-unit.overlays.default ];
      };
    in {
      # Now use pkgs.vimPlugins.neotest-nix-unit
    };
}
```

### lazy.nvim

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "jumziey/neotest-nix-unit.nvim",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-nix-unit"),
      },
    })
  end,
}
```

### packer.nvim

```lua
use {
  "nvim-neotest/neotest",
  requires = {
    "jumziey/neotest-nix-unit.nvim",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-nix-unit"),
      },
    })
  end,
}
```

### vim-plug

```vim
Plug 'nvim-neotest/neotest'
Plug 'jumziey/neotest-nix-unit.nvim'
```

Then in your config:

```lua
require("neotest").setup({
  adapters = {
    require("neotest-nix-unit"),
  },
})
```

## Usage

The adapter automatically detects test files with `.test.nix` or `.tests.nix` extensions.

Test files should follow the nix-unit format:

```nix
{
  testExample = {
    expr = 1 + 1;
    expected = 2;
  };

  nested = {
    testNested = {
      expr = "hello";
      expected = "hello";
    };
  };
}
```

Use standard neotest keymaps to run tests:

- `:lua require("neotest").run.run()` - Run nearest test
- `:lua require("neotest").run.run(vim.fn.expand("%"))` - Run current file
- `:lua require("neotest").summary.toggle()` - Toggle test summary

## Development

### Running Tests

```bash
nvim --headless -u testrc_init.lua -c "PlenaryBustedDirectory spec {init = 'testrc_init.lua'}"
```

### Development Shell (Nix)

```bash
nix develop
```

This provides nix-unit, neovim, stylua, and luacheck.

## License

MIT
