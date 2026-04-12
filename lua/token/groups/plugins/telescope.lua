---@param p TokenPalette
---@return table<string, vim.api.keyset.highlight>
local function telescope(p)
  return {
    -- main window
    TelescopeNormal = { fg = p.fg0, bg = p.bg0 },
    TelescopeBorder = { fg = p.fg3, bg = p.bg0 },
    TelescopeTitle = { fg = p.accent, bg = p.bg0, bold = true },

    -- prompt
    TelescopePromptNormal = { fg = p.fg0, bg = p.bg0 },
    TelescopePromptBorder = { fg = p.fg3, bg = p.bg0 },
    TelescopePromptTitle = { fg = p.accent2, bg = p.bg0, bold = true },
    TelescopePromptPrefix = { fg = p.accent },
    TelescopePromptCounter = { fg = p.fg3 },

    -- results
    TelescopeResultsNormal = { link = 'TelescopeNormal' },
    TelescopeResultsBorder = { link = 'TelescopeBorder' },
    TelescopeResultsTitle = { link = 'TelescopeTitle' },

    -- preview
    TelescopePreviewNormal = { fg = p.fg0, bg = p.bg1 },
    TelescopePreviewBorder = { fg = p.fg3, bg = p.bg1 },
    TelescopePreviewTitle = { fg = p.accent2, bg = p.bg1, bold = true },

    -- selection and matching
    TelescopeSelection = { bg = p.sel, bold = true },
    TelescopeSelectionCaret = { fg = p.accent, bg = p.sel },
    TelescopeMultiSelection = { fg = p.accent2, bg = p.sel },
    TelescopeMultiIcon = { fg = p.accent2 },
    TelescopeMatching = { fg = p.accent, bold = true },

    -- preview highlights
    TelescopePreviewLine = { bg = p.bg5 },
    TelescopePreviewMatch = { link = 'Search' },

    -- preview file type indicators
    TelescopePreviewPipe = { link = 'Constant' },
    TelescopePreviewCharDev = { link = 'Constant' },
    TelescopePreviewDirectory = { link = 'Directory' },
    TelescopePreviewBlock = { link = 'Constant' },
    TelescopePreviewLink = { link = 'Special' },
    TelescopePreviewSocket = { link = 'Statement' },

    -- preview permission indicators
    TelescopePreviewRead = { link = 'Constant' },
    TelescopePreviewWrite = { link = 'Statement' },
    TelescopePreviewExecute = { link = 'String' },
    TelescopePreviewHyphen = { link = 'NonText' },
    TelescopePreviewSticky = { link = 'Keyword' },

    -- preview file metadata
    TelescopePreviewSize = { link = 'String' },
    TelescopePreviewUser = { link = 'Constant' },
    TelescopePreviewGroup = { link = 'Constant' },
    TelescopePreviewDate = { link = 'Directory' },

    -- preview messages
    TelescopePreviewMessage = { link = 'TelescopePreviewNormal' },
    TelescopePreviewMessageFillchar = { link = 'TelescopePreviewMessage' },

    -- results syntax highlighting
    TelescopeResultsClass = { link = 'Function' },
    TelescopeResultsConstant = { link = 'Constant' },
    TelescopeResultsField = { link = 'Function' },
    TelescopeResultsFunction = { link = 'Function' },
    TelescopeResultsMethod = { link = 'Function' },
    TelescopeResultsOperator = { link = 'Operator' },
    TelescopeResultsStruct = { link = 'Structure' },
    TelescopeResultsVariable = { link = 'SpecialChar' },
    TelescopeResultsLineNr = { link = 'LineNr' },
    TelescopeResultsIdentifier = { link = 'Identifier' },
    TelescopeResultsNumber = { link = 'Number' },
    TelescopeResultsComment = { link = 'Comment' },
    TelescopeResultsSpecialComment = { link = 'SpecialComment' },

    -- git diff in results
    TelescopeResultsDiffAdd = { fg = p.green },
    TelescopeResultsDiffChange = { fg = p.yellow },
    TelescopeResultsDiffDelete = { fg = p.red },
    TelescopeResultsDiffUntracked = { fg = p.fg3 },
  }
end

return telescope
