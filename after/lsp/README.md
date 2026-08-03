# `after/lsp/` — per-server LSP configuration

Every `<name>.lua` here returns a `vim.lsp.Config` table. Neovim auto-loads it
when `vim.lsp.enable("<name>")` runs (which mason-lspconfig does for you).

**Why `after/lsp/` and not `lsp/`?**
`nvim-lspconfig` ships its own `lsp/<name>.lua` with the default `cmd`,
`filetypes` and `root_markers`. Files found later on the `runtimepath` win, and
`after/` is loaded last — so putting your overrides here guarantees they beat
the plugin defaults instead of racing them.

The tables here are **merged** with lspconfig's, so you only specify what you
want to change. You do not need to repeat `cmd` or `filetypes` unless you are
deliberately overriding them.
