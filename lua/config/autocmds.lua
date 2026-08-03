-- ============================================================================
--  lua/config/autocmds.lua  —  event-driven behaviour
-- ----------------------------------------------------------------------------
--  Every autocmd goes into a NAMED augroup created with { clear = true }.
--  Why: if you `:source` this file (or a plugin reloads it), the group is wiped
--  first, so autocmds are not registered twice. Un-grouped autocmds accumulate
--  and you end up with a callback firing five times.
-- ============================================================================

local function augroup(name)
  return vim.api.nvim_create_augroup("my_" .. name, { clear = true })
end

-- ── Highlight on yank ───────────────────────────────────────────────────────
-- Brief visual flash of exactly what was yanked. Best "is this on by default
-- yet" feature in Neovim — invaluable for verifying complex motions like `y2i{`.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    -- vim.hl in 0.11+, vim.highlight before it. pcall keeps both working.
    (vim.hl or vim.highlight).on_yank({ timeout = 150 })
  end,
})

-- ── Restore cursor position ─────────────────────────────────────────────────
-- Reopen a file, land where you left off. `'"` is the mark Vim sets on exit.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("restore_cursor"),
  callback = function(ev)
    -- Skip filetypes where jumping is wrong (commit messages should start at
    -- line 1 so you type the subject, not amend an old line).
    local exclude = { "gitcommit", "gitrebase", "svn", "hgcommit" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) then
      return
    end
    -- Guard against a stale mark pointing past the end of a shortened file.
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
      vim.cmd("normal! zvzz") -- open folds around it and centre
    end
  end,
})

-- ── Trim trailing whitespace on save ────────────────────────────────────────
-- conform.nvim handles this for languages with a real formatter. This catches
-- everything else (SQL scratch files, .env, plain text, config files).
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  callback = function()
    -- Never touch markdown: two trailing spaces are a meaningful line break.
    if vim.bo.filetype == "markdown" or vim.bo.filetype == "diff" then
      return
    end
    local view = vim.fn.winsaveview() -- preserve cursor + scroll position
    vim.cmd([[keeppatterns %s/\s\+$//e]]) -- keeppatterns = don't pollute search history
    vim.fn.winrestview(view)
  end,
})

-- ── Auto-create missing parent directories on save ──────────────────────────
-- `:e src/deeply/nested/New.java` then `:w` normally fails with E212.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return -- skip URLs / oil:// / fugitive:// style buffers
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ── Close throwaway windows with `q` ────────────────────────────────────────
-- Every plugin help/output window should close on `q`, not `:q<cr>`.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "man",
    "qf",
    "lspinfo",
    "checkhealth",
    "startuptime",
    "notify",
    "query",
    "spectre_panel",
    "neotest-output",
    "neotest-summary",
    "dbout", -- vim-dadbod query output
    "gitsigns-blame",
    "fugitive",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false -- keep it out of :bnext rotation
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end, { buffer = ev.buf, silent = true, desc = "Close window" })
    end)
  end,
})

-- ── Per-language indentation ────────────────────────────────────────────────
-- Two-space languages (web stack) vs four-space (backend) vs tabs (Go).
-- This is simpler and more predictable than a full editorconfig dependency,
-- but a project's .editorconfig will still win if you install editorconfig
-- support — Neovim 0.9+ has it BUILT IN and respects it automatically.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_two_space"),
  pattern = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "html",
    "css",
    "scss",
    "less",
    "json",
    "jsonc",
    "yaml",
    "twig",
    "markdown",
    "lua",
    "toml",
    "xml",
  },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
    vim.bo.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_go_tabs"),
  pattern = { "go", "gomod", "gowork", "make" },
  callback = function()
    -- Go is gofmt-canonical: TABS, width 4 for display.
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

-- ── Wrap + spell in prose buffers ───────────────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("prose"),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.linebreak = true -- wrap at word boundaries, not mid-word
  end,
})

-- ── Reload files changed outside Neovim ─────────────────────────────────────
-- Essential when you `git checkout` / `git pull` in another terminal, or when
-- a formatter/codegen tool rewrites files (Spring Boot regen, `cargo fmt`).
-- `autoread` alone is not enough — Neovim only checks on certain events.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})
vim.o.autoread = true

-- ── Resize splits when the terminal window changes ──────────────────────────
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- ── Disable expensive features in huge files ────────────────────────────────
-- Treesitter + LSP + syntax on a 10MB SQL dump will freeze Neovim. snacks.nvim's
-- `bigfile` module handles most of this, but this is a plugin-free safety net
-- (and it catches files snacks' threshold misses).
vim.api.nvim_create_autocmd("BufReadPre", {
  group = augroup("bigfile"),
  callback = function(ev)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
    if ok and stats and stats.size > 1024 * 1024 * 2 then -- > 2 MB
      vim.b[ev.buf].bigfile = true
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      vim.opt_local.undofile = false
      vim.opt_local.swapfile = false
      vim.schedule(function()
        vim.bo[ev.buf].syntax = ""
      end)
    end
  end,
})

-- ── Terminal buffers ────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup("term"),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})
