-- ============================================================================
--  lua/plugins/lang/go.lua
-- ----------------------------------------------------------------------------
--  gopls itself is configured in after/lsp/gopls.lua (settings) and enabled by
--  mason-lspconfig. This file adds the two things gopls does not do:
--    1. Debugging via delve.
--    2. Struct-tag / test-generation helpers.
--
--  Deliberately NOT using ray-x/go.nvim: it is a large plugin that duplicates
--  what gopls + conform + nvim-dap-go already provide, and it fights with
--  conform over formatting. Plain gopls is the leaner, more predictable setup.
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-dap-go — delve integration
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    opts = {
      delve = {
        -- On Windows, delve cannot be run from a normal terminal buffer in
        -- some setups; the plugin handles this, but the flag must be set.
        detached = not require("config.platform").is_win,
        -- Give delve longer to start on a cold Windows filesystem.
        initialize_timeout_sec = 30,
      },
      dap_configurations = {
        {
          -- Attach to an already-running process (e.g. a service started by
          -- docker-compose or `go run` in another terminal).
          type = "go",
          name = "Attach to process",
          mode = "local",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      },
    },
    keys = {
      -- Debug the single test function under the cursor. This is the killer
      -- feature: no launch.json, no arguments, just put the cursor in a
      -- TestXxx function and press the key.
      {
        "<leader>dgt",
        function()
          require("dap-go").debug_test()
        end,
        desc = "Debug: Go test (nearest)",
        ft = "go",
      },
      {
        "<leader>dgl",
        function()
          require("dap-go").debug_last_test()
        end,
        desc = "Debug: Go test (last)",
        ft = "go",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  gopher.nvim — struct tags, error handling, test scaffolding
  -- ══════════════════════════════════════════════════════════════════════════
  --  Wraps the standard Go tooling (gomodifytags, impl, iferr) so you can add
  --  `json:"..."` tags to a struct or generate `if err != nil` blocks without
  --  leaving the buffer.
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    -- Installs gomodifytags / impl / iferr / gotests into your GOPATH.
    build = function()
      vim.cmd([[silent! GoInstallDeps]])
    end,
    opts = {},
    keys = {
      -- Prefix is <leader>G (capital = Go). Lowercase <leader>g is git, and
      -- <leader>gs is already "git status" — sharing the prefix would make
      -- every git mapping wait for 'timeoutlen'.
      { "<leader>Gj", "<cmd>GoTagAdd json<cr>", desc = "Go: add json tags", ft = "go" },
      { "<leader>Gy", "<cmd>GoTagAdd yaml<cr>", desc = "Go: add yaml tags", ft = "go" },
      { "<leader>Gd", "<cmd>GoTagRm json<cr>", desc = "Go: remove json tags", ft = "go" },
      { "<leader>Ge", "<cmd>GoIfErr<cr>", desc = "Go: generate if err != nil", ft = "go" },
      { "<leader>Gt", "<cmd>GoTestAdd<cr>", desc = "Go: generate test for func", ft = "go" },
      { "<leader>Ga", "<cmd>GoTestsAll<cr>", desc = "Go: generate all tests", ft = "go" },
      { "<leader>Gi", "<cmd>GoImpl<cr>", desc = "Go: implement interface", ft = "go" },
    },
  },
}
