local raw = require'telescope._extensions.cheat.raw'
local sqlite = require'sqlite'

local VERSION = 0.1 -- should be incremented when sources/presentation/parsing changes.

local dbdir = vim.fn.stdpath("data") .. "/databases"
---@class CheatDB:sqlite_db
---@field state sqlite_tbl
---@field cheat sqlite_tbl
local db = sqlite {
  uri = dbdir .. "/telescope-cheat.db",
  state = {
    id = "number",
    version = "number"
  },
  cheat = {
    id = {"integer", "primary", "key"},
    source = "text",
    ns = "text",
    keyword = "text",
    content = "text",
    ft = "text"
  }
}
---@type sqlite_tbl
local state, data = db.state, db.cheat

function state:get_version()
  local version = self:where {id = 1}
  return version and version.version or nil
end

function state:is_up_to_date()
  if not self:get_version() then
    self:insert{ id = 1, version = VERSION }
  end
  return self:get_version() == VERSION
end

function state:change_version()
  return self:update {
    where = { id = 1 },
    values = { version = VERSION }
  }
end

function data:seed(cb)
  print("telesocpe-cheat.nvim: caching databases ........................ ")
  return raw.get(function(rows)
    self:insert(rows)
    print("telesocpe-cheat.nvim: databases has been successfully cached.")
    cb()
  end)
end

function data:recache(cb)
  print("telesocpe-cheat.nvim: recaching databases ...................... ")
  return raw.get(function(rows)
    print("telesocpe-cheat.nvim: databases has been successfully recached.")
    self:replace(rows)
    if cb then return cb() end
  end)
end

function data:ensure(cb)
  if not vim.loop.fs_stat(dbdir) then
    vim.loop.fs_mkdir(dbdir, 493)
  end

  local up_to_date = state:is_up_to_date()
  local has_content = not self:empty()

  if up_to_date and not has_content then
    return self:seed(cb)
  elseif not up_to_date and has_content then
    state:change_version()
    return self:recache(cb)
  else
    cb()
  end
end

return data
