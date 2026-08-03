-- ============================================================================
--  after/lsp/eslint.lua
-- ----------------------------------------------------------------------------
--  Running ESLint as an LSP (rather than through nvim-lint) is strictly better:
--  you get code ACTIONS ("disable this rule for this line", "apply fix") and a
--  single `EslintFixAll` command, not just diagnostics.
--
--  The server only starts when the project has an eslint config, so it is free
--  on projects that don't use it.
-- ============================================================================

return {
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
  },
  settings = {
    -- Flat config (eslint.config.js) is the default from ESLint 9. `auto`
    -- detects either, so this works with legacy .eslintrc projects too.
    experimental = { useFlatConfig = false },
    workingDirectories = { mode = "auto" }, -- correct behaviour in monorepos
    format = false, -- prettier formats; eslint only lints
    -- Report unused eslint-disable comments as hints. Keeps the codebase tidy.
    problems = { shortenToSingleLine = false },
  },
  on_attach = function(_, bufnr)
    -- Auto-fix on save. Runs BEFORE conform's prettier pass, which is the
    -- right order: eslint --fix can change code structure, prettier then
    -- normalises the formatting of the result.
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "silent! EslintFixAll",
      desc = "eslint --fix on save",
    })
    vim.keymap.set("n", "<leader>ce", "<cmd>EslintFixAll<cr>", {
      buffer = bufnr,
      desc = "ESLint: fix all",
    })
  end,
}
