return {
  {
    'sindrets/diffview.nvim',
    name = 'diffview',
    opts = {
      view = {
        merge_tool = {
          layout = 'diff4_mixed',
        },
      },
    },
    keys = {
      { '<leader>hh', '<cmd>DiffviewFileHistory %<CR>', desc = '[H]unk [H]istory' },
      { '<leader>ph', '<cmd>DiffviewFileHistory<CR>', desc = '[P]roject [H]istory' },
    },
    config = function(_, opts)
      vim.opt.fillchars = {
        foldopen = '',
        foldclose = '',
        fold = ' ',
        foldsep = ' ',
        eob = ' ', -- Don't show ~ at end of buffer
        diff = '╱', -- Nicer delete lines in DiffView
      }

      vim.o.diffopt = 'internal,filler,closeoff,linematch:40'

      local actions = require 'diffview.actions'

      opts.keymaps = {
        view = {
          { 'n', '[x', actions.prev_conflict, { desc = 'In the merge-tool: jump to the previous conflict' } },
          { 'n', ']x', actions.next_conflict, { desc = 'In the merge-tool: jump to the next conflict' } },
          { 'n', '<leader>co', actions.conflict_choose 'ours', { desc = 'Choose the OURS version of a conflict' } },
          { 'n', '<leader>ct', actions.conflict_choose 'theirs', { desc = 'Choose the THEIRS version of a conflict' } },
          { 'n', '<leader>cb', actions.conflict_choose 'base', { desc = 'Choose the BASE version of a conflict' } },
          { 'n', '<leader>ca', actions.conflict_choose 'all', { desc = 'Choose all the versions of a conflict' } },
          { 'n', 'dx', actions.conflict_choose 'none', { desc = 'Delete the conflict region' } },
          { 'n', '<leader>cO', actions.conflict_choose_all 'ours', { desc = 'Choose the OURS version of a conflict for the whole file' } },
          { 'n', '<leader>cT', actions.conflict_choose_all 'theirs', { desc = 'Choose the THEIRS version of a conflict for the whole file' } },
          { 'n', '<leader>cB', actions.conflict_choose_all 'base', { desc = 'Choose the BASE version of a conflict for the whole file' } },
          { 'n', '<leader>cA', actions.conflict_choose_all 'all', { desc = 'Choose all the versions of a conflict for the whole file' } },
          { 'n', 'dX', actions.conflict_choose_all 'none', { desc = 'Delete the conflict region for the whole file' } },
        },
      }

      require('diffview').setup(opts)
    end,
  },
}
