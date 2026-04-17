---
name: colorscheme-review
description: Read-only audit of the token colorscheme for palette integrity, module conformance, and toolchain health
user-invocable: true
---

Perform a **read-only** structured audit of this Neovim colorscheme. Do NOT modify any files. Do NOT create any files (no report saved to disk). Read everything, analyze, and produce a single markdown report printed to the conversation.

## Setup

Before starting, read these files to understand the project:

1. `CLAUDE.md` (project conventions)
2. `colors/token.lua`, `plugin/token.lua`, `lua/token/init.lua`, `lua/token/compile.lua` (entry points and load flow)
3. `lua/token/palette.lua` (dark and light color tables)
4. `lua/token/groups/init.lua`, `lua/token/groups/plugins/init.lua` (group merge order and plugin list)
5. `lua/token/terminal.lua`, `lua/lualine/themes/token.lua`
6. `Makefile`, `.stylua.toml`, `selene.toml`, `neovim.yaml`, `taplo.toml`
7. `scripts/*.lua` (contrib and library generators)

## Tool Usage

Use the available tools to **verify findings before reporting**. A finding based only on grep without verification is not production-grade.

### context7 MCP (library documentation)

Use `resolve-library-id` then `query-docs` to fetch current plugin documentation. Required when:

- Verifying current highlight group names for a plugin in `lua/token/groups/plugins/*.lua` (Phase 5)
- Confirming a group has been renamed, added, or removed upstream before flagging it

Skip plugins whose documentation is not discoverable rather than guessing.

### LSP tool (Lua code intelligence)

Use LSP operations (hover, go-to-definition, find-references, document-symbols) to:

- Confirm a grep match is an actual code reference, not a comment or string (Phase 2, 3)
- Verify `p.<key>` references resolve to real fields on the palette table (Phase 3)
- Check that group modules return a function with the expected signature (Phase 3)

### Bash (read-only targets only)

The following are pre-approved and safe to run:

- `stylua --check --config-path .stylua.toml .`
- `selene --config selene.toml lua/ colors/ plugin/`
- `make contrib-verify`

Do NOT run any command that mutates the working tree. `make format`, `make contrib`, and `make all` all rewrite files and are forbidden in this audit.

## Audit Phases

Execute all 8 phases in order. For each finding, record a severity, an ID tag, the `file:line` reference, and a suggested fix.

### Phase 1: Toolchain & Static Analysis

1. Run `stylua --check --config-path .stylua.toml .` and capture the output.
   - Format drift → Warning (list the files).
   - Missing `stylua` binary → Critical.
2. Run `selene --config selene.toml lua/ colors/ plugin/` and capture the output.
   - Lint errors → Critical.
   - Missing `selene` binary → Critical.
3. Run `make contrib-verify`. Any out-of-date contrib file → Warning, naming the specific file and which palette change likely caused the drift. Missing `luajit` → Critical.
4. Grep Lua sources under `lua/`, `colors/`, `plugin/` for deprecated Neovim APIs. Use LSP to confirm each match is a real call (not a comment or string) before reporting:
   - `vim.cmd('hi ` / `vim.cmd("hi ` / `vim.cmd('highlight ` / `vim.cmd("highlight ` (use `vim.api.nvim_set_hl`)
   - `vim.tbl_flatten` (use `vim.iter(t):flatten():totable()`)
   - `vim.tbl_islist` (use `vim.islist`)
   - `vim.loop` (use `vim.uv`)
   - `vim.api.nvim_set_option` / `nvim_buf_set_option` / `nvim_win_set_option` (use `vim.o` / `vim.bo` / `vim.wo`)

### Phase 2: Palette Integrity

1. Parse `lua/token/palette.lua`. Extract the key sets of both the dark and light tables.
   - Asymmetric key sets → Critical (list missing/extra keys on each side).
2. Verify every value in both tables matches `^#[0-9a-fA-F]{6}$`.
   - Malformed hex → Critical.
