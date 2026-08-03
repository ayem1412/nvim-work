-- ============================================================================
--  after/lsp/html.lua
-- ============================================================================

return {
  -- Attach to Twig and Blade too, so you get tag completion and folding in
  -- templates. The server tolerates the {{ }} / {% %} it doesn't understand.
  filetypes = { "html", "templ", "twig", "blade" },
  settings = {
    html = {
      format = { enable = false }, -- prettier does this
      hover = { documentation = true, references = true },
    },
  },
  init_options = {
    -- Provide completion/validation for embedded CSS and JS inside <style>
    -- and <script> tags.
    provideFormatter = false,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { "html", "css", "javascript" },
  },
}
