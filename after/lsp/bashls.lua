-- ============================================================================
--  after/lsp/bashls.lua
-- ----------------------------------------------------------------------------
--  Also attaches to .env files (registered as `sh` in config/options.lua),
--  which gives you basic syntax checking on environment configuration.
-- ============================================================================

return {
  filetypes = { "sh", "bash", "zsh" },
  settings = {
    bashIde = {
      -- shellcheck integration. Install shellcheck for this to do anything.
      shellcheckPath = "shellcheck",
      -- Don't recursively parse the whole home directory when you open a
      -- script outside a project.
      globPattern = "*@(.sh|.inc|.bash|.command)",
    },
  },
}
