-- File: lua/dbt_preview/init.lua

local M = {}

--------------------------------------------------------------------------------
-- 1) Helper: Extract the current file's name
--------------------------------------------------------------------------------
local function get_current_model_filename()
  local filepath = vim.fn.expand '%:p' -- full path of the current file
  local filename = vim.fn.fnamemodify(filepath, ':t') -- extract just the filename
  return filename
end

--------------------------------------------------------------------------------
-- 2) Asynchronous `dbt show -s` function
--------------------------------------------------------------------------------
local function run_dbt_show_async(model_name, on_success, on_error)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local result = {}

  local handle = vim.loop.spawn('dbt', {
    args = { 'show', '-s', model_name },
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    if code == 0 then
      on_success(table.concat(result, '\n'))
    else
      on_error '[dbt_preview] Error running `dbt show -s`'
    end
  end)

  vim.loop.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then
      table.insert(result, data)
    end
  end)

  vim.loop.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then
      table.insert(result, data)
    end
  end)
end

--------------------------------------------------------------------------------
-- 3) Main preview function with loading indicator
--------------------------------------------------------------------------------
function M.preview_compiled_sql()
  -- (a) Get the current model filename
  local model_name = get_current_model_filename()
  if not model_name or model_name == '' then
    print '[dbt_preview] Could not determine the filename of the current file.'
    return
  end

  -- (b) Show loading indicator
  print '[dbt_preview] Running `dbt show -s`...'

  -- (c) Run `dbt show -s` asynchronously
  run_dbt_show_async(model_name, function(output)
    -- Success callback: display results in a new buffer
    vim.schedule(function()
      vim.cmd 'aboveleft vnew' -- split a new window above the current one
      local buf = vim.api.nvim_create_buf(true, true) -- create a listed, scratch buffer
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n')) -- set output lines
      vim.api.nvim_buf_set_option(buf, 'filetype', 'sql')

      print '[dbt_preview] Output from `dbt show` displayed.'
    end)
  end, function(error_msg)
    -- Error callback: show error message
    vim.schedule(function()
      print(error_msg)
    end)
  end)
end

--------------------------------------------------------------------------------
-- 4) Create the :DBTPreview user command
--------------------------------------------------------------------------------
function M.setup()
  vim.api.nvim_create_user_command('DBTPreview', function()
    M.preview_compiled_sql()
  end, {})
end

return M
