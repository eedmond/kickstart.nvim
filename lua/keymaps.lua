-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Marks
vim.keymap.set('n', '<leader>ml', '<cmd>marks<CR>', { desc = '[M]arks [L]ist' })

-- [[ Lists ]]
-- Strips a leading bullet (-, *, +) or ordered marker (1., a., iv.) from text
local function strip_marker(text)
  for _, pattern in ipairs { '^[-*+]%s+', '^%d+[.)]%s+', '^%l[.)]%s+', '^[ivxlcdm]+[.)]%s+' } do
    local stripped, n = text:gsub(pattern, '', 1)
    if n > 0 then
      return stripped
    end
  end
  return text
end

local function to_alpha(n)
  local s = ''
  while n > 0 do
    n = n - 1
    s = string.char(97 + n % 26) .. s
    n = math.floor(n / 26)
  end
  return s
end

local function to_roman(n)
  local numerals = { { 1000, 'm' }, { 900, 'cm' }, { 500, 'd' }, { 400, 'cd' }, { 100, 'c' }, { 90, 'xc' }, { 50, 'l' }, { 40, 'xl' }, { 10, 'x' }, { 9, 'ix' }, { 5, 'v' }, { 4, 'iv' }, { 1, 'i' } }
  local s = ''
  for _, pair in ipairs(numerals) do
    while n >= pair[1] do
      s = s .. pair[2]
      n = n - pair[1]
    end
  end
  return s
end

-- Nesting levels cycle 1. -> a. -> i. -> 1. ...
local function ordered_marker(level, count)
  local style = (level - 1) % 3
  if style == 0 then
    return count .. '. '
  elseif style == 1 then
    return to_alpha(count) .. '. '
  end
  return to_roman(count) .. '. '
end

-- Rewrites non-blank lines with make_marker(level, count); if nothing would change, strips markers instead
local function toggle_list(first, last, make_marker)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local new, stripped, stack = {}, {}, {}
  for i, line in ipairs(lines) do
    new[i], stripped[i] = line, line
    if line:match '%S' then
      local indent, rest = line:match '^(%s*)(.*)$'
      local width = #indent
      -- Stack of { indent, count } tracks the counter for each nesting level
      while #stack > 0 and stack[#stack].indent > width do
        table.remove(stack)
      end
      if #stack == 0 or stack[#stack].indent < width then
        table.insert(stack, { indent = width, count = 0 })
      end
      stack[#stack].count = stack[#stack].count + 1
      rest = strip_marker(rest)
      new[i] = indent .. make_marker(#stack, stack[#stack].count) .. rest
      stripped[i] = indent .. rest
    end
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, vim.deep_equal(new, lines) and stripped or new)
end

-- Checkboxes: set all to the mark (optionally adding empty boxes first), then uncheck all
local function checkbox_state(line)
  local mark = line:match '%[([ xX%-])%]'
  return mark and mark:lower()
end

local function add_checkbox(line, mark)
  -- Insert the box after an existing list marker, otherwise make the line a bullet item
  local indent, rest = line:match '^(%s*)(.*)$'
  local text = strip_marker(rest)
  local marker = rest:sub(1, #rest - #text)
  if marker == '' then
    marker = '* '
  end
  return indent .. marker .. '[' .. mark .. '] ' .. text
end

local function toggle_checkboxes(first, last, mark, add_empty)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local targets, missing, any_unmarked = {}, false, false
  for i, line in ipairs(lines) do
    if line:match '%S' then
      table.insert(targets, i)
      local state = checkbox_state(line)
      if not state then
        missing = true
      elseif state ~= mark then
        any_unmarked = true
      end
    end
  end
  if #targets == 0 then
    return
  end

  for _, i in ipairs(targets) do
    if not checkbox_state(lines[i]) then
      lines[i] = add_checkbox(lines[i], add_empty and ' ' or mark)
    elseif not (missing and add_empty) then
      lines[i] = lines[i]:gsub('%[[ xX%-]%]', (missing or any_unmarked) and '[' .. mark .. ']' or '[ ]', 1)
    end
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

-- Maps lhs in normal mode (current line) and visual mode (selected lines) to fn(first, last)
local function map_lines(lhs, fn, desc)
  vim.keymap.set('n', lhs, function()
    local lnum = vim.fn.line '.'
    fn(lnum, lnum)
  end, { desc = desc })
  vim.keymap.set('x', lhs, function()
    local first, last = vim.fn.line 'v', vim.fn.line '.'
    if first > last then
      first, last = last, first
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
    fn(first, last)
  end, { desc = desc })
end

map_lines('<leader>ln', function(first, last)
  toggle_list(first, last, ordered_marker)
end, '[L]ist [N]umbered')
map_lines('<leader>lb', function(first, last)
  toggle_list(first, last, function()
    return '* '
  end)
end, '[L]ist [B]ullets')
map_lines('<leader>lc', function(first, last)
  toggle_checkboxes(first, last, 'x', true)
end, '[L]ist [C]heckbox')
map_lines('<leader>lw', function(first, last)
  toggle_checkboxes(first, last, '-')
end, '[L]ist [W]ork in progress')

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
