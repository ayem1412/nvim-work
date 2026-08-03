-- ============================================================================
--  lua/config/icons.lua  —  every glyph in the config, in one place
-- ----------------------------------------------------------------------------
--  WHY THIS FILE EXISTS
--  Nerd Font icons live in the Unicode Private Use Area (U+E000–U+F8FF and
--  U+F0000+). Those codepoints survive a working terminal fine, but they do NOT
--  reliably survive being copied through a browser, a chat window, an email, or
--  a text editor with the wrong encoding — they silently become empty strings.
--
--  That failure is nasty because it is not cosmetic everywhere:
--    * 'fillchars' fields must be EXACTLY one character. An empty string is a
--      hard error (E1511) and Neovim refuses to start.
--    * sign_define() with empty `text` errors too.
--
--  So instead of embedding the glyph, we build it from its codepoint with
--  vim.fn.nr2char(). A number cannot be mangled. If you ever need to see what
--  a codepoint looks like: `:lua print(vim.fn.nr2char(0xf057))`
--
--  NOTE for the curious: Lua 5.3's "\u{f057}" escape would be tidier, but
--  Neovim runs LuaJIT (Lua 5.1 syntax), which does not support it. nr2char is
--  the portable way.
--
--  TO USE A DIFFERENT ICON: look it up at https://www.nerdfonts.com/cheat-sheet
--  and paste the hex codepoint here — not the glyph.
--
--  NO NERD FONT? Set `vim.g.no_nerd_font = true` in lua/config/local.lua and
--  everything below falls back to plain Unicode that renders in any font.
-- ============================================================================

local nr = vim.fn.nr2char
local plain = vim.g.no_nerd_font == true

--- Return the Nerd Font glyph for `codepoint`, or `fallback` in plain mode.
--- @param codepoint integer
--- @param fallback string  must be exactly 1 char where fillchars/signs are used
local function g(codepoint, fallback)
  if plain then
    return fallback
  end
  return nr(codepoint)
end

local M = {}

-- ── Diagnostics ─────────────────────────────────────────────────────────────
M.diagnostics = {
  Error = g(0xf057, "E"), -- times-circle
  Warn = g(0xf071, "W"), -- exclamation-triangle
  Info = g(0xf05a, "I"), -- info-circle
  Hint = g(0xf0eb, "H"), -- lightbulb
}

-- ── Git ─────────────────────────────────────────────────────────────────────
-- The bar glyphs are ordinary Unicode block elements, not Nerd Font, so they
-- are safe to write literally.
M.git = {
  add = "▎",
  change = "▎",
  delete = "契", -- overwritten just below; see note
  topdelete = "‾",
  changedelete = "▎",
  untracked = "▎",
  -- Statusline counts
  added = g(0xf457, "+"),
  modified = g(0xf459, "~"),
  removed = g(0xf458, "-"),
  branch = g(0xf418, "*"),
}
-- gitsigns' delete markers must be single-width; use plain Unicode triangles so
-- they render identically with or without a Nerd Font.
M.git.delete = "▁"
M.git.topdelete = "▔"

-- ── Folds (fillchars — MUST be exactly one character each) ──────────────────
-- Deliberately plain Unicode, never Nerd Font: an empty or double-width value
-- here is a startup error, so this is the one place worth being boring.
M.fold = {
  open = "▾",
  closed = "▸",
  sep = " ",
  fold = " ",
}

-- ── Files / buffers ─────────────────────────────────────────────────────────
M.file = {
  modified = "●",
  readonly = g(0xf023, "-"), -- lock
}

-- ── DAP ─────────────────────────────────────────────────────────────────────
M.dap = {
  breakpoint = g(0xf111, "●"), -- circle
  condition = g(0xf12a, "◆"), -- exclamation
  logpoint = g(0xf29c, "◆"), -- question-circle
  stopped = g(0xf0da, "▶"), -- caret-right
  rejected = g(0xf05e, "○"), -- ban
}

-- ── Misc UI ─────────────────────────────────────────────────────────────────
M.ui = {
  lsp = g(0xf085, "@"), -- cogs
  format = g(0xf031, "F"), -- font
  debug = g(0xf188, "D"), -- bug
  search = g(0xf002, "?"), -- search
  file = g(0xf15b, "*"), -- file
  files = g(0xf07c, "*"), -- folder-open
  new = g(0xf15c, "+"), -- file-text
  clock = g(0xf017, "*"), -- clock
  gear = g(0xf013, "*"), -- cog
  restore = g(0xf1da, "*"), -- history
  lazy = g(0xf0e7, "*"), -- bolt
  exit = g(0xf08b, "x"), -- sign-out
  os = plain and "" or (vim.fn.has("win32") == 1 and g(0xf17a, "") or g(0xf17c, "")),
}

-- ── Mason ───────────────────────────────────────────────────────────────────
-- Plain Unicode; these already render everywhere.
M.mason = {
  installed = "✓",
  pending = "➜",
  uninstalled = "✗",
}

return M
