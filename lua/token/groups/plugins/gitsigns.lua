---@param p TokenPalette
---@return table<string, vim.api.keyset.highlight>
local function gitsigns(p)
  return {
    GitSignsAdd = { fg = p.gsign_add },
    GitSignsChange = { fg = p.gsign_change },
    GitSignsDelete = { fg = p.gsign_del },
    GitSignsTopdelete = { fg = p.gsign_del },
    GitSignsChangedelete = { fg = p.gsign_change },
    GitSignsUntracked = { fg = p.gsign_untracked },
    GitSignsAddNr = { link = 'GitSignsAdd' },
    GitSignsChangeNr = { link = 'GitSignsChange' },
    GitSignsDeleteNr = { link = 'GitSignsDelete' },
    GitSignsAddLn = { bg = p.diff_add },
    GitSignsChangeLn = { bg = p.diff_change },
    GitSignsAddInline = { bg = p.diff_add_inline },
    GitSignsChangeInline = { bg = p.diff_text },
    GitSignsDeleteInline = { bg = p.diff_del_inline },
    GitSignsAddLnInline = { link = 'GitSignsAddInline' },
    GitSignsChangeLnInline = { link = 'GitSignsChangeInline' },
    GitSignsDeleteLnInline = { link = 'GitSignsDeleteInline' },
    GitSignsAddPreview = { bg = p.diff_add },
    GitSignsDeletePreview = { bg = p.diff_del },
    GitSignsStagedAdd = { fg = p.gsign_add_staged },
    GitSignsStagedChange = { fg = p.gsign_change_staged },
    GitSignsStagedDelete = { fg = p.gsign_del_staged },
    GitSignsStagedTopdelete = { fg = p.gsign_del_staged },
    GitSignsStagedChangedelete = { fg = p.gsign_change_staged },
    GitSignsStagedUntracked = { fg = p.gsign_untracked_staged },
    GitSignsStagedAddNr = { link = 'GitSignsStagedAdd' },
    GitSignsStagedChangeNr = { link = 'GitSignsStagedChange' },
    GitSignsStagedDeleteNr = { link = 'GitSignsStagedDelete' },
    GitSignsCurrentLineBlame = { fg = p.fg3, italic = true },
  }
end

return gitsigns
