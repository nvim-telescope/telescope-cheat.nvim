# telescope-cheat.nvim

An attempt to recreate cheat.sh with lua, neovim, [sqlite.lua](https://github.com/kkharji/sqlite.lua), and telescope.nvim.

![](./preview.gif)

## Installation

Install via your favorite package manager:

#### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "yorik1984/telescope-cheat.nvim",
    requires = {
        "kkharji/sqlite.lua",
        "nvim-telescope/telescope.nvim"
    }
}

require("telescope").load_extension("cheat")
```

#### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({
    "yorik1984/telescope-cheat.nvim",
    dependencies = {
        "kkharji/sqlite.lua",
        "nvim-telescope/telescope.nvim"
    }
})

require("telescope").load_extension("cheat")
```

## Usage

```vim
:Telescope cheat fd
:Telescope cheat recache " cheat will be auto cached with new updates on sources
```

## Contribution

New sources can be defined in [./lua/telescope/\_extensions/cheat/sources.lua](https://github.com/nvim-telescope/telescope-cheat.nvim/blob/dev/lua/telescope/_extensions/cheat/sources.lua).

Example:

```lua

M[2] = {
  name = "learnxinyminutes",
  uri = "https://github.com/adambard/learnxinyminutes-docs",
  root = "",
  depth = 1,
  pattern = ".*%.html%.markdown",
  add_dirs = false,
  ft = "markdown",
  parse = function(path)
    local content = p.readlines(path)
    if content[1]:find('---', 1, true) then
      local minus_count = 0
      while minus_count < 2 do
        if content[1]:find('---', 1, true) then minus_count = minus_count + 1 end
        table.remove(content, 1)
      end
    end
    while content[1] == '' do
      table.remove(content, 1)
    end

    return table.concat(content, '\n')
  end,
  get_ns_keyword = function(path)
    return "lang", path:match('.*/([^./]+).*')
  end
}
```
