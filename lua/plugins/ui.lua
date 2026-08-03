-- ============================================================================
--  lua/plugins/ui.lua  —  colourscheme, statusline, bufferline
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  Colourscheme
  -- ══════════════════════════════════════════════════════════════════════════
  --  tokyonight has first-class treesitter AND LSP semantic-token support,
  --  which matters: without semantic tokens, Java/Rust/TypeScript lose the
  --  distinction between e.g. a mutable and immutable binding, or a static and
  --  instance method. Alternatives with equally good support: catppuccin,
  --  kanagawa, rose-pine.
  {
    "folke/tokyonight.nvim",
    lazy = false, -- the colourscheme must load at startup, never lazily
    priority = 1000, -- ...and before every other plugin, so highlight groups
    -- defined by other plugins layer on top correctly
    opts = {
      style = "night", -- storm | night | moon | day
      transparent = false, -- true if your terminal has a background image
      terminal_colors = true, -- also theme :terminal buffers
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      -- Dim inactive splits so the focused one is obvious.
      dim_inactive = false,
      on_highlights = function(hl, c)
        -- Make the treesitter-context header visually distinct from real code.
        hl.TreesitterContext = { bg = c.bg_dark }
        -- Rounded float borders in the theme's accent colour.
        hl.FloatBorder = { fg = c.blue, bg = c.bg_float }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Statusline
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      -- laststatus=3 (global statusline) is set in options.lua. Hide the
      -- built-in ruler/mode so there's no flash of the default UI on startup.
      vim.g.lualine_laststatus = vim.o.laststatus
      vim.o.laststatus = 0
    end,
    opts = function()
      local plat = require("config.platform")
      return {
        options = {
          theme = "tokyonight",
          globalstatus = true,
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard", "alpha" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            -- Path relative to the project root, so you can tell
            -- src/main/java/.../UserService.java from a same-named test file.
            { "filename", path = 1, symbols = { modified = "●", readonly = "" } },
            {
              -- Diagnostics counts.
              "diagnostics",
              symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
            },
          },
          lualine_x = {
            -- Which LSP servers are attached to THIS buffer. Extremely useful
            -- when debugging "why isn't completion working in this .vue file"
            -- — you can see at a glance whether vtsls AND vue_ls are both on.
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then
                  return ""
                end
                local names = vim.tbl_map(function(c)
                  return c.name
                end, clients)
                return " " .. table.concat(names, ",")
              end,
              color = { fg = "#7aa2f7" },
            },
            -- Active formatter(s) from conform.
            {
              function()
                local ok, conform = pcall(require, "conform")
                if not ok then
                  return ""
                end
                local fmts = conform.list_formatters(0)
                if #fmts == 0 then
                  return ""
                end
                return "󰉼 " .. fmts[1].name
              end,
              color = { fg = "#9ece6a" },
            },
            -- Debug adapter status when a session is live.
            {
              function()
                return "  " .. require("dap").status()
              end,
              cond = function()
                return package.loaded["dap"] and require("dap").status() ~= ""
              end,
              color = { fg = "#e0af68" },
            },
            { "diff", symbols = { added = " ", modified = " ", removed = " " } },
          },
          lualine_y = { "filetype", "progress" },
          lualine_z = {
            "location",
            -- Which machine am I on? Trivial, but genuinely helpful when you
            -- have the same config and a shared session on two desktops.
            {
              function()
                return plat.is_win and "" or ""
              end,
            },
          },
        },
        extensions = { "lazy", "mason", "trouble", "quickfix", "oil", "nvim-dap-ui" },
      }
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Bufferline (tabs across the top)
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diag)
          return (diag.error and " " .. diag.error .. " " or "") .. (diag.warning and " " .. diag.warning or "")
        end,
        -- Offset so the buffer tabs don't sit on top of the file explorer.
        offsets = {
          { filetype = "snacks_layout_box", text = "Explorer", highlight = "Directory", text_align = "left" },
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "left" },
        },
        separator_style = "thin",
        always_show_bufferline = false, -- hide when only one buffer is open
      },
    },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned buffers" },
      { "<leader>b1", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Buffer 1" },
      { "<leader>b2", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Buffer 2" },
      { "<leader>b3", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Buffer 3" },
      { "<leader>b4", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Buffer 4" },
      { "<A-,>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
      { "<A-.>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Colour preview (CSS / Tailwind / Vue)
  -- ══════════════════════════════════════════════════════════════════════════
  --  Renders #rrggbb, rgb(), hsl() and Tailwind class names in their actual
  --  colour. Only loads for the filetypes where it matters.
  {
    "brenoprata10/nvim-highlight-colors",
    ft = { "css", "scss", "less", "html", "vue", "javascriptreact", "typescriptreact", "twig", "lua", "conf" },
    opts = {
      render = "virtual", -- "background" | "foreground" | "virtual"
      virtual_symbol = "󱓻",
      enable_tailwind = true,
    },
  },
}
