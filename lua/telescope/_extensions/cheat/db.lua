local raw = require'telescope._extensions.cheat.raw'
local sql = require'sql'

local dbpath = (function()
  local d = vim.fn.stdpath("data") .. "/databases"
  if not vim.loop.fs_stat(d) then vim.loop.fs_mkdir(d, 493) end
  return d  .. "/telescope-cheat.db"
end)()

local db = sql.new(dbpath)

local tbl = function()
  local tbl = db:table("cheat")
  tbl:schema {
    id = {"integer", "primary", "key"},
    source = "text",
    ns = "text",
    keyword = "text",
    content = "text",
    ft = "text",
    ensure = true
  }

  tbl.ensure = function(self, cb)
    if not self.has_content then
      return raw.get(function(rows)
        self:insert(rows)
        cb()
      end)
    else
      cb()
    end
  end

  tbl.recache = function(self, cb)
    if self.has_content then
      return raw.get(function(rows)
        self:replace(rows)
        cb()
      end)
    end
  end
  return tbl
end

return tbl()
