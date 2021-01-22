local j = require'plenary.job'
local scan = require'plenary.scandir'
local sources = require'telescope._extensions.cheat.sources'
local M = {}

local function remove_dir(cwd)
   local handle = vim.loop.fs_scandir(cwd)
  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then break end

    local new_cwd = cwd..'/'..name
    if t == 'directory' then
      local success = remove_dir(new_cwd)
      if not success then return false end
    else
      local success = vim.loop.fs_unlink(new_cwd)
      if not success then return false end
    end
  end

  return vim.loop.fs_rmdir(cwd)
end

local clone = function(uri, path, cb)
  return j:new({
    command = "git",
    args = { "clone", uri, path, "--depth=1" },
    on_exit = function(_, code)
      if code == 0 then
        return cb()
      else
        error(string.format("%s couldn't be temporarily cloned", uri))
      end
    end
  }):start()
end

local get_source_path = function(cb, source)
  local path = "/tmp/cheat_sources/" .. source.name
  if vim.loop.fs_stat(path) == nil then
    local await = function() cb(path) end
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
      add_dirs = source.add_dirs
    })
  end, source)
end

local extract_data = function(cb, source)
  return get_file_paths(vim.schedule_wrap(function(paths)
    local data = {}
    for i, path in ipairs(paths) do
      local ns, keyword = source.get_ns_keyword(path)
      data[i] = {
        source = source.name,
        ns = keyword and ns or source.ns,
        keyword = keyword and keyword or ns,
        ft = source.ft,
        content = source.parse(path)
      }
    end
    cb(data)
  end), source)
end

M.__get = function(cb, lsources, data) -- conni <3
  if table.getn(lsources) > 0 then
    local source = table.remove(lsources, 1)
    extract_data(function(res)
      for _, v in ipairs(res) do
        table.insert(data, v)
      end
      remove_dir("/tmp/cheat_sources/" .. source.name)
      M.__get(cb, lsources, data)
    end, source)
  else
    return cb(data)
  end
end

M.get = function(cb)
  local data = {}
  local lsources = vim.deepcopy(sources)
  M.__get(cb, lsources, data)
end

return M
