-- ============================================================================
--  lua/plugins/lang/rust.lua
-- ----------------------------------------------------------------------------
--  CRITICAL: rust_analyzer is NOT set up through nvim-lspconfig or
--  mason-lspconfig here. rustaceanvim starts and owns the client itself.
--  If both ran you would get two rust-analyzer processes on the same buffer,
--  duplicate diagnostics, and a warning on every Rust file. That is why
--  "rust_analyzer" appears in the `automatic_enable.exclude` list in
--  plugins/lsp.lua and is absent from `ensure_installed`.
--
--  Also note: rust-tools.nvim is DEAD (unmaintained). rustaceanvim is its
--  maintained successor by the same community, with a different API:
--  you configure it via `vim.g.rustaceanvim`, NOT via a setup() call.
-- ============================================================================

return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6", -- pin the major; the API changed between v3/v4/v5
    lazy = false, -- the plugin is already lazy internally (it hooks the
    -- Rust filetype itself); setting lazy=true here is the
    -- documented way to BREAK it
    ft = { "rust" },
    init = function()
      -- Must be set in `init` (before the plugin loads), because rustaceanvim
      -- reads vim.g.rustaceanvim at load time. Setting it in `config` is too late.
      vim.g.rustaceanvim = {
        -- ── Tools (non-LSP features) ────────────────────────────────────
        tools = {
          -- Show inlay-hint-like info and test results in floats with borders.
          float_win_config = { border = "rounded" },
          -- `:RustLsp runnables` etc. use this to execute cargo commands.
          test_executor = "background",
        },

        -- ── LSP server ──────────────────────────────────────────────────
        server = {
          -- rustaceanvim finds rust-analyzer automatically, preferring the
          -- rustup-managed one. That is what you want: it always matches your
          -- toolchain. Install it with:
          --     rustup component add rust-analyzer
          -- (Do NOT install rust-analyzer via Mason — a mismatched version
          -- against your toolchain produces confusing proc-macro errors.)

          on_attach = function(_, bufnr)
            -- rustaceanvim exposes extra commands through :RustLsp. These are
            -- the ones worth binding.
            local function map(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "Rust: " .. desc })
            end

            -- Replaces the generic K. Shows docs, and pressing K again jumps
            -- INTO the hover window so you can follow links.
            map("K", function()
              vim.cmd.RustLsp({ "hover", "actions" })
            end, "Hover actions")

            -- rust-analyzer's own code actions, including the grouped ones
            -- that vim.lsp.buf.code_action cannot render properly.
            map("<leader>ca", function()
              vim.cmd.RustLsp("codeAction")
            end, "Code action (grouped)")

            -- "Runnables": every `fn main`, test, benchmark and example in the
            -- crate, as a picker. This is how you run a single test.
            map("<leader>rr", function()
              vim.cmd.RustLsp("runnables")
            end, "Runnables")
            map("<leader>rd", function()
              vim.cmd.RustLsp("debuggables")
            end, "Debuggables")

            -- Expand the macro under the cursor recursively. Indispensable
            -- when a derive or a declarative macro misbehaves.
            map("<leader>rm", function()
              vim.cmd.RustLsp("expandMacro")
            end, "Expand macro")

            -- Show the exact rustc explanation for the error under the cursor
            -- (the `E0502` style codes) without leaving the editor.
            map("<leader>re", function()
              vim.cmd.RustLsp("explainError")
            end, "Explain error")
            map("<leader>rD", function()
              vim.cmd.RustLsp("renderDiagnostic")
            end, "Render diagnostic (full)")

            -- Open the docs.rs page for the symbol under the cursor.
            map("<leader>ro", function()
              vim.cmd.RustLsp("openDocs")
            end, "Open docs.rs")

            -- Jump between a module and its parent, and to Cargo.toml.
            map("<leader>rp", function()
              vim.cmd.RustLsp("parentModule")
            end, "Parent module")
            map("<leader>rc", function()
              vim.cmd.RustLsp("openCargo")
            end, "Open Cargo.toml")

            -- Rebuild proc macros / reload the workspace after editing
            -- Cargo.toml. Saves restarting the whole server.
            map("<leader>rw", function()
              vim.cmd.RustLsp("reloadWorkspace")
            end, "Reload workspace")
          end,

          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                -- Analyse all feature combinations. Without this, code behind
                -- a non-default feature flag shows as "unresolved".
                allFeatures = true,
                loadOutDirsFromCheck = true, -- understand build.rs output
                buildScripts = { enable = true },
              },
              -- Run clippy instead of `cargo check` on save. Strictly more
              -- lints for the same cost, since clippy runs check anyway.
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" }, -- don't lint your dependencies
              },
              procMacro = {
                enable = true,
                ignored = {
                  -- These macros are known to confuse rust-analyzer; ignoring
                  -- them avoids spurious errors in async/tracing-heavy code.
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              inlayHints = {
                bindingModeHints = { enable = false },
                closureReturnTypeHints = { enable = "with_block" },
                lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
                parameterHints = { enable = true },
                typeHints = { enable = true },
                -- Show `.await` points explicitly — very useful in async code.
                expressionAdjustmentHints = { enable = "reborrow" },
              },
              -- Import style: prefer `use crate::foo::Bar;` grouped and merged.
              imports = {
                granularity = { group = "module" },
                prefix = "self",
              },
              files = {
                -- Don't index these; on a big workspace it saves seconds.
                excludeDirs = { ".git", "target", "node_modules", ".direnv" },
              },
            },
          },
        },

        -- ── DAP ─────────────────────────────────────────────────────────
        -- rustaceanvim auto-detects codelldb from Mason. Since codelldb is in
        -- mason-tool-installer's ensure_installed list, `:RustLsp debuggables`
        -- works with no further configuration.
        dap = {
          autoload_configurations = true,
        },
      }
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  crates.nvim — Cargo.toml superpowers
  -- ══════════════════════════════════════════════════════════════════════════
  --  Shows the latest version of each dependency inline, warns about outdated
  --  or yanked crates, and offers completion for crate names and versions.
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = { enabled = true }, -- fetch crate names from crates.io
      },
      lsp = {
        -- crates.nvim can present itself as an LSP, so hover/code-actions work
        -- through the same keymaps you use everywhere else.
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    keys = {
      {
        "<leader>rC",
        function()
          require("crates").show_popup()
        end,
        desc = "Crates: info popup",
      },
      {
        "<leader>rU",
        function()
          require("crates").upgrade_crate()
        end,
        desc = "Crates: upgrade",
      },
      {
        "<leader>rA",
        function()
          require("crates").upgrade_all_crates()
        end,
        desc = "Crates: upgrade all",
      },
      {
        "<leader>rF",
        function()
          require("crates").show_features_popup()
        end,
        desc = "Crates: features",
      },
    },
  },
}
