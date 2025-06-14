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
  },
}
