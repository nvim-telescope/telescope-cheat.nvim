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
  local get_entry_name = function(entry)
    return entry.value.ns .. '/' .. entry.value.keyword
  end

  return previewers.new_buffer_previewer {
    keep_last_buf = true,
    get_buffer_by_name = function(_, entry)
      return get_entry_name(entry)
    end,
    define_preview = function(self, entry)
      if get_entry_name(entry) ~= self.state.bufname then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value.content, '\n'))
        putils.highlighter(self.state.bufnr, entry.value.ft)
      end
    end
  }
end)

local displayer = entry_display.create{
  separator = " ",
  hl_chars = { ["|"] = "TelescopeResultsNumber" },
  items = {
    { width = 30 },
    { remaining = true },
  }
}

local make_display = function(entry)
  return displayer {
    { entry.value.keyword, "TelescopeResultsNumber" },
    { entry.value.ns, "TabLine" },
  }
end

local entry_maker = function(entry)
  return {
    value = entry,
    ordinal = entry.keyword .. ' ' .. entry.ns,
    display = make_display
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

local cheat_fd = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = 'Cheats',
    finder = finders.new_table{ results = data:get(), entry_maker = entry_maker },
    sorter = conf.generic_sorter(opts), -- shouldn't this be default?
    previewer = previewer.new(opts),
    attach_mappings = set_mappings
  }):find()
end

return require'telescope'.register_extension {
  exports = {
    fd = function(opts)
      return data:ensure(function()
        return cheat_fd(opts)
      end)
    end,
    recache = function(_)
      return data:recache()
    end
  }
}
