-- ============================================================================
--  ftplugin/go.lua
-- ----------------------------------------------------------------------------
--  Go is gofmt-canonical: real tabs, no debate. The FileType autocmd in
--  config/autocmds.lua sets this too; having it here as well means it also
--  applies to buffers created before that autocmd group is registered.
-- ============================================================================

vim.bo.expandtab = false
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4

-- Go's error idiom means very long lines are common and acceptable.
vim.opt_local.colorcolumn = "120"

-- Go tooling helpers (struct tags, iferr, test generation) are under the
-- <leader>G prefix — see lua/plugins/lang/go.lua.
-- Debugging: <leader>dgt debugs the test function under the cursor.
