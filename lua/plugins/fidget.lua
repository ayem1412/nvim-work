-- ============================================================================
--  lua/plugins/fidget.lua  —  LSP progress UI
-- ----------------------------------------------------------------------------
--  A small, unobtrusive corner window showing what each attached LSP server
--  is doing right now — "rust_analyzer: indexing (340/812)", "jdtls: Validate
--  12/40", "vtsls: loading project" — anything reported over the LSP
--  `$/progress` notification. Without this, that information is silently
--  discarded; you just see the editor "not respond" for a few seconds with no
--  indication of why.
--
--  NOT a general notification replacement. snacks.nvim already owns
--  `vim.notify` (see plugins/editor.lua, `notifier`). fidget's own
--  notification subsystem is left OFF (`override_vim_notify = false`, also
--  the default) so the two don't compete for the same corner of the screen or
--  double up on every `vim.notify()` call.
-- ============================================================================

return {
  "j-hui/fidget.nvim",
  event = "LspAttach", -- nothing to show until a server actually attaches
  opts = {
    progress = {
      display = {
        render_limit = 6, -- max concurrent progress items shown at once
        done_ttl = 3, -- seconds a "done" line lingers before disappearing
        done_icon = "✓",
        progress_icon = { pattern = "dots", period = 1 },
      },
      -- Some servers (jdtls and rust-analyzer especially) report progress in
      -- bursts; the default poll rate is plenty, no need to tighten it.
      ignore_done_already = false,
      ignore_empty_message = true,
    },
    notification = {
      window = {
        winblend = 0, -- opaque — matches the rest of the UI, no see-through
        border = "rounded",
        relative = "editor",
        align = "bottom", -- bottom-right, out of the way of code and the
        -- statusline/bufferline at top and bottom-left
      },
      -- MUST stay false: snacks.nvim's notifier is the general vim.notify
      -- handler for this config (plugins/editor.lua). If both claim
      -- vim.notify you get either duplicated notifications or a silent race
      -- over which one wins depending on plugin load order.
      override_vim_notify = false,
    },
  },
}
