---@param p TokenPalette
---@return table<string, vim.api.keyset.highlight>
local function nvimtree(p)
  return {
    NvimTreeNormal = { fg = p.fg0, bg = p.bg1 },
    NvimTreeNormalNC = { fg = p.fg0, bg = p.bg1 },
    NvimTreeWinSeparator = { fg = p.bg4, bg = p.bg1 },
    NvimTreeEndOfBuffer = { fg = p.bg1 },
    NvimTreeCursorLine = { bg = p.bg4 },
    NvimTreeRootFolder = { fg = p.accent, bold = true },
    NvimTreeFolderName = { fg = p.blue },
    NvimTreeFolderIcon = { fg = p.blue },
    NvimTreeOpenedFolderName = { fg = p.blue, bold = true },
    NvimTreeEmptyFolderName = { fg = p.fg3 },
    NvimTreeSymlinkFolderName = { fg = p.purple },
    NvimTreeFileName = { fg = p.fg0 },
    NvimTreeOpenedFile = { fg = p.fg0, bold = true },
    NvimTreeModifiedFile = { fg = p.yellow },
    NvimTreeSpecialFile = { fg = p.accent2 },
    NvimTreeSymlink = { fg = p.purple },
    NvimTreeIndentMarker = { fg = p.fg3 },
    NvimTreeImageFile = { fg = p.purple },
    NvimTreeGitDirty = { fg = p.yellow },
    NvimTreeGitStaged = { fg = p.green },
    NvimTreeGitMerge = { fg = p.accent },
    NvimTreeGitRenamed = { fg = p.purple },
    NvimTreeGitNew = { fg = p.green },
    NvimTreeGitDeleted = { fg = p.red },
    NvimTreeGitIgnored = { fg = p.fg3 },
    NvimTreeDiagnosticErrorIcon = { fg = p.red },
    NvimTreeDiagnosticWarnIcon = { fg = p.yellow },
    NvimTreeDiagnosticInfoIcon = { fg = p.blue },
    NvimTreeDiagnosticHintIcon = { fg = p.cyan },
  }
end

return nvimtree
