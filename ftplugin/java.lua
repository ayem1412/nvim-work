-- ============================================================================
--  ftplugin/java.lua  —  starts jdtls for every Java buffer
-- ----------------------------------------------------------------------------
--  WHY THIS IS AN ftplugin AND NOT A PLUGIN SPEC
--  Files in ftplugin/<filetype>.lua run once per buffer of that filetype. That
--  is exactly what jdtls needs: it must be told the project root for THIS file,
--  and it keeps a separate on-disk index ("workspace") per project. A single
--  global setup() call cannot express that.
--
--  Flow on opening a .java file:
--    1. Find the project root (pom.xml / build.gradle / .git / mvnw / gradlew)
--    2. Derive a unique workspace directory from that root
--    3. Collect DAP + test + Spring Boot "bundles"
--    4. Build the java command line (platform-specific config dir!)
--    5. jdtls.start_or_attach() — reuses an existing client for the same root
--
--  PREREQUISITE: a JDK 17+ on PATH (JDT-LS itself needs 17+, even if your
--  project targets 8/11 — see `runtimes` below for compiling against older
--  versions). Verify with `java -version`.
-- ============================================================================

local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then
  return -- nvim-jdtls not installed yet (first launch); nothing to do
end

local plat = require("config.platform")

-- ── 1. Project root ─────────────────────────────────────────────────────────
-- Order matters: prefer a build file over .git, because in a multi-module
-- monorepo .git is at the top and each module has its own pom.xml. Using .git
-- would make jdtls index the whole repo as one project.
local root_markers = {
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "mvnw",
  "gradlew",
  ".git",
}
local root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
if not root_dir then
  return -- a stray .java file outside any project; don't start a server
end

-- ── 2. Per-project workspace ────────────────────────────────────────────────
-- jdtls writes a large index here. Sharing one directory between projects
-- corrupts it, producing the classic "The project is not a Java project" or
-- phantom compile errors. Naming it after the project directory keeps them
-- separate. If jdtls ever misbehaves, DELETE this directory and restart.
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

-- ── 3. Mason paths and the platform-specific config directory ───────────────
local jdtls_path = plat.mason_pkg("jdtls")

-- The launcher jar filename embeds a version + build timestamp, so it must be
-- globbed rather than hardcoded.
local launcher_jar = plat.first_glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- THE cross-platform gotcha: jdtls ships three configuration directories and
-- you must pass the one matching the OS. Passing config_linux on Windows fails
-- with an opaque OSGi error.
local config_dir
if plat.is_win then
  config_dir = jdtls_path .. "/config_win"
elseif plat.is_mac then
  config_dir = jdtls_path .. "/config_mac"
else
  config_dir = jdtls_path .. "/config_linux"
end

if not launcher_jar then
  vim.notify("jdtls launcher jar not found.\nRun :MasonInstall jdtls and reopen this file.", vim.log.levels.WARN)
  return
end

-- Lombok. Spring Boot projects use it constantly; without the javaagent every
-- @Data/@Getter/@Builder generated method shows as "cannot resolve".
local lombok_jar = jdtls_path .. "/lombok.jar"

-- ── 4. Bundles: debugging, testing, Spring Boot ─────────────────────────────
-- "Bundles" are OSGi plugins loaded into the JDT language server to extend it.
local bundles = {}

-- Spring Boot LSP (spring-boot.nvim). Gives application.yml/properties
-- completion, @RequestMapping navigation, and bean awareness.
local ok_boot, spring_boot = pcall(require, "spring_boot")
if ok_boot then
  vim.list_extend(bundles, spring_boot.java_extensions())
end

