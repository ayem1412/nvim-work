-- ============================================================================
--  lua/config/options.lua  —  editor behaviour, no plugins involved
-- ----------------------------------------------------------------------------
--  `vim.opt` vs `vim.o` vs `vim.g`:
--    vim.opt.x  -> option object; supports list/map options (opt.rtp:prepend,
--                  opt.listchars = {tab="..."}). Use for anything list-like.
--    vim.o.x    -> plain scalar set. Slightly faster, fine for booleans/numbers.
--    vim.g.x    -> global variables (plugin settings), not options.
--  They are interchangeable for scalars; this file uses vim.opt for consistency.
-- ============================================================================

local plat = require("config.platform")
local icons = require("config.icons")
local opt = vim.opt

opt.guicursor = "n-v-c-i:block"

-- ── Encoding ────────────────────────────────────────────────────────────────
-- UTF-8 everywhere. On Windows the default is still the ANSI codepage in some
-- builds, which mangles nerd-font icons and non-ASCII source files.
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- ── Line numbers ────────────────────────────────────────────────────────────
opt.number = true -- absolute number on the cursor line
opt.relativenumber = true -- relative elsewhere -> `12j`, `d5k` become trivial
opt.signcolumn = "yes:1" -- ALWAYS reserve 1 sign column. Without this the text
-- shifts left/right every time a git sign or diagnostic
-- appears, which is visually exhausting.
opt.cursorline = true -- highlight the current line
opt.colorcolumn = "100" -- visual guide; adjust per team style guide

-- ── Indentation ─────────────────────────────────────────────────────────────
-- These are the GLOBAL defaults. Per-language overrides live in ftplugin/ and
-- are also applied by treesitter/editorconfig where a project defines them.
opt.expandtab = true -- spaces, not tabs (Go overrides this in ftplugin/go.lua)
opt.shiftwidth = 4 -- Java/PHP/Rust house style; ftplugin drops web files to 2
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.autoindent = true
opt.breakindent = true -- wrapped lines keep their indent
opt.wrap = false -- long lines scroll horizontally instead of wrapping

-- ── Search ──────────────────────────────────────────────────────────────────
opt.ignorecase = true -- `/foo` matches Foo...
opt.smartcase = true -- ...but `/Foo` only matches Foo (any capital = exact)
opt.hlsearch = true -- highlight matches (cleared by <Esc>, see keymaps.lua)
opt.incsearch = true -- show matches as you type
opt.inccommand = "split" -- live preview of :s/// in a split. Genuinely great.

-- ── Splits ──────────────────────────────────────────────────────────────────
opt.splitright = true -- vertical splits open to the RIGHT (natural reading)
opt.splitbelow = true -- horizontal splits open BELOW
opt.splitkeep = "screen" -- don't scroll the existing window when a split opens

-- ── Scrolling ───────────────────────────────────────────────────────────────
opt.scrolloff = 8 -- keep 8 lines of context above/below the cursor
opt.sidescrolloff = 8

-- ── Files & undo ────────────────────────────────────────────────────────────
opt.swapfile = false -- swap files cause more "recovery?" prompts than they save
opt.backup = false
opt.writebackup = false -- IMPORTANT: some tools (older webpack/php watchers)
-- break if Neovim renames the file on write
opt.undofile = true -- PERSISTENT undo across sessions. This is the killer one:
-- reopen a file tomorrow and `u` still works.
opt.undolevels = 10000
-- Undo files land in stdpath("state")/undo on both OSes. No manual path needed.

-- ── Timing ──────────────────────────────────────────────────────────────────
opt.updatetime = 200 -- ms of idle before CursorHold fires (gitsigns blame,
-- LSP document highlight). Also flushes the swap file.
opt.timeoutlen = 400 -- ms to wait for a mapping sequence. 400 is a good balance:
-- which-key pops up quickly without punishing fast typing.
opt.ttimeoutlen = 10 -- terminal escape sequence timeout; keep tiny so <Esc> is
-- instant in terminal Neovim.

