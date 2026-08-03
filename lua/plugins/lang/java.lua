-- ============================================================================
--  lua/plugins/lang/java.lua  —  Java + Spring Boot
-- ----------------------------------------------------------------------------
--  Java is the one language that CANNOT be driven by vim.lsp.enable(). jdtls
--  (the Eclipse JDT language server) needs:
--    * a separate, per-project data directory ("workspace"), or it corrupts
--      its index when you switch projects
--    * a launcher jar whose filename contains a version stamp
--    * a platform-specific configuration directory
--    * DAP/test "bundles" passed as init_options
--
--  nvim-jdtls exists to do all of that. It is started from ftplugin/java.lua
--  (which runs once per Java buffer) — see that file for the actual launch.
--  This file only declares the plugins.
--
--  That is why "jdtls" is in `automatic_enable.exclude` in plugins/lsp.lua:
--  if mason-lspconfig also enabled it, you would get two competing servers.
-- ============================================================================

return {
  -- ══════════════════════════════════════════════════════════════════════════
  --  nvim-jdtls
  -- ══════════════════════════════════════════════════════════════════════════
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = { "mfussenegger/nvim-dap" },
    -- No opts/config: everything happens in ftplugin/java.lua. Declaring it
    -- here just makes lazy.nvim install it and put it on the runtimepath
    -- before the first Java buffer opens.
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  spring-boot.nvim  —  the Spring Boot language server (STS4) for Neovim
  -- ══════════════════════════════════════════════════════════════════════════
  --  This is what gives you, on top of plain Java support:
  --    * completion and validation inside application.properties /
  --      application.yml, with docs for every Spring property
  --    * @RequestMapping route awareness (jump to the handler for a URL)
  --    * bean/dependency-injection navigation
  --    * SpEL and @Value expression support
  --    * live application data when a Boot app is running with the actuator
  --
  --  It plugs into jdtls as an "extension bundle", which is why
  --  ftplugin/java.lua calls require("spring_boot").java_extensions().
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls", -- must load first: it registers the bundles
    },
    opts = {
      -- Where to find the vscode-spring-boot-tools server. The plugin
      -- downloads it on first use if this is left as the default.
      -- ls_path = vim.fn.stdpath("data") .. "/mason/packages/spring-boot-tools",
      jdtls_name = "jdtls",
    },
  },

  -- ══════════════════════════════════════════════════════════════════════════
  --  Gradle/Maven-aware project detection is handled by jdtls's root markers
  --  (pom.xml / build.gradle / .git / mvnw / gradlew) in ftplugin/java.lua.
  -- ══════════════════════════════════════════════════════════════════════════
}
