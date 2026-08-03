-- ============================================================================
--  lua/config/local.example.lua
-- ----------------------------------------------------------------------------
--  COPY THIS to lua/config/local.lua on each machine and edit it.
--  local.lua is in .gitignore, so it never leaves the machine — which is what
--  makes it the right home for credentials and machine-specific paths.
--
--  init.lua loads it with `pcall(require, "config.local")` at the very end, so
--  anything here overrides everything above it.
-- ============================================================================

-- ── Database connections (vim-dadbod) ───────────────────────────────────────
-- These appear in the DBUI drawer (<leader>Du). Credentials stay local.
vim.g.dbs = {
  { name = "wamp_mysql", url = "mysql://root@localhost:3306/myapp" },
  { name = "local_pg", url = "postgresql://postgres:postgres@localhost:5432/myapp" },
  { name = "app_sqlite", url = "sqlite:C:/wamp64/www/myapp/storage/app.db" },
  {
    name = "work_mssql",
    -- trustServerCertificate is usually required against a dev SQL Server
    -- instance with a self-signed certificate.
    url = "sqlserver://sa:YourPassword@localhost:1433?database=AppDb&trustServerCertificate=true",
  },
}

-- Default SQL dialect for the formatter and linter on this machine.
vim.g.sql_dialect = "mysql"

-- ── Java runtimes ───────────────────────────────────────────────────────────
-- Read by ftplugin/java.lua. Lets jdtls compile against a different JDK than
-- the one it runs on (e.g. server on 21, project targets 17).
vim.g.java_runtimes = {
  -- Windows example:
  -- { name = "JavaSE-17", path = "C:/Program Files/Eclipse Adoptium/jdk-17.0.11-hotspot" },
  -- { name = "JavaSE-21", path = "C:/Program Files/Eclipse Adoptium/jdk-21.0.3-hotspot", default = true },
  -- Linux example:
  -- { name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk" },
  -- { name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk", default = true },
}

-- ── Extra PHP include paths ─────────────────────────────────────────────────
-- Read by after/lsp/intelephense.lua. Use for stubs or shared libraries that
-- live outside the project and outside global Composer.
vim.g.php_include_paths = {
  -- "D:/shared/php-stubs",
}

-- ── Machine-specific tweaks ─────────────────────────────────────────────────
-- Example: a bigger font in a GUI client, a corporate proxy for Mason, or
-- disabling a plugin that misbehaves on this machine only.
--
-- if vim.g.neovide then
--   vim.o.guifont = "JetBrainsMono Nerd Font:h11"
--   vim.g.neovide_cursor_animation_length = 0
-- end
--
-- vim.env.HTTPS_PROXY = "http://proxy.corp.local:8080"
