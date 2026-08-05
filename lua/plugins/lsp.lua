-- ============================================================================
--  lua/plugins/lsp.lua  —  LSP core (Neovim 0.11+ native API)
-- ----------------------------------------------------------------------------
--  READ THIS BEFORE EDITING — the LSP API changed in Neovim 0.11 and most
--  tutorials online are still showing the old way.
--
--  DEPRECATED (do not use):
--      require("lspconfig").gopls.setup({ ... })
--      require("mason-lspconfig").setup_handlers({ ... })   -- removed in v2
--
--  CURRENT:
--      vim.lsp.config("gopls", { ...settings... })   -- declare/merge config
--      vim.lsp.enable("gopls")                       -- actually start it
--
--  Even better: put the per-server table in a file called
--      after/lsp/gopls.lua
--  and Neovim auto-loads it when the server is enabled. That's what this config
--  does — see the after/lsp/ directory. Why `after/lsp/` and not `lsp/`?
--  Because nvim-lspconfig ALSO ships lsp/gopls.lua, and files found later on the
--  runtimepath win. `after/` is loaded last, so your overrides always win.
--
--  So the division of labour is:
--    nvim-lspconfig  -> supplies default `cmd`, `filetypes`, `root_markers`
--    after/lsp/*.lua -> your settings, merged on top
--    mason-lspconfig -> installs the binaries and calls vim.lsp.enable() for you
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  Mason — installs LSP servers, formatters, linters, DAP adapters
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "mason-org/mason.nvim", -- NOTE: moved from williamboman/ to mason-org/ in v2
    version = "^2.0.0", -- pin the major: v1 -> v2 was a breaking change
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
      -- Mason puts its shims in stdpath("data")/mason/bin and prepends that to
      -- Neovim's PATH. `prepend` means Mason's copy of a tool beats a system
      -- copy — usually what you want for reproducibility across two machines.
      PATH = "prepend",
      max_concurrent_installers = 8,
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  mason-tool-installer — declaratively install the NON-LSP tools
  -- ══════════════════════════════════════════════════════════════════════════
  --  mason-lspconfig only handles language servers. Formatters, linters and
  --  debug adapters need this. Declaring them here means a fresh machine gets
  --  the identical toolchain with zero manual :MasonInstall.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- ── Formatters ────────────────────────────────────────────────────
        "stylua", -- Lua
        "prettierd", -- JS/TS/Vue/CSS/HTML/JSON/YAML/MD (daemon = fast)
        "prettier", -- fallback when prettierd misbehaves
        "gofumpt", -- Go, stricter than gofmt
        "goimports", -- Go, manages the import block
        "php-cs-fixer", -- PHP (PSR-12 / Symfony / custom rulesets)
        "google-java-format", -- Java
        "sql-formatter", -- SQL, multi-dialect
        "shfmt", -- shell
        "djlint", -- Twig / Jinja / Django-style templates
        "xmlformatter", -- pom.xml, Spring XML config
        -- ── Linters ───────────────────────────────────────────────────────
        "golangci-lint", -- Go
        "phpstan", -- PHP static analysis
        "eslint_d", -- JS/TS daemon (the eslint LSP covers most cases)
        "sqlfluff", -- SQL linting with dialect awareness
        "hadolint", -- Dockerfile
        -- ── Debug adapters ────────────────────────────────────────────────
        "codelldb", -- Rust / C / C++ (used by rustaceanvim)
        "delve", -- Go
        "php-debug-adapter", -- PHP / Xdebug
        "js-debug-adapter", -- Node / Chrome / TS
        "java-debug-adapter", -- Java
        "java-test", -- JUnit runner for Java
        -- ── Servers that are installed but NOT auto-enabled ───────────────
        "jdtls", -- Java: started by ftplugin/java.lua, not vim.lsp.enable
      },
      run_on_start = true,
      start_delay = 3000, -- don't fight for CPU during startup
      debounce_hours = 24, -- only re-check once a day
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-lspconfig + mason-lspconfig — the actual wiring
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "neovim/nvim-lspconfig",
    -- BufReadPre so the config is in place before the first real buffer opens.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      -- IMPORTANT ORDERING: nvim-lspconfig must already be on the runtimepath
      -- when mason-lspconfig runs, otherwise it can't find the shipped configs.
      -- Listing it as a dependency of lspconfig (rather than the reverse) is
      -- what guarantees that.
      { "mason-org/mason-lspconfig.nvim", version = "^2.0.0" },
      "saghen/blink.cmp", -- for get_lsp_capabilities()
      -- Offline copy of the JSON/YAML schema catalogue. Consumed by
      -- after/lsp/jsonls.lua and after/lsp/yamlls.lua via `require("schemastore")`.
      { "b0o/SchemaStore.nvim", version = false },
    },
    config = function()
      -- ────────────────────────────────────────────────────────────────────
      --  1. Diagnostics UI
      -- ────────────────────────────────────────────────────────────────────
      vim.diagnostic.config({
        -- `virtual_text` is inline; `virtual_lines` (0.11+) is a multi-line
        -- version that is far more readable for Rust/TypeScript's essay-length
        -- errors. We keep virtual_text on and expose virtual_lines as a toggle.
        virtual_text = {
          spacing = 4,
          prefix = "●",
          source = "if_many", -- show "[eslint]" only when 2+ sources overlap
          -- Truncate monster messages inline; the full text is in the float.
          format = function(d)
            local msg = d.message:gsub("\n", " ")
            return #msg > 120 and msg:sub(1, 117) .. "..." or msg
          end,
        },
        virtual_lines = false,
        underline = true,
        update_in_insert = false, -- do NOT re-lint on every keystroke; it is
        -- distracting and costs CPU on big files
        severity_sort = true, -- errors render above warnings on the same line
        float = {
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
          },
        },
      })

      -- Toggle the verbose multi-line diagnostic renderer.
      vim.keymap.set("n", "<leader>uv", function()
        local cfg = vim.diagnostic.config()
        vim.diagnostic.config({
          virtual_lines = not cfg.virtual_lines,
          virtual_text = cfg.virtual_lines, -- swap: only one at a time
        })
      end, { desc = "Toggle virtual_lines diagnostics" })

      -- ────────────────────────────────────────────────────────────────────
      --  2. Global config applied to EVERY server
      -- ────────────────────────────────────────────────────────────────────
      -- The "*" pseudo-server is merged into every real server's config.
      -- This is where cross-cutting concerns belong: capabilities, root markers.
      vim.lsp.config("*", {
        -- Tell servers what this client can do. blink.cmp advertises extra
        -- completion capabilities (snippet support, resolve support, etc.)
        -- that servers use to send richer completion items.
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        -- Fallback project root when a server declares none. `.git` is right
        -- ~95% of the time; per-language markers live in after/lsp/*.lua.
        root_markers = { ".git" },
      })

      -- ────────────────────────────────────────────────────────────────────
      --  3. LspAttach — runs once per (client, buffer) pair
      -- ────────────────────────────────────────────────────────────────────
      -- This is THE place for buffer-local LSP keymaps. Doing it here instead
      -- of in an `on_attach` per server means it works for every server,
      -- including ones started outside lspconfig (jdtls, rustaceanvim).
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("my_lsp_attach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end
          local buf = ev.buf

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
          end

          -- NOTE: Neovim 0.11+ ALREADY provides these by default, so they are
          -- deliberately NOT redefined here:
          --   K    -> hover              grn  -> rename
          --   gra  -> code action        grr  -> references
          --   gri  -> implementation     grt  -> type definition
          --   gO   -> document symbols   <C-s> (insert) -> signature help
          --
          -- What follows are the additions worth having.

          map("n", "gd", vim.lsp.buf.definition, "Goto definition")
          map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
          -- Open the definition in a split instead of replacing the buffer.
          map("n", "gsd", function()
            vim.cmd("vsplit")
            vim.lsp.buf.definition()
          end, "Goto definition (vsplit)")

          -- Workspace-wide symbol search (across the whole project, not just
          -- this file). Requires the server to support workspace/symbol.
          map("n", "<leader>cs", function()
            vim.lsp.buf.workspace_symbol()
          end, "Workspace symbols")

          -- Explicit hover with a border (the default has none).
          map("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, "Hover documentation")

          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>cl", vim.lsp.codelens.run, "Run code lens")

          -- Restart just this server (much faster than :LspRestart everything).
          map("n", "<leader>cR", function()
            vim.cmd("LspRestart " .. client.name)
          end, "Restart this server")

          map("n", "<leader>dm", vim.diagnostic.open_float, "Open diagnostics")

          -- ── Inlay hints ──────────────────────────────────────────────────
          -- Off by default: they are excellent for reading Rust/Go/TS and
          -- distracting while typing. <leader>uh toggles (see keymaps.lua).
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(false, { bufnr = buf })
          end

          -- ── Document highlight ───────────────────────────────────────────
          -- Highlights other occurrences of the symbol under the cursor after
          -- `updatetime` ms of idle. Cheap and genuinely useful for spotting
          -- every use of a variable in a function.
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup("my_lsp_highlight_" .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = hl_group,
              buffer = buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = hl_group,
              buffer = buf,
              callback = vim.lsp.buf.clear_references,
            })
            -- Clean up when the server detaches, or the autocmd fires against
            -- a dead client and spams errors.
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("my_lsp_detach_" .. buf, { clear = true }),
              buffer = buf,
              callback = function()
                vim.lsp.buf.clear_references()
                pcall(vim.api.nvim_del_augroup_by_name, "my_lsp_highlight_" .. buf)
              end,
            })
          end

          -- ── Disable LSP formatting where a dedicated formatter is better ──
          -- conform.nvim drives formatting (see plugins/format.lua). Turning
          -- off the server's own formatter prevents two tools fighting — the
          -- classic symptom is prettier formatting a .vue file and then
          -- vue_ls immediately reformatting it differently.
          local no_format = {
            ts_ls = true,
            vtsls = true,
            vue_ls = true,
            html = true,
            cssls = true,
            jsonls = true,
            intelephense = true, -- php-cs-fixer/pint is better
            lua_ls = true, -- stylua is better
          }
          if no_format[client.name] then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })

      -- ────────────────────────────────────────────────────────────────────
      --  4. mason-lspconfig — install + auto-enable
      -- ────────────────────────────────────────────────────────────────────
      require("mason-lspconfig").setup({
        -- Installed automatically on first launch. Each of these has a matching
        -- settings file in after/lsp/<name>.lua.
        ensure_installed = {
          "lua_ls", -- Lua
          "gopls", -- Go
          "vtsls", -- TypeScript/JavaScript (see after/lsp/vtsls.lua for why
          -- vtsls and not ts_ls)
          "vue_ls", -- Vue 3 (Volar v3, hybrid mode)
          "eslint", -- JS/TS/Vue linting as an LSP (gives code actions)
          "html",
          "cssls",
          "tailwindcss",
          "emmet_language_server",
          "intelephense", -- PHP (incl. Phalcon via stubs)
          "jsonls",
          "yamlls",
          "taplo", -- TOML (Cargo.toml, rustfmt.toml)
          "sqlls", -- SQL (keyword/schema completion; vim-dadbod does the rest)
          "dockerls",
          "bashls",
          -- NOT here on purpose:
          --   rust_analyzer -> owned by rustaceanvim (see lang/rust.lua)
          --   jdtls         -> owned by nvim-jdtls   (see ftplugin/java.lua)
          --   ts_ls         -> conflicts with vtsls; never run both
        },

        -- v2 replaced setup_handlers() with this. When true, every installed
        -- server is passed to vim.lsp.enable() automatically, picking up your
        -- after/lsp/<name>.lua config. The `exclude` list is critical:
        -- these two servers are started by their own plugins, and enabling them
        -- here too would spawn a SECOND client against the same buffer.
        automatic_enable = {
          exclude = { "rust_analyzer", "jdtls", "ts_ls" },
        },
      })
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  lazydev — LuaLS that actually understands your Neovim config
  -- ══════════════════════════════════════════════════════════════════════════
  --  Replaces the deprecated neodev.nvim. Instead of loading the entire Neovim
  --  runtime into LuaLS's workspace (slow, huge memory), lazydev loads only the
  --  modules you actually `require` in open files. Neovim's own type
  --  definitions are built in since 0.10 and no longer need a plugin.
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only ever needed in Lua buffers
    opts = {
      library = {
        -- vim.uv (libuv) types are shipped by LuaLS as a "third party" addon
        -- but are not loaded unless requested. `words` makes it lazy: only
        -- pulled in for files that mention vim.uv.
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        -- Types for plugins whose APIs you call from config files.
        { path = "lazy.nvim", words = { "LazySpec" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}
