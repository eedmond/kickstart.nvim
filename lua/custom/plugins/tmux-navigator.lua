return {
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate left (nvim/tmux)' },
      { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate down (nvim/tmux)' },
      { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate up (nvim/tmux)' },
      { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate right (nvim/tmux)' },
      { '<C-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate to previous (nvim/tmux)' },
    },
  },
}
