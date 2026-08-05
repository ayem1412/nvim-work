-- ============================================================================
--  lua/plugins/completion.lua  —  blink.cmp + LuaSnip
-- ----------------------------------------------------------------------------
--  Why blink.cmp instead of nvim-cmp?
--    * Batteries included: LSP, path, buffer, snippets, cmdline, signature help
--      are all built in. nvim-cmp needs ~6 separate source plugins.
--    * Much faster: async matching with a hard frame budget, so it never blocks
--      typing even on a huge buffer. Optional Rust fuzzy matcher (with a Lua
--      fallback, which matters on the Windows machine where you may not have
--      a Rust toolchain installed).
--    * It is now the default in LazyVim, so the ecosystem/integration story
--      (lazydev, dadbod, copilot) is well supported.
--
--  nvim-cmp still works fine — but do not run both.
-- ============================================================================

return {
  {
    "saghen/blink.cmp",
    -- Pin the major version: blink v2 is in development with breaking changes.
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        -- jsregexp powers LuaSnip's transformations (the `${1/.../.../}` syntax
        -- used in many LSP snippets). `make install_jsregexp` needs a compiler,
        -- which you may not have on Windows — so it is left out and LuaSnip
        -- degrades gracefully. Uncomment on Linux if you want it:
        -- build = (not require("config.platform").is_win) and "make install_jsregexp" or nil,
        dependencies = {
          -- Community snippet collection for every language in this config.
          "rafamadriz/friendly-snippets",
        },
        config = function()
          local ls = require("luasnip")
          ls.setup({
            history = true, -- allow jumping back into a finished snippet
            updateevents = "TextChanged,TextChangedI", -- live-update $1 mirrors
            enable_autosnippets = true,
            delete_check_events = "TextChanged",
          })

          -- Load the friendly-snippets VS Code-format collection.
          require("luasnip.loaders.from_vscode").lazy_load()
          -- Load your OWN snippets from <config>/snippets/<filetype>.json
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })

          -- Filetype inheritance: a .vue file should also offer JS/TS/HTML/CSS
          -- snippets; a .tsx file should offer JS snippets; Twig should offer
          -- HTML snippets. Without this you only get the exact-filetype set.
          ls.filetype_extend("vue", { "javascript", "typescript", "html", "css" })
          ls.filetype_extend("typescriptreact", { "javascript", "typescript", "html" })
          ls.filetype_extend("javascriptreact", { "javascript", "html" })
          ls.filetype_extend("twig", { "html" })
          ls.filetype_extend("blade", { "html", "php" })

          -- <C-l> / <C-h> to jump forward/backward through snippet placeholders.
          -- (blink handles Tab; these are the explicit, always-available pair.)
          vim.keymap.set({ "i", "s" }, "<C-l>", function()
            if ls.expand_or_jumpable() then
              ls.expand_or_jump()
            end
          end, { desc = "LuaSnip forward" })
          vim.keymap.set({ "i", "s" }, "<C-h>", function()
            if ls.jumpable(-1) then
              ls.jump(-1)
            end
          end, { desc = "LuaSnip backward" })
        end,
      },
    },

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      -- ── Keymap ─────────────────────────────────────────────────────────
      -- "default" preset = a Vim-ish, non-Tab-hijacking set:
      --   <C-space> open menu / docs      <C-e> hide
      --   <C-y>     accept                <C-n>/<C-p> next/prev
      --   <C-k>     signature help
      -- Tab/S-Tab are added below for snippet jumping only, so Tab still
      -- indents when there is no active snippet or menu.
      keymap = {
        preset = "default",
        ["<C-y>"] = { "select_and_accept" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-n>"] = { "show", "select_next", "fallback" },
        ["<C-j>"] = { "snippet_forward", "fallback" },
        ["<C-k>"] = { "snippet_backward", "fallback" },
        ["<Tab>"] = { "show", "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        -- "mono" if your nerd font is the Nerd Font Mono variant (icons are
        -- single-width). Use "normal" if icons look cut off / overlapped.
        nerd_font_variant = "mono",
      },

      snippets = { preset = "luasnip" },

      completion = {
        menu = {
          border = "rounded",
          draw = {
            -- Three columns: kind icon | label | source name.
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200, -- don't flash docs while scrolling fast
          window = { border = "rounded" },
        },
        ghost_text = {
          -- Inline preview of the selected item. Turn off if it fights with
          -- Copilot's own ghost text.
          enabled = true,
        },
        list = {
          selection = {
            -- Do NOT preselect: pressing <CR> should insert a newline unless
            -- you explicitly chose an item. This is the single most important
            -- setting for not fighting your completion menu.
            preselect = false,
            auto_insert = false,
          },
        },
        -- Trigger on every keystroke, but not after whitespace.
        trigger = { show_on_keyword = true },
      },

      signature = {
        enabled = true,
        window = { border = "rounded" },
      },

      -- ── Sources ────────────────────────────────────────────────────────
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },

        -- Per-filetype source lists. This is how SQL buffers get table/column
        -- completion from the live database connection instead of generic
        -- buffer words.
        per_filetype = {
          sql = { "dadbod", "snippets", "buffer" },
          mysql = { "dadbod", "snippets", "buffer" },
          plsql = { "dadbod", "snippets", "buffer" },
          -- In Lua config files, lazydev must outrank lua_ls (see score_offset).
          lua = { "lazydev", "lsp", "path", "snippets", "buffer" },
        },

        providers = {
          -- lazydev feeds `require("...")` module-path completions. The high
          -- score_offset makes it win over lua_ls's (worse) suggestions.
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          -- vim-dadbod-completion ships a blink adapter module.
          dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
          },
          -- Buffer completion is noise inside comments/strings of real code,
          -- but the fallback is valuable. Lower its score so LSP always wins.
          buffer = {
            score_offset = -3,
            opts = {
              -- Only scan VISIBLE buffers, not all 40 you have open. Big win
              -- on a large Spring Boot or monorepo session.
              get_bufnrs = function()
                return vim.tbl_filter(function(bufnr)
                  return vim.bo[bufnr].buftype == ""
                end, vim.api.nvim_list_bufs())
              end,
            },
          },
        },
      },

      -- ── Fuzzy matcher ──────────────────────────────────────────────────
      fuzzy = {
        -- "prefer_rust_with_warning" tries the (much faster) Rust matcher, and
        -- falls back to the pure-Lua one with a notification if the prebuilt
        -- binary can't be downloaded and cargo isn't installed. This is the
        -- right setting for a config shared between a Linux box with Rust and
        -- a locked-down Windows work machine without it.
        implementation = "prefer_rust_with_warning",
      },

      -- Completion on the `:` command line too (files, commands, options).
      cmdline = {
        enabled = true,
        completion = { menu = { auto_show = true }, list = { selection = { preselect = false, auto_insert = true } } },
      },
    },
    -- Merge `sources.providers` etc. rather than replacing the whole table if
    -- another spec (e.g. a lang file) extends opts.
    opts_extend = { "sources.default" },
  },
}
