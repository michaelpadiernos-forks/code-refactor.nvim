local php_utils = require("code-refactor.actions.php.utils")
local utils = require("code-refactor.utils")

local M = {}

local function get_title()
  local node = php_utils.get_function_node_at_cursor()
  if node == nil then
    return ""
  end

  if node:type() == "arrow_function" then
    return "Convert arrow function to function declaration"
  end

  return "Convert function declaration to arrow function"
end

M.is_available = function()
  M.title = get_title()
  return php_utils.get_function_node_at_cursor()
end

M.run = function()
  local node = M.is_available()
  if not node then
    return
  end

  local func_info = php_utils.get_function_info_from_node(node)
  if not func_info then
    return
  end

  -- Get the current cursor position, to restore after the function is replaced.
  local win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(win)

  -- Adding a return type to a function is optional in PHP.
  local return_type_text = ""
  if func_info.return_type then
    return_type_text = ": " .. func_info.return_type
  end

  local buf = vim.api.nvim_get_current_buf()

  -- Simplify return statement when converting to arrow.
  if node:type() ~= "arrow_function" then
    local body_node = node:field("body")[1]
    if body_node:type() ~= "compound_statement" then
      return
    end

    local return_stmt_node = body_node:named_child(0)
    if not return_stmt_node or return_stmt_node:type() ~= "return_statement" then
      vim.print("Can't convert to arrow function because function body is too complex.")
      return
    end

    func_info.body = vim.treesitter.get_node_text(return_stmt_node:named_child(0), buf)
  end

  -- Construct the new function.
  local new_func
  if node:type() == "function_definition" or node:type() == "anonymous_function" then
    new_func = "fn" .. func_info.params .. return_type_text .. " => " .. func_info.body
  else
    new_func = "function "
      .. (func_info.func_name or "")
      .. func_info.params
      .. return_type_text
      .. " {\n  return "
      .. func_info.body
      .. ";\n}"
  end

  utils.replace_text_in_buffer(
    func_info.start_row,
    func_info.start_col,
    func_info.end_row,
    func_info.end_col,
    vim.split(new_func, "\n")
  )
  vim.api.nvim_win_set_cursor(win, cursor_pos)
end

return M
