-- ============================================================================
--  lua/config/platform.lua  —  the single source of truth for "which OS am I?"
-- ----------------------------------------------------------------------------
--  Every OS-specific branch in this config goes through this module. That means
--  when something breaks on Windows there is exactly ONE file to look at, and
--  no `if vim.fn.has("win32")` scattered across twenty plugin specs.
--
--  Why vim.fn.has("win32") and not vim.uv.os_uname()?
--    - has("win32") returns 1 on BOTH 32-bit and 64-bit Windows (the name is
--      historical). It is the canonical Vim/Neovim check.
--    - os_uname().sysname returns "Windows_NT" / "Linux" / "Darwin". Useful for
--      logging, but it returns "Linux" under WSL too, which is usually NOT what
--      you want (WSL needs its own clipboard handling).
--    - has("wsl") exists specifically to disambiguate WSL from native Linux.
-- ============================================================================

local M = {}

-- Raw OS flags ---------------------------------------------------------------
M.is_win = vim.fn.has("win32") == 1
M.is_wsl = vim.fn.has("wsl") == 1
M.is_mac = vim.fn.has("mac") == 1
-- "Real" Linux = not Windows, not macOS. WSL is still Linux for most purposes,
-- so it is intentionally included here; only clipboard code checks is_wsl.
M.is_linux = not M.is_win and not M.is_mac

-- Human-readable name, handy in the statusline or for debugging.
M.name = M.is_win and "windows" or (M.is_mac and "macos" or (M.is_wsl and "wsl" or "linux"))

-- Path helpers ---------------------------------------------------------------
-- Mason installs every LSP server / formatter / linter / debug adapter under
-- stdpath("data")/mason. We need those paths a lot (jdtls jars, the Vue TS
-- plugin, the PHP debug adapter), so centralise them here.
M.mason_root = vim.fn.stdpath("data") .. "/mason"

--- Absolute path to a Mason *package* directory.
--- @param name string e.g. "jdtls", "vue-language-server"
--- @return string
function M.mason_pkg(name)
  return M.mason_root .. "/packages/" .. name
end

--- Absolute path to a Mason *executable shim*.
--- On Windows Mason writes `.cmd` wrappers instead of shell scripts, so the
--- bare name is not executable. This handles that difference.
--- @param name string e.g. "php-cs-fixer"
--- @return string
function M.mason_bin(name)
  return M.mason_root .. "/bin/" .. (M.is_win and (name .. ".cmd") or name)
end

--- Does a path exist? Thin wrapper so callers don't juggle vim.uv vs vim.loop.
--- (vim.loop was renamed vim.uv in 0.10; the alias still works but vim.uv is
--- the forward-compatible spelling.)
--- @param path string
--- @return boolean
function M.exists(path)
  return (vim.uv or vim.loop).fs_stat(path) ~= nil
end

--- Expand a glob and return the FIRST match, or nil.
--- Used for versioned jars whose exact filename changes on every update, e.g.
--- org.eclipse.equinox.launcher_1.6.900.v20240613-2009.jar
--- @param pattern string
--- @return string|nil
function M.first_glob(pattern)
  local matches = vim.split(vim.fn.glob(pattern), "\n", { trimempty = true })
  return matches[1]
end

--- Expand a glob and return ALL matches as a list (never nil).
--- Used for DAP "bundles" (java-debug + vscode-java-test ship many jars).
--- @param pattern string
--- @return string[]
function M.all_globs(pattern)
  return vim.split(vim.fn.glob(pattern), "\n", { trimempty = true })
end

--- Is an executable on PATH? Lets us degrade gracefully instead of erroring
--- when e.g. `sqlcmd` or `lazygit` isn't installed on this particular machine.
--- @param bin string
--- @return boolean
function M.has_exe(bin)
  return vim.fn.executable(bin) == 1
end

return M
