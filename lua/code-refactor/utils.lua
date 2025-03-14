local M = {}
local config = require("code-refactor").__conf

M.replace_text_in_buffer = function(start_row, start_col, end_row, end_col, new_lines)
  -- Recover the line content from before and after the function.
  local start_line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  local end_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1]

  local prefix = start_line:sub(1, start_col)
  local suffix = end_line:sub(end_col + 1)

  new_lines[1] = prefix .. new_lines[1]
  new_lines[#new_lines] = new_lines[#new_lines] .. suffix

  -- Replace the old function with the new function.
  vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, new_lines)

  local new_end_row = start_row + #new_lines
  local new_end_row_text = vim.api.nvim_buf_get_lines(0, new_end_row - 1, new_end_row, false)[1]

  -- Format the newly created function.
  config.format({
    range = {
      start = { start_row + 1, start_col },
      ["end"] = { new_end_row, #new_end_row_text },
    },
  })
end

return M
