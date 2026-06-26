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
        -- y: filename, Y: absolute path, C-y: path relative to repo root
        ['y'] = 'copy_filename_to_clipboard',
        ['Y'] = 'copy_path_to_clipboard',
        ['<C-y>'] = 'copy_relative_path_to_clipboard',
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
      copy_relative_path_to_clipboard = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        -- Resolve the git repo root, falling back to cwd if not in a repo
        local root = vim.fn.systemlist('git -C ' .. vim.fn.fnamemodify(path, ':h') .. ' rev-parse --show-toplevel')[1]
        if vim.v.shell_error ~= 0 or not root or root == '' then
          root = vim.fn.getcwd()
        end
        local relative = vim.fn.fnamemodify(path, ':.')
        if path:sub(1, #root) == root then
          relative = path:sub(#root + 2)
        end
        vim.fn.setreg('+', relative)
        vim.notify('Copied relative path: ' .. relative)
      end,
    },
    filesystem = {
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['Y'] = function(state)
            local node = state.tree:get_node()
            vim.fn.setreg('+', node.path)
            vim.notify('Copied file path to clipboard: ' .. node.path)
          end,
          ['y'] = function(state)
            local node = state.tree:get_node()
            vim.fn.setreg('+', node.name)
            vim.notify('Copied file name to clipboard: ' .. node.name)
          end,
          ['<C-y>'] = 'copy_to_clipboard',
          ['<C-p>'] = 'paste_from_clipboard',
        },
      },
    },
  },
}
