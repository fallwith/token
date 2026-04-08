---@param p TokenPalette
---@return table<string, vim.api.keyset.highlight>
local function matchup(p)
  return {
    MatchWord = { bg = p.bg5 },
    MatchWordCur = { bg = p.bg5 },
    MatchParenCur = { fg = p.accent, bold = true, underline = true },
  }
end

return matchup
