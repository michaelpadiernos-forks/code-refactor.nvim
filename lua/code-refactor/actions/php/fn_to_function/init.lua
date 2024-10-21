local ts_utils = require 'nvim-treesitter.ts_utils'
local utils = require 'code-refactor.utils'

local M = {
  title = 'Convert fn()=> to function(){}',
}

M.is_available = function()
  local node = ts_utils.get_node_at_cursor()
  while node ~= nil and node:type() ~= 'arrow_function' do
    node = node:parent()
  end

  return node
end

M.get_function_expression = function(node)
  local bufnr = vim.api.nvim_get_current_buf()

  local params_node = node:field('parameters')[1]
  local return_type_node = node:field('return_type')[1]
  local body_node = node:field('body')[1]

  if not params_node or not body_node then
    return nil
  end

  local params_text = vim.treesitter.get_node_text(params_node, bufnr)
  local body_text = vim.treesitter.get_node_text(body_node, bufnr)

  local return_type_text = ''
  -- adding a return type to a function is optional in PHP
  if return_type_node then
    return_type_text = ': ' .. vim.treesitter.get_node_text(return_type_node, bufnr)
  end

  return ('function ' .. params_text .. return_type_text .. ' {' .. '\n' .. 'return ' .. body_text .. ';' .. '\n}')
end

M.run = function(conf)
  local node = M.is_available()
  if not node then
    return
  end

  -- Get the current cursor position, to restore after the function is replaced.
  local win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(win)

  local start_row, start_col, end_row, end_col = node:range()

  local new_expression = M.get_function_expression(node)
  if not new_expression then
    return
  end

  utils.replace_text_in_buffer(start_row, start_col, end_row, end_col, vim.split(new_expression, '\n'))
  vim.api.nvim_win_set_cursor(win, cursor_pos)
end

return M
