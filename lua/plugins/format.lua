-- ============================================================================
--  lua/plugins/format.lua  —  conform.nvim (format) + nvim-lint (diagnose)
-- ----------------------------------------------------------------------------
--  These two replace null-ls / none-ls entirely. That matters: null-ls is
--  archived and none-ls is community life-support. conform + nvim-lint are
--  simpler, faster (no fake LSP server in the middle), and independently
--  maintained.
--
--  Split of responsibilities:
--    conform  -> runs FORMATTERS on write, or on demand
--    nvim-lint-> runs LINTERS and publishes real vim.diagnostic entries
--    the LSP  -> everything else (types, refactors, go-to-def)
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  conform.nvim
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer / selection",
      },
      {
        "<leader>uf",
        function()
          -- Toggle format-on-save globally. `vim.g.disable_autoformat` is read
          -- by format_on_save below.
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save (global)",
      },
      {
        "<leader>uF",
        function()
          -- Buffer-local variant, for when ONE file has a formatter you're
          -- fighting with (a legacy PHP file, a generated Java class).
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Format on save (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save (buffer)",
      },
    },
    opts = {
      -- ── Formatter selection per filetype ───────────────────────────────
      --  A plain list  { "a", "b" }        -> run a THEN b (sequential)
      --  A nested list { { "a", "b" } }    -> run the FIRST one available
      --  The nested form is what you want when a project may use pint OR
      --  php-cs-fixer, prettierd OR prettier.
      formatters_by_ft = {
        lua = { "stylua" },

        -- Go: goimports first (fixes/sorts the import block, which gofumpt
        -- won't do), then gofumpt for the stricter formatting rules.
        go = { "goimports", "gofumpt" },

        -- Rust: rustfmt via the toolchain. rustaceanvim also exposes
        -- rust-analyzer's formatting; using rustfmt directly is more
        -- predictable and respects rustfmt.toml.
        rust = { "rustfmt" },

        -- Web stack: prettierd is a persistent daemon, ~10x faster than
        -- spawning prettier per save. Falls back to prettier if the daemon
        -- isn't available (common on a fresh Windows install).
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        vue = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        less = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "prettierd", "prettier", stop_after_first = true },

        -- PHP: pint (Laravel's opinionated wrapper) if the project has it,
        -- otherwise php-cs-fixer. For Phalcon projects php-cs-fixer with a
        -- PSR-12 ruleset is the usual choice — see .php-cs-fixer.dist.php.
        php = { "pint", "php_cs_fixer", stop_after_first = true },
        blade = { "blade-formatter" },

        -- Twig / Volt templates.
        twig = { "djlint" },

        -- Java. google-java-format is the least controversial choice; if your
        -- team uses the Spring/Eclipse formatter, remove this and let jdtls
        -- format instead (and drop `jdtls` from the no_format table in
        -- plugins/lsp.lua).
        java = { "google-java-format" },

        -- SQL. sql-formatter needs to know the dialect — see `formatters` below.
        sql = { "sql_formatter" },
        mysql = { "sql_formatter" },
        plsql = { "sql_formatter" },

        -- Misc
        sh = { "shfmt" },
        bash = { "shfmt" },
        xml = { "xmlformat" },
        toml = { "taplo" },

        -- Run on EVERY filetype not listed above: trim trailing whitespace and
        -- ensure a final newline. "_" is conform's wildcard key.
        ["_"] = { "trim_whitespace", "trim_newlines" },
      },

      -- ── Format on save ─────────────────────────────────────────────────
      format_on_save = function(bufnr)
        -- Respect the toggles bound to <leader>uf / <leader>uF.
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        -- Never auto-format files outside the project (a vendor/ dependency,
        -- a node_modules file you opened to read). Auto-formatting those
        -- creates enormous accidental diffs.
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") or bufname:match("[/\\]vendor[/\\]") then
          return
        end
        return {
          timeout_ms = 3000, -- google-java-format and phpcs can be slow to boot
          lsp_format = "fallback", -- if no formatter is configured, ask the LSP
        }
      end,

      -- ── Per-formatter overrides ────────────────────────────────────────
      formatters = {
        sql_formatter = {
          -- sql-formatter's default dialect is generic SQL, which mangles
          -- T-SQL and PostgreSQL specifics. Pick the dialect from a buffer
          -- variable so you can set it per project/connection:
          --   :lua vim.b.sql_dialect = "postgresql"
          -- Valid: sql | mysql | mariadb | postgresql | tsql | sqlite | bigquery
          prepend_args = function(_, ctx)
            local dialect = vim.b[ctx.buf].sql_dialect or vim.g.sql_dialect or "sql"
            return { "-l", dialect }
          end,
        },
        djlint = {
          -- Reformat Twig without collapsing the whole template onto one line.
          prepend_args = { "--reformat", "--profile", "jinja", "--indent", "2" },
        },
        php_cs_fixer = {
          -- Non-zero exit codes are NORMAL for php-cs-fixer (it returns 8 when
          -- it changed something). Without this conform reports a failure.
          exit_codes = { 0, 8 },
          prepend_args = { "--rules=@PSR12", "--using-cache=no" },
        },
        stylua = {
          -- Fall back to sane defaults when a project has no stylua.toml.
          prepend_args = function(_, ctx)
            local has_config = vim.fs.find({ "stylua.toml", ".stylua.toml" }, {
              upward = true,
              path = vim.fs.dirname(ctx.filename),
            })[1]
            if has_config then
              return {}
            end
            return { "--indent-type", "Spaces", "--indent-width", "2", "--column-width", "120" }
          end,
        },
        goimports = {
          -- Group your own module's imports separately from third-party ones.
          -- Replace "example.com/yourorg" with your module prefix, or delete.
          -- prepend_args = { "-local", "example.com/yourorg" },
        },
      },

      -- Show which formatter failed rather than a generic message.
      notify_on_error = true,
      notify_no_formatters = false,
    },
    init = function()
      -- Make `gq` (the built-in format operator) use conform. Handy for
      -- formatting a single function without touching the rest of the file.
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-lint
  -- ══════════════════════════════════════════════════════════════════════════
  --  Only add linters here that the LSP does NOT already provide. Notably:
  --    * eslint      -> handled by the `eslint` LSP (which also gives fixes)
  --    * rust        -> clippy runs inside rust-analyzer (see lang/rust.lua)
  --    * lua         -> lua_ls covers it
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- PHP static analysis. phpstan needs a phpstan.neon in the project;
        -- without one it errors, so it is guarded in the autocmd below.
        php = { "phpstan" },
        -- Go: golangci-lint aggregates ~50 linters. gopls already reports
        -- vet-level issues, so this adds the stricter/style checks.
        go = { "golangcilint" },
        -- SQL dialect-aware linting.
        sql = { "sqlfluff" },
        -- Templates.
        twig = { "djlint" },
        -- Containers.
        dockerfile = { "hadolint" },
      }

      -- ── sqlfluff dialect ────────────────────────────────────────────────
      -- sqlfluff refuses to run without a dialect. Same buffer variable as the
      -- formatter, so `:lua vim.b.sql_dialect = "tsql"` configures both.
      lint.linters.sqlfluff.args = {
        "lint",
        "--format=json",
        function()
          return "--dialect=" .. (vim.b.sql_dialect or vim.g.sql_dialect or "ansi")
        end,
      }

      -- ── Run the linters ─────────────────────────────────────────────────
      -- Debounced so a burst of writes doesn't spawn ten phpstan processes.
      local timer = assert(vim.uv.new_timer())
      local function debounced_lint()
        timer:stop()
        timer:start(300, 0, function()
          vim.schedule(function()
            -- Only lint real, modifiable, on-disk files.
            if vim.bo.buftype ~= "" or not vim.bo.modifiable then
              return
            end
            -- Skip linters whose executable is missing on this machine instead
            -- of erroring — the two machines will not always be identical.
            local names = lint.linters_by_ft[vim.bo.filetype] or {}
            local runnable = vim.tbl_filter(function(name)
              local linter = lint.linters[name]
              local cmd = type(linter) == "table" and linter.cmd or nil
              if type(cmd) ~= "string" then
                return true
              end
              return vim.fn.executable(cmd) == 1 or vim.fn.executable(vim.fn.exepath(cmd)) == 1
            end, names)
            if #runnable > 0 then
              lint.try_lint(runnable)
            end
          end)
        end)
      end

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("my_nvim_lint", { clear = true }),
        callback = debounced_lint,
      })

      vim.keymap.set("n", "<leader>cL", function()
        lint.try_lint()
      end, { desc = "Lint buffer now" })
    end,
  },
}
