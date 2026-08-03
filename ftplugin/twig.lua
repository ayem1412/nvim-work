-- ============================================================================
--  ftplugin/twig.lua
-- ----------------------------------------------------------------------------
--  Twig (and Phalcon Volt, which is registered as `twig` in config/options.lua).
-- ============================================================================

-- `gc` should produce {# ... #}, not <!-- ... -->.
vim.bo.commentstring = "{# %s #}"

vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.expandtab = true

-- Match {% block %} / {% endblock %} with `%`. matchit is disabled in
-- init.lua's disabled_plugins, so this is informational — treesitter's
-- textobjects cover the same ground via `ai`/`ii`.
vim.opt_local.matchpairs:append("<:>")
