-- ============================================================================
--  init.lua  —  Neovim entry point
-- ----------------------------------------------------------------------------
--  Load order matters. Nothing here is accidental:
--
--   1. vim.loader.enable()  -> turn on the byte-compiled Lua module cache FIRST,
--                              so every `require` below is already cached.
--   2. leader keys          -> MUST be set before lazy.nvim loads plugins,
--                              because plugin `keys = {...}` specs are resolved
--                              at load time and bake in whatever <leader> is.
--   3. config.options       -> pure vim options, no plugin dependency.
--   4. lazy.nvim bootstrap  -> clone the plugin manager if missing.
--   5. lazy.setup           -> imports every file under lua/plugins/.
--   6. keymaps / autocmds   -> after plugins so they can reference them.
--   7. config.local         -> OPTIONAL, git-ignored, per-machine overrides.
--
--  This config targets Neovim >= 0.11 (0.12+ recommended) and works unchanged
--  on Windows and Linux. See README.md for the prerequisites per OS.
-- ============================================================================

-- 1. -------------------------------------------------------------------------
-- vim.loader is Neovim's built-in Lua module cache. It byte-compiles every
-- Lua file once and reuses the compiled chunk on subsequent starts. On a big
-- config this alone is typically 10-30ms of startup. It must be enabled before
-- we require anything of our own, otherwise those first requires miss the cache.
vim.loader.enable()

-- 2. -------------------------------------------------------------------------
-- <leader> is the prefix for almost every custom mapping. Space is the usual
-- choice because it is huge, reachable with either thumb, and does nothing
-- useful in normal mode by default.
vim.g.mapleader = " "
-- <localleader> is for filetype-specific mappings (e.g. Rust/Java/SQL runners).
-- Backslash keeps it out of the way of the global leader.
vim.g.maplocalleader = "\\"

-- Disable providers we do not use. Without this, Neovim probes for perl/ruby/
-- python/node executables on every startup and `:checkhealth` fills with noise.
-- If you ever want a python-based plugin, flip loaded_python3_provider back.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
-- Node provider is only needed by legacy remote plugins; LSP servers written in
-- node (vtsls, intelephense, ...) do NOT need it.
vim.g.loaded_node_provider = 0

-- 3. -------------------------------------------------------------------------
-- Options first: some plugins read options at load time (e.g. `termguicolors`
-- for colorschemes, `shell` for terminal/lazygit integrations).
require("config.options")

-- 4. -------------------------------------------------------------------------
-- lazy.nvim bootstrap. stdpath("data") resolves to:
--   Linux   : ~/.local/share/nvim
--   Windows : %LOCALAPPDATA%\nvim-data
-- Never hardcode either path — stdpath is the whole cross-platform story.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none", -- shallow-ish clone: skip file blobs we don't need
    "--branch=stable", -- track the stable tag, not bleeding-edge main
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nIs `git` on your PATH?", "WarningMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
-- Prepend so lazy.nvim itself is requireable before it manages anything.
vim.opt.rtp:prepend(lazypath)

-- 5. -------------------------------------------------------------------------
require("lazy").setup({
  -- `import` walks lua/plugins/ and lua/plugins/lang/ and merges every returned
  -- spec table. This is what makes the config modular: adding a language is
  -- "drop a new file in lua/plugins/lang/", nothing else.
  spec = {
    { import = "plugins" },
    { import = "plugins.lang" },
  },
  defaults = {
    -- Plugins are NOT lazy by default. Being explicit per-plugin (event/ft/cmd/
    -- keys) is safer than a blanket `lazy = true`, which silently breaks plugins
    -- that must run at startup (colorscheme, treesitter, snacks).
    lazy = false,
    -- Do not blindly take the latest git commit of every plugin. `version=false`
    -- means "use the default branch HEAD"; combined with lazy-lock.json (which
    -- you SHOULD commit to git) both machines stay byte-identical.
    version = false,
  },
  install = {
    -- Colorscheme used while plugins are still installing on first launch.
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = {
    enabled = true, -- background check for plugin updates
    notify = false, -- ...but don't nag on every start
    frequency = 86400, -- once a day
  },
  change_detection = {
    enabled = true,
    notify = false, -- don't toast every time you save a plugin file
  },
  performance = {
    rtp = {
      -- Built-in Vim plugins we never use. Each one costs a bit of startup and
      -- some (netrw) actively conflict with modern replacements (oil/snacks).
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
        "rplugin",
        "matchit", -- replaced by treesitter/vim-matchup style plugins
      },
    },
  },
  ui = { border = "rounded" },
})

-- 6. -------------------------------------------------------------------------
require("config.keymaps")
require("config.autocmds")

-- 7. -------------------------------------------------------------------------
-- Per-machine escape hatch. Create lua/config/local.lua on ONE machine (and add
-- it to .gitignore) for things that genuinely differ: a work proxy, a JDK path,
-- a database connection list with credentials, a different font size in a GUI.
-- pcall means "if the file doesn't exist, silently carry on".
pcall(require, "config.local")
