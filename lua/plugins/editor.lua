-- ============================================================================
--  lua/plugins/editor.lua  —  navigation, search, QoL
-- ----------------------------------------------------------------------------
--  The centrepiece is snacks.nvim: folke's collection of small, well-integrated
--  modules that replace roughly a dozen separate plugins (dashboard, notifier,
--  picker, explorer, lazygit, bigfile, indent guides, input, terminal, ...).
--
--  Why snacks.picker rather than telescope?
--    * Zero native compilation. telescope's fast sorter (telescope-fzf-native)
--      needs make/cmake + a C compiler — a real obstacle on a locked-down
--      Windows work machine. snacks.picker is pure Lua and still fast.
--    * Built-in frecency, better preview performance on big repos.
--    * One less plugin graph to keep in sync across two machines.
--  telescope is still excellent if you want its extension ecosystem.
-- ============================================================================

local plat = require("config.platform")

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  snacks.nvim
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "folke/snacks.nvim",
    priority = 1000, -- load before everything else...
    lazy = false, -- ...and at startup: bigfile/quickfile must hook the very
    -- first BufReadPre, and other plugins call Snacks.* APIs.
    ---@type snacks.Config
    opts = {
      -- Detects huge files and disables treesitter/LSP/syntax before they can
      -- hang the editor. Complements the manual guard in autocmds.lua.
      bigfile = { enabled = true, size = 1.5 * 1024 * 1024 },

      -- Renders the first screen of a file before plugins load, so `nvim file`
      -- feels instant.
      quickfile = { enabled = true },

      -- Start screen.
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find file", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Grep text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = " ", key = "s", desc = "Restore session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },

      -- Replaces vim.notify with a proper notification stack.
      notifier = {
        enabled = true,
        timeout = 3000,
        style = "compact",
      },

      -- Replaces vim.ui.input with a floating prompt (used by LSP rename).
      input = { enabled = true },

      -- Indent guides + scope highlighting (replaces indent-blankline).
      indent = {
        enabled = true,
        indent = { char = "│" },
        scope = { char = "│", hl = "SnacksIndentScope" },
        animate = { enabled = false }, -- animation is pure cost; disable
      },

      -- Highlights other references to the word under the cursor via LSP.
      words = { enabled = true },

      -- Distraction-free writing modes.
      zen = { enabled = true },

      -- A better `:h statuscolumn` with fold + git + sign integration.
      statuscolumn = { enabled = true },

      -- Smooth scrolling. Disabled: it adds latency and is a matter of taste.
      scroll = { enabled = false },

      -- ── The picker ──────────────────────────────────────────────────────
      picker = {
        enabled = true,
        ui_select = true, -- also replace vim.ui.select (code actions, etc.)
        sources = {
          files = {
            hidden = true, -- show dotfiles
            -- `fd` is dramatically faster than the fallback. See README for
            -- how to install it on each OS.
          },
          explorer = {
            hidden = true,
            layout = { preset = "sidebar", preview = false },
          },
        },
        formatters = {
          file = { filename_first = true }, -- name before path: easier to scan
        },
        win = {
          input = {
            keys = {
              -- <Esc> closes instead of dropping to normal mode inside input.
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["<C-j>"] = { "list_down", mode = { "n", "i" } },
              ["<C-k>"] = { "list_up", mode = { "n", "i" } },
            },
          },
        },
      },

      -- ── File explorer ───────────────────────────────────────────────────
      explorer = { enabled = true, replace_netrw = true },

      -- ── Terminal / lazygit ──────────────────────────────────────────────
      terminal = { enabled = true },
      lazygit = {
        enabled = true,
        -- Make lazygit use the same colours as your colourscheme.
        configure = true,
      },

      -- Scratch buffers: brilliant for SQL scratchpads and one-off Lua tests.
      scratch = { enabled = true },
    },

    -- Every snacks keymap in one place. Lazy-loading is irrelevant here since
    -- snacks loads at startup, but `keys` still gives which-key its labels.
    keys = {
      -- ── Files & search ────────────────────────────────────────────────
      {
        "<leader><space>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart find files",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find git files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find config file",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
      -- Grep
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep (live)",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Grep word under cursor",
        mode = { "n", "x" },
      },
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Grep current buffer",
      },
      {
        "<leader>sB",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep open buffers",
      },
      -- Vim things
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help pages",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sc",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command history",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics (workspace)",
      },
      {
        "<leader>sD",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Diagnostics (buffer)",
      },
      {
        "<leader>sq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "Quickfix list",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume last picker",
      },
      {
        "<leader>su",
        function()
          Snacks.picker.undo()
        end,
        desc = "Undo history",
      },
      {
        '<leader>s"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      -- LSP navigation via the picker (nicer than the quickfix list)
      -- Override the NATIVE grr (Neovim 0.11+ maps it to a quickfix list) with
      -- the picker. Deliberately not plain `gr`: that would shadow the whole
      -- native grn/gra/gri/grt family behind a 'timeoutlen' wait.
      {
        "grr",
        function()
          Snacks.picker.lsp_references()
        end,
        desc = "LSP references",
        nowait = true,
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "Document symbols",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "Workspace symbols",
      },
      -- ── Explorer ──────────────────────────────────────────────────────
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "File explorer",
      },
      -- ── Git ───────────────────────────────────────────────────────────
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gb",
        function()
          Snacks.git.blame_line()
        end,
        desc = "Git blame line",
      },
      -- <leader>gB is gitsigns' inline-blame toggle; this is <leader>go.
      {
        "<leader>go",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Open in browser (git)",
        mode = { "n", "v" },
      },
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git log",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log_line()
        end,
        desc = "Git log (line)",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git status",
      },
      -- ── Buffers / windows ─────────────────────────────────────────────
      {
        "<A-x>",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete buffer (keep layout)",
      },
      {
        "<leader>bo",
        function()
          Snacks.bufdelete.other()
        end,
        desc = "Delete other buffers",
      },
      -- ── Terminal ──────────────────────────────────────────────────────
      {
        "<C-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle terminal",
      },
      {
        "<leader>tt",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle terminal",
      },
      -- ── Misc ──────────────────────────────────────────────────────────
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle scratch buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select scratch buffer",
      },
      {
        "<leader>uz",
        function()
          Snacks.zen()
        end,
        desc = "Toggle zen mode",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss notifications",
      },
      -- <leader>cR is "restart this LSP server" (plugins/lsp.lua).
      {
        "<leader>cn",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename file (LSP-aware)",
      },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Make the debug helpers global. `dd(table)` pretty-prints anything;
          -- `bt()` prints a backtrace. Invaluable when writing config.
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd

          -- Register toggles under <leader>u so they show up in which-key.
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>uS")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>ur")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.dim():map("<leader>uD")
        end,
      })
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  oil.nvim — edit the filesystem like a buffer
  -- ══════════════════════════════════════════════════════════════════════════
  --  Complements the sidebar explorer rather than replacing it. `-` opens the
  --  parent directory as a normal, editable buffer: rename with `cw`, delete
  --  with `dd`, create with `o`, then `:w` to apply. For bulk file operations
  --  (very common when restructuring a Java package or a Vue components dir)
  --  nothing else comes close.
  {
    "stevearc/oil.nvim",
    lazy = false, -- must own the netrw hijack from the start
    opts = {
      default_file_explorer = false, -- snacks.explorer owns netrw; oil is on-demand
      delete_to_trash = true, -- safer; needs `gio` (Linux) or works natively on Windows
      skip_confirm_for_simple_edits = true,
      view_options = { show_hidden = true },
      keymaps = {
        ["<C-h>"] = false, -- don't shadow the window-left mapping
        ["<C-l>"] = false,
        ["q"] = "actions.close",
      },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
      {
        "<leader>fo",
        function()
          require("oil").toggle_float()
        end,
        desc = "Oil (floating)",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  which-key — discoverability
  -- ══════════════════════════════════════════════════════════════════════════
  --  NOTE the v3 API: `wk.add({ ... })` with a flat list of specs. The old
  --  nested `wk.register({ ["<leader>f"] = { name = "+file" } })` form is
  --  deprecated and silently ignored in v3.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix", -- side panel; "modern" and "classic" also available
      delay = function(ctx)
        return ctx.plugin and 0 or 300
      end,
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code / LSP" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "file / find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "git hunk" },
        { "<leader>G", group = "go tooling" },
        { "<leader>j", group = "java (jdtls)" },
        { "<leader>n", group = "npm" },
        { "<leader>p", group = "php (phpactor)" },
        { "<leader>r", group = "rust / crates" },
        { "<leader>q", group = "quit / session" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "terminal / test" },
        { "<leader>u", group = "ui toggles" },
        { "<leader>w", group = "window" },
        { "<leader>x", group = "diagnostics / lists" },
        { "<leader>D", group = "database" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer local keymaps",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  mini.nvim modules — small, dependency-free editing primitives
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "echasnovski/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      -- ── mini.ai: better a/i textobjects ─────────────────────────────────
      -- Adds `aq`/`iq` (any quote), `ab`/`ib` (any bracket), and makes the
      -- built-ins treesitter-aware and multi-line capable.
      local ai = require("mini.ai")
      ai.setup({
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        },
      })

      -- ── mini.surround: add/delete/replace surroundings ──────────────────
      -- Deliberately NOT using the default `s` prefix, which shadows Vim's
      -- perfectly good `s` (substitute). `gs` is free.
      require("mini.surround").setup({
        mappings = {
          add = "gsa", -- gsaiw" -> surround inner word with quotes
          delete = "gsd", -- gsd" -> delete surrounding quotes
          find = "gsf",
          find_left = "gsF",
          highlight = "gsh",
          replace = "gsr", -- gsr"' -> change " to '
          update_n_lines = "gsn",
        },
      })

      -- ── mini.pairs: auto-close brackets/quotes ──────────────────────────
      require("mini.pairs").setup({
        modes = { insert = true, command = true, terminal = false },
        -- Don't auto-pair before an alphanumeric character — stops `(` from
        -- becoming `()` when you're wrapping an existing expression.
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        skip_ts = { "string" },
        skip_unbalanced = true,
        markdown = true,
      })

      -- ── mini.comment fallback ───────────────────────────────────────────
      -- Neovim 0.10+ has built-in `gc` commenting via 'commentstring', which
      -- treesitter keeps accurate even for mixed files (JS inside .vue, PHP
      -- inside .twig). So mini.comment is NOT needed. Listed here so you know
      -- why it's absent.

      -- ── mini.icons: icon provider ───────────────────────────────────────
      require("mini.icons").setup()
      -- Some plugins still ask for nvim-web-devicons by name; this shims it.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end

      -- ── mini.bufremove ──────────────────────────────────────────────────
      -- (snacks.bufdelete covers this; omitted to avoid duplication.)
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  trouble.nvim — a real list for diagnostics / references / symbols
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      modes = {
        -- A right-hand symbol outline. Very useful in long Java classes and
        -- PHP controllers.
        symbols = {
          desc = "symbols",
          win = { position = "right", size = 0.25 },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbol outline" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/defs" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  todo-comments — highlight and search TODO/FIXME/HACK/NOTE
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
    keys = {
      { "<leader>st", "<cmd>TodoTrouble<cr>", desc = "Todo list" },
      { "<leader>sT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix only" },
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo comment",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  flash.nvim — jump anywhere on screen with 2 characters
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote flash",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  persistence — session per project directory
  -- ══════════════════════════════════════════════════════════════════════════
  --  Reopen a project and get your buffers, splits and folds back. Combined
  --  with `undofile` this makes switching between the two machines painless.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't save current session",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Multi-file search & replace across the project
  -- ══════════════════════════════════════════════════════════════════════════
  --  grug-far replaces the older nvim-spectre. Needs ripgrep (see README).
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sr",
        function()
          local ft = vim.bo.filetype
          require("grug-far").open({
            transient = true,
            prefills = { filesFilter = ft and ("*." .. vim.fn.expand("%:e")) or nil },
          })
        end,
        desc = "Search & replace (project)",
      },
    },
    enabled = plat.has_exe("rg"),
  },
}
