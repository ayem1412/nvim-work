-- ============================================================================
--  ftplugin/sql.lua
-- ----------------------------------------------------------------------------
--  Sets the dialect used by BOTH the formatter (sql-formatter) and the linter
--  (sqlfluff). Override per project in lua/config/local.lua:
--      vim.g.sql_dialect = "tsql"
--  or per buffer with a one-off:
--      :lua vim.b.sql_dialect = "postgresql"
--
--  Valid values (sql-formatter): sql | mysql | mariadb | postgresql | tsql |
--                                sqlite | bigquery | db2 | plsql | redshift
--  Valid values (sqlfluff):      ansi | mysql | postgres | tsql | sqlite | ...
--  They differ slightly; the formatter config in plugins/format.lua maps the
--  common ones. When in doubt set both explicitly.
-- ============================================================================

vim.b.sql_dialect = vim.b.sql_dialect or vim.g.sql_dialect or "sql"

-- SQL keywords are conventionally uppercase; make `~` and `guu`/`gUU` easy to
-- reach isn't needed, but word boundaries matter: treat `_` as part of a word
-- so `w` skips over snake_case column names in one jump.
vim.opt_local.iskeyword:append("_")

-- Don't auto-wrap long SELECT lists.
vim.opt_local.textwidth = 0
vim.opt_local.wrap = false
