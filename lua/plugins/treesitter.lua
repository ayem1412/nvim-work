-- ============================================================================
--  lua/plugins/treesitter.lua  —  syntax, indentation, textobjects, folds
-- ----------------------------------------------------------------------------
--  BRANCH: `main` (the rewrite), for Neovim 0.12+.
--
--  This is NOT the old `master` config with the big `configs.setup{}` table.
--  On the main branch that whole module system is gone. Specifically:
--    * `ensure_installed` no longer exists -> you call
--      require("nvim-treesitter").install({...}) yourself.
--    * `highlight = { enable = true }` is gone -> you start highlighting per
--      buffer with vim.treesitter.start() in a FileType autocmd.
--    * indent / folds are enabled by setting Neovim's own options, not by a
--      treesitter module flag.
--    * incremental selection is no longer built in -> wired manually below.
--    * textobjects moved to the textobjects plugin's OWN `main` branch, with a
--      new API: require("nvim-treesitter-textobjects").setup{} plus explicit
--      select/move/swap keymaps (the old `keymaps = {...}` table is gone).
--
--  PREREQUISITES on this machine (you already have zig for the compiler):
--    * Neovim 0.12+          (you're on 0.12.4 — correct)
--    * a C compiler          (zig — configured below on Windows)
--    * the tree-sitter CLI   (scoop install tree-sitter)  <-- needed by `main`
--
--  If you ever drop back to Neovim 0.11.x, switch this file back to the
--  master-branch version — main requires 0.12.
-- ============================================================================

-- The parsers this config installs. One list, reused by the installer and by
-- the FileType autocmd that starts highlighting.
local ensure_installed = {
  -- Config / infra
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query",
  "regex",
  "bash",
  "json",
  "yaml",
  "toml",
  "xml",
  "markdown",
  "markdown_inline",
  "dockerfile",
  "gitignore",
  "gitcommit",
  "diff",
  "rust",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "gotmpl",
  "html",
  "css",
  "scss",
  "javascript",
  "jsdoc",
  "typescript",
  "tsx",
  "vue",
  "twig",
  "graphql",
  "php",
  "php_only",
  "phpdoc",
  "java",
  "properties",
  "sql",
}

-- Filetypes that should get treesitter highlighting/indent/folds. The mapping
-- from filetype -> parser is mostly 1:1, but a few differ (e.g. the `vue`
-- filetype uses the `vue` parser; `jproperties` uses `properties`). We start
-- treesitter for these filetypes and let it resolve the parser.
local ft_enable = {
  "lua",
  "vim",
  "bash",
  "sh",
  "json",
  "jsonc",
  "yaml",
  "toml",
  "xml",
  "markdown",
  "dockerfile",
  "gitcommit",
  "diff",
  "rust",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "html",
  "css",
  "scss",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "tsx",
  "vue",
  "twig",
  "graphql",
  "php",
  "java",
  "jproperties",
  "sql",
  "mysql",
  "plsql",
}

-- Filetypes where we DELIBERATELY keep Vim's regex syntax running ALONGSIDE
-- treesitter, because treesitter's parser misses some edges:
--   php  -> heredoc/nowdoc and some interpolation
--   twig -> template delimiters
--   markdown -> some inline constructs
local keep_regex_syntax = { php = true, twig = true, markdown = true }

-- Filetypes where treesitter indentation is worse than Vim's built-in indent.
-- On master these were in `indent.disable`; here we just don't set indentexpr.
local bad_ts_indent = { php = true, twig = true, yaml = true }

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-treesitter (main branch)
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- main does not support lazy-loading the way master did; load at startup.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local TS = require("nvim-treesitter")

      -- Guard: if the plugin hasn't been updated to the main-branch code yet
      -- (first install, or updating from master), `install` won't exist.
      if not TS.get_installed then
        vim.notify(
          "nvim-treesitter: restart Neovim and run :TSUpdate to finish the main-branch install.",
          vim.log.levels.WARN
        )
        return
      end

      -- ── Install missing parsers ──────────────────────────────────────────
      -- `install` replaces the old `ensure_installed`. We diff against what's
      -- already installed so we don't rebuild everything on every startup —
      -- important, because compiling 40 parsers takes a while.
      local already = {}
      for _, name in ipairs(TS.get_installed("parsers")) do
        already[name] = true
      end
      local to_install = vim.tbl_filter(function(name)
        return not already[name]
      end, ensure_installed)
      if #to_install > 0 then
        -- install() is async and returns immediately; parsers appear as they
        -- finish compiling. Safe to call at startup.
        TS.install(to_install)
      end

      -- ── Enable features per filetype ─────────────────────────────────────
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("my_treesitter", { clear = true }),
        pattern = ft_enable,
        callback = function(ev)
          local ft = vim.bo[ev.buf].filetype

          -- Skip the big-file fast path (set by the bigfile autocmd in
          -- config/autocmds.lua and by snacks). Starting treesitter on a
          -- multi-megabyte minified file is exactly what we want to avoid.
          if vim.b[ev.buf].bigfile then
            return
          end

          -- 1. Highlighting. pcall because a parser may still be compiling on
          --    first launch; it'll work on the next file of that type.
          local ok = pcall(vim.treesitter.start, ev.buf)
          if not ok then
            return
          end

          -- Keep Vim regex syntax alongside treesitter for the few filetypes
          -- that need it. vim.treesitter.start() normally turns ':syntax' off;
          -- re-enabling it here runs both.
          if keep_regex_syntax[ft] then
            vim.bo[ev.buf].syntax = "ON"
          end

          -- 2. Folding. Uses Neovim's core treesitter foldexpr. The window-
          --    local set here matches the global default in options.lua and
          --    makes sure folds work even in windows opened before startup.
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

          -- 3. Indentation (experimental on main). Skip the filetypes where
          --    Vim's built-in indent is better.
          if not bad_ts_indent[ft] then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- ── Incremental selection ────────────────────────────────────────────
      -- No longer built in on main, so we implement it against the core
      -- treesitter API. Grow the selection by syntax node with <C-space>,
      -- shrink with <BS>. identifier -> expression -> statement -> block ...
      do
        local ns_nodes = {} -- per-buffer stack of selected ranges

        local function get_node_at_cursor()
          return vim.treesitter.get_node()
        end

        local function select_range(node, buf)
          local sr, sc, er, ec = node:range()
          vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
          vim.cmd("normal! v")
          -- move to end of the node
          local ok = pcall(vim.api.nvim_win_set_cursor, 0, { er + 1, math.max(ec - 1, 0) })
          if not ok then
            vim.api.nvim_win_set_cursor(0, { er + 1, 0 })
          end
        end

        local function init_or_grow()
          local buf = vim.api.nvim_get_current_buf()
          local node = get_node_at_cursor()
          if not node then
            return
          end
          local stack = ns_nodes[buf] or {}
          -- If we already have a selection, grow to the parent.
          if #stack > 0 then
            local parent = node:parent()
            -- Walk up until the parent's range is strictly bigger than the
            -- current node's, so each press visibly grows the selection.
            while
              parent
              and select(1, parent:range()) == select(1, node:range())
              and select(3, parent:range()) == select(3, node:range())
            do
              parent = parent:parent()
            end
            node = parent or node
          end
          table.insert(stack, node)
          ns_nodes[buf] = stack
          select_range(node, buf)
        end

        local function shrink()
          local buf = vim.api.nvim_get_current_buf()
          local stack = ns_nodes[buf]
          if not stack or #stack <= 1 then
            return
          end
          table.remove(stack) -- drop current
          local node = stack[#stack]
          select_range(node, buf)
        end

        vim.keymap.set("n", "<C-space>", init_or_grow, { desc = "TS: init/grow selection" })
        vim.keymap.set("x", "<C-space>", init_or_grow, { desc = "TS: grow selection" })
        vim.keymap.set("x", "<BS>", shrink, { desc = "TS: shrink selection" })

        -- Reset the stack when leaving visual mode so the next <C-space>
        -- starts fresh from the cursor.
        vim.api.nvim_create_autocmd("ModeChanged", {
          group = vim.api.nvim_create_augroup("my_ts_incremental", { clear = true }),
          pattern = "[vV\x16]*:[^vV\x16]*",
          callback = function()
            ns_nodes[vim.api.nvim_get_current_buf()] = nil
          end,
        })
      end
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-treesitter-textobjects (main branch)
  -- ══════════════════════════════════════════════════════════════════════════
  --  The API changed completely from master. There is no `keymaps = {...}`
  --  table anymore; you call setup() for behaviour (lookahead, jumps) and then
  --  bind each textobject/motion yourself via the select/move/swap modules.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true, -- jump forward to the next object if not inside one
          -- Pick the visual mode per object: functions/classes linewise reads
          -- better; arguments charwise.
          selection_modes = {
            ["@function.outer"] = "V",
            ["@function.inner"] = "V",
            ["@class.outer"] = "V",
            ["@class.inner"] = "V",
            ["@parameter.outer"] = "v",
            ["@parameter.inner"] = "v",
          },
          include_surrounding_whitespace = false,
        },
        move = {
          set_jumps = true, -- record in the jumplist so <C-o> comes back
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- ── Select ───────────────────────────────────────────────────────────
      -- Same mnemonics as before: af/if function, ac/ic class, aa/ia argument,
      -- ai/ii conditional, al/il loop, a/ comment.
      local sel = {
        ["af"] = { "@function.outer", "a function" },
        ["if"] = { "@function.inner", "inner function" },
        ["ac"] = { "@class.outer", "a class" },
        ["ic"] = { "@class.inner", "inner class" },
        ["aa"] = { "@parameter.outer", "an argument" },
        ["ia"] = { "@parameter.inner", "inner argument" },
        ["ai"] = { "@conditional.outer", "a conditional" },
        ["ii"] = { "@conditional.inner", "inner conditional" },
        ["al"] = { "@loop.outer", "a loop" },
        ["il"] = { "@loop.inner", "inner loop" },
        ["a/"] = { "@comment.outer", "a comment" },
      }
      for lhs, spec in pairs(sel) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(spec[1], "textobjects")
        end, { desc = "TS: " .. spec[2] })
      end

      -- ── Move ─────────────────────────────────────────────────────────────
      local goto_next_start = {
        ["]f"] = { "@function.outer", "Next function" },
        ["]c"] = { "@class.outer", "Next class" },
        ["]a"] = { "@parameter.inner", "Next argument" },
      }
      local goto_prev_start = {
        ["[f"] = { "@function.outer", "Prev function" },
        ["[c"] = { "@class.outer", "Prev class" },
        ["[a"] = { "@parameter.inner", "Prev argument" },
      }
      for lhs, spec in pairs(goto_next_start) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move.goto_next_start(spec[1], "textobjects")
        end, { desc = spec[2] })
      end
      for lhs, spec in pairs(goto_prev_start) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move.goto_previous_start(spec[1], "textobjects")
        end, { desc = spec[2] })
      end

      -- ── Swap ─────────────────────────────────────────────────────────────
      -- Reorder function arguments without touching commas by hand.
      vim.keymap.set("n", "<leader>cxa", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "TS: swap argument next" })
      vim.keymap.set("n", "<leader>cxA", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "TS: swap argument prev" })
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-ts-autotag  —  auto close/rename HTML/JSX/Vue/Twig tags
  -- ══════════════════════════════════════════════════════════════════════════
  --  Independent of the master/main split; it hooks Neovim's treesitter core
  --  directly, so it works the same on 0.12.
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html",
      "javascriptreact",
      "typescriptreact",
      "vue",
      "twig",
      "blade",
      "xml",
      "markdown",
    },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      per_filetype = {
        html = { enable_close = true },
        twig = { enable_close = true },
        blade = { enable_close = true },
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Sticky context header
  -- ══════════════════════════════════════════════════════════════════════════
  --  Pins the enclosing function/class/if signature to the top of the window
  --  while you scroll inside it. Works on both treesitter branches.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      separator = "─",
    },
    keys = {
      {
        "<leader>ut",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "Toggle treesitter context",
      },
      {
        "[x",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Jump to context (upwards)",
      },
    },
  },
}
