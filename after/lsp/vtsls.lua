-- ============================================================================
--  after/lsp/vtsls.lua  —  TypeScript / JavaScript / React / (and Vue's TS)
-- ----------------------------------------------------------------------------
--  THE VUE WIRING LIVES HERE. This is the piece people get wrong.
--
--  In Volar v3 "hybrid mode", the TypeScript server is responsible for all TS
--  and JS — including the <script> block of a .vue file. It can only do that
--  if the @vue/typescript-plugin is loaded INTO it. That is what
--  `settings.vtsls.tsserver.globalPlugins` below does.
--
--  Three things must all be true or Vue support silently half-works:
--    1. `location` points at the @vue/language-server directory (NOT the
--       plugin directory, NOT the binary).
--    2. `languages` includes "vue".
--    3. "vue" is in vtsls's `filetypes`, so vtsls actually attaches to .vue
--       buffers in the first place.
--
--  Symptoms of getting it wrong:
--    * "Could not find ts_ls, vtsls or typescript-tools lsp client required by
--      vue_ls"  -> vtsls isn't attached to the .vue buffer (point 3)
--    * Types work in .ts but every import from a .vue file is `any`
--                             -> the plugin isn't loaded (points 1/2)
--
--  Version match matters: @vue/typescript-plugin and @vue/language-server must
--  be the same version. Installing vue_ls through Mason keeps them in sync
--  because they ship together in the vue-language-server package.
-- ============================================================================

local plat = require("config.platform")

-- Mason installs vue-language-server as an npm package; the TS plugin lives
-- inside it. Using the Mason path (rather than a global npm install) means the
-- Windows and Linux machines resolve it identically.
local vue_language_server_path = plat.mason_pkg("vue-language-server") .. "/node_modules/@vue/language-server"

local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

return {

  -- ── tsserver-only commands ─────────────────────────────────────────────
  --  These are NOT in vim.lsp.buf: they are tsserver commands exposed through
  --  workspace/executeCommand. They live here (rather than in a plugin spec)
  --  because this is the file that owns the vtsls client.
  on_attach = function(client, bufnr)
    local function exec(command)
      return function()
        client:exec_cmd({
          title = command,
          command = command,
          arguments = { vim.uri_from_bufnr(bufnr) },
        }, { bufnr = bufnr })
      end
    end
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "TS: " .. desc })
    end

    map("<leader>co", exec("typescript.organizeImports"), "Organize imports")
    map("<leader>cM", exec("typescript.addMissingImports"), "Add missing imports")
    map("<leader>cu", exec("typescript.removeUnusedImports"), "Remove unused imports")
    map("<leader>cF", exec("typescript.fixAll"), "Fix all fixable problems")
    map("<leader>cD", exec("typescript.selectTypeScriptVersion"), "Select TS version")

    -- "Go to source definition" follows through .d.ts declaration files to the
    -- real implementation. Indispensable with typed npm packages, where plain
    -- `gd` lands you in a type stub.
    -- NOTE: bound to <leader>cd, not `gs` — `gs` is mini.surround's prefix
    -- (gsa/gsd/gsr), and a bare `gs` mapping makes every surround command wait
    -- for 'timeoutlen' before firing.
    map("<leader>cd", function()
      local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
      client:exec_cmd({
        title = "Go to source definition",
        command = "typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
      }, { bufnr = bufnr })
    end, "Goto source definition")
  end,

  -- vtsls must attach to .vue buffers, not just .ts/.tsx.
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "vue",
  },

  settings = {
    -- ── vtsls-specific ───────────────────────────────────────────────────
    vtsls = {
      -- Load the Vue plugin into tsserver. `globalPlugins` (rather than a
      -- per-project tsconfig plugin entry) means it works without touching
      -- every project's tsconfig.json.
      tsserver = {
        globalPlugins = { vue_plugin },
      },
      -- Auto-update imports when you move/rename a file (works with
      -- Snacks.rename.rename_file / oil.nvim renames).
      autoUseWorkspaceTsdk = true,
      experimental = {
        -- Render the "completion detail" (types, JSDoc) eagerly. Costs a bit
        -- of latency, gains a lot of clarity on overloaded functions.
        completion = { enableServerSideFuzzyMatch = true },
        maxInlayHintLength = 30,
      },
    },

    -- ── Shared TypeScript + JavaScript settings ──────────────────────────
    -- vtsls accepts the same keys VS Code uses, under `typescript` and
    -- `javascript`. They must be specified separately — a setting under
    -- `typescript` does not apply to .js files.
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      preferences = {
        -- Use relative imports inside the project. Change to "non-relative"
        -- if your project uses path aliases (@/components/...).
        importModuleSpecifier = "shortest",
        preferTypeOnlyAutoImports = true, -- `import type { X }` where possible
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" }, -- only for literal arguments
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false }, -- noisy; the type is usually obvious
      },
      -- Show the whole workspace's errors, not just open files. Slower on a
      -- huge monorepo — set to "openEditors" there.
      tsserver = {
        maxTsServerMemory = 8192, -- MB. Raise for very large codebases.
      },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
  },
}
