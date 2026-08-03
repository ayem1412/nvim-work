-- ============================================================================
--  lua/plugins/lang/sql.lua  —  SQL Server / MySQL / PostgreSQL / SQLite
-- ----------------------------------------------------------------------------
--  vim-dadbod is the actual database client. It shells out to the NATIVE CLI
--  for each engine, which is why you must install those separately — see the
--  table below and the README.
--
--    Engine        Connection URL                                   Needs on PATH
--    ------------  -----------------------------------------------  --------------
--    PostgreSQL    postgresql://user:pass@host:5432/dbname          psql
--    MySQL         mysql://user:pass@host:3306/dbname               mysql
--    SQLite        sqlite:C:/path/to/file.db  (or /abs/path.db)     sqlite3
--    SQL Server    sqlserver://user:pass@host:1433?database=dbname  sqlcmd
--
--  Notes on the two awkward ones:
--    * SQL Server: dadbod builds a `sqlcmd` command line. Install "ODBC Driver
--      18 for SQL Server" + "mssql-tools18" (Windows: the MS installers or
--      `winget install Microsoft.SQLServer.2022.CommandLineUtilities`;
--      Linux: the packages.microsoft.com repo, package `mssql-tools18`).
--      If your server uses a self-signed cert (very common on a dev box) add
--      `?trustServerCertificate=true` to the URL or sqlcmd will refuse.
--    * MySQL from WAMP: the client is at C:\wamp64\bin\mysql\mysql8.x.x\bin —
--      add that to PATH so `mysql` resolves.
--
--  SECURITY: do NOT commit real credentials. Put your connection list in
--  lua/config/local.lua (git-ignored) — see the example at the bottom.
-- ============================================================================

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DB" },
    init = function()
      -- ── UI ────────────────────────────────────────────────────────────
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_winwidth = 35
      vim.g.db_ui_win_position = "left"

      -- Where saved queries live. Keeping them under stdpath("data") means
      -- they are per-machine (not synced), which is usually what you want for
      -- scratch queries. Point it at a repo path if you'd rather version them.
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"

      -- Execute the query on save (:w in a query buffer runs it). Very fast
      -- iteration loop; set to 0 if you find it surprising.
      vim.g.db_ui_execute_on_save = 0

      -- Auto-run the query under the cursor with <leader>S (dadbod's default
      -- is <leader>S in the query buffer).
      vim.g.db_ui_disable_mappings = 0

      -- Force UTF-8 output on Windows terminals.
      vim.g.db_ui_force_echo_notifications = 1

      -- Table helpers per dialect: what `Preview` / count / DDL do. dadbod has
      -- sensible defaults; overriding for sqlserver gives a much better
      -- default preview than SELECT *.
      vim.g.db_ui_table_helpers = {
        sqlserver = {
          Count = "SELECT COUNT(*) FROM {optional_schema}{table}",
          Top100 = "SELECT TOP 100 * FROM {optional_schema}{table}",
          Columns = table.concat({
            "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE",
            "FROM INFORMATION_SCHEMA.COLUMNS",
            "WHERE TABLE_NAME = '{table}'",
          }, " "),
        },
        postgresql = {
          Count = "SELECT COUNT(*) FROM {optional_schema}{table}",
          Explain = "EXPLAIN ANALYZE {last_query}",
        },
        mysql = {
          Count = "SELECT COUNT(*) FROM {optional_schema}{table}",
          Explain = "EXPLAIN {last_query}",
        },
      }

      -- ── Connections ───────────────────────────────────────────────────
      -- Defined here ONLY as a documented example. Real connections (with
      -- credentials) belong in lua/config/local.lua, which is git-ignored:
      --
      --   vim.g.dbs = {
      --     { name = "local_mysql",  url = "mysql://root@localhost:3306/myapp" },
      --     { name = "local_pg",     url = "postgresql://postgres:pass@localhost:5432/myapp" },
      --     { name = "local_sqlite", url = "sqlite:C:/wamp64/www/app/storage/db.sqlite" },
      --     { name = "work_mssql",   url = "sqlserver://sa:pass@localhost:1433?database=Prod&trustServerCertificate=true" },
      --   }
      --
      -- dadbod also reads a project-local .env automatically if you set:
      --   let g:db = $DATABASE_URL
      if vim.g.dbs == nil then
        vim.g.dbs = {}
      end
    end,
    config = function()
      -- ── Per-buffer setup for query buffers ───────────────────────────
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        group = vim.api.nvim_create_augroup("my_dadbod_sql", { clear = true }),
        callback = function()
          -- The blink source is wired in plugins/completion.lua via
          -- `per_filetype.sql = { "dadbod", ... }`; nothing to do here.

          -- Tell the formatter/linter which dialect this buffer is.
          -- Override per project in lua/config/local.lua or with a modeline.
          vim.b.sql_dialect = vim.b.sql_dialect or vim.g.sql_dialect or "sql"

          -- <leader>Dr executes the query under the cursor / the selection.
          vim.keymap.set({ "n", "v" }, "<leader>Dr", "<Plug>(DBUI_ExecuteQuery)", {
            buffer = true,
            desc = "DB: execute query",
          })
          vim.keymap.set("n", "<leader>DS", "<Plug>(DBUI_SaveQuery)", {
            buffer = true,
            desc = "DB: save query",
          })
        end,
      })

      -- Make the results buffer readable and closable with `q`
      -- (the `dbout` filetype is already in the close_with_q list in
      -- config/autocmds.lua).
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        group = vim.api.nvim_create_augroup("my_dadbod_out", { clear = true }),
        callback = function()
          vim.opt_local.foldenable = false
          vim.opt_local.wrap = false
          vim.opt_local.number = false
        end,
      })
    end,
    keys = {
      { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "DB: toggle UI" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "DB: find buffer" },
      { "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "DB: add connection" },
      { "<leader>Dl", "<cmd>DBUILastQueryInfo<cr>", desc = "DB: last query info" },
      -- A scratch SQL buffer to poke at a database without saving a file.
      {
        "<leader>Ds",
        function()
          Snacks.scratch({ ft = "sql", name = "SQL scratch" })
        end,
        desc = "DB: SQL scratch buffer",
      },
    },
  },
}
