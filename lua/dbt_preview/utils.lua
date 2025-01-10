--------------------------------------------------------------------------------
-- File: lua/dbt_preview/init.lua
--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
-- 1) Hardcode or auto-detect your DBT project root
--------------------------------------------------------------------------------
local PROJECT_ROOT = '/Users/fpcarvalho/Documents/solar/DBT_TEST'

--------------------------------------------------------------------------------
-- 2) Convert absolute path -> relative path, so dbt doesn't complain
--------------------------------------------------------------------------------
local function to_relative_path(abs_path)
  if abs_path:find(PROJECT_ROOT, 1, true) then
    -- strip "<PROJECT_ROOT>/" prefix
    local rel = abs_path:gsub('^' .. vim.pesc(PROJECT_ROOT .. '/'), '')
    return rel
  end
  return abs_path
end

--------------------------------------------------------------------------------
-- 3) Synchronous shell command using :systemlist (blocking)
--------------------------------------------------------------------------------
local function run_cmd(cmd, opts)
  opts = opts or {}
  if opts.chdir then
    cmd = string.format('cd %s && %s', vim.fn.shellescape(PROJECT_ROOT), cmd)
  end
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(output, '\n')
  end
  return output, nil
end

--------------------------------------------------------------------------------
-- 4) dbt compile (relative path)
--------------------------------------------------------------------------------
local function dbt_compile(rel_path)
  local cmd = string.format('dbt compile --select %s', vim.fn.shellescape(rel_path))
  return run_cmd(cmd, { chdir = true }) -- run in PROJECT_ROOT
end

--------------------------------------------------------------------------------
-- 5) Append LIMIT 200 to compiled SQL
--------------------------------------------------------------------------------
local function modify_compiled_sql(rel_path)
  local model_name = vim.fn.fnamemodify(rel_path, ':t')
  local compiled_sql_path = vim.fn.glob('target/compiled/**/' .. model_name)
  if compiled_sql_path == '' then
    return nil, '[dbt_preview] Could not find compiled SQL for: ' .. rel_path
  end

  local f = io.open(compiled_sql_path, 'r')
  if not f then
    return nil, '[dbt_preview] Failed to open compiled file: ' .. compiled_sql_path
  end
  local compiled_sql = f:read '*all'
  f:close()

  -- append LIMIT
  local modified_sql = compiled_sql .. '\nLIMIT 200;\n'

  local temp_sql_file = vim.fn.tempname() .. '.sql'
  local w = io.open(temp_sql_file, 'w')
  if not w then
    return nil, '[dbt_preview] Unable to write temp file: ' .. temp_sql_file
  end
  w:write(modified_sql)
  w:close()

  return temp_sql_file, nil
end

--------------------------------------------------------------------------------
-- 6) Run dbsqlcli in a terminal buffer with "--table-format ascii"
--    So we preserve dbsqlcli's table formatting in ASCII style.
--------------------------------------------------------------------------------
local function run_dbsqlcli_in_terminal(sql_file)
  -- We'll 'cd' to the project root to be consistent
  -- then run "dbsqlcli --table-format ascii -e <temp_file.sql>" in a terminal buffer

  vim.cmd 'enew' -- open new empty buffer
  vim.cmd 'startinsert' -- start in insert mode (typical for terminals)

  -- Notice we add "--table-format ascii" here
  local cmd = string.format('cd %s && dbsqlcli-e %s', vim.fn.shellescape(PROJECT_ROOT), vim.fn.shellescape(sql_file))

  vim.fn.termopen(cmd, {
    on_exit = function(_, code, _)
      if code == 0 then
        print '[dbt_preview] dbsqlcli finished successfully (ASCII table format).'
      else
        print('[dbt_preview] dbsqlcli exited with code: ' .. code)
      end
    end,
  })
end

--------------------------------------------------------------------------------
-- 7) Main function
--------------------------------------------------------------------------------
function M.preview_compiled_sql()
  local abs_path = vim.fn.expand '%:p'
  if abs_path == '' then
    print '[dbt_preview] No file path found.'
    return
  end

  -- Convert absolute -> relative
  local rel_path = to_relative_path(abs_path)
  print('[dbt_preview] dbt compile --select ' .. rel_path)

  -- Run dbt compile (blocking)
  local ok, err = dbt_compile(rel_path)
  if not ok then
    print('[dbt_preview] dbt compile failed:\n' .. err)
    return
  end

  -- Append LIMIT 200
  local temp_sql_file, modify_err = modify_compiled_sql(rel_path)
  if not temp_sql_file then
    print(modify_err)
    return
  end
  print '[dbt_preview] Running dbsqlcli in a terminal (ASCII format)...'

  -- dbsqlcli in terminal => preserve formatting
  run_dbsqlcli_in_terminal(temp_sql_file)
end

--------------------------------------------------------------------------------
-- 8) Setup command
--------------------------------------------------------------------------------
function M.setup()
  vim.api.nvim_create_user_command('DBTPreview', function()
    M.preview_compiled_sql()
  end, {})
end

return M
