local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local utils = require("telescope.utils")
local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local data = require('telescope._extensions.cheat.db')
local previewer = utils.make_default_callable(function(_)
  previewers.new_buffer_previewer {
    keep_last_buf = true,
    get_buffer_by_name = function(_, entry) return entry.ns .. "/" .. entry.keyword end,
    define_preview = function(self, entry, status)
      if entry.ns .. "/" .. entry.keyword ~= self.state.bufname then
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.fn.json_decode(entry.content))
      vim.api.nvim_win_set_option(self.state.preview_win, "wrap", true)
      putils.highlighter(self.state.bufnr, entry.ft)
      end
    end
  }
end)

local make_display = function(entry)
  local displayer = entry_display.create{
    separator = " ",
    hl_chars = { ["|"] = "TelescopeResultsNumber" },
    items = {
      {width = 30},
      {remaining = true},
      {remaining = true}
    }
  }

  return displayer {
    {entry.keyword, "TelescopeResultsNumber"},
    {entry.ns, "TabLine"},
  }
end

local entry_maker = function(entry)
  return {
    name = entry.name,
    ns = entry.ns,
    content = entry.content,
    ft = entry.ft,
    ordinal = entry.ns .. " " .. entry.name
  }
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
  pickers.new(opts, {
    prompt_title = 'Cheats',
    finder = finders.new_table{
      results = data:get(),
      entry_maker = entry_maker
    },
    sorter = conf.generic_sorter(opts),
    previewer = previewer.new(opts),
    attach_mappings = set_mappings
  }):find()
end

data:seed(cheat_fd)

-- local cheat_current_ft = function(opts)
--   opts = opts or {}
--   cheat_fd(vim.tbl_extend("keep", opts, {ft = vim.bo.filetype}))
-- end

-- return require'telescope'.register_extension {
--   exports = {
--     cheat_fd = cheat_fd,
--     -- cheat_current_ft = cheat_current_ft
--   }
-- }
