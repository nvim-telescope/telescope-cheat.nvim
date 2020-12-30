local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local curl = require("plenary.curl")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local putils = require('telescope.previewers.utils')
local actions = require('telescope.actions')

local get_query = function(qry)
  local query, filetype
  if qry == nil or vim.tbl_isempty(qry) then
    query = ":list"
  elseif qry.child == nil then
    query = string.format("%s/:list", qry.ft)
    filetype = qry.ft
  else
    query = string.format("%s/%s", qry.ft, qry.child)
    filetype = qry.ft
  end
  return "cht.sh/"..query.."?T"
end

local preview_entry = function(value, ft, bufnr, bufname)
  if value ~= bufname then
    local url = get_query{ft = ft, child = value}
    curl.get(url,{
      callback = vim.schedule_wrap(function(results)
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(results.body, '\n'))
        end
      end)
    })
  end
  putils.highlighter(bufnr, ft)
end

local set_mappings = function(prompt_bufnr)
  actions._goto_file_selection:replace(function(_, cmd)
    actions.close(prompt_bufnr)
    local last_bufnr = require'telescope.state'.get_global_key('last_preview_bufnr')
    if cmd == 'edit' then
      vim.cmd(string.format(":buffer %d", last_bufnr))
    elseif cmd == 'new' then
      vim.cmd(string.format(":sbuffer %d", last_bufnr))
    elseif cmd == 'vnew' then
      vim.cmd(string.format(":vert sbuffer %d", last_bufnr))
    elseif cmd == 'tabedit' then
      vim.cmd(string.format(":tab sb %d", last_bufnr))
    end
  end)
  return true
end

local cheat_fd = function(opts) -- TODO Make it non blocking
  opts = opts or {}

  local res = (function()
    local ret = curl.get(get_query(opts))
    if ret.status == 200 then
      return vim.split(ret.body, "\n")
    end
  end)()

  pickers.new(opts, {
    prompt_title = 'Cheats',
    finder = finders.new_table{ results = res },
    sorter = conf.generic_sorter(opts),
    -- ft = res.ft, -- incase we want to have recusive finders.
    previewer = previewers.new_buffer_previewer{
      keep_last_buf = true,
      get_buffer_by_name = function(_, entry)
        return entry.value
      end,
      define_preview = function(self, entry, status)
        putils.with_preview_window(status, nil, function()
          preview_entry(entry.value, self.ft, self.state.bufnr, self.state.bufname)
        end)
      end
    },
    attach_mappings = set_mappings
  }):find()
end

local cheat_current_ft = function(opts)
  opts = opts or {}
  cheat_fd(vim.tbl_extend("keep", opts, {ft = vim.bo.filetype}))
end

return telescope.register_extension {
  exports = {
    cheat_fd = cheat_fd,
    cheat_current_ft = cheat_current_ft
  }
}