-- ── Completion ──────────────────────────────────────────────────────────────
-- menuone : show the menu even with a single match (so you can see the docs)
-- noselect: don't auto-insert the first match; you choose explicitly
-- popup   : render extra info in a popup window (Neovim 0.11+)
opt.completeopt = { "menuone", "noselect", "popup" }
opt.pumheight = 12 -- max visible completion items; stops the menu eating the screen
opt.pumblend = 10 -- slight transparency on the popup menu

-- ── UI ──────────────────────────────────────────────────────────────────────
opt.termguicolors = true -- 24-bit colour. Required by every modern colourscheme.
-- On Windows use Windows Terminal / WezTerm / Alacritty;
-- the legacy conhost console does not support this.
opt.showmode = false -- the statusline already shows the mode
opt.laststatus = 3 -- ONE global statusline instead of one per split. Much
-- cleaner with many splits.
opt.cmdheight = 1
opt.conceallevel = 0 -- don't hide markdown/JSON syntax characters by default
opt.list = true -- render whitespace characters listed below
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = {
  eob = " ", -- no "~" on empty lines below the buffer
  fold = icons.fold.fold,
  foldopen = icons.fold.open,
  foldclose = icons.fold.closed,
  foldsep = icons.fold.sep,
  diff = "╱",
}
opt.mouse = "a" -- mouse in all modes (useful for resizing splits fast)
opt.confirm = true -- :q on a modified buffer asks instead of failing
opt.winminwidth = 5 -- don't let a split collapse to nothing

-- ── Folding (treesitter-powered) ────────────────────────────────────────────
-- Neovim 0.10+ ships vim.treesitter.foldexpr(). It gives structural folds for
-- every language that has a parser, replacing the old indent/syntax heuristics.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = "" -- 0.10+: use the real (highlighted) first line as fold text
opt.foldlevel = 99 -- start with everything OPEN. Folds are opt-in via `zc`.
opt.foldlevelstart = 99

-- ── Clipboard ───────────────────────────────────────────────────────────────
-- Deliberately NOT set to "unnamedplus" globally here — see the WSL block below
-- and the yank keymaps. Sharing the system clipboard with every delete/change
-- means `diw` clobbers what you copied. This config keeps them separate and
-- gives you explicit <leader>y / <leader>p mappings instead.
-- If you prefer the everything-shared behaviour, uncomment:
-- opt.clipboard = "unnamedplus"

-- ── Misc ────────────────────────────────────────────────────────────────────
opt.virtualedit = "block" -- let visual-block selections go past end of line
opt.wildmode = "longest:full,full" -- cmdline completion: complete longest, then menu
opt.jumpoptions = "view" -- restore the view when jumping back (0.11+)
opt.grepprg = "rg --vimgrep" -- :grep uses ripgrep
opt.grepformat = "%f:%l:%c:%m"
opt.shortmess:append({ W = true, I = true, c = true, C = true }) -- quieter messages
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Diagnostics are configured in plugins/lsp.lua (they need the LSP loaded).

