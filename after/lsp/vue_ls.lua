-- ============================================================================
--  after/lsp/vue_ls.lua  —  Vue 3 (Volar v3)
-- ----------------------------------------------------------------------------
--  Naming history, so old tutorials make sense:
--      volar  ->  vuels  ->  volar (again)  ->  vue_ls
--  `vue_ls` is the current lspconfig name. Mason package: vue-language-server.
--
--  In hybrid mode this server handles ONLY the <template> and <style> blocks.
--  All TypeScript/JavaScript — including <script setup> — is handled by vtsls
--  via the @vue/typescript-plugin. See after/lsp/vtsls.lua.
--
--  Hybrid mode is the DEFAULT in v3, so there is no `hybridMode` flag to set.
--  If you are on a v2 server you would need:
--      init_options = { vue = { hybridMode = true } }
-- ============================================================================

return {
  -- vue_ls needs vtsls (or ts_ls) running on the same buffer. It will emit
  -- "Could not find ts_ls, vtsls, or typescript-tools lsp client required by
  -- vue_ls" if that server isn't attached — check vtsls's `filetypes`.
  on_init = function(client)
    -- Volar v3 asks the TypeScript server to do the type work through a custom
    -- request. This handler forwards those requests to vtsls and returns the
    -- answer. Without it, template type-checking (`v-for` item types, prop
    -- validation) silently returns nothing.
    client.handlers["tsserver/request"] = function(_, result, context)
      local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
      if #ts_clients == 0 then
        ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })
      end
      if #ts_clients == 0 then
        vim.notify(
          "vue_ls: no TypeScript server attached. Vue type support will be limited.\n"
            .. "Check that 'vue' is in vtsls's filetypes (after/lsp/vtsls.lua).",
          vim.log.levels.WARN
        )
        return
      end
      local ts_client = ts_clients[1]
      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        command = "typescript.tsserverRequest",
        arguments = { command, payload },
      }, { bufnr = context.bufnr }, function(_, r)
        local response = r and r.body
        -- Volar expects [id, response] back on the same channel.
        client:notify("tsserver/response", { { id, response } })
      end)
    end
  end,

  settings = {
    vue = {
      -- Enable the "component info" hover: shows props, emits and slots when
      -- you hover a component tag in a template. This is the feature that
      -- makes Vue in Neovim actually pleasant.
      inlayHints = {
        destructuredProps = true,
        missingProps = true,
        inlineHandlerLeading = true,
        optionsWrapper = true,
        vBindShorthand = true,
      },
    },
  },
}
