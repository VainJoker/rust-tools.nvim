local A = vim.api
local fn = vim.fn
local cmd = A.nvim_command

---@return table
local function get_dimension(opts)
    -- get lines and columns
    local cl = vim.o.columns
    local ln = vim.o.lines

    -- calculate our floating window size
    local width = math.ceil(cl * opts.width)
    local height = math.ceil(ln * opts.height - 4)

    -- and its starting position
    local col = math.ceil((cl - width) * opts.x)
    local row = math.ceil((ln - height) * opts.y - 1)

    return {
        width = width,
        height = height,
        col = col,
        row = row,
    }
end

---Check whether the window is valid
---@param win number Window ID
---@return boolean
local function is_win_valid(win)
    return win and A.nvim_win_is_valid(win)
end

---Check whether the buffer is valid
---@param buf number Buffer ID
---@return boolean
local function is_buf_valid(buf)
    return buf and A.nvim_buf_is_loaded(buf)
end

local function is_command(command)
    return type(command) == 'function' and command() or command
end

local Term = {}

local defaults = {
  shell = 'fish',
    -- cmd = function()
    --     return assert(
    --         os.getenv('SHELL'),
    --         '[FTerm] $SHELL is not present! Please provide a shell (`config.cmd`) to use.'
    --     )
    -- end,
    border = 'single',
    auto_close = true,
    hl = 'Normal',
    blend = 0,
    clear_env = false,
    dimensions = {
        height = 0.8,
        width = 0.8,
        x = 0.5,
        y = 0.5,
    },
}

function Term:new()
    return setmetatable({
        win = nil,
        buf = nil,
        terminal = nil,
        config = defaults,
    }, { __index = self })
end

function Term:store(win, buf)
    self.win = win
    self.buf = buf

    return self
end

function Term:remember_cursor()
    self.last_win = A.nvim_get_current_win()
    self.prev_win = fn.winnr('#')
    self.last_pos = A.nvim_win_get_cursor(self.last_win)

    return self
end

function Term:restore_cursor()
    if self.last_win and self.last_pos ~= nil then
        if self.prev_win > 0 then
            cmd(('silent! %s wincmd w'):format(self.prev_win))
        end

        if is_win_valid(self.last_win) then
            A.nvim_set_current_win(self.last_win)
            A.nvim_win_set_cursor(self.last_win, self.last_pos)
        end

        self.last_win = nil
        self.prev_win = nil
        self.last_pos = nil
    end

    return self
end

function Term:create_buf()
    -- If previous buffer exists then return it
    local prev = self.buf

    if is_buf_valid(prev) then
        return prev
    end

    local buf = A.nvim_create_buf(false, true)

    -- this ensures filetype is set to Fterm on first run
    -- A.nvim_buf_set_option(buf, 'filetype', self.config.ft)

    return buf
end

function Term:create_win(buf)
    local cfg = self.config

    local dim = get_dimension(cfg.dimensions)

    local win = A.nvim_open_win(buf, true, {
        border = cfg.border,
        relative = 'editor',
        style = 'minimal',
        width = dim.width,
        height = dim.height,
        col = dim.col,
        row = dim.row,
    })

    return win
end

---Term:handle_exit gracefully closed/kills the terminal
---@private
function Term:handle_exit(job_id, code, ...)
    if self.config.auto_close and code == 0 then
        self:close(true)
    end
    if self.config.on_exit then
        self.config.on_exit(job_id, code, ...)
    end
end

function Term:prompt()
    -- cmd('startinsert')
    return self
end

function Term:open_term()

    -- NOTE: `termopen` will fails if the current buffer is modified
    self.terminal = fn.termopen(is_command(self.config.shell), {
        clear_env = self.config.clear_env,
        env = self.config.env,
        on_stdout = self.config.on_stdout,
        on_stderr = self.config.on_stderr,
        on_exit = function(...)
            self:handle_exit(...)
        end,
    })

    -- This prevents the filetype being changed to `term` instead of `FTerm` when closing the floating window
    -- A.nvim_buf_set_option(self.buf, 'filetype', self.config.ft)
    -- A.nvim_buf_set_config(self.buf, {
    --   filetype = 'terminal'
    -- })

    return self:prompt()
end

function Term:open()
    -- Move to existing window if the window already exists
    if is_win_valid(self.win) then
        return A.nvim_set_current_win(self.win)
    end

    self:remember_cursor()

    -- Create new window and terminal if it doesn't exist
    local buf = self:create_buf()
    local win = self:create_win(buf)

    -- This means we are just toggling the terminal
    -- So we don't have to call `:open_term()`
    if self.buf == buf then
        return self:store(win, buf):prompt()
    end

    return self:store(win, buf):open_term()
end

function Term:close(force)
    if not is_win_valid(self.win) then
        return self
    end

    A.nvim_win_close(self.win, force)

    self.win = nil

    if force then
        if is_buf_valid(self.buf) then
            A.nvim_buf_delete(self.buf, { force = true })
        end

        fn.jobstop(self.terminal)

        self.buf = nil
        self.terminal = nil
    end

    self:restore_cursor()

    return self
end

function Term:toggle()
    -- If window is stored and valid then it is already opened, then close it
    if is_win_valid(self.win) then
        self:close()
    else
        self:open()
    end

    return self
end

function Term:run(command)
    self:open()
    local exec = is_command(command)
    A.nvim_chan_send(
        self.terminal,
        table.concat({
            type(exec) == 'table' and table.concat(exec, ' ') or exec,
            A.nvim_replace_termcodes('<CR>', true, true, true),
        })
    )
    return self
end

-- function Term:open_term(command)
--
--     self.terminal = fn.termopen(command, {
--         clear_env = self.config.clear_env,
--         env = self.config.env,
--         on_stdout = self.config.on_stdout,
--         on_stderr = self.config.on_stderr,
--         on_exit = function(...)
--             self:handle_exit(...)
--         end,
--     })
--
--     -- This prevents the filetype being changed to `term` instead of `FTerm` when closing the floating window
--     -- A.nvim_buf_set_option(self.buf, 'filetype', self.config.ft)
--     -- A.nvim_buf_set_config(self.buf, {
--     --   filetype = 'terminal'
--     -- })
--
--     return self:prompt()
-- end
--
-- function Term:open(command)
--     -- Move to existing window if the window already exists
--     if is_win_valid(self.win) then
--         return A.nvim_set_current_win(self.win)
--     end
--
--     self:remember_cursor()
--
--     -- Create new window and terminal if it doesn't exist
--     local buf = self:create_buf()
--     local win = self:create_win(buf)
--
--     -- This means we are just toggling the terminal
--     -- So we don't have to call `:open_term()`
--     if self.buf == buf then
--         return self:store(win, buf):prompt()
--     end
--
--     return self:store(win, buf):open_term(command)
-- end

function Term:executor(command)
    local exec = is_command(command)
    -- self:open(exec)
    -- vim.fn.termopen('echo hello')
    -- A.nvim_chan_send(
    --     self.terminal,
    --     table.concat({
    --         type(exec) == 'table' and table.concat(exec, ' ') or exec,
    --         A.nvim_replace_termcodes('<CR>', true, true, true),
    --     })
    -- )
    -- return self
end


return Term
