-- ============================================================================
--  after/lsp/sqlls.lua
-- ----------------------------------------------------------------------------
--  A caveat worth knowing: sqlls (and its cousin `sqls`) are lightly
--  maintained and, without a live connection, give you keyword completion and
--  basic syntax checking only.
--
--  The REAL SQL workflow in this config is vim-dadbod + vim-dadbod-completion
--  (lua/plugins/lang/sql.lua), which completes actual table and column names
--  from a connected database. This server is a lightweight complement, not the
--  main event.
--
--  If you want sqlls to know your schema, it reads a `config.json` from the
--  project root (or ~/.config/sqlls/config.json) with connection details.
-- ============================================================================

return {
  -- Only start in real SQL files, not in dadbod's output buffers.
  filetypes = { "sql", "mysql", "plsql" },
  root_markers = { ".sqllsrc.json", ".git" },
  settings = {
    sqlLanguageServer = {
      connections = {
        -- Example (do not put credentials here — use lua/config/local.lua):
        -- {
        --   name = "local_pg",
        --   adapter = "postgres",
        --   host = "localhost", port = 5432,
        --   user = "postgres", database = "myapp",
        --   projectPaths = { "/home/you/projects/myapp" },
        -- },
      },
      lint = {
        rules = {
          ["align-column-to-the-first"] = "off",
          ["column-new-line"] = "off",
          ["linebreak-after-clause-keyword"] = "off",
          ["reserved-word-case"] = { "error", "upper" },
          ["space-surrounding-operators"] = "error",
          ["where-clause-new-line"] = "off",
        },
      },
    },
  },
}
