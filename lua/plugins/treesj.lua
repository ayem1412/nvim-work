-- ============================================================================
--  lua/plugins/treesj.lua  —  split / join blocks of code
-- ----------------------------------------------------------------------------
--  Toggles a block between one-line and multi-line form using treesitter, so
--  it works across every language you have a parser for:
--
--    { a, b, c }                    <->    {
--                                            a,
--                                            b,
--                                            c,
--                                          }
--
--  Works on objects, arrays, function arguments, JSX/Vue attributes, Rust
--  structs, Go composite literals, PHP arrays, SQL column lists — anything the
--  parser recognises as a splittable node. Call it from anywhere inside the
--  block; the cursor doesn't need to be on the bracket.
--
--  KEYMAPS (default <space>m/j/s are DISABLED to avoid colliding with the
--  leader menu — <leader>m is Mason). Bound under the <leader>c "code" prefix:
--      <leader>cj   toggle split/join (autodetects which)
--      <leader>cJ   force join  (collapse to one line)
--      <leader>cS   force split (expand to multi-line)
--  All three support `.` repeat.
-- ============================================================================

return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  -- Lazy-load only when one of the keymaps is pressed.
  keys = { "<space>m", "<space>j", "<space>s" },
  opts = {
    -- We bind our own keys above; don't also register <space>m/j/s.
    use_default_keymaps = false,
    -- Don't reformat a node that contains a syntax error — the result would be
    -- garbage. Better to no-op and let you fix the error first.
    check_syntax_error = true,
    -- If joining would produce a line longer than this, treesj refuses to join
    -- and leaves it split. 120 matches your PSR-12 / general column guide.
    max_join_length = 120,
    -- Cursor follows the text it was called on, rather than jumping to the
    -- start/end of the reformatted node.
    cursor_behavior = "hold",
    -- Whether to notify when a node can't be formatted (no handler for that
    -- node type). Off — it's noisy when you hit a key on an unsupported block.
    notify = false,
    -- `dot_repeat = true` is the default; `.` repeats the last split/join.
    dot_repeat = true,
  },
}
