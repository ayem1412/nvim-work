-- ============================================================================
--  after/lsp/tailwindcss.lua
-- ----------------------------------------------------------------------------
--  The server only starts when it finds a Tailwind config in the project, so
--  it costs nothing on non-Tailwind projects.
-- ============================================================================

return {
  filetypes = {
    "html",
    "css",
    "scss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "twig", -- Tailwind in Twig templates
    "blade",
    "php",
  },
  root_markers = {
    "tailwind.config.js",
    "tailwind.config.cjs",
    "tailwind.config.mjs",
    "tailwind.config.ts",
    "postcss.config.js",
    -- Tailwind v4 has no JS config; it lives in the CSS file.
    "package.json",
  },
  settings = {
    tailwindCSS = {
      validate = true,
      classAttributes = { "class", "className", "classList", "ngClass" },
      -- Teach the server about class names in non-obvious positions:
      -- cva()/clsx()/cn() helper calls, and Twig's `class="..."`.
      experimental = {
        classRegex = {
          { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          { "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          "class:\\s*?[\"'`]([^\"'`]*).*?[\"'`]",
        },
      },
      lint = {
        cssConflict = "warning",
        invalidApply = "error",
        invalidConfigPath = "error",
        invalidTailwindDirective = "error",
        recommendedVariantOrder = "warning",
      },
    },
  },
}
