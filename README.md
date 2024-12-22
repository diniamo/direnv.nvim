# direnv.nvim

Simple Neovim plugin that provides a lua interface to interact with direnv, and a way to automatically load .envrc files.

## Setup / Configuration

Install the plugin with your favorite plugin manager, and call the setup function in your configuration (the values below are the defaults):

```lua
require("direnv").setup({
    -- The direnv command/executable to run
    direnv = "direnv",
    -- Automatically load .envrc files on startup and when changing directories
    auto_load = false,
    -- Automatically reload .envrc files when they are changed
    -- Note that this only works if specifically .envrc is changed, and doesn't
    -- if files that .envrc uses change
    watch_envrc = false
})
```

## Usage

The plugin provides a `Direnv` command, with 3 subcommands: `allow`, `deny`, `reload` (also used for loading). The same functionality is also exposed through lua functions (see the API section for that below).

If you don't want to enable the `auto_load` option, then it's recommended to create mappings:

```lua
local direnv = require("direnv")

vim.keymap.set('n', "<leader>da", direnv.alow)
vim.keymap.set('n', "<leader>dd", direnv.deny)
vim.keymap.set('n', "<leader>dr", direnv.reload)
```

## API

The plugin exposes the following fields:
- `setup(config?)` - initialization
- `config` the config in use
- `allow(callback?)` - allow the .envrc file; the callback can be used to run a function after
- `deny()` - deny the .envrc file
- `reload()` - load or reload the .envrc file
- `check()` - check if there is a .envrc file that can be loaded, and show a prompt to allow it if it's denied
