local raw = require'telescope._extensions.cheat.raw'
local sql = require'sql'

local VERSION = 0.1 -- should be incremented when sources/presentation/parsing changes.

local db = sql.new((function()
  local d = vim.fn.stdpath("data") .. "/databases"
  if not vim.loop.fs_stat(d) then vim.loop.fs_mkdir(d, 493) end
  return d  .. "/telescope-cheat.db"
end)())

local state = (function()
  local tbl = db:table("state")
  local version

  tbl:schema {
    id = "number",
    version = "number",
    ensure = true
  }

  if not tbl.has_content then
    tbl:insert{ id = 1, version = VERSION }
  end

  function tbl:is_up_to_date()
    version = self:get{where = {id = 1}, keys = "version"}
    return version[1].version == VERSION
  end

  function tbl:change_version()
    return self:update{
      where = { id = 1 },
      values = { version = VERSION }
    }
  end

  return tbl
end)()

local data = (function()
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

  function tbl:seed(cb)
    if not self.has_content then
      print("telesocpe-cheat.nvim: caching databases ........................ ")
      return raw.get(function(rows)
        self:insert(rows)
        print("telesocpe-cheat.nvim: databases has been successfully cached.")
        cb()
      end)
    else
      cb()
    end
  end

  function tbl:recache(cb)
    if self.has_content then
      print("telesocpe-cheat.nvim: recaching databases ...................... ")
      return raw.get(function(rows)
        print("telesocpe-cheat.nvim: databases has been successfully recached.")
        self:replace(rows)
        if cb then return cb() end
      end)
    end
  end

  function tbl:ensure(cb)
    local up_to_date = state:is_up_to_date()
    if up_to_date and not self.has_content  then
      return self:seed(cb)
    elseif not up_to_date and self.has_content then
      state:change_version()
      return self:recache(cb)
    else
      cb()
    end
  end

  return tbl
end)()

return data
