-- ============================================================================
--  ftplugin/php.lua
-- ============================================================================

-- PSR-12: 4 spaces.
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

-- PSR-12 has a 120-column soft limit.
vim.opt_local.colorcolumn = "120"

-- Treat `$` as part of a word, so `w`, `*`, `diw` and `ciw` operate on
-- `$userId` as a single token instead of stopping at the sigil. This one line
-- removes a surprising amount of daily friction in PHP.
vim.opt_local.iskeyword:append("$")

-- `gc` in a .php file containing inline HTML: treesitter keeps 'commentstring'
-- accurate per-region automatically (// inside <?php, <!-- --> inside HTML),
-- so nothing to set here.