-- ============================================================================
--  WINDOWS-SPECIFIC CONFIGURATION
-- ----------------------------------------------------------------------------
--  Everything below is the difference between "Neovim works on Windows" and
--  "Neovim is painful on Windows".
-- ============================================================================
if plat.is_win then
  -- ── Shell ────────────────────────────────────────────────────────────────
  -- cmd.exe quoting rules are hostile to every plugin that shells out (lazygit,
  -- conform, gitsigns, :terminal). PowerShell handles arguments sanely.
  -- Prefer `pwsh` (PowerShell 7, cross-platform, much faster to start) and fall
  -- back to the built-in Windows PowerShell 5 if pwsh isn't installed.
  local pwsh = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
  vim.o.shell = pwsh
  -- -NoLogo/-NoProfile: skip the banner and the user's profile script (startup
  --   speed; a slow $PROFILE makes every :! call slow).
  -- -ExecutionPolicy RemoteSigned: allow local scripts.
  -- The InputEncoding/OutputEncoding assignment forces UTF-8 so command output
  --   with non-ASCII characters isn't mangled.
  vim.o.shellcmdflag = table.concat({
    "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command",
    "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
    "$PSDefaultParameterValues['Out-File:Encoding']='utf8';",
  }, " ")
  -- How Neovim redirects command output to a temp file. The `%%{ "$_" }` dance
  -- converts PowerShell objects to plain strings so we get text, not tables.
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  -- Empty quote settings: PowerShell does its own quoting; letting Vim add
  -- another layer double-escapes arguments and breaks paths with spaces.
  vim.o.shellquote = ""
  vim.o.shellxquote = ""

  -- ── shellslash ───────────────────────────────────────────────────────────
  -- INTENTIONALLY LEFT OFF. Setting shellslash makes Vim use forward slashes in
  -- filenames, which looks nicer, but it breaks a number of plugins that build
  -- Windows command lines (and some LSP servers that compare URIs literally).
  -- If you hit path weirdness, this is the first switch to try — not the default.
  -- vim.opt.shellslash = true

  -- ── Clipboard ────────────────────────────────────────────────────────────
  -- Native Windows Neovim talks to the Windows clipboard directly; nothing to do.
end

-- ── WSL clipboard ───────────────────────────────────────────────────────────
-- Under WSL, Neovim is a Linux binary with no X server, so it cannot reach the
-- Windows clipboard on its own. win32yank.exe bridges the two.
--   * `-i --crlf` converts LF -> CRLF on copy so Windows apps see proper lines.
--   * `-o --lf`  converts CRLF -> LF on paste so you don't get ^M everywhere.
--   * cache_enabled = 0 avoids the classic "paste returns stale text" bug.
if plat.is_wsl and plat.has_exe("win32yank.exe") then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end

-- ── Native Linux clipboard ──────────────────────────────────────────────────
-- Neovim auto-detects wl-copy/xclip/xsel. We only warn (once, lazily) if none
-- of them exist, because the failure mode otherwise is a silent no-op yank.
if plat.is_linux and not plat.is_wsl then
  local has_clip = plat.has_exe("wl-copy") or plat.has_exe("xclip") or plat.has_exe("xsel")
  if not has_clip then
    vim.schedule(function()
      vim.notify(
        "No clipboard provider found.\nWayland: install wl-clipboard\nX11: install xclip or xsel",
        vim.log.levels.WARN
      )
    end)
  end
end

-- ── Filetype registrations ──────────────────────────────────────────────────
-- vim.filetype.add is the modern, Lua-native replacement for filetype.vim.
-- It runs before any plugin and is significantly faster than autocmd patterns.
vim.filetype.add({
  extension = {
    -- Twig templates. Without this they'd be detected as plain `html` (or
    -- nothing), and the treesitter twig parser / twig LSP would never attach.
    twig = "twig",
    -- Phalcon Volt templates use the same syntax family as Twig.
    volt = "twig",
    -- Common config files that Neovim doesn't know by default.
    conf = "conf",
    mdx = "markdown.mdx",
    http = "http",
  },
  filename = {
    [".env"] = "sh",
    ["Dockerfile"] = "dockerfile",
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    -- WAMP / Apache configs
    ["httpd.conf"] = "apache",
    ["my.ini"] = "dosini",
    ["php.ini"] = "dosini",
  },
  pattern = {
    -- .env.local, .env.production, ...
    ["%.env%.[%w_.-]+"] = "sh",
    -- Spring Boot application-*.yml / .properties
    ["application.*%.ya?ml"] = "yaml",
    ["application.*%.properties"] = "jproperties",
    -- Blade (in case you touch Laravel too)
    [".*%.blade%.php"] = "blade",
  },
})
