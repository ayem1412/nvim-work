-- ============================================================================
--  after/lsp/emmet_language_server.lua
-- ----------------------------------------------------------------------------
--  Emmet expands abbreviations like `div.row>ul>li*3` into markup. It appears
--  as a completion item — accept it (<CR> / <C-y>) to expand.
--
--  NOTE: "vue" is deliberately ABSENT from this filetype list. vue_ls already
--  provides Emmet inside .vue templates, and running both produces duplicate
--  completion entries for every abbreviation.
-- ============================================================================

return {
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "sass",
    "javascriptreact",
    "typescriptreact",
    "twig", -- Emmet in Twig templates
    "blade",
    "php", -- inline HTML in .php files
  },
  init_options = {
    showExpandedAbbreviation = "always",
    showAbbreviationSuggestions = true,
    -- Don't expand in the middle of a word — stops Emmet hijacking normal
    -- completion when you type an identifier that looks like an abbreviation.
    showSuggestionsAsSnippets = false,
    preferences = {},
    syntaxProfiles = {
      -- Emmet doesn't know `twig`; tell it to treat those files as HTML.
      twig = "html",
      blade = "html",
      php = "html",
    },
  },
}
