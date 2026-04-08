local plugin_modules = {
  'token.groups.plugins.blink',
  'token.groups.plugins.claudecode',
  'token.groups.plugins.diffview',
  'token.groups.plugins.fugitive',
  'token.groups.plugins.fzf',
  'token.groups.plugins.gitsigns',
  'token.groups.plugins.hlchunk',
  'token.groups.plugins.ibl',
  'token.groups.plugins.markview',
  'token.groups.plugins.mason',
  'token.groups.plugins.matchup',
  'token.groups.plugins.mini',
  'token.groups.plugins.neogit',
  'token.groups.plugins.nvimtree',
  'token.groups.plugins.oil',
  'token.groups.plugins.snacks',
  'token.groups.plugins.treesitter_context',
  'token.groups.plugins.trouble',
}

local M = {}

---@param p TokenPalette
---@return table<string, vim.api.keyset.highlight>
function M.load(p)
  local groups = {}
  for _, mod in ipairs(plugin_modules) do
    groups = vim.tbl_extend('force', groups, require(mod)(p))
  end
  return groups
end

return M
