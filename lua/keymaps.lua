-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Marks
vim.keymap.set('n', '<leader>ml', '<cmd>marks<CR>', { desc = '[M]arks [L]ist' })

-- Markdown checkboxes: add missing boxes first, then check all, then uncheck all
local function checkbox_state(line)
  if line:match '%[[xX]%]' then
    return 'checked'
  elseif line:match '%[ %]' then
    return 'unchecked'
  end
end

local function add_checkbox(line)
  -- Insert the box after an existing list marker, otherwise make the line a list item
  local indent, marker, rest = line:match '^(%s*)([-*+]%s+)(.*)$'
  if not marker then
    indent, marker, rest = line:match '^(%s*)(%d+[.)]%s+)(.*)$'
  end
  if marker then
    return indent .. marker .. '[ ] ' .. rest
  end
  local text
  indent, text = line:match '^(%s*)(.*)$'
  return indent .. '- [ ] ' .. text
end

local function toggle_checkboxes(first, last)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local targets, missing, any_unchecked = {}, false, false
  for i, line in ipairs(lines) do
    if line:match '%S' then
      table.insert(targets, i)
      local state = checkbox_state(line)
      if not state then
        missing = true
      elseif state == 'unchecked' then
        any_unchecked = true
      end
    end
  end
  if #targets == 0 then
    return
  end

  for _, i in ipairs(targets) do
    if missing then
      if not checkbox_state(lines[i]) then
        lines[i] = add_checkbox(lines[i])
      end
    elseif any_unchecked then
      lines[i] = lines[i]:gsub('%[ %]', '[x]', 1)
    else
      lines[i] = lines[i]:gsub('%[[xX]%]', '[ ]', 1)
    end
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

vim.keymap.set('n', '<leader>mx', function()
  local lnum = vim.fn.line '.'
  toggle_checkboxes(lnum, lnum)
end, { desc = '[M]arkdown toggle checkbo[x]' })

vim.keymap.set('x', '<leader>mx', function()
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  if first > last then
    first, last = last, first
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  toggle_checkboxes(first, last)
end, { desc = '[M]arkdown toggle checkbo[x]' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Split navigation between nvim windows AND tmux panes is handled by
-- vim-tmux-navigator (lua/custom/plugins/tmux-navigator.lua).

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
