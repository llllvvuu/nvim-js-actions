local ts_utils = require('nvim-treesitter.ts_utils')

local M = {}

local function ensure_parentheses(str)
  if not string.find(str, "^%s*%(") then
    return "(" .. str .. ")"
  end
  return str
end

local function toggle_arrow_vs_function()
  local node = ts_utils.get_node_at_cursor()

  -- 'function' means non-arrow anonymous function
  while node ~= nil
      and node:type() ~= 'function_declaration'
      and node:type() ~= 'function'
      and node:type() ~= 'arrow_function' do
    node = node:parent()
  end

  if node == nil then
    vim.notify("Cursor is not in a function.")
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = node:range()
  local children = ts_utils.get_named_children(node)

  -- Get the current cursor position, to restore after the function is replaced
	local win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(win)

  -- Extract the function name, and body, and rest
  local func_name, body
  local rest = {}

  if node:type() == 'function_declaration' then
    func_name = vim.treesitter.get_node_text(children[1], buf)
    body = vim.treesitter.get_node_text(children[#children], buf)

    for i=2, #children-1 do
      table.insert(rest, vim.treesitter.get_node_text(children[i], buf))
    end
  else
    local parent = node:parent()
    if parent:type() == 'variable_declarator' then
      start_row, start_col, _, _ = parent:parent():range()
      func_name = vim.treesitter.get_node_text(parent:named_child(0), buf)
    else
      func_name = ''
    end

    body = vim.treesitter.get_node_text(children[#children], buf)
    if children[#children]:type() ~= 'statement_block' then
      body = "{\nreturn " .. body .. "\n}"
    end

    for i=1, #children-1 do
      local child_text = vim.treesitter.get_node_text(children[i], buf)
      -- parameter without parentheses needs to get parenthesized
      if children[i]:type() == 'identifier' then
        child_text = ensure_parentheses(child_text)
      end
      table.insert(rest, child_text)
    end
  end

  local rest_str = table.concat(rest)

  -- Simplify return statement if possible when converting to arrow
  if node:type() ~= 'arrow_function' then
    local body_node = children[#children]
    if body_node:type() == 'statement_block' then
      local return_stmt_node = body_node:named_child(0)
      if return_stmt_node and return_stmt_node:type() == 'return_statement' then
        body = vim.treesitter.get_node_text(
            return_stmt_node:named_child(0), buf)
      end
    end
  end

  -- Construct the new function
  local new_func
  if node:type() == 'function_declaration' then
    new_func = "const " .. func_name .. " = " .. rest_str .. " => " .. body
  elseif node:type() == 'function' then
    new_func = rest_str .. " => " .. body
  else
    new_func = "function " .. func_name ..  rest_str .. " " .. body
  end

  local new_func_lines = vim.split(new_func, "\n")

  -- Recover the line content from before and after the function
  local start_line = vim.api.nvim_buf_get_lines(
    0,
    start_row,
    start_row + 1,
    false
  )[1]
  local end_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1]

  local prefix = start_line:sub(1, start_col)
  local suffix = end_line:sub(end_col + 1)

  new_func_lines[1] = prefix .. new_func_lines[1]
  new_func_lines[#new_func_lines] = new_func_lines[#new_func_lines] .. suffix

  -- Replace the old function with the new function
  vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, new_func_lines)

  local new_end_row = start_row + #new_func_lines
  local new_end_row_text = vim.api.nvim_buf_get_lines(
    0,
    new_end_row-1,
    new_end_row,
    false
  )[1]

  -- Fix the formatting
  vim.cmd('normal! ' .. start_row+1 .. 'G=' .. new_end_row .. 'G')
  vim.lsp.buf.format({
    range = {
      ["start"] = { start_row + 1, start_col },
      ["end"] = { start_row + #new_func_lines, #new_end_row_text },
    }
  })

  -- Restore cursor position
  vim.api.nvim_win_set_cursor(win, cursor_pos)
end

M.toggle = toggle_arrow_vs_function

return M
