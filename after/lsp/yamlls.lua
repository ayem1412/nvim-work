-- ============================================================================
--  after/lsp/yamlls.lua
-- ----------------------------------------------------------------------------
--  Schema-aware YAML: GitHub Actions workflows, docker-compose, Kubernetes,
--  and — relevant to you — Spring Boot's application.yml.
--
--  NOTE: for application.yml, the SPRING BOOT language server (spring-boot.nvim)
--  provides much better property completion than a generic schema. Both can
--  attach; yamlls handles structure, the Boot server handles property names
--  and values.
-- ============================================================================

return {
  settings = {
    yaml = {
      validate = true,
      keyOrdering = false, -- don't demand alphabetical keys
      format = { enable = false },
      -- Let SchemaStore supply schemas by filename pattern.
      schemaStore = {
        -- Disabled here because SchemaStore.nvim (below) provides a better,
        -- offline copy of the same catalogue.
        enable = false,
        url = "",
      },
      schemas = {}, -- filled in by before_init
    },
    redhat = { telemetry = { enabled = false } },
  },
  before_init = function(_, config)
    local ok, schemastore = pcall(require, "schemastore")
    config.settings.yaml.schemas = ok and schemastore.yaml.schemas() or {}
  end,
}