3. Grep for the pattern `#[0-9a-fA-F]{6}` under `lua/`, `colors/`, `plugin/`. Any hit outside `lua/token/palette.lua` and `lua/token/terminal.lua` → Warning (colors should flow through the palette).
   - Guard: `scripts/` and `contrib/` are allowed to embed hex — they generate external theme files. Do not scan those directories.
4. **Unused palette keys**: for each key in the dark palette, grep `p\.<key>\b` across `lua/token/groups/**/*.lua`, `lua/token/terminal.lua`, and `lua/lualine/themes/token.lua`.
   - Zero references anywhere → Info.
   - Guard: verify with LSP that the grep has searched every file that consumes the palette. Do not flag keys that appear only in indexed form (e.g., `palette[name]`) — check for dynamic access before flagging.

### Phase 3: Group Module Conformance

1. For every `.lua` file in `lua/token/groups/` and `lua/token/groups/plugins/` (excluding the two `init.lua` files): verify it returns a function with signature `(palette) -> table<string, vim.api.keyset.highlight>`.
   - Non-conforming (returns a table directly, returns nothing, wrong arity) → Critical.
2. For every `p.<key>` reference in a group module, verify the key exists in the palette. Use LSP go-to-definition or field-completion to confirm.
   - Unresolved reference → Critical.
3. **Link preference**: within a single group module, if two or more groups share the exact same options table (same keys, same values), suggest linking later ones to the first → Info.
   - Guard: do not flag across modules (cross-module links introduce load-order dependencies). Only flag duplicates in the same file.

### Phase 4: Plugin List Coherence

1. List filenames under `lua/token/groups/plugins/` (excluding `init.lua`). Compare against the hardcoded module list in `lua/token/groups/plugins/init.lua`.
   - File on disk not in list → Critical (module is never loaded; its groups are dead code).
   - Entry in list without a corresponding file → Critical (`require` will fail at startup).
2. Verify the list in `init.lua` is alphabetically sorted.
   - Out of order → Info.

### Phase 5: Plugin API Verification (context7)

For each plugin group module in `lua/token/groups/plugins/`, resolve the upstream library via `resolve-library-id` and pull current highlight-group documentation via `query-docs`. Compare against the groups the module defines.

- Module sets a group that no longer appears in upstream docs (may be stale) → Info.
- Upstream documents a highlight group that the module does not define or link → Info.
- Upstream documents a renamed group (e.g., old name removed, new name added) → Warning.

Batch one resolve + one query per plugin. Skip plugins whose docs are not discoverable — silence beats a guess.

### Phase 6: Load Path & Compile Cache

