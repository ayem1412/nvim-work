-- ============================================================================
--  after/lsp/taplo.lua  —  TOML
-- ----------------------------------------------------------------------------
--  Mainly for Cargo.toml, rustfmt.toml, and pyproject-style configs. Provides
--  schema validation for Cargo manifests, so a typo'd key is flagged
--  immediately rather than at build time.
-- ============================================================================

return {
  settings = {
    evenBetterToml = {
      schema = {
        enabled = true,
        catalogs = { "https://www.schemastore.org/api/json/catalog.json" },
      },
      formatter = { alignEntries = false },
    },
  },
}
