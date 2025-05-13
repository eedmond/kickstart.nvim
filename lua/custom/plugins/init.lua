-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'altermo/ultimate-autopair.nvim',
    event = { 'InsertEnter', 'CmdlineEnter' },
    branch = 'v0.6', --recommended as each new version will have breaking changes
    opts = {
      --Config goes here
    },
  },
  {
    'wojciech-kulik/xcodebuild.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'MunifTanjim/nui.nvim',
      -- 'folke/snacks.nvim', -- (optional) to show previews
      'nvim-tree/nvim-tree.lua', -- (optional) to manage project files
      'stevearc/oil.nvim', -- (optional) to manage project files
      'nvim-treesitter/nvim-treesitter', -- (optional) for Quick tests support (required Swift parser)
    },
    config = function()
      require('xcodebuild').setup {
        -- put some options here or leave it empty to use default settings
      }
    end,
  },
  { 'catppuccin/nvim', name = 'catppuccin', flavour = 'mocha', priority = 1000 },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    config = function()
      vim.keymap.set('n', '<Leader>mp', '<Plug>MarkdownPreview', { desc = 'Markdown Preview' })
    end,
  },
}
