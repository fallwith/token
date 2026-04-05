---@param p table palette
---@param is_dark boolean
local function terminal(p, is_dark)
  vim.g.terminal_color_0 = is_dark and p.bg1 or p.fg0
  vim.g.terminal_color_1 = p.red
  vim.g.terminal_color_2 = p.green
  vim.g.terminal_color_3 = p.yellow
  vim.g.terminal_color_4 = p.blue
  vim.g.terminal_color_5 = p.purple
  vim.g.terminal_color_6 = p.cyan
  vim.g.terminal_color_7 = is_dark and p.fg1 or p.bg1
  vim.g.terminal_color_8 = is_dark and p.fg3 or p.fg2
  vim.g.terminal_color_9 = p.accent
  vim.g.terminal_color_10 = p.bright_green
  vim.g.terminal_color_11 = p.accent2
  vim.g.terminal_color_12 = p.bright_blue
  vim.g.terminal_color_13 = p.bright_purple
  vim.g.terminal_color_14 = p.bright_cyan
  vim.g.terminal_color_15 = is_dark and p.fg0 or p.bg3
end

return terminal
