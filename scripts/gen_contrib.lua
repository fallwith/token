#!/usr/bin/env luajit

-- Generates contrib/ theme files from the canonical palette.
-- Run: luajit scripts/gen_contrib.lua [--verify]

package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path

local palette_fn = require('token.palette')
local terminal = require('token.terminal')

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function strip(hex)
  return hex:gsub('^#', '')
end

local function hex_to_rgb(hex)
  local h = strip(hex)
  return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function rgb_fmt(hex)
  local r, g, b = hex_to_rgb(hex)
  return string.format('0x%02x,0x%02x,0x%02x', r, g, b)
end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()
  return content
end

local function mkdir_p(path)
  -- paths are all hardcoded contrib/ subdirs, no quoting needed
  os.execute('mkdir -p ' .. path)
end

local function write_if_changed(path, content, verify)
  local existing = read_file(path)
  if existing == content then
    if not verify then
      io.write('skip: ' .. path .. ' (unchanged)\n')
    end
    return true
  end
  if verify then
    if existing == nil then
      io.stderr:write('missing: ' .. path .. '\n')
    else
      io.stderr:write('outdated: ' .. path .. '\n')
    end
    return false
  end
  local dir = path:match('(.+)/[^/]+$')
  if dir then
    mkdir_p(dir)
  end
  local f = assert(io.open(path, 'w'))
  f:write(content)
  f:close()
  io.write('wrote: ' .. path .. '\n')
  return true
end

