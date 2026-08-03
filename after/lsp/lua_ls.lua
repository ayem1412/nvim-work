-- ============================================================================
--  after/lsp/lua_ls.lua  —  Lua
-- ----------------------------------------------------------------------------
--  Note how little is here: lazydev.nvim (see plugins/lsp.lua) handles the
--  hard part — making LuaLS understand the Neovim API and your plugin types —
--  lazily, so we do NOT stuff the whole runtime into `workspace.library`.
-- ============================================================================

return {
  settings = {
    Lua = {
      runtime = {
        -- Neovim embeds LuaJIT, which is Lua 5.1 + extensions. Telling LuaLS
        -- this stops it suggesting Lua 5.4-only APIs that will fail at runtime.
        version = "LuaJIT",
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      workspace = {
        -- Don't prompt "do you want to configure this third-party library?"
        -- every time you open a file in a plugin's directory.
        checkThirdParty = false,
        -- lazydev supplies the library paths on demand; leaving this empty
        -- keeps LuaLS's memory footprint small.
        library = {},
      },
      diagnostics = {
        -- `vim` is injected by Neovim, not declared anywhere LuaLS can see.
        globals = { "vim", "Snacks" },
        -- These two are noisy in plugin configs and rarely indicate a bug.
        disable = { "missing-fields", "incomplete-signature-doc" },
        unusedLocalExclude = { "_*" }, -- allow `local _ = ...` and `_unused`
      },
      completion = {
        -- Insert the full call snippet with parameter placeholders, e.g.
        -- `vim.keymap.set(mode, lhs, rhs)` rather than just `vim.keymap.set`.
        callSnippet = "Replace",
        keywordSnippet = "Replace",
      },
      hint = {
        enable = true,
        arrayIndex = "Disable", -- `[1]:` markers on every table entry are noise
        setType = true,
        paramName = "Literal", -- only hint parameter names for literal args
        paramType = true,
      },
      format = {
        -- stylua does the formatting (see plugins/format.lua). LuaLS's own
        -- formatter is also disabled via the no_format table in plugins/lsp.lua;
        -- this is belt and braces.
        enable = false,
      },
      telemetry = { enable = false },
    },
  },
}
