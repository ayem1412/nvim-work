-- ============================================================================
--  lua/plugins/git.lua
-- ----------------------------------------------------------------------------
--  Division of labour:
--    gitsigns  -> in-buffer signs, hunk staging/reset, inline blame
--    lazygit   -> everything else (commit, rebase, stash, push, branches)
--                 launched via Snacks.lazygit (<leader>gg)
--    diffview  -> reviewing a whole PR/merge, resolving conflicts
--  Deliberately no fugitive/neogit: lazygit covers that ground better and is
--  one binary that works identically on Windows and Linux.
-- ============================================================================

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged_enable = true, -- distinguish staged from unstaged hunks
      current_line_blame = false, -- toggle with <leader>gB; always-on is noisy
      current_line_blame_opts = {
        virt_text_pos = "eol",
        delay = 300,
        ignore_whitespace = true,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> · <summary>",
      -- On Windows, git status over a large repo can be slow. Increase the
      -- debounce so gitsigns doesn't re-run git on every keystroke.
      update_debounce = require("config.platform").is_win and 500 or 100,
      preview_config = { border = "rounded" },

      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = "Git: " .. desc })
        end

        -- ── Navigation ────────────────────────────────────────────────────
        -- ]h / [h jump between hunks. Inside a diff buffer they fall back to
        -- Vim's own ]c/[c so the mapping works everywhere.
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous hunk")

        -- ── Staging ───────────────────────────────────────────────────────
        map("n", "<leader>ghs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>ghr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>ghs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected lines")
        map("v", "<leader>ghr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected lines")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")

        -- ── Inspection ────────────────────────────────────────────────────
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, "Blame line (full)")
        map("n", "<leader>ghd", gs.diffthis, "Diff against index")
        map("n", "<leader>ghD", function()
          gs.diffthis("~")
        end, "Diff against last commit")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")

        -- ── Textobject ────────────────────────────────────────────────────
        -- `dih` / `vih` operate on the hunk under the cursor.
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Inner hunk")
      end,
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  diffview — full-project diffs and merge-conflict resolution
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    opts = {
      enhanced_diff_hl = true,
      view = {
        -- 3-way merge layout is what makes conflict resolution bearable:
        -- OURS | RESULT | THEIRS with the base available too.
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview (working tree)" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
      -- NOT <leader>gh: that is gitsigns' hunk prefix (ghs/ghr/ghp/...).
      { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>gA", "<cmd>DiffviewFileHistory<cr>", desc = "File history (branch)" },
      { "<leader>gm", "<cmd>DiffviewOpen<cr>", desc = "Resolve merge conflicts" },
    },
  },
}
