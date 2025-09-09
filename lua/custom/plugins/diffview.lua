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
        fold = ' ',
        diff = '╱',
        wbr = '─',
        msgsep = '─',
        horiz = ' ',
        horizup = '│',
        horizdown = '│',
        vertright = '│',
        vertleft = '│',
        verthoriz = '│',
      }

      local colors = {
        '#40a02b', -- 0 Green
        '#d20f39', -- 1 Red
        '#1e66f5', -- 2 Blue
        '#179299', -- 3 Teal
        '#fe640b', -- 4 Peach
        '#df8e1d', -- 5 Yellow
        '#8839ef', -- 6 Mauve
        '#40a02b', -- 7 Green
        '#ea76cb', -- 8 Pink
        '#4c4f69', -- 9 Text
        '#1e1e2d', -- 10 Base
      }
      vim.api.nvim_set_hl(0, 'DiffAdd', { fg = colors[0], bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'DiffDelete', { fg = colors[9], bg = colors[10] })
      vim.api.nvim_set_hl(0, 'DiffChange', { fg = colors[2], bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'DiffText', { fg = colors[3], bg = 'NONE' })

      vim.api.nvim_set_hl(0, 'DiffAdded', { fg = colors[0], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffRemoved', { fg = colors[1], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffChanged', { fg = colors[2], bg = 'NONE', bold = true })

      vim.api.nvim_set_hl(0, 'DiffviewWinSeparator', { fg = colors[9], bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'DiffviewDiffDelete', { fg = colors[9], bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'DiffviewFilePanelSelected', { fg = colors[6], bg = 'NONE' })

      vim.api.nvim_set_hl(0, 'DiffviewStatusAdded', { fg = colors[0], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffviewStatusUntracked', { fg = colors[8], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffviewStatusModified', { fg = colors[4], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffviewStatusRenamed', { fg = colors[3], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffviewStatusDeleted', { fg = colors[1], bg = 'NONE', bold = true })
      vim.api.nvim_set_hl(0, 'DiffviewStatusIgnored', { fg = colors[9], bg = 'NONE', bold = true })
      require('diffview').setup(opts)
    end,
  },
}
