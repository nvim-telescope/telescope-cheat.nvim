local p = require "plenary.path"
local M = {}
local parse = function(path)
  local content = p.readlines(path)
  if content[1]:find("---", 1, true) then
    local minus_count = 0
    while minus_count < 2 do
      if content[1]:find("---", 1, true) then
        minus_count = minus_count + 1
      end
      table.remove(content, 1)
    end
  end
  while content[1] == "" do
    table.remove(content, 1)
  end

  return table.concat(content, "\n")
end

M[1] = {
  name = "cheatsheets",
  uri = "https://github.com/cheat/cheatsheets",
  ns = "unix",
  root = "",
  pattern = "",
  ft = "sh",
  parse = parse,
  get_ns_keyword = function(path)
    local name = vim.split(path, "/")
    local a, b = unpack(vim.split(name[#name], "-"))
    return a, b
  end,
}

M[2] = {
  name = "learnxinyminutes",
  uri = "https://github.com/adambard/learnxinyminutes-docs",
  root = "",
  depth = 1,
  pattern = ".*%.html%.markdown",
  add_dirs = false,
  ft = "markdown",
  parse = parse,
  get_ns_keyword = function(path)
    return "lang", path:match ".*/([^./]+).*"
  end,
}

M[3] = {
  name = "nvim-lua-guide",
  uri = "https://github.com/nanotee/nvim-lua-guide",
  root = "",
  depth = 1,
  pattern = "README.md",
  add_dirs = false,
  ft = "markdown",
  parse = parse,
  get_ns_keyword = function(path)
    return "lang", path:match ".*/([^./]+).*"
  end,
}

return M
