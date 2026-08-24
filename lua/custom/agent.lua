-- Ask a coding agent (Claude by default) about the current file/selection and let it edit.
-- <leader>a in normal mode attaches the current file + cursor line; in visual mode the range.
-- Runs headless & async (nvim never blocks), auto-accepts edits, reloads the buffer afterwards.
-- The response float supports `r` to reply, resuming the same session for multi-turn back-and-forth.

local M = {}

-- Forward declarations so the UI helpers can reference each other.
local open_prompt, open_response

M.config = {
  default = 'claude', -- which agent key below to use
  keymap = '<leader>a', -- ask about the current file/selection
  continue_keymap = '<leader>A', -- continue the most recent project chat
  agents = {
    claude = {
      cmd = 'claude',
      -- Prompt goes over stdin to avoid positional/variadic arg clashes.
      -- resume: nil (fresh) · { id = <session> } (--resume) · { continue = true } (--continue).
      build = function(full, resume)
        local args = {
          '-p',
          '--output-format',
          'json',
          '--permission-mode',
          'acceptEdits',
          '--allowedTools',
          'Read',
          'Edit',
          'Write',
          'MultiEdit',
          'Grep',
          'Glob',
        }
        if resume and resume.id then
          vim.list_extend(args, { '--resume', resume.id })
        elseif resume and resume.continue then
          table.insert(args, '--continue')
        end
        return { args = args, stdin = full }
      end,
      -- JSON output carries the reply text and a session id for follow-ups.
      parse = function(out)
        local ok, obj = pcall(vim.json.decode, out)
        if ok and type(obj) == 'table' then
          return obj.result, obj.session_id
        end
        return out, nil
      end,
    },
    gemini = {
      cmd = 'gemini',
      build = function(full, _resume)
        -- Gemini has no simple headless resume, so follow-ups start fresh.
        return { args = { '-p', full, '--approval-mode', 'auto_edit' }, stdin = nil }
      end,
      parse = function(out)
        return out, nil
      end,
    },
  },
}

-- Snapshot of what the user is looking at when they invoke the agent.
local function current_ctx()
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    file = vim.fn.expand '%:p',
    line = vim.fn.line '.',
    ft = vim.bo.filetype,
  }
end

-- Build the context preamble prepended to the user's prompt on the first turn.
local function build_context(ctx)
  local rel = ctx.file ~= '' and vim.fn.fnamemodify(ctx.file, ':.') or '[unnamed buffer]'
  if ctx.line1 and ctx.line2 then
    local sel = vim.api.nvim_buf_get_lines(ctx.bufnr, ctx.line1 - 1, ctx.line2, false)
    local lines = { string.format('File `%s`, lines %d-%d:', rel, ctx.line1, ctx.line2), '```' .. (ctx.ft or '') }
    vim.list_extend(lines, sel)
    table.insert(lines, '```')
    return table.concat(lines, '\n')
  end
  return string.format('File `%s` (cursor on line %d).', rel, ctx.line)
end

-- Centered floating window backing both the prompt and response UIs.
local function float(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(90, math.floor(vim.o.columns * 0.7))
  local height = opts.height or math.floor(vim.o.lines * 0.5)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = opts.title,
    title_pos = 'center',
  })
  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end
  return buf, win
end

-- Animated indicator shown bottom-right while the agent runs (JSON mode returns nothing until done).
local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local function spinner_start(label)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - 2,
    col = vim.o.columns - 1,
    width = 32,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true,
    zindex = 200,
  })
  vim.wo[win].winhl = 'Normal:Comment,FloatBorder:Comment'
  local timer = vim.uv.new_timer()
  local i, start = 0, vim.uv.now()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      i = (i % #spinner_frames) + 1
      local secs = math.floor((vim.uv.now() - start) / 1000)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.format(' %s %s  %ds', spinner_frames[i], label, secs) })
    end)
  )
  return function()
    timer:stop()
    timer:close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
end

-- Spawn the configured agent asynchronously and surface the result.
-- resume: nil · { id = <session> } (reply in a conversation) · { continue = true } (last project chat).
function M.run(ctx, user_prompt, resume)
  local agent = M.config.agents[M.config.default]
  if not agent then
    vim.notify('agent: unknown agent "' .. M.config.default .. '"', vim.log.levels.ERROR)
    return
  end

  -- Flush unsaved changes so the agent reads the current content.
  if vim.bo[ctx.bufnr].modified and vim.api.nvim_buf_get_name(ctx.bufnr) ~= '' then
    vim.api.nvim_buf_call(ctx.bufnr, function()
      vim.cmd 'silent write'
    end)
  end

  -- A reply within a conversation (id) already has the context; fresh & continued runs prepend it.
  local prepend = not (resume and resume.id)
  local full = prepend and (build_context(ctx) .. '\n\n' .. user_prompt) or user_prompt
  local built = agent.build(full, resume)
  local cmd = { agent.cmd }
  vim.list_extend(cmd, built.args)

  local stop_spinner = spinner_start(M.config.default .. ' working…')
  vim.system(cmd, { text = true, stdin = built.stdin, cwd = vim.fn.getcwd() }, function(res)
    vim.schedule(function()
      stop_spinner()
      if res.code ~= 0 then
        vim.notify('agent failed: ' .. (res.stderr ~= '' and res.stderr or res.stdout or 'unknown'), vim.log.levels.ERROR, { title = 'agent' })
        return
      end
      vim.cmd 'checktime' -- reload any files the agent edited
      local text, sid = agent.parse(res.stdout or '')
      open_response(ctx, text, sid)
      vim.cmd 'redraw' -- force the float to paint even if nvim was idle
    end)
  end)
