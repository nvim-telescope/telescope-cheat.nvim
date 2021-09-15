# telescope-cheat.nvim

An attempt to recreate cheat.sh with lua, neovim, [sqlite.lua](https://github.com/tami5/sqlite.lua), and telescope.nvim.

![](./preview.gif)

## Installation

```lua
Plug 'tami5/sqlite.lua'
Plug 'nvim-telescope/telescope-cheat.nvim'

lua require'telescope'.load_extension("cheat")

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
