-- ============================================================================
--  lua/config/keymaps.lua  —  global mappings only
-- ----------------------------------------------------------------------------
--  Plugin-specific mappings live in the plugin's own spec (`keys = {...}`),
--  because that is what lets lazy.nvim lazy-load the plugin on first keypress.
--  Only mappings that need no plugin belong here.
--
--  Every mapping sets `desc`, because which-key renders `desc` in its popup.
--  A mapping without a description is invisible in the help menu.
-- ============================================================================

local map = vim.keymap.set

map({ "n", "i" }, "<C-a>", "<Esc>ggVG", { desc = "Select all" })

-- ── Sanity ──────────────────────────────────────────────────────────────────
-- Clear search highlight AND dismiss any snacks/noice notification with <Esc>.
-- `nohlsearch` alone leaves the highlight until the next search.
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Make Y behave like C and D (yank to end of line) instead of being yy's twin.
map("n", "Y", "y$", { desc = "Yank to end of line" })

-- Keep the cursor centred when jumping half a page or through search results.
-- Without `zz` you constantly lose your place after `n`.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centred)" })
map("n", "n", "nzzzv", { desc = "Next search result (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centred)" })

-- Undo break-points. By default `u` undoes an entire insert session; inserting
-- an explicit undo break after punctuation gives you finer-grained undo.
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- ── Clipboard (explicit, not global) ────────────────────────────────────────
-- Because `clipboard=unnamedplus` is NOT set globally (see options.lua), these
-- give deliberate access to the system clipboard without letting every `x` and
-- `diw` overwrite it.
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
-- Paste is <leader>v (as in Ctrl+V), NOT <leader>p — <leader>p is the PHP
-- refactoring prefix (lua/plugins/lang/php.lua) and a bare <leader>p mapping
-- would make every PHP command wait for 'timeoutlen'.
map({ "n", "v" }, "<leader>v", [["+p]], { desc = "Paste from system clipboard" })
map("n", "<leader>V", [["+P]], { desc = "Paste before from system clipboard" })
-- Paste over a visual selection WITHOUT clobbering the unnamed register.
-- The default `p` in visual mode swaps the selection into your register, so
-- pasting the same thing twice fails. `"_d` deletes into the black hole first.
map("x", "<leader>P", [["_dP]], { desc = "Paste (keep register)" })
-- Delete without clobbering the unnamed register.
-- NOTE: <leader>d is NOT used for this — it is the debug prefix (plugins/dap.lua).
-- `x` almost always means "get rid of this character", never "copy it", so
-- routing it to the black-hole register is a pure win.
map({ "n", "v" }, "x", [["_x]], { desc = "Delete char (no yank)" })
-- For anything larger, the explicit form is two extra keys: "_dd, "_diw, ...

-- ── Moving lines ────────────────────────────────────────────────────────────
-- `:m` moves lines; `gv=gv` re-selects and re-indents so the block keeps its
-- indentation when it moves into/out of a nested scope.
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })

-- Keep the cursor in place when joining lines (default J moves it to the seam).
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Stay in visual mode after indenting, so you can press < / > repeatedly.
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- ── Window navigation ───────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
-- Resize with arrows (no plugin needed).
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })
-- Splits
map("n", "<leader>|", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>-", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

-- ── Buffers ─────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Alternate buffer" })

-- ── Files ───────────────────────────────────────────────────────────────────
-- Write only if modified (`:w` on an unmodified buffer still touches mtime,
-- which can retrigger file watchers like vite/nodemon/webpack).
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>update<cr><esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- ── Quickfix / location list ────────────────────────────────────────────────
-- Used heavily by :grep, LSP references, and nvim-lint.
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix list" })
map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location list" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous quickfix item" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix item" })

-- ── Diagnostics ─────────────────────────────────────────────────────────────
-- NOTE: Neovim 0.11+ already maps ]d / [d and <C-w>d natively. These add the
-- severity-filtered variants, which are what you actually want on a large
-- codebase full of warnings.
local function diag_goto(count, severity)
  return function()
    vim.diagnostic.jump({ count = count, severity = severity and vim.diagnostic.severity[severity] or nil })
  end
end
map("n", "]e", diag_goto(1, "ERROR"), { desc = "Next error" })
map("n", "[e", diag_goto(-1, "ERROR"), { desc = "Previous error" })
map("n", "]w", diag_goto(1, "WARN"), { desc = "Next warning" })
map("n", "[w", diag_goto(-1, "WARN"), { desc = "Previous warning" })

-- ── Terminal ────────────────────────────────────────────────────────────────
-- Escape terminal-insert mode. Without this you are trapped in :terminal.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Window left" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Window down" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Window up" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Window right" })

-- ── Toggles ─────────────────────────────────────────────────────────────────
-- NOTE: most UI toggles (<leader>uw wrap, <leader>uS spell, <leader>ud
-- diagnostics, <leader>uh inlay hints, <leader>ug indent guides, ...) are
-- registered by snacks.toggle in plugins/editor.lua, so they appear in
-- which-key with proper on/off state. They are deliberately NOT duplicated
-- here — defining the same lhs twice means whichever loads last silently wins,
-- which is exactly the kind of bug that is miserable to track down.
--
-- Only toggles with no snacks equivalent belong here.

-- Toggle between the two most useful colour-column positions, for when you
-- switch from a 120-col Java project to an 80-col one.
map("n", "<leader>uc", function()
  vim.opt_local.colorcolumn = (vim.wo.colorcolumn == "120") and "80" or "120"
end, { desc = "Toggle colorcolumn 80/120" })

-- ── Lazy / Mason ────────────────────────────────────────────────────────────
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy (plugin manager)" })
map("n", "<leader>M", "<cmd>Mason<cr>", { desc = "Mason (tool installer)" })
map("n", "<leader>ci", "<cmd>checkhealth<cr>", { desc = "Checkhealth" })