end

-- Multi-line prompt box. <CR> (normal) or <C-s> (insert) sends; q/<Esc> cancels.
function open_prompt(ctx, resume)
  local title = ' Ask agent  (⏎ send · q cancel) '
  if resume and resume.continue then
    title = ' Continue last chat  (⏎ send · q cancel) '
  elseif resume then
    title = ' Follow-up  (⏎ send · q cancel) '
  end
  local buf, win = float { title = title, filetype = 'markdown', height = math.floor(vim.o.lines * 0.35) }
  vim.cmd 'startinsert'

  local function submit()
    local prompt = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
    if vim.trim(prompt) == '' then
      return
    end
    vim.api.nvim_win_close(win, true)
    M.run(ctx, prompt, resume)
  end
  local function cancel()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', '<CR>', submit, { buffer = buf })
  vim.keymap.set('i', '<C-s>', submit, { buffer = buf })
  vim.keymap.set('n', 'q', cancel, { buffer = buf })
  vim.keymap.set('n', '<Esc>', cancel, { buffer = buf })
end

-- Show the agent's reply. `r` opens a follow-up that resumes the session; q/<Esc> closes.
function open_response(ctx, text, session_id)
  if not text or text == '' then
    text = '(no text response — the file may have been edited directly)'
  end
  local buf, win = float { title = ' agent  (r reply · q close) ', filetype = 'markdown' }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, '\n', { plain = true }))
  vim.bo[buf].modifiable = false

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set('n', 'q', close, { buffer = buf })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf })
  vim.keymap.set('n', 'r', function()
    close()
    -- Resume by id when we have one, otherwise fall back to continuing the last chat.
    open_prompt(ctx, session_id and { id = session_id } or { continue = true })
  end, { buffer = buf })
end

-- Normal-mode entry: attach the current file + cursor line.
function M.ask()
  open_prompt(current_ctx(), nil)
end

-- Continue the most recent conversation in this project (persisted on disk across restarts).
function M.continue()
  open_prompt(current_ctx(), { continue = true })
end

-- Visual-mode entry (invoked via <Cmd> so the selection stays live).
function M.ask_visual()
  local a, b = vim.fn.line 'v', vim.fn.line '.'
  local ctx = current_ctx()
  ctx.line1, ctx.line2 = math.min(a, b), math.max(a, b)
  open_prompt(ctx, nil)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  vim.o.autoread = true -- let :checktime pull in the agent's edits

  local key = M.config.keymap
  vim.keymap.set('n', key, M.ask, { desc = '[A]gent: ask about file' })
  vim.keymap.set('x', key, "<Cmd>lua require('custom.agent').ask_visual()<CR>", { desc = '[A]gent: ask about selection' })
  vim.keymap.set('n', M.config.continue_keymap, M.continue, { desc = '[A]gent: continue last chat' })

  -- :Agent (optionally with a range) mirrors the keymaps.
  vim.api.nvim_create_user_command('Agent', function(o)
    if o.range ~= 0 then
      local ctx = current_ctx()
      ctx.line1, ctx.line2 = o.line1, o.line2
      open_prompt(ctx, nil)
    else
      M.ask()
    end
  end, { range = true, desc = 'Ask the coding agent' })

  -- :AgentContinue resumes the most recent conversation in this project.
  vim.api.nvim_create_user_command('AgentContinue', function()
    M.continue()
  end, { desc = 'Continue the last agent chat' })

  -- :AgentUse claude|gemini switches the active agent for the session.
  vim.api.nvim_create_user_command('AgentUse', function(o)
    if M.config.agents[o.args] then
      M.config.default = o.args
      vim.notify('agent: using ' .. o.args, vim.log.levels.INFO)
    else
      vim.notify('agent: unknown agent "' .. o.args .. '"', vim.log.levels.ERROR)
    end
  end, { nargs = 1, complete = function()
    return vim.tbl_keys(M.config.agents)
  end, desc = 'Switch the active coding agent' })
end

return M