-- java-debug-adapter: the DAP server, exposed as a jdtls command.
vim.list_extend(
  bundles,
  plat.all_globs(plat.mason_pkg("java-debug-adapter") .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
)

-- vscode-java-test: JUnit/TestNG discovery and running.
-- The `!**-sources.jar` exclusion is required — including the sources jars
-- makes jdtls fail to start.
for _, jar in ipairs(plat.all_globs(plat.mason_pkg("java-test") .. "/extension/server/*.jar")) do
  if
    not jar:match("%-sources%.jar$")
    and not jar:match("com%.microsoft%.java%.test%.runner%-jar%-with%-dependencies%.jar$")
  then
    table.insert(bundles, jar)
  end
end

-- ── 5. The command line ─────────────────────────────────────────────────────
local cmd = {
  -- Use a specific JDK if JAVA_HOME points somewhere odd:
  --   plat.is_win and "C:/Program Files/Java/jdk-21/bin/java.exe" or "java",
  "java",

  -- JVM flags required by the Eclipse JDT server.
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.protocol=true",
  "-Dlog.level=ALL",
  -- Use UTF-8 for source files regardless of the platform default codepage
  -- (Windows defaults to CP-1252, which mangles non-ASCII string literals).
  "-Dfile.encoding=UTF-8",
  -- Java 17+ module system needs these opens for JDT's reflection.
  "--add-modules=ALL-SYSTEM",
  "--add-opens",
  "java.base/java.util=ALL-UNNAMED",
  "--add-opens",
  "java.base/java.lang=ALL-UNNAMED",
  -- Memory. 2GB is enough for most Spring Boot services; raise for monorepos.
  "-Xmx2g",
  "-XX:+UseParallelGC",
  "-XX:GCTimeRatio=4",
  "-XX:AdaptiveSizePolicyWeight=90",
  "-XX:+UseStringDeduplication",
}

-- Lombok must be a javaagent, and it must come BEFORE -jar.
if plat.exists(lombok_jar) then
  table.insert(cmd, "-javaagent:" .. lombok_jar)
end

vim.list_extend(cmd, {
  "-jar",
  launcher_jar,
  "-configuration",
  config_dir,
  "-data",
  workspace_dir,
})

-- ── 6. Settings ─────────────────────────────────────────────────────────────
local settings = {
  java = {
    -- Which JDKs are available for compiling. jdtls itself runs on 17+, but a
    -- project can target an older release if you declare the runtime here.
    -- EDIT THESE PATHS to match your machines (or set them in
    -- lua/config/local.lua as vim.g.java_runtimes and they'll be used instead).
    configuration = {
      updateBuildConfiguration = "interactive", -- prompt on pom.xml change
      runtimes = vim.g.java_runtimes or {
        -- Example — adjust to what you actually have installed:
        -- { name = "JavaSE-17", path = "C:/Program Files/Java/jdk-17" },
        -- { name = "JavaSE-21", path = "C:/Program Files/Java/jdk-21", default = true },
      },
    },

    eclipse = { downloadSources = true }, -- fetch sources so goto-def works
    -- into dependencies
    maven = { downloadSources = true },
    implementationsCodeLens = { enabled = true },
    referencesCodeLens = { enabled = true },
    references = { includeDecompiledSources = true },

    -- ── Formatting ───────────────────────────────────────────────────────
    -- google-java-format runs via conform. If your team uses the Eclipse
    -- formatter XML instead, point at it here and remove `java` from
    -- formatters_by_ft in plugins/format.lua:
    -- format = {
    --   enabled = true,
    --   settings = {
    --     url = vim.fn.stdpath("config") .. "/eclipse-java-style.xml",
    --     profile = "GoogleStyle",
    --   },
    -- },
    format = { enabled = false },

    -- ── Inlay hints ──────────────────────────────────────────────────────
    inlayHints = { parameterNames = { enabled = "literals" } },

    -- ── Code generation ──────────────────────────────────────────────────
    -- Controls what :JdtGenerate* / the code actions produce.
    signatureHelp = { enabled = true, description = { enabled = true } },
    contentProvider = { preferred = "fernflower" }, -- decompiler for .class files
    sources = {
      organizeImports = {
        -- Collapse to `import java.util.*` only after 99 imports from one
        -- package, i.e. effectively never. Explicit imports are clearer and
        -- most style guides require them.
        starThreshold = 99,
        staticStarThreshold = 99,
      },
    },
    codeGeneration = {
      toString = {
        template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
      },
      hashCodeEquals = { useJava7Objects = true },
      useBlocks = true, -- always generate braces, even for one-line ifs
    },

    -- ── Completion ───────────────────────────────────────────────────────
    completion = {
      -- Never auto-import from these: they are almost always the wrong choice
      -- and pollute the import block.
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*",
        "sun.*",
      },
      -- Import ordering. This matches the common Spring/Google convention.
      importOrder = { "java", "javax", "jakarta", "com", "org" },
      favoriteStaticMembers = {
        "org.junit.jupiter.api.Assertions.*",
        "org.junit.jupiter.api.Assumptions.*",
        "org.junit.jupiter.api.DynamicTest.*",
        "org.mockito.Mockito.*",
        "org.mockito.ArgumentMatchers.*",
        "org.assertj.core.api.Assertions.*",
        "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
        "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
        "java.util.Objects.requireNonNull",
        "java.util.Objects.requireNonNullElse",
      },
    },

    -- Show a progress spinner while the (slow) initial project import runs.
    -- Without this, the first minute in a big project looks like a hang.
    project = {
      referencedLibraries = { "lib/**/*.jar" },
    },
  },
}

-- ── 7. Start ────────────────────────────────────────────────────────────────
local config = {
  cmd = cmd,
  root_dir = root_dir,
  settings = settings,
  -- capabilities are inherited from the vim.lsp.config("*") defaults set in
  -- plugins/lsp.lua, so blink.cmp's extra capabilities apply here too.
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  init_options = {
    bundles = bundles,
    -- Ask jdtls to send us project-import progress reports.
    extendedClientCapabilities = vim.tbl_deep_extend(
      "force",
      jdtls.extendedClientCapabilities or {},
      { resolveAdditionalTextEditsSupport = true, progressReportProvider = true }
    ),
  },

  on_attach = function(_, bufnr)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "Java: " .. desc })
    end
    local function vmap(lhs, rhs, desc)
      vim.keymap.set("v", lhs, rhs, { buffer = bufnr, desc = "Java: " .. desc })
    end

    -- ── jdtls-specific commands (not available via vim.lsp.buf) ──────────
    map("<leader>jo", jdtls.organize_imports, "Organize imports")
    map("<leader>jv", jdtls.extract_variable, "Extract variable")
    map("<leader>jc", jdtls.extract_constant, "Extract constant")
    vmap("<leader>jv", function()
      jdtls.extract_variable()
    end, "Extract variable (selection)")
    vmap("<leader>jc", function()
      jdtls.extract_constant()
    end, "Extract constant (selection)")
    vmap("<leader>jm", function()
      jdtls.extract_method()
    end, "Extract method (selection)")

    -- Jump between Foo.java and FooTest.java.
    map("<leader>jt", function()
      jdtls.tests.goto_subjects()
    end, "Goto test / subject")

    -- ── Testing + debugging ──────────────────────────────────────────────
    -- These come from the java-test / java-debug bundles loaded above.
    map("<leader>dtc", jdtls.test_class, "Debug: test class")
    map("<leader>dtm", jdtls.test_nearest_method, "Debug: nearest test method")

    -- Register DAP configurations derived from the project (main classes,
    -- test runners). Must run AFTER the server has attached.
    local ok_dap = pcall(require, "dap")
    if ok_dap then
      -- `config_overrides` applies to every generated configuration.
      jdtls.setup_dap({ hotcodereplace = "auto", config_overrides = {} })
      -- Discover main classes so `<leader>dc` offers "Launch Application".
      pcall(require("jdtls.dap").setup_dap_main_class_configs)
    end
  end,
}

jdtls.start_or_attach(config)

-- ── 8. Java buffer-local options ────────────────────────────────────────────
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true
vim.opt_local.colorcolumn = "120"
