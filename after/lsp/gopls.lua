-- ============================================================================
--  after/lsp/gopls.lua  —  Go
-- ============================================================================

return {
  -- Go workspaces: go.work matters for multi-module repos, and gopls will pick
  -- the wrong root without it listed first.
  root_markers = { "go.work", "go.mod", ".git" },

  settings = {
    gopls = {
      -- ── Formatting ─────────────────────────────────────────────────────
      -- gofumpt is gofmt plus a set of stricter, uncontroversial rules.
      -- conform runs goimports+gofumpt on save; this makes gopls's own
      -- suggestions consistent with that.
      gofumpt = true,

      -- ── Completion ─────────────────────────────────────────────────────
      usePlaceholders = true, -- fill function args as snippet placeholders
      completeUnimported = true, -- offer symbols from packages not yet imported
      -- and add the import automatically. This is
      -- the single best gopls setting.
      matcher = "Fuzzy",
      experimentalPostfixCompletions = true, -- `x.for`, `err.if`, `s.print`

      -- ── Analysis ───────────────────────────────────────────────────────
      staticcheck = true, -- enable the staticcheck analyzer suite
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        nilness = true, -- catches `if err != nil` when err is always nil
        shadow = true, -- catches the classic `err :=` shadowing bug
        fieldalignment = false, -- noisy; only useful when optimising memory
        unusedvariable = true,
      },
      -- Report vulnerabilities from the Go vulnerability database as
      -- diagnostics. "Imports" is the cheap mode; "Import" scans more deeply.
      vulncheck = "Imports",

      -- ── Inlay hints ────────────────────────────────────────────────────
      -- Off at the buffer level by default (see the LspAttach handler);
      -- these define WHAT is shown when you toggle them on with <leader>uh.
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },

      -- ── Code lenses ────────────────────────────────────────────────────
      -- Clickable "run test" / "generate" / "tidy" actions above the relevant
      -- lines. Run the one under the cursor with <leader>cl.
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },

      -- ── Performance ────────────────────────────────────────────────────
      -- Don't index build artefacts or node_modules in a mixed repo.
      directoryFilters = { "-**/node_modules", "-**/.git", "-**/vendor", "-**/bin", "-**/dist" },
      semanticTokens = true, -- richer highlighting than treesitter alone
      symbolMatcher = "fuzzy",
      buildFlags = { "-tags=integration" }, -- analyse build-tagged test files too
    },
  },
}
