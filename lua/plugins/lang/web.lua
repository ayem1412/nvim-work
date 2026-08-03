-- ============================================================================
--  lua/plugins/lang/web.lua  —  TypeScript / JavaScript / Vue / React / Twig
-- ----------------------------------------------------------------------------
--  Most of the web stack needs no plugins at all — it is LSP configuration,
--  and that lives in after/lsp/:
--      vtsls.lua                  TypeScript/JS/React + the Vue TS plugin
--      vue_ls.lua                 Vue 3 template/style
--      eslint.lua                 linting + fix-on-save
--      html.lua / cssls.lua       markup and styles
--      tailwindcss.lua            Tailwind class intelligence
--      emmet_language_server.lua  abbreviation expansion
--
--  READ THIS if Vue support misbehaves — it is the part of a Neovim config
--  most likely to be wrong, because it has changed three times:
--
--    * "Take Over mode" is GONE in Volar v3. Do not use it, do not look for it.
--    * The current model is HYBRID MODE:
--        - vue_ls handles <template> and <style>
--        - a TypeScript server handles all TS/JS, INCLUDING inside .vue files
--        - the bridge is @vue/typescript-plugin, loaded INTO the TS server
--    * So TWO servers attach to a .vue buffer. The wiring is in
--      after/lsp/vtsls.lua (globalPlugins) and after/lsp/vue_ls.lua (the
--      tsserver/request handler).
--
--  Server choice: vtsls, not ts_ls, not typescript-tools.nvim.
--      ts_ls  -> reference implementation; slow on large projects
--      vtsls  -> thin maintained tsserver wrapper; fast, monorepo-aware, and
--                the option with the best Vue-plugin support
--  NEVER run vtsls and ts_ls together. That is why ts_ls is listed in
--  `automatic_enable.exclude` in plugins/lsp.lua.
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  package.json version hints
  -- ══════════════════════════════════════════════════════════════════════════
  --  The npm equivalent of crates.nvim: current vs latest version, inline.
  {
    "vuki656/package-info.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    event = { "BufRead package.json" },
    opts = { package_manager = "npm", hide_up_to_date = true },
    keys = {
      {
        "<leader>ns",
        function()
          require("package-info").show()
        end,
        desc = "npm: show versions",
      },
      {
        "<leader>nu",
        function()
          require("package-info").update()
        end,
        desc = "npm: update package",
      },
      {
        "<leader>ni",
        function()
          require("package-info").install()
        end,
        desc = "npm: install package",
      },
      {
        "<leader>nc",
        function()
          require("package-info").change_version()
        end,
        desc = "npm: change version",
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  NOTES — things that are deliberately NOT plugins
  -- ══════════════════════════════════════════════════════════════════════════
  --
  --  Twig:
  --    * filetype detection  -> vim.filetype.add in lua/config/options.lua
  --    * comment string,indent -> ftplugin/twig.lua
  --    * highlighting        -> treesitter `twig` parser
  --    * formatting/linting  -> djlint (plugins/format.lua)
  --    * completion (optional): there is a twiggy_language_server
  --      (npm @moetelo/twiggy) giving Twig function/filter and Symfony route
  --      completion. Its Mason registry entry has been inconsistent, so it is
  --      not in ensure_installed. To enable:
  --          :MasonInstall twiggy-language-server
  --      then add "twiggy_language_server" to ensure_installed in
  --      plugins/lsp.lua and create after/lsp/twiggy_language_server.lua.
  --
  --  Tailwind class sorting:
  --    No Neovim plugin needed — install the prettier plugin in the project:
  --        npm i -D prettier prettier-plugin-tailwindcss
  --    and add to .prettierrc:  { "plugins": ["prettier-plugin-tailwindcss"] }
  --    conform's prettier/prettierd run will then sort classes on save.
  --
  --  Auto-closing JSX/Vue/Twig tags:
  --    Handled by nvim-ts-autotag, configured in plugins/treesitter.lua.
}
