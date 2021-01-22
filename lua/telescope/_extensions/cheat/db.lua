local raw = require'telescope._extensions.cheat.raw'
local sql = require'sql'

local VERSION = 0.1 -- should be incremented when sources/presentation/parsing changes.

local db = sql.new((function()
  local d = vim.fn.stdpath("data") .. "/databases"
  if not vim.loop.fs_stat(d) then vim.loop.fs_mkdir(d, 493) end
  return d  .. "/telescope-cheat.db"
end)())

local state = db:table("state")

function state:__ensure_schema()
  return self:schema {
    id = "number",
    version = "number",
    ensure = true
  }
end

function state:get_version()
  self:__ensure_schema()
  local version = self:get({ where = {id = 1}, keys = "version" })
  return version[1] and version[1].version
end

function state:is_up_to_date()
  if not self:get_version() then
    self:insert{ id = 1, version = VERSION }
  end
  return self:get_version() == VERSION
end

function state:change_version()
  return self:update{
    where = { id = 1 },
    values = { version = VERSION }
  }
end

local data = db:table("cheat")

function data:__ensure_schema()
  return self:schema {
    id = {"integer", "primary", "key"},
    source = "text",
    ns = "text",
    keyword = "text",
    content = "text",
    ft = "text",
    ensure = true
  }
end

function data:seed(cb)
  self:__ensure_schema()

  print("telesocpe-cheat.nvim: caching databases ........................ ")
  return raw.get(function(rows)
    self:insert(rows)
    print("telesocpe-cheat.nvim: databases has been successfully cached.")
    cb()
  end)
end

function data:recache(cb)
  self:__ensure_schema()

  print("telesocpe-cheat.nvim: recaching databases ...................... ")
  return raw.get(function(rows)
    print("telesocpe-cheat.nvim: databases has been successfully recached.")
    self:replace(rows)
    if cb then return cb() end
  end)
end

function data:ensure(cb)
  self:__ensure_schema()

  local up_to_date = state:is_up_to_date()
  local has_content = not self:empty()

  if up_to_date and not has_content  then
    return self:seed(cb)
  elseif not up_to_date and has_content then
    state:change_version()
    return self:recache(cb)
  else
    cb()
  end
end


return data
