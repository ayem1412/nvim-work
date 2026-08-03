-- ============================================================================
--  after/lsp/jsonls.lua
-- ----------------------------------------------------------------------------
--  Schema-aware JSON: completion and validation for package.json, tsconfig,
--  composer.json, .eslintrc, launch.json and hundreds more, courtesy of the
--  SchemaStore catalogue.
-- ============================================================================

return {
  settings = {
    json = {
      validate = { enable = true },
      format = { enable = false }, -- prettier handles it
    },
  },
  -- The schemas list is populated lazily, because SchemaStore.nvim may not be
  -- loaded yet when this file is read.
  before_init = function(_, config)
    local ok, schemastore = pcall(require, "schemastore")
    config.settings = config.settings or {}
    config.settings.json = config.settings.json or {}
    config.settings.json.schemas = ok and schemastore.json.schemas() or {}
  end,
}
