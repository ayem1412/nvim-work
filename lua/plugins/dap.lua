-- ============================================================================
--  lua/plugins/dap.lua  —  debugging (Debug Adapter Protocol)
-- ----------------------------------------------------------------------------
--  Architecture:
--    nvim-dap          -> the protocol client (breakpoints, stepping, REPL)
--    nvim-dap-ui       -> the panes (scopes, watches, stacks, breakpoints)
--    dap-virtual-text  -> inline variable values next to your code
--    per-language      -> the "adapter" that speaks to the actual debugger
--
--  Adapter ownership, so you know where to look when something breaks:
--    Rust  -> rustaceanvim configures codelldb itself   (lang/rust.lua)
--    Go    -> nvim-dap-go configures delve              (lang/go.lua)
--    Java  -> nvim-jdtls configures java-debug bundles  (ftplugin/java.lua)
--    PHP   -> configured HERE (Xdebug via php-debug-adapter)
--    JS/TS -> configured HERE (js-debug-adapter)
-- ============================================================================

local plat = require("config.platform")

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" }, -- required since dap-ui v3
      },
      "theHamsta/nvim-dap-virtual-text",
    },
    -- Only load when you actually start debugging.
    keys = {
      { "<leader>d", "", desc = "+debug" },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          -- Conditional breakpoint: "only stop when userId == 42".
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dl",
        function()
          -- Logpoint: prints a message instead of stopping. Far better than
          -- adding and forgetting a println/var_dump.
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: "))
        end,
        desc = "Logpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue / start",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session info",
      },
      -- <leader>dq, not <leader>dt: <leader>dt* is the Java test-debug prefix
      -- (ftplugin/java.lua) and <leader>dg* the Go one.
      {
        "<leader>dq",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate session",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        mode = { "n", "v" },
        desc = "Evaluate expression",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Hover variables",
      },
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Debug: continue",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Debug: step over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Debug: step into",
      },
      {
        "<F12>",
        function()
          require("dap").step_out()
        end,
        desc = "Debug: step out",
      },
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Debug: breakpoint",
      },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- ── Signs ────────────────────────────────────────────────────────────
      -- `text` must be a non-empty, 1-2 cell string or sign_define() errors.
      local icons = require("config.icons")
      vim.fn.sign_define("DapBreakpoint", { text = icons.dap.breakpoint, texthl = "DiagnosticError", numhl = "" })
      vim.fn.sign_define(
        "DapBreakpointCondition",
        { text = icons.dap.condition, texthl = "DiagnosticWarn", numhl = "" }
      )
      vim.fn.sign_define("DapLogPoint", { text = icons.dap.logpoint, texthl = "DiagnosticInfo", numhl = "" })
      vim.fn.sign_define(
        "DapStopped",
        { text = icons.dap.stopped, texthl = "DiagnosticWarn", linehl = "Visual", numhl = "" }
      )
      vim.fn.sign_define("DapBreakpointRejected", { text = icons.dap.rejected, texthl = "DiagnosticError", numhl = "" })

      -- ── UI ───────────────────────────────────────────────────────────────
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.35 }, -- local/global variables
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.25 }, -- call stack
              { id = "watches", size = 0.25 }, -- your own expressions
            },
            size = 45,
            position = "left",
          },
          {
            elements = { "repl", "console" },
            size = 0.28,
            position = "bottom",
          },
        },
        floating = { border = "rounded" },
      })

      -- Open the UI automatically when a session starts, close it when it ends.
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      require("nvim-dap-virtual-text").setup({
        virt_text_pos = "eol",
        commented = true, -- render as a comment so it's visually distinct
        only_first_definition = true,
      })

      -- ══════════════════════════════════════════════════════════════════════
      --  PHP / Xdebug
      -- ══════════════════════════════════════════════════════════════════════
      --  How this works: Xdebug in your WAMP PHP *connects out* to Neovim.
      --  So Neovim listens and you then hit the page in the browser.
      --
      --  Required php.ini (WAMP: right-click tray icon -> PHP -> php.ini):
      --      zend_extension=xdebug
      --      xdebug.mode=debug
      --      xdebug.start_with_request=yes     ; or use the browser extension
      --      xdebug.client_host=127.0.0.1
      --      xdebug.client_port=9003           ; 9003 is Xdebug 3's default
      --                                        ; (Xdebug 2 used 9000)
      --  Then restart all WAMP services.
      dap.adapters.php = {
        type = "executable",
        command = "node",
        args = { plat.mason_pkg("php-debug-adapter") .. "/extension/out/phpDebug.js" },
      }

      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug (9003)",
          port = 9003,
          -- WAMP runs the code from the same filesystem Neovim sees, so no
          -- path mapping is needed. If you ever debug PHP inside Docker/WSL,
          -- uncomment and map the container path to the local one:
          -- pathMappings = { ["/var/www/html"] = "${workspaceFolder}" },
          log = false,
        },
        {
          type = "php",
          request = "launch",
          name = "Debug current script (CLI)",
          program = "${file}",
          cwd = "${workspaceFolder}",
          port = 9003,
          runtimeArgs = { "-dxdebug.start_with_request=yes" },
          env = { XDEBUG_MODE = "debug,develop" },
        },
        {
          -- Phalcon apps are usually served by Apache/nginx, so the listener
          -- above is what you want. This entry is for `phalcon serve` or the
          -- PHP built-in server.
          type = "php",
          request = "launch",
          name = "Listen for Xdebug (Phalcon / built-in server)",
          port = 9003,
          stopOnEntry = false,
          -- Don't step into the framework's own bootstrap on every request.
          ignore = { "**/vendor/**/*.php" },
        },
      }

      -- ══════════════════════════════════════════════════════════════════════
      --  JavaScript / TypeScript / Node / Chrome
      -- ══════════════════════════════════════════════════════════════════════
      --  js-debug-adapter runs as a SERVER (not executable) — it starts a
      --  DAP server on a free port and nvim-dap connects to it.
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}", -- nvim-dap substitutes a free port
        executable = {
          command = "node",
          args = {
            plat.mason_pkg("js-debug-adapter") .. "/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }
      dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]

      for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" }) do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (Node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            protocol = "inspector",
            -- Don't step through node internals or dependencies.
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to running Node process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            skipFiles = { "<node_internals>/**" },
          },
          {
            -- For debugging a Vue/React app running in the browser. Start your
            -- dev server first (`npm run dev`), then launch this.
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome against localhost:5173 (Vite)",
            url = "http://localhost:5173",
            webRoot = "${workspaceFolder}/src",
            sourceMaps = true,
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome against localhost:3000 (React/Next)",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
        }
      end

      -- ══════════════════════════════════════════════════════════════════════
      --  .vscode/launch.json
      -- ══════════════════════════════════════════════════════════════════════
      --  Nothing to do. Recent nvim-dap reads ./.vscode/launch.json
      --  automatically, on demand, whenever you call dap.continue() — the old
      --  `require("dap.ext.vscode").load_launchjs(...)` call is deprecated and
      --  now prints a warning. See :help dap-providers.
      --
      --  Practical upshot: on a team where everyone else uses VS Code, their
      --  debug configurations show up in your <leader>dc picker for free.
      --
      --  If a launch.json entry uses an adapter type nvim-dap doesn't know,
      --  register an alias instead of a loader, e.g.:
      --      dap.adapters.node = dap.adapters["pwa-node"]
    end,
  },
}
