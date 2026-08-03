-- ============================================================================
--  lua/plugins/treesitter.lua  —  syntax, indentation, textobjects, folds
-- ----------------------------------------------------------------------------
--  BRANCH CHOICE — read before "upgrading".
--
--  nvim-treesitter has two branches:
--    master : the long-standing, stable one. Has the `configs.setup{}` module
--             system (`ensure_installed`, `highlight`, `indent`, ...), ships
--             prebuilt-friendly parser handling, and has the best documented
--             Windows story.
--    main   : a full, INCOMPATIBLE rewrite. Requires Neovim 0.12+, the
--             tree-sitter CLI and a working C compiler on PATH, and drops the
--             module system entirely (you call `install()` and enable features
--             per-filetype yourself).
--
--  This config uses `master` deliberately, because it is by far the smoother
--  experience on a Windows work machine where you may not control the
--  toolchain. If you later want `main`, see the commented block at the bottom.
-- ============================================================================

local plat = require("config.platform")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate", -- recompile parsers after the plugin updates
    -- BufReadPost so parsers attach to the first file you open, but not before.
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    cmd = { "TSUpdate", "TSInstall", "TSInstallInfo", "TSBufToggle" },
    dependencies = {
      -- Adds `af`/`if` (function), `ac`/`ic` (class), `aa`/`ia` (argument)
      -- textobjects that are *syntax aware* rather than regex guesses.
      "nvim-treesitter/nvim-treesitter-textobjects",
      -- Auto-close and auto-rename HTML/JSX/Vue/Twig tags.
      "windwp/nvim-ts-autotag",
    },
    config = function()
      -- ── Windows compiler selection ───────────────────────────────────────
      -- Parser compilation needs a C compiler. The default probe order often
      -- lands on `cl.exe` (MSVC), which most people don't have. `zig` is the
      -- easiest working compiler on Windows: `scoop install zig`.
      if plat.is_win then
        require("nvim-treesitter.install").compilers = { "zig", "clang", "gcc", "cc", "cl" }
        -- Use the git protocol Windows corporate proxies are least likely to
        -- block. (Comment out if your network is fine with the default.)
        require("nvim-treesitter.install").prefer_git = true
      end

      require("nvim-treesitter.configs").setup({
        -- ── Parsers ────────────────────────────────────────────────────────
        -- One entry per language you actually open. Installing all 200+ parsers
        -- wastes disk and update time.
        ensure_installed = {
          -- Config / infra
          "lua",
          "luadoc",
          "vim",
          "vimdoc",
          "query", -- treesitter's own query language (for :InspectTree)
          "regex",
          "bash",
          "json",
          "jsonc",
          "yaml",
          "toml",
          "xml", -- pom.xml, Spring XML
          "markdown",
          "markdown_inline",
          "dockerfile",
          "gitignore",
          "gitcommit",
          "diff",
          -- Rust
          "rust",
          -- Go
          "go",
          "gomod",
          "gosum",
          "gowork",
          "gotmpl",
          -- Web
          "html",
          "css",
          "scss",
          "javascript",
          "jsdoc",
          "typescript",
          "tsx", -- React
          "vue",
          "twig", -- Twig / Volt templates
          "graphql",
          -- PHP
          "php",
          "php_only", -- required by the `php` parser for pure-PHP files
          "phpdoc",
          -- Java
          "java",
          "properties", -- application.properties
          -- SQL
          "sql",
        },

        -- Install parsers for a filetype the moment you open one that is
        -- missing. Convenient, but it needs a compiler — it will simply fail
        -- with a message if you don't have one, which is why the compiler list
        -- above matters on Windows.
        auto_install = false,
        sync_install = false, -- install in the background, never block startup

        -- ── Highlighting ───────────────────────────────────────────────────
        highlight = {
          enable = true,
          -- Some languages still need Vim's regex syntax running alongside
          -- treesitter for things treesitter doesn't model:
          --   php  -> the legacy syntax handles some heredoc/interpolation edges
          --   twig -> template delimiters
          -- The cost is a bit of CPU; correctness wins.
          additional_vim_regex_highlighting = { "php", "twig", "markdown" },
          -- Disable on huge files (see also the bigfile autocmd in autocmds.lua).
          disable = function(_, buf)
            local max_filesize = 1024 * 1024 -- 1 MB
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            return ok and stats and stats.size > max_filesize
          end,
        },

        -- ── Indentation ────────────────────────────────────────────────────
        indent = {
          enable = true,
          -- Treesitter's PHP and Twig indent modules are known to be shaky;
          -- Vim's built-in indent for those is better in practice.
          disable = { "php", "twig", "yaml" },
        },

        -- ── Incremental selection ──────────────────────────────────────────
        -- Grow the selection by syntax node. Press <C-space> repeatedly to go
        -- identifier -> expression -> statement -> block -> function.
        -- Genuinely one of treesitter's best features for refactoring.
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },

        -- ── Textobjects ────────────────────────────────────────────────────
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- jump forward to the next object if not inside one
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "a function" },
              ["if"] = { query = "@function.inner", desc = "inner function" },
              ["ac"] = { query = "@class.outer", desc = "a class" },
              ["ic"] = { query = "@class.inner", desc = "inner class" },
              ["aa"] = { query = "@parameter.outer", desc = "an argument" },
              ["ia"] = { query = "@parameter.inner", desc = "inner argument" },
              ["ai"] = { query = "@conditional.outer", desc = "a conditional" },
              ["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
              ["al"] = { query = "@loop.outer", desc = "a loop" },
              ["il"] = { query = "@loop.inner", desc = "inner loop" },
              ["a/"] = { query = "@comment.outer", desc = "a comment" },
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- record in the jumplist so <C-o> comes back
            goto_next_start = {
              ["]f"] = { query = "@function.outer", desc = "Next function" },
              ["]c"] = { query = "@class.outer", desc = "Next class" },
              ["]a"] = { query = "@parameter.inner", desc = "Next argument" },
            },
            goto_previous_start = {
              ["[f"] = { query = "@function.outer", desc = "Prev function" },
              ["[c"] = { query = "@class.outer", desc = "Prev class" },
              ["[a"] = { query = "@parameter.inner", desc = "Prev argument" },
            },
          },
          swap = {
            enable = true,
            -- Reorder function arguments without touching commas manually.
            swap_next = { ["<leader>cxa"] = "@parameter.inner" },
            swap_previous = { ["<leader>cxA"] = "@parameter.inner" },
          },
        },
      })

      -- Auto-close/rename tags. Configured separately from the main setup
      -- because nvim-ts-autotag moved to its own `setup()` in recent versions.
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
        -- Twig/Blade aren't in the default list.
        per_filetype = {
          html = { enable_close = true },
          twig = { enable_close = true },
          blade = { enable_close = true },
        },
      })
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Sticky context header
  -- ══════════════════════════════════════════════════════════════════════════
  --  Pins the enclosing function/class/if signature to the top of the window
  --  while you scroll inside it. Invaluable in long Java/PHP methods.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3, -- more than 3 lines of context eats the screen
      multiline_threshold = 1, -- collapse multi-line signatures to one line
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

-- ============================================================================
--  APPENDIX — migrating to the `main` branch (Neovim 0.12+ only)
-- ----------------------------------------------------------------------------
--  There is no incremental migration; the module system is gone. The whole spec
--  becomes roughly:
--
--    {
--      "nvim-treesitter/nvim-treesitter",
--      branch = "main",
--      lazy = false,                 -- main does NOT support lazy-loading
--      build = ":TSUpdate",
--      config = function()
--        require("nvim-treesitter").install({ "lua", "rust", "go", ... })
--        vim.api.nvim_create_autocmd("FileType", {
--          pattern = { "lua", "rust", "go", "php", "vue", ... },
--          callback = function()
--            pcall(vim.treesitter.start)                       -- highlighting
--            vim.wo.foldexpr  = "v:lua.vim.treesitter.foldexpr()"
--            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--          end,
--        })
--      end,
--    }
--
--  Prerequisites: Neovim 0.12+, `tree-sitter` CLI on PATH (npm i -g
--  tree-sitter-cli / cargo install tree-sitter-cli), and a C compiler.
--  Windows parser builds on `main` were still rough as of mid-2026 — verify
--  before switching the machine you actually work on.
-- ============================================================================
