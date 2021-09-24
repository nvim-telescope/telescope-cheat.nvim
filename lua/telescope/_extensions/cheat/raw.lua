local j = require "plenary.job"
local scan = require "plenary.scandir"
local sources = require "telescope._extensions.cheat.sources"
local M = {}

local extract_path = nil
local __get

local clone = function(uri, path, cb)
  return j
    :new({
      command = "git",
      args = { "clone", uri, path, "--depth=1" },
      on_exit = function(_, code)
        if code == 0 then
          return cb()
        else
          error(string.format("%s couldn't be temporarily cloned", uri))
        end
      end,
    })
    :start()
end

local get_source_path = function(cb, source)
  local path = extract_path .. "/" .. source.name
  if vim.loop.fs_stat(path) == nil then
    local await = function()
      cb(path)
    end
    clone(source.uri, path, await)
  else
    cb(path)
  end
end

local get_file_paths = function(cb, source)
  return get_source_path(function(path)
    return scan.scan_dir_async(path .. source.root, {
      search_pattern = source.pattern,
      on_exit = cb,
      depth = source.depth,
      add_dirs = source.add_dirs,
    })
  end, source)
end

local extract_data = function(cb, source)
  return get_file_paths(
    vim.schedule_wrap(function(paths)
      local data = {}
      for i, path in ipairs(paths) do
        local ns, keyword = source.get_ns_keyword(path)
        data[i] = {
          source = source.name,
          ns = keyword and ns or source.ns,
          keyword = keyword and keyword or ns,
          ft = source.ft,
          content = source.parse(path),
        }
      end
      cb(data)
    end),
    source
  )
end

__get = function(cb, lsources, data) -- conni <3
  if table.getn(lsources) > 0 then
    local source = table.remove(lsources, 1)
    extract_data(function(res)
      for _, v in ipairs(res) do
        table.insert(data, v)
      end
      __get(cb, lsources, data)
    end, source)
  else
    extract_path = nil
    return cb(data)
  end
end

M.get = function(cb)
  if extract_path then
    return
  end

  extract_path = os.tmpname()
  os.remove(extract_path)

  local data = {}
  local lsources = vim.deepcopy(sources)
  __get(cb, lsources, data)
end

return M