1. `colors/token.lua`: must be a thin entry that calls `require('token').load()`. Anything else → Warning.
2. `plugin/token.lua`: must register the `:TokenCompile` user command and wire it to `require('token.compile').compile()`. Missing → Warning.
3. `lua/token/init.lua` dynamic-fallback path must:
   (a) call `vim.cmd('hi clear')` (or equivalent),
   (b) bust `token.*` (except `token.compile`) and `lualine.themes.token` from `package.loaded`,
   (c) load the palette for the current `vim.o.background`,
   (d) merge groups via `require('token.groups')(p)`,
   (e) apply via `vim.api.nvim_set_hl`,
   (f) set terminal colors via `require('token.terminal').set(p, is_dark)`.
   - Any missing step → Critical (colorscheme won't reload cleanly after `:TokenCompile`).
4. `lua/token/compile.lua`: `load(bg)` must recover from a missing or corrupt bytecode cache (delete the stale file, fall back to dynamic load). Missing recovery → Warning.

### Phase 7: Terminal & Lualine Coverage

1. `lua/token/terminal.lua`: verify the `colors(p, is_dark)` function returns a table with all 16 indices (0–15) populated for both `is_dark = true` and `is_dark = false`. Any nil slot → Critical.
2. `lua/lualine/themes/token.lua`: verify all 7 lualine modes are present: `normal`, `insert`, `visual`, `replace`, `command`, `terminal`, `inactive`. Each must have `a`, `b`, `c` sections.
   - Missing mode → Warning.
   - Missing section within a mode → Warning.
3. Verify the lualine theme loads colors via `require('token.palette')(vim.o.background)` (not a hardcoded palette copy). Hardcoded hex in the lualine theme → Warning.

### Phase 8: Standard Neovim Group Coverage

Cross-reference defined highlight groups against a curated list of commonly user-visible standard Neovim groups (from `:h highlight-groups` and `:h group-name`). For each standard group that is neither defined nor linked in any module, report as Info.

**Curated list of groups to check** (this is a small, stable set — do not expand it speculatively):

`ColorColumn`, `Conceal`, `CurSearch`, `Cursor`, `CursorColumn`, `CursorLine`, `CursorLineNr`, `Directory`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `EndOfBuffer`, `ErrorMsg`, `FloatBorder`, `FloatTitle`, `FoldColumn`, `Folded`, `IncSearch`, `LineNr`, `MatchParen`, `ModeMsg`, `MoreMsg`, `NonText`, `Normal`, `NormalFloat`, `NormalNC`, `Pmenu`, `PmenuSbar`, `PmenuSel`, `PmenuThumb`, `Question`, `QuickFixLine`, `Search`, `SignColumn`, `SpecialKey`, `SpellBad`, `SpellCap`, `SpellLocal`, `SpellRare`, `StatusLine`, `StatusLineNC`, `Substitute`, `TabLine`, `TabLineFill`, `TabLineSel`, `Title`, `Visual`, `VisualNOS`, `WarningMsg`, `Whitespace`, `WinSeparator`.

Guard: only flag a group if it is absent **and** not targeted via `link = '<Group>'` elsewhere. Apply the zero-false-positive rule harder here than anywhere else — bias toward silence.

## Output Format

Produce a single markdown report with this structure, printed to the conversation (do not write to disk):

```markdown
# Token Colorscheme Audit Report

## Summary

| Severity | Count |
|----------|-------|
| Critical | X     |
| Warning  | X     |
| Info     | X     |

## Critical

### [C-01] Title
- **File**: `path/to/file.lua:42`
- **Issue**: Description of the problem
- **Fix**: Suggested resolution

## Warnings

### [W-01] Title
- **File**: `path/to/file.lua:10`
- **Issue**: Description
- **Fix**: Suggested resolution

## Info

### [I-01] Title
- **File**: `path/to/file.lua:5`
- **Issue**: Description
- **Suggestion**: Optional improvement
```

## Severity Definitions

- **Critical**: broken functionality right now. `make all` or `make contrib-verify` failures. Palette asymmetry. Unresolved `p.<key>` references. Plugin file/list mismatch. Missing load-path step. Gaps in terminal colors 0–15.
- **Warning**: convention violations from CLAUDE.md. Deprecated APIs (still functional but should be updated). Hardcoded hex outside the allowed files. Missing lualine mode or section. Contrib drift. Renamed upstream highlight groups.
- **Info**: consistency improvements, unused palette keys, missing standard Neovim groups, minor stylistic opportunities. Not wrong, just could be better.

## Rules

1. Do NOT modify any files. This is a read-only audit.
2. Do NOT create any files (no reports saved to disk). Print the report to the conversation only.
3. Use context7 MCP (`resolve-library-id` then `query-docs`) to verify plugin highlight groups before flagging drift.
4. Use the LSP tool to verify grep matches are real code, not comments or strings.
5. Be specific: always include `file:line` references.
6. Do not flag intentional design choices:
   - `scripts/` and `contrib/` may contain hex literals (they generate external theme files).
   - Some palette keys exist primarily for terminal colors or lualine and may look unused from a narrow grep.
   - `ibl.lua` and `hlchunk.lua` coexist by design (different indentation plugins supported in parallel).
   - Both `neo_tree.lua` and `nvimtree.lua` coexist by design (two file tree plugins supported in parallel).
7. Group related findings under the same ID if they share a root cause (e.g., ten unused keys from one naming family = one finding).
8. **Zero false positives is more important than coverage.** If a check might flag correct code, skip the finding rather than report it. The user can request deeper investigation.
9. **Do not report the absence of optional features.** Missing support for a plugin not in the current list is not a finding. Missing a niche highlight group outside the Phase 8 curated list is not a finding.
