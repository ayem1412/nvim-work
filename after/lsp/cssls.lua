-- ============================================================================
--  after/lsp/cssls.lua
-- ============================================================================

return {
  settings = {
    css = {
      validate = true,
      -- Tailwind's @tailwind / @apply / @screen directives are not standard
      -- CSS, so the validator flags them. "ignore" silences that without
      -- disabling validation entirely.
      lint = { unknownAtRules = "ignore" },
    },
    scss = {
      validate = true,
      lint = { unknownAtRules = "ignore" },
    },
    less = { validate = true },
  },
}
