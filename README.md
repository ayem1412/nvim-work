# Neovim config — Rust / Go / Web / PHP / Java / SQL, Windows + Linux

One config, two machines. Everything OS-specific is isolated in
`lua/config/platform.lua`, so the same repo runs unchanged on a Windows work
desktop and a Linux home desktop.

---

## Quick start (under 5 minutes to a working editor)

### 1. Install Neovim 0.11.3+ (0.12+ recommended)

```bash
# Linux — Arch
sudo pacman -S neovim
# Linux — Debian/Ubuntu (the apt version is usually too old; use the appimage or PPA)
sudo add-apt-repository ppa:neovim-ppa/unstable && sudo apt install neovim
# Windows
winget install Neovim.Neovim
```

Check: `nvim --version` must report **0.11.3 or newer**. This config uses the
native `vim.lsp.config()` API and will not work on 0.10.

### 2. Install the config

```bash
# Linux
git clone <your-repo> ~/.config/nvim

# Windows (PowerShell)
git clone <your-repo> $env:LOCALAPPDATA\nvim
```

> Both paths resolve from `vim.fn.stdpath("config")`. Nothing in the config
> hardcodes either one.

### 3. Install the external tools

**Everyone needs these:**

| Tool | Why | Linux | Windows |
|---|---|---|---|
| `git` | plugin manager | package manager | `winget install Git.Git` |
| `ripgrep` | grep / search-replace | `pacman -S ripgrep` | `winget install BurntSushi.ripgrep.MSVC` |
| `fd` | fast file finding | `pacman -S fd` | `winget install sharkdp.fd` |
| `lazygit` | `<leader>gg` | `pacman -S lazygit` | `winget install JesseDuffield.lazygit` |
| C compiler | treesitter parsers | `gcc` (usually present) | **see below** |
| A Nerd Font | icons | [nerdfonts.com](https://nerdfonts.com) | same |

**Windows compiler** — this is the one thing that reliably bites. Treesitter
compiles parsers from C. The easiest working option is Zig:

```powershell
scoop install zig       # or: winget install zig.zig
```

The config already tells treesitter to prefer `zig` on Windows
(`lua/plugins/treesitter.lua`). MSVC (`cl.exe` from Visual Studio Build Tools)
and mingw `gcc` from MSYS2 also work if you have them.

**Terminal on Windows**: use Windows Terminal, WezTerm or Alacritty. The legacy
console host does not support 24-bit colour and everything will look wrong.

### 4. Launch

```bash
nvim
```

lazy.nvim bootstraps itself, installs plugins, and Mason installs the language
servers and tools in the background. **The first launch takes a few minutes.**
Wait for the Mason notifications to stop, then restart.

### 5. Verify

```vim
:checkhealth
:Lazy         " plugin status
:Mason        " tool status — everything should show ✓
:LspInfo      " which servers are attached to this buffer
```

---

## Per-language prerequisites

Install only what you actually use. Nothing breaks if a toolchain is missing —
the relevant server just won't start.

### Rust
```bash
rustup component add rust-analyzer      # REQUIRED
rustup component add clippy rustfmt
```
> Do **not** install rust-analyzer through Mason. rustaceanvim uses the
> rustup-managed one so it always matches your toolchain; a mismatched version
> produces confusing proc-macro errors.

### Go
Install Go, then the config's `<leader>G` helpers run `:GoInstallDeps` on first
use to fetch `gomodifytags`, `impl`, `iferr` and `gotests`. `gopls` and `delve`
come from Mason.

### Node / TypeScript / Vue / React
Node 18+ on PATH. Everything else (vtsls, vue_ls, eslint, prettier) is
installed by Mason.

### PHP (WAMP)
1. Add PHP to PATH: `C:\wamp64\bin\php\php8.x.x`
2. Add Composer to PATH.
3. **Phalcon stubs** — this is what makes Phalcon classes resolve:
   ```bash
   composer global require phalcon/ide-stubs
   ```
   `after/lsp/intelephense.lua` finds the global Composer vendor directory
   automatically on both OSes. Alternatively `composer require --dev
   phalcon/ide-stubs` inside the project, which needs no configuration at all.
4. Set your real PHP version in `after/lsp/intelephense.lua`
   (`environment.phpVersion`) — check with `php -v`.
5. **Xdebug** — add to `php.ini` (WAMP tray icon → PHP → php.ini):
   ```ini
   zend_extension=xdebug
   xdebug.mode=debug
   xdebug.start_with_request=yes
   xdebug.client_host=127.0.0.1
   xdebug.client_port=9003
   ```
   Restart all WAMP services. Then `<leader>dc` → "Listen for Xdebug" and load
   the page in your browser.

### Java / Spring Boot
JDK **17 or newer** on PATH (jdtls itself requires it, even if your project
targets 8 or 11). Declare the JDKs you have in `lua/config/local.lua`:
```lua
vim.g.java_runtimes = {
  { name = "JavaSE-17", path = "C:/Program Files/Eclipse Adoptium/jdk-17..." },
  { name = "JavaSE-21", path = "C:/Program Files/Eclipse Adoptium/jdk-21...", default = true },
}
```
jdtls, java-debug-adapter, java-test and lombok come from Mason. The first
project import is slow (minutes on a large Spring Boot app) — that is jdtls
building its index, not a hang.

### Databases
vim-dadbod shells out to each engine's native CLI. Install the ones you use:

| Engine | Needs on PATH | Connection URL |
|---|---|---|
| PostgreSQL | `psql` | `postgresql://user:pass@localhost:5432/db` |
| MySQL | `mysql` (WAMP: `C:\wamp64\bin\mysql\mysql8.x.x\bin`) | `mysql://user:pass@localhost:3306/db` |
| SQLite | `sqlite3` | `sqlite:C:/path/to/file.db` |
| SQL Server | `sqlcmd` (mssql-tools18) | `sqlserver://user:pass@host:1433?database=db` |

SQL Server on Windows:
`winget install Microsoft.SQLServer.2022.CommandLineUtilities`.
On a dev box with a self-signed certificate add `&trustServerCertificate=true`
to the URL or `sqlcmd` will refuse to connect.

---

## Machine-specific settings

```bash
cp lua/config/local.example.lua lua/config/local.lua
```

`local.lua` is git-ignored and loaded last, so it overrides everything. Put
database credentials, JDK paths and per-machine tweaks there — never in the
tracked files.

**Commit `lazy-lock.json`.** It pins every plugin to an exact commit, which is
what keeps the two machines byte-identical. `:Lazy update` on one machine,
commit the lockfile, `git pull` + `:Lazy restore` on the other.

---

## Layout

```
.
├── init.lua                    entry point: loader, leader, bootstrap, load order
├── lua/
│   ├── config/
│   │   ├── platform.lua        ← ALL OS detection lives here. One file to check
│   │   │                         when something breaks on only one machine.
│   │   ├── options.lua         editor options + Windows shell/clipboard + filetypes
│   │   ├── keymaps.lua         global mappings (plugin ones live in their specs)
│   │   ├── autocmds.lua        yank highlight, cursor restore, indent, bigfile...
│   │   └── local.lua           ← YOUR machine-specific overrides (git-ignored)
│   └── plugins/
│       ├── lsp.lua             Mason + native vim.lsp.config + LspAttach keymaps
│       ├── completion.lua      blink.cmp + LuaSnip
│       ├── treesitter.lua      parsers, textobjects, folds, autotag
│       ├── editor.lua          snacks (picker/explorer/git), oil, which-key, mini
│       ├── ui.lua              colourscheme, lualine, bufferline
│       ├── git.lua             gitsigns, diffview
│       ├── format.lua          conform (format) + nvim-lint (diagnose)
│       ├── dap.lua             debugging core + PHP/Xdebug + JS/Chrome adapters
│       └── lang/
│           ├── rust.lua        rustaceanvim + crates.nvim
│           ├── go.lua          nvim-dap-go + gopher
│           ├── web.lua         package-info (the rest is LSP config)
│           ├── php.lua         phpactor as a REFACTORING engine only
│           ├── java.lua        nvim-jdtls + spring-boot.nvim
│           └── sql.lua         vim-dadbod stack
├── after/lsp/                  ← per-server settings, auto-loaded by name
│   ├── intelephense.lua        PHP + PHALCON STUBS (edit here for Phalcon)
│   ├── vtsls.lua               TypeScript + the Vue TS plugin wiring
│   ├── vue_ls.lua              Vue 3 hybrid mode
│   └── ...                     gopls, lua_ls, html, cssls, tailwind, eslint, ...
├── ftplugin/
│   ├── java.lua                ← starts jdtls per project (the whole Java setup)
│   ├── php.lua  go.lua  sql.lua  twig.lua
└── snippets/                   your own LuaSnip snippets (VS Code JSON format)
```

**Where to change what:**

| I want to... | Edit |
|---|---|
| Change a language server's settings | `after/lsp/<server>.lua` |
| Add a language server | `ensure_installed` in `lua/plugins/lsp.lua` + a new `after/lsp/` file |
| Change a formatter | `formatters_by_ft` in `lua/plugins/format.lua` |
| Fix Phalcon "undefined class" | `after/lsp/intelephense.lua` (stubs / includePaths) |
| Fix Vue types | `after/lsp/vtsls.lua` (globalPlugins) |
| Change Java/JDK behaviour | `ftplugin/java.lua` |
| Add a plugin | a new file in `lua/plugins/` — it's auto-imported |
| Something machine-specific | `lua/config/local.lua` |

---

## Keymap overview

`<leader>` is **Space**. Press `<leader>` and wait — which-key lists everything.

| Prefix | Area |
|---|---|
| `<leader>f` | find files |
| `<leader>s` | search (grep, symbols, help, diagnostics) |
| `<leader>c` | code / LSP (action, rename, format, organize imports) |
| `<leader>g` | git (`gg` lazygit, `gh*` hunks, `gd` diffview) |
| `<leader>d` | debug (`dc` continue, `db` breakpoint, `du` UI) |
| `<leader>x` | diagnostics & lists (trouble) |
| `<leader>u` | UI toggles |
| `<leader>b` `<leader>w` | buffers, windows |
| `<leader>D` | database (dadbod) |
| `<leader>r` | rust · `<leader>G` go · `<leader>p` php · `<leader>j` java · `<leader>n` npm |

Neovim 0.11 provides these natively and the config does **not** override them:
`K` hover · `grn` rename · `gra` code action · `gri` implementation ·
`grt` type definition · `gO` document symbols · `]d`/`[d` diagnostics.

---

## Troubleshooting

**Treesitter parsers fail to compile (Windows).**
Install `zig` (`scoop install zig`) and restart. Verify with
`:checkhealth nvim-treesitter`. If it still probes for `cl.exe`, set the `CC`
environment variable to your compiler.

**Vue: types work in `.ts` but everything from a `.vue` file is `any`.**
The `@vue/typescript-plugin` isn't loaded. Check `:LspInfo` in a `.vue` buffer —
you must see **both** `vtsls` and `vue_ls` attached. If `vtsls` is missing,
`"vue"` is not in its `filetypes` (`after/lsp/vtsls.lua`).

**`Could not find ts_ls, vtsls, or typescript-tools lsp client required by vue_ls`.**
Same cause as above: vtsls is not attached to the `.vue` buffer.

**Phalcon classes show as undefined.**
Run `composer global require phalcon/ide-stubs`, confirm `"phalcon"` is in the
`stubs` list in `after/lsp/intelephense.lua`, then `:LspRestart intelephense`.

**Java: "The project is not a Java project" or phantom compile errors.**
The jdtls workspace index is corrupt. Delete
`stdpath("data")/jdtls-workspace/<project>` and reopen. Find the path with
`:lua print(vim.fn.stdpath("data"))`.

**Java: jdtls doesn't start.**
`:MasonInstall jdtls`, confirm `java -version` reports 17+, and check
`:messages` for the launcher-jar warning.

**Two sets of diagnostics on the same line.**
Two servers are attached. Check `:LspInfo`. The usual culprits are running
`ts_ls` alongside `vtsls`, or enabling `rust_analyzer`/`jdtls` through
mason-lspconfig — all three are in the `automatic_enable.exclude` list in
`lua/plugins/lsp.lua` for exactly this reason.

**Formatting fights itself.**
conform owns formatting; the LSP formatters are disabled per-server in the
`no_format` table in `lua/plugins/lsp.lua`. If a server is reformatting your
file, add its name there.

**Slow startup.**
`nvim --startuptime /tmp/st.log` and `:Lazy profile`. On Windows, exclude
`%LOCALAPPDATA%\nvim-data` from Windows Defender real-time scanning — it makes
plugin and parser installs dramatically faster.

**Clipboard does nothing (WSL).**
Install `win32yank.exe` on PATH. The config detects it and wires it up.

**Everything is broken after an update.**
`:Lazy restore` rolls every plugin back to the committed `lazy-lock.json`.

---

## Deliberate choices worth knowing

These are the places where this config differs from what an older tutorial
would tell you. Each one is explained in a comment at the relevant file:

- **Native `vim.lsp.config()` / `vim.lsp.enable()`**, not
  `require("lspconfig").x.setup{}`. mason-lspconfig v2 removed
  `setup_handlers()`.
- **`after/lsp/`, not `lsp/`** — files found later on the runtimepath win, and
  nvim-lspconfig ships its own `lsp/<server>.lua`.
- **rustaceanvim owns rust-analyzer.** rust-tools.nvim is dead.
- **nvim-jdtls owns jdtls**, launched from `ftplugin/java.lua`, because jdtls
  needs a per-project workspace directory.
- **vtsls, not ts_ls.** Never both.
- **Vue hybrid mode.** Volar "take over mode" no longer exists.
- **treesitter `master`, not `main`.** `main` is a full rewrite requiring
  Neovim 0.12 + the tree-sitter CLI, and its Windows story is still rough. The
  migration snippet is at the bottom of `lua/plugins/treesitter.lua`.
- **blink.cmp, not nvim-cmp.** Faster, batteries included, no native build
  required (Lua fuzzy fallback).
- **conform + nvim-lint, not null-ls/none-ls.** null-ls is archived.
- **snacks.picker, not telescope.** No native compilation — which matters on a
  locked-down work machine.
- **`clipboard=unnamedplus` is NOT set.** Explicit `<leader>y` / `<leader>v`
  instead, so `diw` doesn't clobber what you copied.
