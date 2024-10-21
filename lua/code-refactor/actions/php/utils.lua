local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.get_function_node_at_cursor = function()
  local node = ts_utils.get_node_at_cursor()

  -- 'function' means non-arrow anonymous function
  while
    node ~= nil
    and node:type() ~= "function_definition"
    and node:type() ~= "anonymous_function"
    and node:type() ~= "arrow_function"
  do
    node = node:parent()
  end

  if node == nil then
    return nil
  end

  return node
end

M.get_function_info_from_node = function(node)
  if
    node:type() ~= "function_definition"
    and node:type() ~= "anonymous_function"
    and node:type() ~= "arrow_function"
  then
    return nil
  end

  -- Extract the function name, and body, and rest.
  local func_name, params, return_type, body

  local name_node = node:field("name")[1]
  local params_node = node:field("parameters")[1]
  local return_type_node = node:field("return_type")[1]
  local body_node = node:field("body")[1]

  if not params_node or not body_node then
    return nil
  end

  local buf = vim.api.nvim_get_current_buf()
  if name_node then
    func_name = vim.treesitter.get_node_text(name_node, buf)
  end
  params = vim.treesitter.get_node_text(params_node, buf)
  if return_type_node then
    return_type = vim.treesitter.get_node_text(return_type_node, buf)
  end
  body = vim.treesitter.get_node_text(body_node, buf)

  local start_row, start_col, end_row, end_col = node:range()

  return {
    func_name = func_name,
    params = params,
    return_type = return_type,
    body = body,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

return M
