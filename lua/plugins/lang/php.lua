-- ============================================================================
--  lua/plugins/lang/php.lua  —  PHP / Phalcon / WAMP
-- ----------------------------------------------------------------------------
--  Where the rest of the PHP setup lives:
--    after/lsp/intelephense.lua   the language server + PHALCON STUBS
--                                 (edit that file when Phalcon classes show
--                                  as "undefined")
--    plugins/dap.lua              Xdebug adapter + the php.ini settings you
--                                 need in WAMP
--    plugins/format.lua           pint / php-cs-fixer, and phpstan linting
--    ftplugin/php.lua             indentation and `$` word-boundary handling
--
--  This file holds only the PHP-specific refactoring tooling.
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  phpactor — refactoring engine (NOT a second language server)
  -- ══════════════════════════════════════════════════════════════════════════
  --  intelephense is the language server because it handles framework magic
  --  (DI containers, __get/__call, annotations) far better, which means far
  --  fewer false "undefined method" errors on Phalcon code.
  --
  --  But intelephense's free tier has no rename, no extract-method, no code
  --  actions. phpactor is fully free and excellent at exactly those. So it is
  --  used here as a refactoring engine ONLY, with its LSP explicitly disabled.
  {
    "gbprod/phpactor.nvim",
    ft = "php",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    build = function()
      -- Downloads phpactor.phar. Needs PHP on PATH — on WAMP add
      -- C:\wamp64\bin\php\php8.x.x to your system PATH first.
      require("phpactor.handler.update")()
    end,
    opts = {
      install = {
        path = vim.fn.stdpath("data") .. "/opt",
        branch = "master",
        bin = vim.fn.stdpath("data") .. "/opt/phpactor/bin/phpactor",
        php_bin = "php",
        composer_bin = "composer",
      },
      lspconfig = {
        -- MUST be false. Running phpactor as a second PHP language server
        -- alongside intelephense gives you duplicate diagnostics and duplicate
        -- completion items on every PHP buffer.
        enabled = false,
      },
    },
    keys = {
      -- The context menu is the entry point — it offers whatever refactors
      -- apply to the thing under the cursor.
      { "<leader>pm", "<cmd>PhpActor context_menu<cr>", desc = "PHP: context menu", ft = "php" },
      { "<leader>pn", "<cmd>PhpActor class_new<cr>", desc = "PHP: new class", ft = "php" },
      -- Fixes the namespace declaration to match the PSR-4 autoload path.
      -- The single most useful one when moving files around a Phalcon app.
      { "<leader>pf", "<cmd>PhpActor fix_namespace_class_name<cr>", desc = "PHP: fix namespace", ft = "php" },
      { "<leader>pi", "<cmd>PhpActor import_missing_classes<cr>", desc = "PHP: import missing classes", ft = "php" },
      { "<leader>pc", "<cmd>PhpActor copy_class<cr>", desc = "PHP: copy class", ft = "php" },
      { "<leader>pM", "<cmd>PhpActor move_class<cr>", desc = "PHP: move class", ft = "php" },
      -- "transform" adds missing interface methods, generates accessors, etc.
      { "<leader>pt", "<cmd>PhpActor transform<cr>", desc = "PHP: transform", ft = "php" },
      { "<leader>pe", "<cmd>PhpActor extract_method<cr>", mode = "v", desc = "PHP: extract method", ft = "php" },
      {
        "<leader>pE",
        "<cmd>PhpActor extract_expression<cr>",
        mode = "v",
        desc = "PHP: extract expression",
        ft = "php",
      },
    },
  },
}