local function extend_lines(dst, src)
  for _, line in ipairs(src) do
    dst[#dst + 1] = line
  end
end

-- ---------------------------------------------------------------------------
-- bat (.tmTheme)
-- ---------------------------------------------------------------------------

local function xml_escape(s)
  return s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

local function tmtheme_entry(name, scope, fg, style)
  local lines = {
    '    <dict>',
    '      <key>name</key>',
    '      <string>' .. xml_escape(name) .. '</string>',
    '      <key>scope</key>',
    '      <string>' .. xml_escape(scope) .. '</string>',
    '      <key>settings</key>',
    '      <dict>',
  }
  if fg then
    lines[#lines + 1] = '        <key>foreground</key>'
    lines[#lines + 1] = '        <string>' .. fg .. '</string>'
  end
  if style then
    lines[#lines + 1] = '        <key>fontStyle</key>'
    lines[#lines + 1] = '        <string>' .. style .. '</string>'
  end
  lines[#lines + 1] = '      </dict>'
  lines[#lines + 1] = '    </dict>'
  return table.concat(lines, '\n')
end

local function gen_bat(p, variant, _term)
  local name = 'token-' .. variant

  local scopes = {
    tmtheme_entry('Comment', 'comment, punctuation.definition.comment', p.fg2, 'italic'),
    tmtheme_entry('Keyword', 'keyword, keyword.control, keyword.other', p.accent2, nil),
    tmtheme_entry('Storage', 'storage, storage.modifier', p.accent2, nil),
    tmtheme_entry('Operator', 'keyword.operator', p.fg1, nil),
    tmtheme_entry('Function', 'entity.name.function, support.function, meta.function-call', p.accent, nil),
    tmtheme_entry('String', 'string, punctuation.definition.string', p.green, nil),
    tmtheme_entry('String escape', 'constant.character.escape', p.purple, nil),
    tmtheme_entry('Boolean', 'constant.language.boolean', p.accent2, nil),
    tmtheme_entry('Number', 'constant.numeric', p.purple, nil),
    tmtheme_entry('Constant', 'constant, constant.language, support.constant, variable.other.constant', p.purple, nil),
    tmtheme_entry('Type', 'storage.type, support.type, entity.name.type, entity.other.inherited-class', p.blue, nil),
    tmtheme_entry('Class', 'entity.name.type.class, support.class, entity.name.class', p.blue, nil),
    tmtheme_entry('Module', 'entity.name.namespace, entity.name.type.module, support.module', p.blue, nil),
    tmtheme_entry(
      'PreProc',
      'keyword.control.import, keyword.control.export, keyword.control.directive, keyword.preprocessor',
      p.purple,
      nil
    ),
    tmtheme_entry('Include', 'keyword.other.import, keyword.other.package, keyword.other.using', p.purple, nil),
    tmtheme_entry('Macro', 'entity.name.function.preprocessor', p.purple, nil),
    tmtheme_entry('Tag', 'entity.name.tag', p.purple, nil),
    tmtheme_entry('Tag attribute', 'entity.other.attribute-name', p.accent2, 'italic'),
    tmtheme_entry('Attribute', 'meta.annotation, storage.type.annotation', p.purple, nil),
    tmtheme_entry('Label', 'entity.name.label, constant.other.label', p.accent2, nil),
    tmtheme_entry('Special', 'variable.language, constant.language.null, constant.language.undefined', p.purple, nil),
    tmtheme_entry('Debug', 'keyword.other.debugger', p.red, nil),
    tmtheme_entry('Exception', 'keyword.control.exception, keyword.control.trycatch', p.red, nil),
    tmtheme_entry('Identifier', 'variable, support.variable, meta.definition.variable', p.fg0, nil),
    tmtheme_entry(
      'Property',
      'variable.object.property, variable.other.property, variable.other.member, meta.object-literal.key',
      p.fg0,
      nil
    ),
    tmtheme_entry('Delimiter', 'punctuation, meta.brace, meta.delimiter, meta.bracket', p.fg1, nil),
    tmtheme_entry('Parameter', 'variable.parameter', p.fg1, nil),
    -- Markup
    tmtheme_entry('Heading 1', 'heading.1.markdown, markup.heading.setext.1.markdown', p.accent, 'bold'),
    tmtheme_entry('Heading 2', 'heading.2.markdown, markup.heading.setext.2.markdown', p.accent2, 'bold'),
    tmtheme_entry('Heading 3', 'heading.3.markdown', p.yellow, 'bold'),
    tmtheme_entry('Heading 4', 'heading.4.markdown', p.blue, 'bold'),
    tmtheme_entry('Heading 5', 'heading.5.markdown', p.green, 'bold'),
    tmtheme_entry('Heading 6', 'heading.6.markdown', p.purple, 'bold'),
    tmtheme_entry('Heading delimiter', 'punctuation.definition.heading.markdown', p.fg2, nil),
    tmtheme_entry('Markup link', 'markup.underline.link, string.other.link', p.blue, 'underline'),
    tmtheme_entry(
      'Markup link text',
      'string.other.link.title.markdown, constant.other.reference.link.markdown',
      p.blue,
      nil
    ),
    tmtheme_entry(
      'Markup code',
      'markup.fenced_code.block.markdown, markup.inline.raw.string.markdown, markup.raw',
      p.green,
      nil
    ),
    tmtheme_entry(
      'Markup code delimiter',
      'punctuation.definition.markdown, punctuation.definition.raw.markdown',
      p.fg2,
      nil
    ),
    tmtheme_entry('Markup list', 'punctuation.definition.list.begin.markdown, markup.list', p.accent2, nil),
    tmtheme_entry('Markup bold', 'markup.bold', nil, 'bold'),
    tmtheme_entry('Markup italic', 'markup.italic', nil, 'italic'),
    tmtheme_entry('Markup bold italic', 'markup.bold markup.italic, markup.italic markup.bold', nil, 'italic bold'),
    tmtheme_entry('Markup quote', 'markup.quote', p.fg2, 'italic'),
    -- Diff
    tmtheme_entry('Diff added', 'markup.inserted, meta.diff.header.to-file', p.green, nil),
    tmtheme_entry('Diff deleted', 'markup.deleted, meta.diff.header.from-file', p.red, nil),
    tmtheme_entry('Diff changed', 'markup.changed', p.yellow, nil),
    -- GitGutter
    tmtheme_entry('GitGutter inserted', 'markup.inserted.git_gutter', p.green, nil),
    tmtheme_entry('GitGutter deleted', 'markup.deleted.git_gutter', p.red, nil),
    tmtheme_entry('GitGutter changed', 'markup.changed.git_gutter', p.yellow, nil),
    tmtheme_entry('GitGutter untracked', 'markup.untracked.git_gutter', p.fg3, nil),
    tmtheme_entry('GitGutter ignored', 'markup.ignored.git_gutter', p.fg3, nil),
  }

  local content = table.concat({
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    '<!-- Generated by token colorscheme. Do not edit manually. -->',
    '<plist version="1.0">',
    '  <dict>',
    '    <key>name</key>',
    '    <string>' .. name .. '</string>',
    '    <key>settings</key>',
    '    <array>',
    '      <dict>',
    '        <key>settings</key>',
    '        <dict>',
    '          <key>background</key>',
    '          <string>' .. p.bg3 .. '</string>',
    '          <key>foreground</key>',
    '          <string>' .. p.fg0 .. '</string>',
    '          <key>caret</key>',
    '          <string>' .. p.fg0 .. '</string>',
    '          <key>lineHighlight</key>',
    '          <string>' .. p.bg5 .. '40</string>',
    '          <key>selection</key>',
    '          <string>' .. p.sel .. 'cc</string>',
    '          <key>activeGuide</key>',
    '          <string>' .. p.fg2 .. '20</string>',
    '          <key>findHighlight</key>',
    '          <string>' .. p.match .. '</string>',
    '          <key>misspelling</key>',
    '          <string>' .. p.red .. '</string>',
    '        </dict>',
    '      </dict>',
    table.concat(scopes, '\n'),
    '    </array>',
    '  </dict>',
    '</plist>',
    '',
  }, '\n')

  return { path = 'contrib/bat/' .. name .. '.tmTheme', content = content }
end

-- ---------------------------------------------------------------------------
-- delta (.gitconfig)
-- ---------------------------------------------------------------------------

local function gen_delta(dark, light, _dark_term, _light_term)
  local function section(p, variant)
    local is_dark = variant == 'dark'
    local lines = {
      '[delta "token-' .. variant .. '"]',
      '\t' .. (is_dark and 'dark' or 'light') .. ' = true',
      '\tsyntax-theme = token-' .. variant,
      '\tblame-palette = "' .. p.bg1 .. ' ' .. p.bg2 .. ' ' .. p.bg3 .. ' ' .. p.bg4 .. ' ' .. p.bg5 .. '"',
      '\tcommit-decoration-style = "' .. p.fg3 .. '" bold box ul',
      '\tfile-style = "' .. p.fg0 .. '"',
      '\tfile-decoration-style = "' .. p.fg3 .. '"',
      '\thunk-header-style = file line-number syntax',
      '\thunk-header-decoration-style = "' .. p.fg3 .. '" box ul',
      '\thunk-header-file-style = bold',
      '\thunk-header-line-number-style = bold "' .. p.fg2 .. '"',
      '\tline-numbers-left-style = "' .. p.fg3 .. '"',
      '\tline-numbers-right-style = "' .. p.fg3 .. '"',
      '\tline-numbers-minus-style = bold "' .. p.red .. '"',
      '\tline-numbers-plus-style = bold "' .. p.green .. '"',
      '\tline-numbers-zero-style = "' .. p.fg2 .. '"',
      '\tminus-style = syntax "' .. p.diff_del .. '"',
      '\tminus-non-emph-style = syntax "' .. p.diff_del .. '"',
      '\tminus-emph-style = bold syntax "' .. p.diff_del_inline .. '"',
      '\tminus-empty-line-marker-style = syntax "' .. p.diff_del .. '"',
      '\tplus-style = syntax "' .. p.diff_add .. '"',
      '\tplus-non-emph-style = syntax "' .. p.diff_add .. '"',
      '\tplus-emph-style = bold syntax "' .. p.diff_add_inline .. '"',
      '\tplus-empty-line-marker-style = syntax "' .. p.diff_add .. '"',
    }
    return table.concat(lines, '\n')
  end

  local content = table.concat({
    '# Generated by token colorscheme. Do not edit manually.',
    '# Include this file from ~/.gitconfig, then enable one of these named delta features:',
    '#   [delta]',
    '#     features = token-dark',
    '',
    section(dark, 'dark'),
    '',
    section(light, 'light'),
    '',
  }, '\n')

  return { path = 'contrib/delta/token.gitconfig', content = content }
end

-- ---------------------------------------------------------------------------
-- emacs (.el)
-- ---------------------------------------------------------------------------

-- Palette keys bound in the emacs `let` block. Grouped by semantic category
-- (bg ramp -> fg ramp -> accents -> syntax -> brights -> diffs -> ui).
-- Only keys referenced by EMACS_FACES are bound: the emacs byte-compiler warns
-- on unused lexical bindings, and `emacs_audit` enforces the invariant both
-- ways (unused key here, or missing key referenced from EMACS_FACES, both
-- error at generation time).
-- To add a new palette key: add it here AND reference it from EMACS_FACES.
local EMACS_LET_KEYS = {
  'bg0',
  'bg1',
  'bg2',
  'bg3',
  'bg4',
  'bg5',
  'fg0',
  'fg1',
  'fg2',
  'fg3',
  'accent',
  'accent2',
  'blue',
  'green',
  'red',
  'yellow',
  'purple',
  'cyan',
  'orange',
  'bright_green',
  'bright_blue',
  'bright_purple',
  'bright_cyan',
  'diff_add',
  'diff_del',
  'diff_add_inline',
  'diff_del_inline',
  'diff_change',
  'diff_text',
  'sel',
  'match',
}

-- Face table schema:
--   Face entry (positional [1] is the elisp face name, rest are attributes):
--     { 'face-name', fg = 'palette_key', bg = 'palette_key',
--       bold = true, italic = true, underline = true|false|<table>,
--       strike = true, extend = true, box = true|<table>, height = N }
--   Nested tables:
--     underline = { style = 'wave'|'dots', color = 'palette_key' }
--     box       = { line_width = N, color = 'palette_key' }
--   Section marker (emitted as a comment, not a face):
--     { section = 'Label' }
--   Literal escape hatch (faces with no palette refs, e.g. `bold`):
--     { 'face-name', literal = '(:weight bold)' }
local EMACS_FACES = {
  { section = 'Core' },
  { 'default', fg = 'fg0', bg = 'bg3' },
  { 'cursor', bg = 'fg0' },
  { 'fringe', fg = 'fg3', bg = 'bg3' },
  { 'region', bg = 'sel', extend = true },
  { 'secondary-selection', bg = 'bg5', extend = true },
  { 'highlight', bg = 'bg5' },
  { 'hl-line', bg = 'bg5', extend = true },
  { 'shadow', fg = 'fg2' },
  { 'vertical-border', fg = 'bg4' },
  { 'window-divider', fg = 'bg4' },
  { 'window-divider-first-pixel', fg = 'bg4' },
  { 'window-divider-last-pixel', fg = 'bg4' },
  { 'internal-border', bg = 'bg1' },
  { 'child-frame-border', bg = 'bg1' },
  { 'fill-column-indicator', fg = 'bg5' },
  { 'separator-line', fg = 'bg4' },
  { 'nobreak-space', fg = 'fg3', underline = true },
  { 'nobreak-hyphen', fg = 'fg3' },
  { 'homoglyph', fg = 'yellow' },
  { 'escape-glyph', fg = 'cyan' },
  { 'glyphless-char', fg = 'fg3' },
  { 'trailing-whitespace', bg = 'red' },
  { 'tooltip', fg = 'fg0', bg = 'bg0' },
  { 'menu', fg = 'fg0', bg = 'bg1' },
  { 'minibuffer-prompt', fg = 'blue', bold = true },
  { 'link', fg = 'blue', underline = true },
  { 'link-visited', fg = 'purple', underline = true },
  { 'button', fg = 'blue', underline = true },
  { 'bookmark-face', fg = 'accent', bg = 'bg4' },
  { 'bookmark-menu-bookmark', fg = 'accent', bold = true },

  { section = 'Text / Formatting' },
  { 'bold', literal = '(:weight bold)' },
  { 'italic', literal = '(:slant italic)' },
  { 'bold-italic', literal = '(:weight bold :slant italic)' },
  { 'underline', literal = '(:underline t)' },
  { 'fixed-pitch', literal = '(:family "monospace")' },
  { 'variable-pitch', literal = '(:family "sans-serif")' },

  { section = 'Line numbers' },
  { 'line-number', fg = 'fg3', bg = 'bg3' },
  { 'line-number-current-line', fg = 'accent2', bg = 'bg3', bold = true },
  { 'line-number-major-tick', fg = 'fg2', bg = 'bg3', bold = true },
  { 'line-number-minor-tick', fg = 'fg3', bg = 'bg3' },

  { section = 'Mode line' },
  { 'mode-line', fg = 'fg1', bg = 'bg1' },
  { 'mode-line-inactive', fg = 'fg3', bg = 'bg1' },
  { 'mode-line-buffer-id', fg = 'accent', bold = true },
  { 'mode-line-highlight', fg = 'accent' },
  { 'mode-line-emphasis', bold = true },
  { 'header-line', fg = 'fg1', bg = 'bg1' },
  { 'header-line-highlight', fg = 'accent', bold = true },
  { 'doom-modeline-buffer-path', fg = 'fg2' },
  { 'doom-modeline-buffer-file', fg = 'fg0', bold = true },
  { 'doom-modeline-buffer-modified', fg = 'accent' },
  { 'doom-modeline-project-dir', fg = 'blue' },
  { 'doom-modeline-error', fg = 'red', bold = true },
  { 'doom-modeline-warning', fg = 'yellow', bold = true },
  { 'doom-modeline-info', fg = 'green', bold = true },

  { section = 'Tab bar / Tab line' },
  { 'tab-bar', fg = 'fg2', bg = 'bg1' },
  { 'tab-bar-tab', fg = 'fg0', bg = 'bg3', bold = true },
  { 'tab-bar-tab-inactive', fg = 'fg2', bg = 'bg1' },
  { 'tab-bar-tab-group-current', fg = 'accent', bg = 'bg3', bold = true },
  { 'tab-bar-tab-group-inactive', fg = 'fg2', bg = 'bg1' },
  { 'tab-bar-tab-ungrouped', fg = 'fg3', bg = 'bg1' },
  { 'tab-line', fg = 'fg2', bg = 'bg1' },
  { 'tab-line-tab', fg = 'fg1', bg = 'bg3' },
  { 'tab-line-tab-current', fg = 'fg0', bg = 'bg3', bold = true },
  { 'tab-line-tab-inactive', fg = 'fg2', bg = 'bg1' },
  { 'tab-line-tab-modified', fg = 'accent' },
  { 'tab-line-highlight', fg = 'fg0', bg = 'bg5' },
  { 'tab-line-close-highlight', fg = 'red' },
  { 'tab-line-new-tab', fg = 'green' },

  { section = 'Whitespace' },
  { 'whitespace-space', fg = 'bg5' },
  { 'whitespace-hspace', fg = 'bg5' },
  { 'whitespace-tab', fg = 'bg5' },
  { 'whitespace-newline', fg = 'bg5' },
  { 'whitespace-missing-newline-at-eof', fg = 'red' },
  { 'whitespace-trailing', fg = 'red', bg = 'diff_del' },
  { 'whitespace-line', bg = 'diff_del' },
  { 'whitespace-space-before-tab', bg = 'diff_del' },
  { 'whitespace-indentation', fg = 'fg3' },
  { 'whitespace-big-indent', bg = 'diff_del' },
  { 'whitespace-empty', bg = 'diff_change' },
  { 'whitespace-space-after-tab', bg = 'diff_del' },

  { section = 'Font lock' },
  { 'font-lock-comment-face', fg = 'fg2', italic = true },
  { 'font-lock-comment-delimiter-face', fg = 'fg2', italic = true },
  { 'font-lock-doc-face', fg = 'fg2', italic = true },
  { 'font-lock-doc-markup-face', fg = 'green', italic = true },
  { 'font-lock-string-face', fg = 'green' },
  { 'font-lock-keyword-face', fg = 'accent2' },
  { 'font-lock-builtin-face', fg = 'purple' },
  { 'font-lock-function-name-face', fg = 'accent' },
  { 'font-lock-function-call-face', fg = 'accent' },
  { 'font-lock-variable-name-face', fg = 'fg0' },
  { 'font-lock-variable-use-face', fg = 'fg0' },
  { 'font-lock-type-face', fg = 'blue' },
  { 'font-lock-constant-face', fg = 'purple' },
  { 'font-lock-preprocessor-face', fg = 'purple' },
  { 'font-lock-negation-char-face', fg = 'red' },
  { 'font-lock-warning-face', fg = 'yellow' },
  { 'font-lock-regexp-grouping-backslash', fg = 'purple' },
  { 'font-lock-regexp-grouping-construct', fg = 'purple' },
  { 'font-lock-escape-face', fg = 'purple' },
  { 'font-lock-number-face', fg = 'orange' },
  { 'font-lock-operator-face', fg = 'fg1' },
  { 'font-lock-delimiter-face', fg = 'fg1' },
  { 'font-lock-bracket-face', fg = 'fg1' },
  { 'font-lock-punctuation-face', fg = 'fg1' },
  { 'font-lock-misc-punctuation-face', fg = 'fg1' },
  { 'font-lock-property-name-face', fg = 'fg0' },
  { 'font-lock-property-use-face', fg = 'fg0' },
  { 'font-lock-reference-face', fg = 'blue' },

  { section = 'Treesitter (Emacs 29+)' },
  { 'treesit-fold-replacement-face', fg = 'fg2', bg = 'bg4' },

  { section = 'Search' },
  { 'isearch', fg = 'fg0', bg = 'match', bold = true },
  { 'isearch-fail', fg = 'fg0', bg = 'diff_del' },
  { 'isearch-group-1', fg = 'bg3', bg = 'accent' },
  { 'isearch-group-2', fg = 'bg3', bg = 'accent2' },
  { 'lazy-highlight', bg = 'bg5' },
  { 'match', fg = 'fg0', bg = 'match' },
  { 'query-replace', fg = 'fg0', bg = 'diff_del' },

  { section = 'Occur / grep / compilation' },
  { 'occur-match', fg = 'fg0', bg = 'match', bold = true },
  { 'occur-prefix', fg = 'fg2' },
  { 'occur-suffix', fg = 'fg2' },
  { 'grep-match-face', fg = 'fg0', bg = 'match', bold = true },
  { 'grep-hit-face', fg = 'accent', bold = true },
  { 'grep-context-face', fg = 'fg2' },
  { 'compilation-error', fg = 'red', bold = true },
  { 'compilation-warning', fg = 'yellow' },
  { 'compilation-info', fg = 'blue' },
  { 'compilation-mode-line-exit', fg = 'green', bold = true },
  { 'compilation-mode-line-fail', fg = 'red', bold = true },
  { 'compilation-mode-line-run', fg = 'yellow', bold = true },
  { 'compilation-line-number', fg = 'accent' },
  { 'compilation-column-number', fg = 'fg2' },
  { 'compilation-face', fg = 'fg0' },
  { 'next-error', bg = 'diff_change', extend = true },

  { section = 'Parentheses / Delimiters' },
  { 'show-paren-match', fg = 'accent', bold = true, underline = true },
  { 'show-paren-mismatch', fg = 'fg0', bg = 'red' },
  { 'show-paren-match-expression', bg = 'bg5' },
  { 'rainbow-delimiters-depth-1-face', fg = 'fg1' },
  { 'rainbow-delimiters-depth-2-face', fg = 'cyan' },
  { 'rainbow-delimiters-depth-3-face', fg = 'blue' },
  { 'rainbow-delimiters-depth-4-face', fg = 'purple' },
  { 'rainbow-delimiters-depth-5-face', fg = 'accent' },
  { 'rainbow-delimiters-depth-6-face', fg = 'green' },
  { 'rainbow-delimiters-depth-7-face', fg = 'accent2' },
  { 'rainbow-delimiters-depth-8-face', fg = 'bright_cyan' },
  { 'rainbow-delimiters-depth-9-face', fg = 'bright_blue' },
  { 'rainbow-delimiters-base-error-face', fg = 'red' },
  { 'rainbow-delimiters-mismatched-face', fg = 'fg0', bg = 'red' },
  { 'rainbow-delimiters-unmatched-face', fg = 'fg0', bg = 'red' },
  { 'paren-face', fg = 'fg3' },

  { section = 'Outline' },
  { 'outline-1', fg = 'accent', bold = true },
  { 'outline-2', fg = 'accent2', bold = true },
  { 'outline-3', fg = 'blue', bold = true },
  { 'outline-4', fg = 'green', bold = true },
  { 'outline-5', fg = 'cyan', bold = true },
  { 'outline-6', fg = 'purple', bold = true },
  { 'outline-7', fg = 'yellow', bold = true },
  { 'outline-8', fg = 'red', bold = true },
  { 'outline-minor-0', bg = 'bg4' },
  { 'outline-minor-1', fg = 'accent', bold = true },

  { section = 'Diffs' },
  { 'diff-header', fg = 'fg0', bg = 'bg2', bold = true, extend = true },
  { 'diff-file-header', fg = 'accent', bg = 'bg2', bold = true, extend = true },
  { 'diff-index', fg = 'fg2', bg = 'bg2', extend = true },
  { 'diff-function', fg = 'cyan', bg = 'diff_change', extend = true },
  { 'diff-hunk-header', fg = 'cyan', bg = 'diff_change', extend = true },
  { 'diff-added', fg = 'bright_green', bg = 'diff_add', extend = true },
  { 'diff-removed', fg = 'red', bg = 'diff_del', extend = true },
  { 'diff-changed', fg = 'yellow', bg = 'diff_change', extend = true },
  { 'diff-unchanged', fg = 'fg2', extend = true },
  { 'diff-context', fg = 'fg2', extend = true },
  { 'diff-indicator-added', fg = 'green', bg = 'diff_add' },
  { 'diff-indicator-removed', fg = 'red', bg = 'diff_del' },
  { 'diff-indicator-changed', fg = 'yellow', bg = 'diff_change' },
  { 'diff-refine-added', bg = 'diff_add_inline', extend = true },
  { 'diff-refine-removed', bg = 'diff_del_inline', extend = true },
  { 'diff-refine-changed', bg = 'diff_text', extend = true },
  { 'diff-nonexistent', fg = 'fg3' },
  { 'diff-error', fg = 'red', bold = true },

  { section = 'Version control' },
  { 'vc-state-base', fg = 'fg2' },
  { 'vc-up-to-date-state', fg = 'fg2' },
  { 'vc-edited-state', fg = 'yellow' },
  { 'vc-conflict-state', fg = 'red', bold = true },
  { 'vc-locally-added-state', fg = 'green' },
  { 'vc-missing-state', fg = 'red' },
  { 'vc-removed-state', fg = 'red' },
  { 'vc-needs-update-state', fg = 'blue' },
  { 'vc-dir-status-warning', fg = 'yellow' },
  { 'vc-dir-status-ignored', fg = 'fg3' },
  { 'vc-dir-directory', fg = 'blue', bold = true },
  { 'vc-dir-file', fg = 'fg0' },
  { 'vc-dir-mark-indicator', fg = 'accent' },
  { 'diff-hl-insert', fg = 'green', bg = 'diff_add' },
  { 'diff-hl-delete', fg = 'red', bg = 'diff_del' },
  { 'diff-hl-change', fg = 'yellow', bg = 'diff_change' },
  { 'diff-hl-margin-insert', fg = 'green' },
  { 'diff-hl-margin-delete', fg = 'red' },
  { 'diff-hl-margin-change', fg = 'yellow' },
  { 'diff-hl-reverted-hunk-highlight', fg = 'fg0', bg = 'bg5' },
  { 'git-gutter:added', fg = 'green' },
  { 'git-gutter:deleted', fg = 'red' },
  { 'git-gutter:modified', fg = 'yellow' },
  { 'git-gutter:unchanged', fg = 'fg3' },
  { 'git-gutter-fr:added', fg = 'green', bg = 'bg3' },
  { 'git-gutter-fr:deleted', fg = 'red', bg = 'bg3' },
  { 'git-gutter-fr:modified', fg = 'yellow', bg = 'bg3' },
  { 'git-timemachine-minibuffer-author-face', fg = 'accent' },
  { 'git-timemachine-minibuffer-detail-face', fg = 'fg2' },
  { 'git-timemachine-commit', fg = 'purple' },

  { section = 'Ediff' },
  { 'ediff-current-diff-A', bg = 'diff_del', extend = true },
  { 'ediff-current-diff-B', bg = 'diff_add', extend = true },
  { 'ediff-current-diff-C', bg = 'diff_change', extend = true },
  { 'ediff-current-diff-Ancestor', bg = 'bg5', extend = true },
  { 'ediff-even-diff-A', bg = 'bg4', extend = true },
  { 'ediff-even-diff-B', bg = 'bg4', extend = true },
  { 'ediff-even-diff-C', bg = 'bg4', extend = true },
  { 'ediff-even-diff-Ancestor', bg = 'bg4', extend = true },
  { 'ediff-odd-diff-A', bg = 'bg5', extend = true },
  { 'ediff-odd-diff-B', bg = 'bg5', extend = true },
  { 'ediff-odd-diff-C', bg = 'bg5', extend = true },
  { 'ediff-odd-diff-Ancestor', bg = 'bg5', extend = true },
  { 'ediff-fine-diff-A', bg = 'diff_del_inline', extend = true },
  { 'ediff-fine-diff-B', bg = 'diff_add_inline', extend = true },
  { 'ediff-fine-diff-C', bg = 'diff_text', extend = true },
  { 'ediff-fine-diff-Ancestor', bg = 'bg5', extend = true },

  { section = 'Smerge' },
  { 'smerge-base', bg = 'diff_change', extend = true },
  { 'smerge-lower', bg = 'diff_add', extend = true },
  { 'smerge-upper', bg = 'diff_del', extend = true },
  { 'smerge-markers', fg = 'fg2', bg = 'bg4', bold = true, extend = true },
  { 'smerge-refined-added', bg = 'diff_add_inline' },
  { 'smerge-refined-removed', bg = 'diff_del_inline' },
  { 'smerge-refined-changed', bg = 'diff_text' },

  { section = 'Diagnostics' },
  { 'error', fg = 'red', bold = true },
  { 'warning', fg = 'yellow' },
  { 'success', fg = 'green' },
  { 'flymake-error', underline = { style = 'wave', color = 'red' } },
  { 'flymake-warning', underline = { style = 'wave', color = 'yellow' } },
  { 'flymake-note', underline = { style = 'wave', color = 'green' } },
  { 'flymake-error-echo', fg = 'red' },
  { 'flymake-warning-echo', fg = 'yellow' },
  { 'flymake-note-echo', fg = 'green' },
  { 'flymake-error-echo-at-eol', fg = 'red', italic = true },
  { 'flymake-warning-echo-at-eol', fg = 'yellow', italic = true },
  { 'flymake-note-echo-at-eol', fg = 'green', italic = true },
  { 'flycheck-error', underline = { style = 'wave', color = 'red' } },
  { 'flycheck-warning', underline = { style = 'wave', color = 'yellow' } },
  { 'flycheck-info', underline = { style = 'wave', color = 'blue' } },
  { 'flycheck-fringe-error', fg = 'red', bold = true },
  { 'flycheck-fringe-warning', fg = 'yellow', bold = true },
  { 'flycheck-fringe-info', fg = 'blue', bold = true },
  { 'flycheck-error-list-error', fg = 'red', bold = true },
  { 'flycheck-error-list-warning', fg = 'yellow' },
  { 'flycheck-error-list-info', fg = 'blue' },
  { 'flycheck-error-list-id', fg = 'purple' },
  { 'flycheck-error-list-filename', fg = 'accent' },
  { 'flycheck-error-list-line-column', fg = 'fg2' },

  { section = 'LSP' },
  { 'eglot-highlight-symbol-face', bg = 'bg5' },
  { 'eglot-inlay-hint-face', fg = 'fg3', bg = 'bg4', italic = true },
  { 'eglot-parameter-hint-face', fg = 'fg3', bg = 'bg4', italic = true },
  { 'eglot-type-hint-face', fg = 'blue', bg = 'bg4', italic = true },
  { 'eglot-diagnostic-tag-unnecessary-face', fg = 'fg3' },
  { 'eglot-diagnostic-tag-deprecated-face', fg = 'fg2', strike = true },
  { 'lsp-face-highlight-textual', bg = 'bg5' },
  { 'lsp-face-highlight-read', bg = 'bg5' },
  { 'lsp-face-highlight-write', bg = 'bg5', bold = true },
  { 'lsp-ui-doc-background', bg = 'bg0' },
  { 'lsp-ui-doc-border', fg = 'fg3' },
  { 'lsp-ui-doc-header', fg = 'accent', bg = 'bg0', bold = true },
  { 'lsp-ui-sideline-code-action', fg = 'yellow' },
  { 'lsp-ui-sideline-current-symbol', fg = 'fg0', bg = 'bg5' },
  { 'lsp-ui-sideline-symbol-info', fg = 'fg2', italic = true },
  { 'lsp-inlay-hint-face', fg = 'fg3', bg = 'bg4', italic = true },

  { section = 'Completions' },
  { 'completions-common-part', fg = 'accent', bold = true },
  { 'completions-first-difference', fg = 'fg0' },
  { 'completions-annotations', fg = 'fg2', italic = true },
  { 'completions-group-title', fg = 'blue', bold = true },
  { 'completions-group-separator', fg = 'fg3', strike = true },
  { 'completion-preview', fg = 'fg3' },
  { 'completion-preview-exact', fg = 'fg2', underline = true },

  { section = 'Corfu' },
  { 'corfu-default', fg = 'fg0', bg = 'bg1' },
  { 'corfu-current', fg = 'fg0', bg = 'sel', bold = true },
  { 'corfu-bar', bg = 'fg3' },
  { 'corfu-border', bg = 'bg4' },
  { 'corfu-annotations', fg = 'fg2', italic = true },
  { 'corfu-deprecated', fg = 'fg3', strike = true },
  { 'corfu-quick1', fg = 'fg0', bg = 'bg4', bold = true },
  { 'corfu-quick2', fg = 'fg0', bg = 'bg5', bold = true },
  { 'corfu-popupinfo', fg = 'fg0', bg = 'bg0' },

  { section = 'Company' },
  { 'company-tooltip', fg = 'fg0', bg = 'bg1' },
  { 'company-tooltip-selection', fg = 'fg0', bg = 'sel', bold = true },
  { 'company-tooltip-common', fg = 'accent', bold = true },
  { 'company-tooltip-common-selection', fg = 'accent', bg = 'sel', bold = true },
  { 'company-tooltip-annotation', fg = 'fg2', italic = true },
  { 'company-tooltip-annotation-selection', fg = 'fg2', italic = true },
  { 'company-tooltip-search', fg = 'fg0', bg = 'match' },
  { 'company-tooltip-search-selection', fg = 'fg0', bg = 'match' },
  { 'company-tooltip-scrollbar-thumb', bg = 'fg3' },
  { 'company-tooltip-scrollbar-track', bg = 'bg4' },
  { 'company-preview', fg = 'fg2' },
  { 'company-preview-common', fg = 'fg3' },
  { 'company-echo-common', fg = 'accent' },

  { section = 'Vertico / Selectrum' },
  { 'vertico-current', bg = 'sel', extend = true },
  { 'vertico-group-title', fg = 'blue', bold = true, italic = true },
  { 'vertico-group-separator', fg = 'fg3', strike = true },
  { 'vertico-multiline', fg = 'fg2' },

  { section = 'Orderless' },
  { 'orderless-match-face-0', fg = 'accent', bold = true },
  { 'orderless-match-face-1', fg = 'blue', bold = true },
  { 'orderless-match-face-2', fg = 'green', bold = true },
  { 'orderless-match-face-3', fg = 'purple', bold = true },

  { section = 'Marginalia' },
  { 'marginalia-documentation', fg = 'fg2', italic = true },
  { 'marginalia-file-name', fg = 'fg1' },
  { 'marginalia-file-modes', fg = 'fg3' },
  { 'marginalia-file-owner', fg = 'fg2' },
  { 'marginalia-key', fg = 'accent' },
  { 'marginalia-type', fg = 'blue' },
  { 'marginalia-value', fg = 'fg0' },
  { 'marginalia-date', fg = 'cyan' },
  { 'marginalia-number', fg = 'purple' },
  { 'marginalia-string', fg = 'green' },
  { 'marginalia-on', fg = 'green', bold = true },
  { 'marginalia-off', fg = 'red', bold = true },

  { section = 'Consult' },
  { 'consult-file', fg = 'blue' },
  { 'consult-separator', fg = 'fg3' },
  { 'consult-preview-cursor', bg = 'sel' },
  { 'consult-preview-error', bg = 'diff_del' },
  { 'consult-preview-insertion', bg = 'diff_add' },
  { 'consult-line-number', fg = 'fg3' },
  { 'consult-line-number-prefix', fg = 'fg3' },
  { 'consult-grep-context', fg = 'fg2' },
  { 'consult-async-running', fg = 'yellow' },
  { 'consult-async-failed', fg = 'red' },
  { 'consult-async-finished', fg = 'green' },
  { 'consult-async-split', fg = 'fg3' },

  { section = 'Embark' },
  { 'embark-target', fg = 'fg0', bg = 'bg5', underline = true },
  { 'embark-collect-marked', fg = 'accent', bg = 'bg4' },
  { 'embark-collect-candidate', fg = 'fg0' },
  { 'embark-selected', bg = 'sel' },

  { section = 'Ivy' },
  { 'ivy-current-match', fg = 'fg0', bg = 'sel', bold = true, extend = true },
  { 'ivy-minibuffer-match-face-1', fg = 'fg2' },
  { 'ivy-minibuffer-match-face-2', fg = 'accent', bold = true },
  { 'ivy-minibuffer-match-face-3', fg = 'blue', bold = true },
  { 'ivy-minibuffer-match-face-4', fg = 'purple', bold = true },
  { 'ivy-confirm-face', fg = 'green' },
  { 'ivy-match-required-face', fg = 'red' },
  { 'ivy-virtual', fg = 'fg2', italic = true },
  { 'ivy-subdir', fg = 'blue', bold = true },
  { 'ivy-org', fg = 'fg1' },
  { 'ivy-separator', fg = 'fg3' },
  { 'ivy-action', fg = 'accent' },
  { 'ivy-prompt-match', fg = 'fg0', bg = 'match' },

  { section = 'Xref' },
  { 'xref-match', fg = 'fg0', bg = 'match', bold = true },
  { 'xref-file-header', fg = 'accent', bold = true },
  { 'xref-line-number', fg = 'fg3' },

  { section = 'Info' },
  { 'info-menu-header', fg = 'accent', bold = true },
  { 'info-menu-star', fg = 'red' },
  { 'info-node', fg = 'accent', bold = true, italic = true },
  { 'info-title-1', fg = 'accent', bold = true, height = 1.4 },
  { 'info-title-2', fg = 'accent2', bold = true, height = 1.3 },
  { 'info-title-3', fg = 'blue', bold = true, height = 1.2 },
  { 'info-title-4', fg = 'fg0', bold = true, height = 1.1 },
  { 'info-xref', fg = 'blue', underline = true },
  { 'info-xref-visited', fg = 'purple', underline = true },
  { 'info-index-match', fg = 'fg0', bg = 'match' },
  { 'info-header-xref', fg = 'blue', underline = true },

  { section = 'Help' },
  { 'help-argument-name', fg = 'accent', italic = true },
  { 'help-key-binding', fg = 'fg0', bg = 'bg4', box = { line_width = -1, color = 'fg3' } },

  { section = 'Helpful' },
  { 'helpful-heading', fg = 'accent', bold = true },

  { section = 'Describe' },
  { 'describe-variable-value', fg = 'green' },

  { section = 'Eldoc' },
  { 'eldoc-highlight-function-argument', fg = 'accent', bold = true },

  { section = 'Dired' },
  { 'dired-directory', fg = 'blue', bold = true },
  { 'dired-flagged', fg = 'red', bold = true },
  { 'dired-header', fg = 'accent', bold = true },
  { 'dired-ignored', fg = 'fg3' },
  { 'dired-mark', fg = 'accent' },
  { 'dired-marked', fg = 'yellow', bold = true },
  { 'dired-perm-write', fg = 'yellow' },
  { 'dired-set-id', fg = 'red' },
  { 'dired-special', fg = 'purple' },
  { 'dired-symlink', fg = 'cyan', italic = true },
  { 'dired-warning', fg = 'yellow', bold = true },
  { 'dired-broken-symlink', fg = 'red', italic = true, strike = true },
  { 'diredfl-dir-name', fg = 'blue', bold = true },
  { 'diredfl-dir-heading', fg = 'accent', bold = true },
  { 'diredfl-dir-priv', fg = 'blue' },
  { 'diredfl-exec-priv', fg = 'green' },
  { 'diredfl-file-name', fg = 'fg0' },
  { 'diredfl-file-suffix', fg = 'fg2' },
  { 'diredfl-flag-mark', fg = 'accent', bold = true },
  { 'diredfl-flag-mark-line', bg = 'bg4', extend = true },
  { 'diredfl-ignored-file-name', fg = 'fg3' },
  { 'diredfl-link-priv', fg = 'cyan' },
  { 'diredfl-no-priv', fg = 'fg3' },
  { 'diredfl-number', fg = 'purple' },
  { 'diredfl-read-priv', fg = 'yellow' },
  { 'diredfl-symlink', fg = 'cyan', italic = true },
  { 'diredfl-write-priv', fg = 'red' },

  { section = 'Ibuffer' },
  { 'ibuffer-locked-buffer', fg = 'yellow' },
  { 'ibuffer-filter-group-name', fg = 'accent', bold = true },
  { 'ibuffer-deletion', fg = 'red' },
  { 'ibuffer-marked', fg = 'yellow', bold = true },

  { section = 'Treemacs / Neotree' },
  { 'treemacs-root-face', fg = 'accent', bold = true, height = 1.1 },
  { 'treemacs-directory-face', fg = 'blue', bold = true },
  { 'treemacs-file-face', fg = 'fg0' },
  { 'treemacs-git-modified-face', fg = 'yellow' },
  { 'treemacs-git-renamed-face', fg = 'cyan' },
  { 'treemacs-git-ignored-face', fg = 'fg3' },
  { 'treemacs-git-untracked-face', fg = 'fg2' },
  { 'treemacs-git-added-face', fg = 'green' },
  { 'treemacs-git-conflict-face', fg = 'red', bold = true },
  { 'treemacs-tags-face', fg = 'fg2' },
  { 'neo-root-dir-face', fg = 'accent', bold = true },
  { 'neo-dir-link-face', fg = 'blue', bold = true },
  { 'neo-file-link-face', fg = 'fg0' },
  { 'neo-expand-btn-face', fg = 'fg2' },
  { 'neo-banner-face', fg = 'accent' },

  { section = 'Magit' },
  { 'magit-section-heading', fg = 'accent', bold = true },
  { 'magit-section-heading-selection', fg = 'accent2', bold = true },
  { 'magit-section-highlight', bg = 'bg5', extend = true },
  { 'magit-section-secondary-heading', fg = 'fg1', bold = true },
  { 'magit-diff-added', fg = 'bright_green', bg = 'diff_add', extend = true },
  { 'magit-diff-removed', fg = 'red', bg = 'diff_del', extend = true },
  { 'magit-diff-base', fg = 'yellow', bg = 'diff_change', extend = true },
  { 'magit-diff-added-highlight', fg = 'bright_green', bg = 'diff_add_inline', extend = true },
  { 'magit-diff-removed-highlight', fg = 'red', bg = 'diff_del_inline', extend = true },
  { 'magit-diff-base-highlight', fg = 'yellow', bg = 'diff_text', extend = true },
  { 'magit-diff-context', fg = 'fg2', extend = true },
  { 'magit-diff-context-highlight', fg = 'fg1', bg = 'bg5', extend = true },
  { 'magit-diff-hunk-heading', fg = 'cyan', bg = 'diff_change', extend = true },
  { 'magit-diff-hunk-heading-highlight', fg = 'bright_cyan', bg = 'diff_text', bold = true, extend = true },
  { 'magit-diff-hunk-heading-selection', fg = 'fg0', bg = 'bg5', extend = true },
  { 'magit-diff-hunk-region', extend = true },
  { 'magit-diff-lines-heading', fg = 'fg0', bg = 'bg4', extend = true },
  { 'magit-diff-lines-boundary', bg = 'bg4', extend = true },
  { 'magit-diff-whitespace-warning', bg = 'diff_del' },
  { 'magit-diffstat-added', fg = 'green' },
  { 'magit-diffstat-removed', fg = 'red' },
  { 'magit-branch-local', fg = 'blue' },
  { 'magit-branch-remote', fg = 'green' },
  { 'magit-branch-remote-head', fg = 'bright_green', box = true },
  { 'magit-branch-current', fg = 'blue', box = true },
  { 'magit-branch-upstream', fg = 'fg2', italic = true },
  { 'magit-branch-warning', fg = 'yellow', bold = true },
  { 'magit-tag', fg = 'yellow' },
  { 'magit-hash', fg = 'fg3' },
  { 'magit-filename', fg = 'fg0' },
  { 'magit-log-author', fg = 'accent' },
  { 'magit-log-date', fg = 'fg2' },
  { 'magit-log-graph', fg = 'fg3' },
  { 'magit-log-head-label-head', fg = 'fg0', bg = 'accent', bold = true },
  { 'magit-process-ok', fg = 'green', bold = true },
  { 'magit-process-ng', fg = 'red', bold = true },
  { 'magit-reflog-commit', fg = 'green' },
  { 'magit-reflog-amend', fg = 'purple' },
  { 'magit-reflog-merge', fg = 'cyan' },
  { 'magit-reflog-checkout', fg = 'blue' },
  { 'magit-reflog-reset', fg = 'red' },
  { 'magit-reflog-rebase', fg = 'purple' },
  { 'magit-reflog-cherry-pick', fg = 'green' },
  { 'magit-reflog-remote', fg = 'cyan' },
  { 'magit-reflog-other', fg = 'fg2' },
  { 'magit-signature-good', fg = 'green' },
  { 'magit-signature-bad', fg = 'red', bold = true },
  { 'magit-signature-untrusted', fg = 'yellow' },
  { 'magit-signature-expired', fg = 'yellow' },
  { 'magit-signature-revoked', fg = 'red' },
  { 'magit-signature-error', fg = 'red' },
  { 'magit-cherry-equivalent', fg = 'cyan' },
  { 'magit-cherry-unmatched', fg = 'purple' },
  { 'magit-blame-heading', fg = 'fg1', bg = 'bg2', extend = true },
  { 'magit-blame-hash', fg = 'accent', bg = 'bg2' },
  { 'magit-blame-name', fg = 'accent2', bg = 'bg2' },
  { 'magit-blame-date', fg = 'fg2', bg = 'bg2' },
  { 'magit-blame-summary', fg = 'fg0', bg = 'bg2' },
  { 'magit-blame-margin', fg = 'fg2', bg = 'bg2' },
  { 'magit-blame-dimmed', fg = 'fg3', bg = 'bg2' },

  { section = 'Git commit' },
  { 'git-commit-summary', fg = 'fg0', bold = true },
  { 'git-commit-overlong-summary', fg = 'red', underline = true },
  { 'git-commit-nonempty-second-line', fg = 'red', underline = true },
  { 'git-commit-comment-heading', fg = 'accent', bold = true },
  { 'git-commit-comment-action', fg = 'green' },
  { 'git-commit-comment-branch-local', fg = 'blue' },
  { 'git-commit-comment-branch-remote', fg = 'green' },
  { 'git-commit-comment-file', fg = 'accent' },
  { 'git-commit-keyword', fg = 'purple' },
  { 'git-commit-trailer-token', fg = 'blue' },
  { 'git-commit-trailer-value', fg = 'fg0' },

  { section = 'Git rebase' },
  { 'git-rebase-pick', fg = 'green' },
  { 'git-rebase-reword', fg = 'blue' },
  { 'git-rebase-edit', fg = 'yellow' },
  { 'git-rebase-squash', fg = 'purple' },
  { 'git-rebase-fixup', fg = 'accent2' },
  { 'git-rebase-exec', fg = 'cyan' },
  { 'git-rebase-kill-line', fg = 'red', strike = true },
  { 'git-rebase-hash', fg = 'fg3' },
  { 'git-rebase-description', fg = 'fg0' },
  { 'git-rebase-label', fg = 'fg2' },

  { section = 'Forge' },
  { 'forge-topic-label', box = true },
  { 'forge-pullreq-open', fg = 'green' },
  { 'forge-pullreq-merged', fg = 'purple' },
  { 'forge-pullreq-closed', fg = 'red' },
  { 'forge-issue-open', fg = 'green' },
  { 'forge-issue-closed', fg = 'fg3' },
  { 'forge-issue-completed', fg = 'fg3', strike = true },
  { 'forge-post-author', fg = 'accent', bold = true },

  { section = 'Transient' },
  { 'transient-heading', fg = 'accent', bold = true },
  { 'transient-key', fg = 'cyan', bold = true },
  { 'transient-argument', fg = 'yellow', bold = true },
  { 'transient-value', fg = 'green' },
  { 'transient-inactive-argument', fg = 'fg3' },
  { 'transient-inactive-value', fg = 'fg3' },
  { 'transient-enabled-suffix', fg = 'green', bold = true },
  { 'transient-disabled-suffix', fg = 'red', bold = true },
  { 'transient-inapt-suffix', fg = 'fg3', italic = true },
  { 'transient-mismatched-key', fg = 'red', underline = true },
  { 'transient-nonstandard-key', fg = 'yellow', underline = true },
  { 'transient-unreachable', fg = 'fg3' },
  { 'transient-unreachable-key', fg = 'fg3', underline = true },
  { 'transient-separator', fg = 'fg3', strike = true, extend = true },
  { 'transient-amaranth', fg = 'red', bold = true },
  { 'transient-blue', fg = 'blue', bold = true },
  { 'transient-pink', fg = 'bright_purple', bold = true },
  { 'transient-purple', fg = 'purple', bold = true },
  { 'transient-teal', fg = 'cyan', bold = true },
  { 'transient-red', fg = 'red', bold = true },

  { section = 'Which-key' },
  { 'which-key-key-face', fg = 'accent', bold = true },
  { 'which-key-separator-face', fg = 'fg3' },
  { 'which-key-note-face', fg = 'fg2', italic = true },
  { 'which-key-command-description-face', fg = 'fg0' },
  { 'which-key-group-description-face', fg = 'blue', bold = true },
  { 'which-key-highlighted-command-face', fg = 'accent', underline = true },
  { 'which-key-local-map-description-face', fg = 'bright_green' },
  { 'which-key-special-key-face', fg = 'purple', bold = true },
  { 'which-key-docstring-face', fg = 'fg2', italic = true },

  { section = 'Hydra' },
  { 'hydra-face-red', fg = 'red', bold = true },
  { 'hydra-face-blue', fg = 'blue', bold = true },
  { 'hydra-face-amaranth', fg = 'yellow', bold = true },
  { 'hydra-face-pink', fg = 'bright_purple', bold = true },
  { 'hydra-face-teal', fg = 'cyan', bold = true },

  { section = 'Avy' },
  { 'avy-lead-face', fg = 'bg3', bg = 'accent', bold = true },
  { 'avy-lead-face-0', fg = 'bg3', bg = 'blue', bold = true },
  { 'avy-lead-face-1', fg = 'bg3', bg = 'fg2', bold = true },
  { 'avy-lead-face-2', fg = 'bg3', bg = 'purple', bold = true },
  { 'avy-background-face', fg = 'fg3' },

  { section = 'hl-todo' },
  { 'hl-todo', bold = true, italic = true },

  { section = 'Pulsar / Pulse' },
  { 'pulsar-red', bg = 'diff_del', extend = true },
  { 'pulsar-green', bg = 'diff_add', extend = true },
  { 'pulsar-yellow', bg = 'diff_text', extend = true },
  { 'pulsar-blue', bg = 'diff_change', extend = true },
  { 'pulsar-cyan', bg = 'diff_change', extend = true },
  { 'pulsar-magenta', bg = 'diff_del', extend = true },
  { 'pulse-highlight-start-face', bg = 'match', extend = true },
  { 'pulse-highlight-face', bg = 'bg5', extend = true },

  { section = 'Org mode' },
  { 'org-level-1', fg = 'accent', bold = true },
  { 'org-level-2', fg = 'accent2', bold = true },
  { 'org-level-3', fg = 'blue', bold = true },
  { 'org-level-4', fg = 'green', bold = true },
  { 'org-level-5', fg = 'cyan', bold = true },
  { 'org-level-6', fg = 'purple', bold = true },
  { 'org-level-7', fg = 'yellow', bold = true },
  { 'org-level-8', fg = 'red', bold = true },
  { 'org-document-title', fg = 'accent', bold = true },
  { 'org-document-info', fg = 'fg2' },
  { 'org-document-info-keyword', fg = 'fg3' },
  { 'org-block', fg = 'fg0', bg = 'bg2', extend = true },
  { 'org-block-begin-line', fg = 'fg3', bg = 'bg2', italic = true, extend = true },
  { 'org-block-end-line', fg = 'fg3', bg = 'bg2', italic = true, extend = true },
  { 'org-code', fg = 'green', bg = 'bg2' },
  { 'org-verbatim', fg = 'cyan', bg = 'bg2' },
  { 'org-meta-line', fg = 'fg3' },
  { 'org-drawer', fg = 'fg3' },
  { 'org-property-value', fg = 'fg2' },
  { 'org-special-keyword', fg = 'accent2' },
  { 'org-tag', fg = 'fg3', bold = true },
  { 'org-tag-group', fg = 'fg2', bold = true },
  { 'org-ellipsis', fg = 'fg3', underline = false },
  { 'org-hide', fg = 'bg3' },
  { 'org-link', fg = 'blue', underline = true },
  { 'org-footnote', fg = 'cyan', underline = true },
  { 'org-target', fg = 'fg2', underline = true },
  { 'org-date', fg = 'cyan' },
  { 'org-date-selected', fg = 'bg3', bg = 'cyan' },
  { 'org-sexp-date', fg = 'cyan' },
  { 'org-time-grid', fg = 'fg3' },
  { 'org-todo', fg = 'red', bold = true },
  { 'org-done', fg = 'green', bold = true },
  { 'org-headline-todo', fg = 'fg0' },
  { 'org-headline-done', fg = 'fg2', strike = true },
  { 'org-priority', fg = 'purple' },
  { 'org-checkbox', fg = 'accent2', bold = true },
  { 'org-checkbox-statistics-todo', fg = 'yellow', bold = true },
  { 'org-checkbox-statistics-done', fg = 'green', bold = true },
  { 'org-table', fg = 'blue' },
  { 'org-table-header', fg = 'fg0', bg = 'bg4', bold = true },
  { 'org-formula', fg = 'yellow' },
  { 'org-list-dt', fg = 'accent2', bold = true },
  { 'org-scheduled', fg = 'green' },
  { 'org-scheduled-previously', fg = 'yellow' },
  { 'org-scheduled-today', fg = 'bright_green' },
  { 'org-upcoming-deadline', fg = 'yellow' },
  { 'org-imminent-deadline', fg = 'red', bold = true },
  { 'org-warning', fg = 'yellow', bold = true },
  { 'org-default', fg = 'fg0', bg = 'bg3' },
  { 'org-quote', fg = 'fg1', bg = 'bg2', italic = true, extend = true },
  { 'org-verse', fg = 'fg1', bg = 'bg2', italic = true, extend = true },
  { 'org-latex-and-related', fg = 'purple' },
  { 'org-macro', fg = 'accent' },
  { 'org-mode-line-clock', fg = 'fg1' },
  { 'org-mode-line-clock-overrun', fg = 'red', bold = true },

  { section = 'Org Agenda' },
  { 'org-agenda-structure', fg = 'accent', bold = true },
  { 'org-agenda-structure-filter', fg = 'accent2' },
  { 'org-agenda-date', fg = 'blue', bold = true },
  { 'org-agenda-date-today', fg = 'accent', bold = true, underline = true },
  { 'org-agenda-date-weekend', fg = 'fg2' },
  { 'org-agenda-date-weekend-today', fg = 'accent2', underline = true },
  { 'org-agenda-current-time', fg = 'accent2', bold = true },
  { 'org-agenda-done', fg = 'fg2', strike = true },
  { 'org-agenda-dimmed-todo-face', fg = 'fg3' },
  { 'org-agenda-restriction-lock', fg = 'fg0', bg = 'yellow' },
  { 'org-agenda-clocking', fg = 'fg0', bg = 'bg4' },
  { 'org-agenda-diary', fg = 'fg2' },
  { 'org-agenda-calendar-event', fg = 'fg0' },
  { 'org-agenda-calendar-sexp', fg = 'fg2' },
  { 'org-agenda-filter-category', fg = 'yellow', bold = true },
  { 'org-agenda-filter-regexp', fg = 'yellow', bold = true },
  { 'org-agenda-filter-tags', fg = 'yellow', bold = true },
  { 'org-agenda-filter-effort', fg = 'yellow', bold = true },
  { 'org-agenda-column-dateline', fg = 'cyan' },

  { section = 'Org Roam' },
  { 'org-roam-link', fg = 'blue', underline = true },
  { 'org-roam-link-current', fg = 'accent', underline = true },
  { 'org-roam-link-invalid', fg = 'red', underline = true },
  { 'org-roam-header-line', fg = 'accent', bold = true },
  { 'org-roam-olp', fg = 'fg2', italic = true },
  { 'org-roam-preview-heading', fg = 'accent2', bold = true },

  { section = 'Markdown' },
  { 'markdown-header-face', fg = 'accent', bold = true },
  { 'markdown-header-face-1', fg = 'accent', bold = true },
  { 'markdown-header-face-2', fg = 'accent2', bold = true },
  { 'markdown-header-face-3', fg = 'blue', bold = true },
  { 'markdown-header-face-4', fg = 'green', bold = true },
  { 'markdown-header-face-5', fg = 'cyan', bold = true },
  { 'markdown-header-face-6', fg = 'purple', bold = true },
  { 'markdown-header-delimiter-face', fg = 'fg3', bold = true },
  { 'markdown-bold-face', bold = true },
  { 'markdown-italic-face', italic = true },
  { 'markdown-strike-through-face', fg = 'fg2', strike = true },
  { 'markdown-code-face', fg = 'fg0', bg = 'bg2', extend = true },
  { 'markdown-inline-code-face', fg = 'green', bg = 'bg2' },
  { 'markdown-pre-face', fg = 'fg0', bg = 'bg2' },
  { 'markdown-language-keyword-face', fg = 'fg3' },
  { 'markdown-blockquote-face', fg = 'fg2', italic = true },
  { 'markdown-list-face', fg = 'accent2' },
  { 'markdown-link-face', fg = 'blue', underline = true },
  { 'markdown-url-face', fg = 'cyan' },
  { 'markdown-plain-url-face', fg = 'cyan', underline = true },
  { 'markdown-reference-face', fg = 'fg2' },
  { 'markdown-footnote-marker-face', fg = 'purple' },
  { 'markdown-footnote-text-face', fg = 'fg1' },
  { 'markdown-table-face', fg = 'blue' },
  { 'markdown-hr-face', fg = 'fg3' },
  { 'markdown-html-attr-name-face', fg = 'blue' },
  { 'markdown-html-attr-value-face', fg = 'green' },
  { 'markdown-html-tag-delimiter-face', fg = 'fg2' },
  { 'markdown-html-tag-name-face', fg = 'accent' },
  { 'markdown-math-face', fg = 'purple' },
  { 'markdown-metadata-key-face', fg = 'fg2' },
  { 'markdown-metadata-value-face', fg = 'fg1' },
  { 'markdown-highlighting-face', bg = 'match' },

  { section = 'Shell / Terminal' },
  { 'comint-highlight-input', fg = 'fg0', bold = true },
  { 'comint-highlight-prompt', fg = 'green', bold = true },
  { 'eshell-prompt', fg = 'accent', bold = true },
  { 'eshell-ls-directory', fg = 'blue', bold = true },
  { 'eshell-ls-executable', fg = 'green' },
  { 'eshell-ls-missing', fg = 'red', bold = true },
  { 'eshell-ls-product', fg = 'yellow' },
  { 'eshell-ls-readonly', fg = 'fg2' },
  { 'eshell-ls-special', fg = 'purple' },
  { 'eshell-ls-symlink', fg = 'cyan' },
  { 'eshell-ls-unreadable', fg = 'red' },
  { 'eshell-ls-backup', fg = 'fg3' },
  { 'eshell-ls-clutter', fg = 'fg3' },
  { 'eshell-ls-archive', fg = 'yellow' },
  { 'vterm-color-default', fg = 'fg0', bg = 'bg3' },
  { 'vterm-color-black', fg = 'bg1', bg = 'bg1' },
  { 'vterm-color-red', fg = 'red', bg = 'red' },
  { 'vterm-color-green', fg = 'green', bg = 'green' },
  { 'vterm-color-yellow', fg = 'yellow', bg = 'yellow' },
  { 'vterm-color-blue', fg = 'blue', bg = 'blue' },
  { 'vterm-color-magenta', fg = 'purple', bg = 'purple' },
  { 'vterm-color-cyan', fg = 'cyan', bg = 'cyan' },
  { 'vterm-color-white', fg = 'fg1', bg = 'fg1' },
  { 'vterm-color-bright-black', fg = 'fg3', bg = 'fg3' },
  { 'vterm-color-bright-red', fg = 'accent', bg = 'accent' },
  { 'vterm-color-bright-green', fg = 'bright_green', bg = 'bright_green' },
  { 'vterm-color-bright-yellow', fg = 'accent2', bg = 'accent2' },
  { 'vterm-color-bright-blue', fg = 'bright_blue', bg = 'bright_blue' },
  { 'vterm-color-bright-magenta', fg = 'bright_purple', bg = 'bright_purple' },
  { 'vterm-color-bright-cyan', fg = 'bright_cyan', bg = 'bright_cyan' },
  { 'vterm-color-bright-white', fg = 'fg0', bg = 'fg0' },

  { section = 'Ansi colors' },
  { 'ansi-color-black', fg = 'bg1', bg = 'bg1' },
  { 'ansi-color-red', fg = 'red', bg = 'red' },
  { 'ansi-color-green', fg = 'green', bg = 'green' },
  { 'ansi-color-yellow', fg = 'yellow', bg = 'yellow' },
  { 'ansi-color-blue', fg = 'blue', bg = 'blue' },
  { 'ansi-color-magenta', fg = 'purple', bg = 'purple' },
  { 'ansi-color-cyan', fg = 'cyan', bg = 'cyan' },
  { 'ansi-color-white', fg = 'fg1', bg = 'fg1' },
  { 'ansi-color-bright-black', fg = 'fg3', bg = 'fg3' },
  { 'ansi-color-bright-red', fg = 'accent', bg = 'accent' },
  { 'ansi-color-bright-green', fg = 'bright_green', bg = 'bright_green' },
  { 'ansi-color-bright-yellow', fg = 'accent2', bg = 'accent2' },
  { 'ansi-color-bright-blue', fg = 'bright_blue', bg = 'bright_blue' },
  { 'ansi-color-bright-magenta', fg = 'bright_purple', bg = 'bright_purple' },
  { 'ansi-color-bright-cyan', fg = 'bright_cyan', bg = 'bright_cyan' },
  { 'ansi-color-bright-white', fg = 'fg0', bg = 'fg0' },

  { section = 'Calendar' },
  { 'calendar-today', fg = 'accent', bold = true, underline = true },
  { 'calendar-month-header', fg = 'accent', bold = true },
  { 'calendar-weekday-header', fg = 'blue' },
  { 'calendar-weekend-header', fg = 'fg2' },
  { 'diary', fg = 'yellow' },
  { 'holiday', fg = 'red' },
  { 'diary-anniversary', fg = 'cyan' },

  { section = 'Message / Mail' },
  { 'message-header-name', fg = 'blue', bold = true },
  { 'message-header-to', fg = 'fg0', bold = true },
  { 'message-header-cc', fg = 'fg1' },
  { 'message-header-subject', fg = 'accent', bold = true },
  { 'message-header-other', fg = 'fg1' },
  { 'message-header-newsgroups', fg = 'yellow', bold = true },
  { 'message-header-xheader', fg = 'fg2' },
  { 'message-separator', fg = 'fg3', italic = true },
  { 'message-cited-text-1', fg = 'blue' },
  { 'message-cited-text-2', fg = 'green' },
  { 'message-cited-text-3', fg = 'purple' },
  { 'message-cited-text-4', fg = 'cyan' },
  { 'message-mml', fg = 'fg2', italic = true },

  { section = 'Gnus' },
  { 'gnus-group-mail-1', fg = 'accent', bold = true },
  { 'gnus-group-mail-2', fg = 'accent' },
  { 'gnus-group-mail-3', fg = 'fg1' },
  { 'gnus-group-mail-1-empty', fg = 'fg2' },
  { 'gnus-group-mail-2-empty', fg = 'fg2' },
  { 'gnus-group-mail-3-empty', fg = 'fg3' },
  { 'gnus-group-news-1', fg = 'blue', bold = true },
  { 'gnus-group-news-2', fg = 'blue' },
  { 'gnus-group-news-3', fg = 'fg1' },
  { 'gnus-summary-selected', fg = 'fg0', bg = 'sel' },
  { 'gnus-summary-normal-read', fg = 'fg2' },
  { 'gnus-summary-normal-unread', fg = 'fg0', bold = true },
  { 'gnus-summary-high-unread', fg = 'accent', bold = true },
  { 'gnus-summary-low-unread', fg = 'fg2', italic = true },
  { 'gnus-header-name', fg = 'blue', bold = true },
  { 'gnus-header-from', fg = 'accent' },
  { 'gnus-header-subject', fg = 'fg0', bold = true },
  { 'gnus-header-content', fg = 'fg1' },

  { section = 'Notmuch' },
  { 'notmuch-search-date', fg = 'fg3' },
  { 'notmuch-search-count', fg = 'fg3' },
  { 'notmuch-search-subject', fg = 'fg0' },
  { 'notmuch-search-matching-authors', fg = 'accent' },
  { 'notmuch-search-non-matching-authors', fg = 'fg2' },
  { 'notmuch-search-flagged-face', fg = 'blue' },
  { 'notmuch-search-unread-face', bold = true },
  { 'notmuch-tag-face', fg = 'green' },
  { 'notmuch-tag-unread', fg = 'yellow', bold = true },
  { 'notmuch-tag-flagged', fg = 'blue' },
  { 'notmuch-tag-deleted', fg = 'red', strike = true },
  { 'notmuch-tree-match-face', fg = 'fg0', bold = true },
  { 'notmuch-tree-no-match-face', fg = 'fg2' },
  { 'notmuch-message-summary-face', fg = 'fg2', bg = 'bg2' },

  { section = 'Elfeed' },
  { 'elfeed-search-date-face', fg = 'fg3' },
  { 'elfeed-search-feed-face', fg = 'blue' },
  { 'elfeed-search-filter-face', fg = 'accent', bold = true },
  { 'elfeed-search-last-update-face', fg = 'fg3', italic = true },
  { 'elfeed-search-tag-face', fg = 'green' },
  { 'elfeed-search-title-face', fg = 'fg0' },
  { 'elfeed-search-unread-title-face', fg = 'fg0', bold = true },
  { 'elfeed-search-unread-count-face', fg = 'accent2', bold = true },
  { 'elfeed-log-error-level-face', fg = 'red' },
  { 'elfeed-log-warn-level-face', fg = 'yellow' },
  { 'elfeed-log-info-level-face', fg = 'blue' },
  { 'elfeed-log-debug-level-face', fg = 'fg2' },

  { section = 'EWW' },
  { 'eww-valid-certificate', fg = 'green', bold = true },
  { 'eww-invalid-certificate', fg = 'red', bold = true },
  { 'eww-form-checkbox', fg = 'fg0', bg = 'bg4', box = true },
  { 'eww-form-file', fg = 'fg0', bg = 'bg4', box = true },
  { 'eww-form-select', fg = 'fg0', bg = 'bg4', box = true },
  { 'eww-form-submit', fg = 'fg0', bg = 'bg4', bold = true, box = true },
  { 'eww-form-text', fg = 'fg0', bg = 'bg4', box = true },
  { 'eww-form-textarea', fg = 'fg0', bg = 'bg4', box = true },
  { 'shr-link', fg = 'blue', underline = true },
  { 'shr-visited-link', fg = 'purple', underline = true },
  { 'shr-selected-link', fg = 'bg3', bg = 'blue' },
  { 'shr-strike-through', fg = 'fg2', strike = true },
  { 'shr-abbreviation', underline = { style = 'dots', color = 'fg2' } },
  { 'shr-h1', fg = 'accent', bold = true },
  { 'shr-h2', fg = 'accent2', bold = true },
  { 'shr-h3', fg = 'blue', bold = true },
  { 'shr-h4', fg = 'fg0', bold = true },
  { 'shr-h5', fg = 'fg1', bold = true },
  { 'shr-h6', fg = 'fg2', bold = true },
  { 'shr-code', fg = 'green', bg = 'bg2' },

  { section = 'CIDER' },
  { 'cider-result-overlay-face', fg = 'fg0', bg = 'bg4', box = { line_width = -1, color = 'fg3' } },
  { 'cider-debug-code-overlay-face', bg = 'bg5' },
  { 'cider-error-highlight-face', underline = { style = 'wave', color = 'red' } },
  { 'cider-warning-highlight-face', underline = { style = 'wave', color = 'yellow' } },
  { 'cider-repl-prompt-face', fg = 'green', bold = true },
  { 'cider-repl-input-face', bold = true },
  { 'cider-repl-output-face', fg = 'fg1' },
  { 'cider-repl-stderr-face', fg = 'red' },
  { 'cider-test-success-face', fg = 'bg3', bg = 'green' },
  { 'cider-test-failure-face', fg = 'bg3', bg = 'red' },
  { 'cider-test-error-face', fg = 'bg3', bg = 'yellow' },
  { 'cider-test-skipped-face', fg = 'bg3', bg = 'fg2' },
  { 'cider-fringe-good-face', fg = 'green' },
  { 'cider-enlightened-face', fg = 'yellow', box = { line_width = -1, color = 'yellow' } },
  { 'cider-enlightened-local-face', fg = 'yellow', bold = true },
  { 'cider-traced-face', box = { line_width = -1, color = 'cyan' } },
  { 'cider-stacktrace-error-message-face', fg = 'red' },
  { 'cider-stacktrace-filter-active-face', fg = 'fg0', underline = true },
  { 'cider-stacktrace-filter-inactive-face', fg = 'fg2' },

  { section = 'SLIME / SLY' },
  { 'slime-repl-prompt-face', fg = 'green', bold = true },
  { 'slime-repl-output-face', fg = 'fg1' },
  { 'slime-repl-inputed-output-face', fg = 'fg2' },
  { 'slime-error-face', underline = { style = 'wave', color = 'red' } },
  { 'slime-warning-face', underline = { style = 'wave', color = 'yellow' } },
  { 'slime-style-warning-face', underline = { style = 'wave', color = 'blue' } },
  { 'slime-note-face', underline = { style = 'wave', color = 'green' } },
  { 'sly-mrepl-prompt-face', fg = 'green', bold = true },
  { 'sly-mrepl-output-face', fg = 'fg1' },
  { 'sly-mrepl-note-face', fg = 'fg3' },
  { 'sly-stickers-placed-face', bg = 'bg5' },

  { section = 'Package menu' },
  { 'package-name', fg = 'blue' },
  { 'package-description', fg = 'fg1' },
  { 'package-status-available', fg = 'green' },
  { 'package-status-avail-obso', fg = 'fg2' },
  { 'package-status-installed', fg = 'fg0', bold = true },
  { 'package-status-dependency', fg = 'blue' },
  { 'package-status-built-in', fg = 'fg2' },
  { 'package-status-new', fg = 'accent', bold = true },
  { 'package-status-held', fg = 'yellow' },
  { 'package-status-external', fg = 'cyan' },
  { 'package-status-incompat', fg = 'red' },
  { 'package-status-disabled', fg = 'fg3', strike = true },

  { section = 'Custom / Customize' },
  { 'custom-group-tag', fg = 'accent', bold = true },
  { 'custom-group-tag-1', fg = 'blue', bold = true },
  { 'custom-variable-tag', fg = 'accent2', bold = true },
  { 'custom-variable-obsolete', fg = 'fg2', strike = true },
  { 'custom-state', fg = 'green' },
  { 'custom-changed', fg = 'yellow' },
  { 'custom-modified', fg = 'yellow', bold = true },
  { 'custom-set', fg = 'blue' },
  { 'custom-themed', fg = 'blue' },
  { 'custom-saved', fg = 'green', bold = true },
  { 'custom-rogue', fg = 'red', bg = 'bg4' },
  { 'custom-invalid', fg = 'fg0', bg = 'red' },
  { 'custom-comment', fg = 'fg2', bg = 'bg2' },
  { 'custom-comment-tag', fg = 'fg2' },
  { 'custom-button', fg = 'fg0', bg = 'bg4', box = true },
  { 'custom-button-mouse', fg = 'fg0', bg = 'bg5', box = true },
  { 'custom-button-pressed', fg = 'bg3', bg = 'accent', box = true },
  { 'custom-documentation', italic = true },
  { 'widget-field', fg = 'fg0', bg = 'bg4' },
  { 'widget-button', fg = 'blue', bold = true },
  { 'widget-button-pressed', fg = 'accent' },
  { 'widget-documentation', fg = 'fg2', italic = true },
  { 'widget-inactive', fg = 'fg3' },
  { 'widget-single-line-field', fg = 'fg0', bg = 'bg4' },
}

-- Face name column: names are padded to this column before `((,class`.
-- Names longer than this get one space of separation and overflow.
local EMACS_NAME_COL = 34

-- Canonical emission order for face attributes.
local EMACS_ATTR_ORDER = {
  'fg',
  'bg',
  'bold',
  'italic',
  'underline',
  'strike',
  'extend',
  'box',
  'height',
}

-- Precomputed dash line for section headers. 70 U+2500 chars (210 bytes).
local EMACS_DASH_LINE = string.rep('─', 70)

local function emacs_key(k)
  return (k:gsub('_', '-'))
end

local function emacs_known_keys()
  local set = {}
  for _, k in ipairs(EMACS_LET_KEYS) do
    set[k] = true
  end
  return set
end

local function emacs_check_key(key, context, known)
  if not known[key] then
    error('emacs: unknown palette key "' .. tostring(key) .. '" in ' .. context)
  end
end

-- Emit one :keyword VALUE fragment. Returns nil if the attribute should be skipped.
local function emacs_attr_part(name, value, known)
  if value == nil then
    return nil
  end
  if name == 'fg' then
    emacs_check_key(value, 'fg', known)
    return ':foreground ,' .. emacs_key(value)
  elseif name == 'bg' then
    emacs_check_key(value, 'bg', known)
    return ':background ,' .. emacs_key(value)
  elseif name == 'bold' then
    return value and ':weight bold' or nil
  elseif name == 'italic' then
    return value and ':slant italic' or nil
  elseif name == 'underline' then
    if type(value) == 'table' then
      emacs_check_key(value.color, 'underline.color', known)
      return ':underline (:style ' .. value.style .. ' :color ,' .. emacs_key(value.color) .. ')'
    elseif value == true then
      return ':underline t'
    elseif value == false then
      return ':underline nil'
    end
    return nil
  elseif name == 'strike' then
    return value and ':strike-through t' or nil
  elseif name == 'extend' then
    return value and ':extend t' or nil
  elseif name == 'box' then
    if type(value) == 'table' then
      emacs_check_key(value.color, 'box.color', known)
      return ':box (:line-width ' .. value.line_width .. ' :color ,' .. emacs_key(value.color) .. ')'
    elseif value == true then
      return ':box t'
    end
    return nil
  elseif name == 'height' then
    return ':height ' .. tostring(value)
  end
  return nil
end

local function emacs_face_body(entry, known)
  if entry.literal then
    return entry.literal
  end
  local parts = {}
  for _, k in ipairs(EMACS_ATTR_ORDER) do
    local part = emacs_attr_part(k, entry[k], known)
    if part then
      parts[#parts + 1] = part
    end
  end
  return '(' .. table.concat(parts, ' ') .. ')'
end

-- Build one face line. When `last` is true, append the two extra closing parens
-- that close `(custom-theme-set-faces ...)` and the enclosing `(let ...)`.
local function emacs_face_line(entry, known, last)
  local name = entry[1]
  local body = emacs_face_body(entry, known)
  local pad_len = math.max(1, EMACS_NAME_COL - #name)
  local tail = last and ')))))' or ')))'
  return '   `(' .. name .. string.rep(' ', pad_len) .. '((,class ' .. body .. tail
end

local function emacs_section_comment(label)
  -- Visible prefix for ASCII labels: '   ;; ── LABEL ' = 10 + #label cols.
  local dashes = 79 - 10 - #label
  if dashes < 1 then
    dashes = 1
  end
  -- Each U+2500 is 3 bytes in UTF-8; slice by byte.
  return '   ;; ── ' .. label .. ' ' .. string.sub(EMACS_DASH_LINE, 1, dashes * 3)
end

-- Return the lines of the `(let (BINDINGS) ...)` opener through the final
-- binding (with its closing `))`). The body of the let is appended by the
-- caller.
local function emacs_let_block(p)
  -- longest hyphenated key is 'diff-add-inline' (15 chars); pad to 16 so
  -- names of the maximum length still get one space before the hex value.
  local key_col = 16
  local lines = { "(let ((class '((class color) (min-colors 89)))" }
  local n = #EMACS_LET_KEYS
  for i, key in ipairs(EMACS_LET_KEYS) do
    local ekey = emacs_key(key)
    local pad = string.rep(' ', math.max(1, key_col - #ekey))
    local suffix = (i == n) and '"))' or '")'
    lines[#lines + 1] = '      (' .. ekey .. pad .. '"' .. p[key] .. suffix
  end
  return lines
end

-- Generator-time sanity check. Errors on:
--   1. A palette key referenced in EMACS_FACES but absent from EMACS_LET_KEYS.
--   2. A palette key in EMACS_LET_KEYS that is never referenced.
--   3. A duplicate face name in EMACS_FACES.
local function emacs_audit(known)
  local referenced = {}
  local seen = {}
  local function check(face_name, kind, value)
    if type(value) == 'string' then
      if not known[value] then
        error('emacs: face "' .. face_name .. '" references unknown palette key "' .. value .. '" in ' .. kind)
      end
      referenced[value] = true
    end
  end
  for _, entry in ipairs(EMACS_FACES) do
    if entry.section == nil then
      local name = entry[1]
      if not name then
        error('emacs: face entry with no name')
      end
      if seen[name] then
        error('emacs: duplicate face name "' .. name .. '"')
      end
      seen[name] = true
      check(name, 'fg', entry.fg)
      check(name, 'bg', entry.bg)
      if type(entry.underline) == 'table' then
        check(name, 'underline.color', entry.underline.color)
      end
      if type(entry.box) == 'table' then
        check(name, 'box.color', entry.box.color)
      end
    end
  end
  for _, key in ipairs(EMACS_LET_KEYS) do
    if not referenced[key] then
      error('emacs: EMACS_LET_KEYS contains unused palette key "' .. key .. '"')
    end
  end
end

local function gen_emacs(p, variant)
  local known = emacs_known_keys()
  emacs_audit(known)

  local theme = 'token-' .. variant
  local file = theme .. '-theme.el'

  local lines = {
    ';;; ' .. file .. ' --- Token ' .. variant .. ' color theme -*- lexical-binding: t -*-',
    '',
    ';;; Commentary:',
    ';; Generated by token colorscheme. Do not edit manually.',
    ';; Face list adapted from work by srg-dev',
    ';; (https://github.com/ThorstenRhau/token/pull/1).',
    '',
    ';;; Code:',
    '',
    '(deftheme ' .. theme .. ' "Token ' .. variant .. ' color theme.")',
    '',
  }

  extend_lines(lines, emacs_let_block(p))
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  (custom-theme-set-faces'
  lines[#lines + 1] = "   '" .. theme

  -- Find the last face entry index (skipping section markers) so we can
  -- append the two extra closing parens to close custom-theme-set-faces and
  -- the outer let.
  local last_face = 0
  for i, entry in ipairs(EMACS_FACES) do
    if entry.section == nil then
      last_face = i
    end
  end

  for i, entry in ipairs(EMACS_FACES) do
    if entry.section then
      lines[#lines + 1] = ''
      lines[#lines + 1] = emacs_section_comment(entry.section)
    else
      lines[#lines + 1] = emacs_face_line(entry, known, i == last_face)
    end
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = ';;;###autoload'
  lines[#lines + 1] = '(when load-file-name'
  lines[#lines + 1] = "  (add-to-list 'custom-theme-load-path"
  lines[#lines + 1] = '               (file-name-as-directory (file-name-directory load-file-name))))'
  lines[#lines + 1] = ''
  lines[#lines + 1] = '(provide-theme ' .. "'" .. theme .. ')'
  lines[#lines + 1] = ''
  lines[#lines + 1] = ';;; ' .. file .. ' ends here'
  lines[#lines + 1] = ''

  return { path = 'contrib/emacs/' .. file, content = table.concat(lines, '\n') }
end

-- ---------------------------------------------------------------------------
-- fish (.theme)
-- ---------------------------------------------------------------------------

local function fish_theme_lines(p)
  local s = strip
  return {
    'fish_color_normal ' .. s(p.fg0),
    'fish_color_command ' .. s(p.blue),
    'fish_color_keyword ' .. s(p.accent2),
    'fish_color_quote ' .. s(p.green),
    'fish_color_redirection ' .. s(p.purple),
    'fish_color_end ' .. s(p.fg2),
    'fish_color_error ' .. s(p.red),
    'fish_color_param ' .. s(p.fg1),
    'fish_color_comment ' .. s(p.fg2),
    'fish_color_selection --reverse',
    'fish_color_operator ' .. s(p.accent),
    'fish_color_escape ' .. s(p.purple),
    'fish_color_autosuggestion ' .. s(p.line_nr),
    'fish_color_cwd ' .. s(p.blue),
    'fish_color_user ' .. s(p.green),
    'fish_color_host ' .. s(p.blue),
    'fish_color_host_remote ' .. s(p.accent2),
    'fish_color_cancel ' .. s(p.red),
    'fish_color_search_match --background=' .. s(p.match),
    'fish_color_valid_path --underline',
    '',
    '# Pager',
    'fish_pager_color_progress ' .. s(p.accent),
    'fish_pager_color_prefix ' .. s(p.accent) .. ' --bold',
    'fish_pager_color_completion ' .. s(p.fg0),
    'fish_pager_color_description ' .. s(p.fg2),
    'fish_pager_color_selected_background --background=' .. s(p.sel),
    'fish_pager_color_selected_prefix ' .. s(p.accent) .. ' --bold',
    'fish_pager_color_selected_completion ' .. s(p.fg0),
    'fish_pager_color_selected_description ' .. s(p.fg2),
  }
end

local function gen_fish(dark, light, _dark_term, _light_term)
  local function add_variant(lines, name, p)
    lines[#lines + 1] = '[' .. name .. ']'
    lines[#lines + 1] = '# preferred_background: ' .. strip(p.bg3)
    extend_lines(lines, fish_theme_lines(p))
    lines[#lines + 1] = ''
  end

  local lines = {
    '# Generated by token colorscheme. Do not edit manually.',
    "# name: 'token'",
    '',
  }

  add_variant(lines, 'dark', dark)
  add_variant(lines, 'light', light)
  add_variant(lines, 'unknown', dark)

  return { path = 'contrib/fish/token.theme', content = table.concat(lines, '\n') }
end

-- ---------------------------------------------------------------------------
-- fzf (fish script)
-- ---------------------------------------------------------------------------

local function gen_fzf(p, variant, _term)
  local content = table.concat({
    '# Generated by token colorscheme. Do not edit manually.',
    '# Source this file from config.fish to append token colors to FZF_DEFAULT_OPTS.',
    '',
    'set -gx FZF_DEFAULT_OPTS (string join " " -- \\',
    '  $FZF_DEFAULT_OPTS \\',
    '  --border \\',
    "  '--color=fg:" .. p.fg0 .. ',bg:' .. p.bg3 .. ',hl:' .. p.accent .. "' \\",
    "  '--color=fg+:" .. p.fg0 .. ',bg+:' .. p.sel .. ',hl+:' .. p.accent .. "' \\",
    "  '--color=border:" .. p.fg3 .. ',header:' .. p.blue .. ',gutter:' .. p.bg3 .. "' \\",
    "  '--color=spinner:" .. p.accent2 .. ',info:' .. p.fg2 .. "' \\",
    "  '--color=pointer:" .. p.accent .. ',marker:' .. p.green .. ',prompt:' .. p.accent .. "')",
    '',
  }, '\n')

  return { path = 'contrib/fzf/token-' .. variant .. '.fish', content = content }
end

-- ---------------------------------------------------------------------------
-- ghostty (config fragment)
-- ---------------------------------------------------------------------------

local function gen_ghostty(p, variant, term)
  local lines = {
    '# Generated by token colorscheme. Do not edit manually.',
    '',
    'background = ' .. p.bg3,
    'foreground = ' .. p.fg0,
    'cursor-color = ' .. p.fg0,
    'cursor-text = ' .. p.bg3,
    'selection-background = ' .. p.sel,
    'selection-foreground = ' .. p.fg0,
    '',
  }
  for i = 0, 15 do
    lines[#lines + 1] = 'palette = ' .. i .. '=' .. term[i]
  end
  lines[#lines + 1] = ''

  return { path = 'contrib/ghostty/token-' .. variant, content = table.concat(lines, '\n') }
end

-- ---------------------------------------------------------------------------
-- lazygit (YAML)
-- ---------------------------------------------------------------------------

local function gen_lazygit(p, variant, _term)
  local content = table.concat({
    '# yaml-language-server: $schema=https://raw.githubusercontent.com/jesseduffield/lazygit/master/schema/config.json',
    '# Generated by token colorscheme. Do not edit manually.',
    '# Merge this into your lazygit config.yml.',
    '',
    'gui:',
    '  theme:',
    '    activeBorderColor:',
    '      - "' .. p.accent .. '"',
    '      - bold',
    '    inactiveBorderColor:',
    '      - "' .. p.fg3 .. '"',
    '    searchingActiveBorderColor:',
    '      - "' .. p.yellow .. '"',
    '      - bold',
    '    optionsTextColor:',
    '      - "' .. p.blue .. '"',
    '    selectedLineBgColor:',
    '      - "' .. p.sel .. '"',
    '    inactiveViewSelectedLineBgColor:',
    '      - "' .. p.bg4 .. '"',
    '    cherryPickedCommitFgColor:',
    '      - "' .. p.blue .. '"',
    '    cherryPickedCommitBgColor:',
    '      - "' .. p.bg4 .. '"',
    '    markedBaseCommitFgColor:',
    '      - "' .. p.purple .. '"',
    '    markedBaseCommitBgColor:',
    '      - "' .. p.bg4 .. '"',
    '    unstagedChangesColor:',
    '      - "' .. p.red .. '"',
    '    defaultFgColor:',
    '      - "' .. p.fg0 .. '"',
    '',
  }, '\n')

  return { path = 'contrib/lazygit/token-' .. variant .. '.yml', content = content }
end

-- ---------------------------------------------------------------------------
-- ripgrep (.ripgreprc)
-- ---------------------------------------------------------------------------

local function gen_ripgrep(p, variant, _term)
  local content = table.concat({
    '# Generated by token colorscheme. Do not edit manually.',
    '--colors=match:none',
    '--colors=match:fg:' .. rgb_fmt(p.accent),
    '--colors=match:style:bold',
    '--colors=path:none',
    '--colors=path:fg:' .. rgb_fmt(p.blue),
    '--colors=path:style:nobold',
    '--colors=line:none',
    '--colors=line:fg:' .. rgb_fmt(p.fg2),
    '--colors=line:style:nobold',
    '--colors=column:none',
    '--colors=column:fg:' .. rgb_fmt(p.fg3),
    '--colors=column:style:nobold',
    '',
  }, '\n')

  return { path = 'contrib/ripgrep/token-' .. variant .. '.ripgreprc', content = content }
end

-- ---------------------------------------------------------------------------
-- starship (TOML palette)
-- ---------------------------------------------------------------------------

local function gen_starship(p, variant, _term)
  local content = table.concat({
    '# Generated by token colorscheme. Do not edit manually.',
    '# Add palette = "token" to your starship.toml to use these colors.',
    '',
    '[palettes.token]',
    'bg      = "' .. p.bg3 .. '"',
    'fg      = "' .. p.fg0 .. '"',
    'muted   = "' .. p.fg2 .. '"',
    'subtle  = "' .. p.fg3 .. '"',
    'accent  = "' .. p.accent .. '"',
    'accent2 = "' .. p.accent2 .. '"',
    'blue    = "' .. p.blue .. '"',
    'green   = "' .. p.green .. '"',
    'red     = "' .. p.red .. '"',
    'yellow  = "' .. p.yellow .. '"',
    'purple  = "' .. p.purple .. '"',
    'cyan    = "' .. p.cyan .. '"',
    'orange  = "' .. p.orange .. '"',
    '',
  }, '\n')

  return { path = 'contrib/starship/token-' .. variant .. '.toml', content = content }
end

-- ---------------------------------------------------------------------------
-- tmux (.conf)
-- ---------------------------------------------------------------------------

local function gen_tmux(p, variant, _term)
  local content = table.concat({
    '# Generated by token colorscheme. Do not edit manually.',
    '# Source this file from your tmux.conf: source-file /path/to/token-' .. variant .. '.conf',
    '',
    '# Status bar',
    'set -g status-style "bg=' .. p.bg0 .. ',fg=' .. p.fg1 .. '"',
    'set -g status-left-style "bg=' .. p.bg0 .. ',fg=' .. p.accent .. ',bold"',
    'set -g status-right-style "bg=' .. p.bg0 .. ',fg=' .. p.fg2 .. '"',
    '',
    '# Window status',
    'setw -g window-status-style "bg=' .. p.bg0 .. ',fg=' .. p.fg2 .. '"',
    'setw -g window-status-current-style "bg=' .. p.bg0 .. ',fg=' .. p.blue .. ',bold"',
    'setw -g window-status-activity-style "bg=' .. p.bg0 .. ',fg=' .. p.yellow .. '"',
    'setw -g window-status-bell-style "bg=' .. p.bg0 .. ',fg=' .. p.red .. '"',
    '',
    '# Pane borders',
    'set -g pane-border-style "fg=' .. p.fg3 .. '"',
    'set -g pane-active-border-style "fg=' .. p.blue .. '"',
    '',
    '# Messages',
    'set -g message-style "bg=' .. p.bg3 .. ',fg=' .. p.fg0 .. '"',
    'set -g message-command-style "bg=' .. p.bg3 .. ',fg=' .. p.fg0 .. '"',
    '',
    '# Copy mode',
    'setw -g mode-style "bg=' .. p.sel .. ',fg=' .. p.fg0 .. '"',
    '',
    '# Clock',
    'setw -g clock-mode-colour "' .. p.accent .. '"',
    '',
    '# Display panes',
    'set -g display-panes-active-colour "' .. p.accent .. '"',
    'set -g display-panes-colour "' .. p.fg3 .. '"',
    '',
  }, '\n')

  return { path = 'contrib/tmux/token-' .. variant .. '.conf', content = content }
end

-- ---------------------------------------------------------------------------
-- Main
-- ---------------------------------------------------------------------------

local function main()
  local verify = false
  for _, a in ipairs(arg) do
    if a == '--verify' then
      verify = true
    end
  end

  local dark = palette_fn('dark')
  local light = palette_fn('light')
  local dark_term = terminal.colors(dark, true)
  local light_term = terminal.colors(light, false)

  local files = {}

  for _, variant in ipairs({ 'dark', 'light' }) do
    local p = variant == 'dark' and dark or light
    local term = variant == 'dark' and dark_term or light_term
    files[#files + 1] = gen_bat(p, variant, term)
    files[#files + 1] = gen_emacs(p, variant)
    files[#files + 1] = gen_fzf(p, variant, term)
    files[#files + 1] = gen_ghostty(p, variant, term)
    files[#files + 1] = gen_lazygit(p, variant)
    files[#files + 1] = gen_ripgrep(p, variant, term)
    files[#files + 1] = gen_starship(p, variant, term)
    files[#files + 1] = gen_tmux(p, variant, term)
  end

  files[#files + 1] = gen_fish(dark, light, dark_term, light_term)
  files[#files + 1] = gen_delta(dark, light, dark_term, light_term)

  local ok = true
  for _, f in ipairs(files) do
    if not write_if_changed(f.path, f.content, verify) then
      ok = false
    end
  end

  if verify and not ok then
    io.stderr:write('contrib files are out of date. Run: make contrib\n')
    os.exit(1)
  end
end

main()
