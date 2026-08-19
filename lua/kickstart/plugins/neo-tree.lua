-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    window = {
      mappings = {
        -- y: copy just the filename, Y: copy the absolute path
        ['y'] = 'copy_filename_to_clipboard',
        ['Y'] = 'copy_path_to_clipboard',
      },
    },
    commands = {
      copy_filename_to_clipboard = function(state)
        local node = state.tree:get_node()
        local filename = node.name
        vim.fn.setreg('+', filename)
        vim.notify('Copied filename: ' .. filename)
      end,
      copy_path_to_clipboard = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        vim.fn.setreg('+', path)
        vim.notify('Copied path: ' .. path)
      end,
    },
    filesystem = {
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
