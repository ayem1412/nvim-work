-- ============================================================================
--  after/lsp/intelephense.lua  —  PHP, with Phalcon support
-- ----------------------------------------------------------------------------
--  WHY INTELEPHENSE AND NOT PHPACTOR
--    intelephense understands framework "magic" (facades, DI containers,
--    annotations, __get/__call) far better, so you get dramatically fewer false
--    "undefined method" diagnostics on Phalcon/Laravel/Symfony code. phpactor
--    is fully free and is used here as a REFACTORING engine only — see
--    lua/plugins/lang/php.lua.
--
--    intelephense is freemium. The free tier covers completion, diagnostics,
--    goto-definition, find-references and hover. A one-off personal licence
--    (~$35) unlocks rename, code actions, code lens, inlay hints, folding and
--    type hierarchy. If you buy one, drop the key in a file and point
--    `licenceKey` at it (see below).
--
--  ── PHALCON SETUP (the important bit) ──────────────────────────────────────
--  Phalcon is a C extension, so its classes have no PHP source for the server
--  to read. You must give it the IDE stubs:
--
--      composer global require phalcon/ide-stubs
--
--  That installs to:
--      Linux   : ~/.config/composer/vendor/phalcon/ide-stubs
--                (older setups: ~/.composer/vendor/phalcon/ide-stubs)
--      Windows : %APPDATA%\Composer\vendor\phalcon\ide-stubs
--
--  The code below finds whichever exists. Alternatively, require the stubs in
--  the project itself (`composer require --dev phalcon/ide-stubs`) and
--  intelephense will pick them up from vendor/ with no configuration at all —
--  that is the cleaner option for a team.
-- ============================================================================

local plat = require("config.platform")

-- ── Locate the global Composer vendor directory ─────────────────────────────
local function composer_global_vendor()
  local candidates
  if plat.is_win then
    candidates = {
      vim.fn.expand("$APPDATA") .. "/Composer/vendor",
    }
  else
    candidates = {
      vim.fn.expand("~/.config/composer/vendor"), -- XDG (current default)
      vim.fn.expand("~/.composer/vendor"), -- legacy
    }
  end
  for _, dir in ipairs(candidates) do
    if plat.exists(dir) then
      return dir
    end
  end
  return nil
end

-- ── Build the list of extra include paths ───────────────────────────────────
local include_paths = {}
local vendor = composer_global_vendor()
if vendor then
  -- Phalcon IDE stubs. `src` is the directory that actually contains the
  -- namespaced class files.
  local phalcon_stubs = vendor .. "/phalcon/ide-stubs/src"
  if plat.exists(phalcon_stubs) then
    table.insert(include_paths, phalcon_stubs)
  end
  -- If you also want globally-installed tools' types available:
  -- table.insert(include_paths, vendor)
end

-- Add any machine-specific paths from lua/config/local.lua, e.g. a shared
-- library directory on the work network drive:
--   vim.g.php_include_paths = { "D:/shared/php-libs" }
if type(vim.g.php_include_paths) == "table" then
  vim.list_extend(include_paths, vim.g.php_include_paths)
end

return {
  -- WAMP projects often have no .git at the web root; composer.json is the
  -- more reliable marker for a PHP project.
  root_markers = { "composer.json", ".git", "phalcon.json", ".phalcon" },

  init_options = {
    -- Paid licence: put the key on the first line of this file and it is read
    -- automatically. Harmless if the file doesn't exist.
    licenceKey = (function()
      local key_file = vim.fn.stdpath("config") .. "/intelephense_licence.txt"
      if plat.exists(key_file) then
        local lines = vim.fn.readfile(key_file)
        return lines[1] and vim.trim(lines[1]) or nil
      end
      return nil
    end)(),
    -- Where intelephense caches its index. Keeping it under stdpath("data")
    -- means the two machines don't try to share an index over a synced folder,
    -- which corrupts it.
    storagePath = vim.fn.stdpath("data") .. "/intelephense",
  },

  settings = {
    intelephense = {
      -- ── Stubs ──────────────────────────────────────────────────────────
      -- Stubs are prebuilt type definitions for PHP extensions. Anything NOT
      -- in this list is invisible to the server — that is exactly why Phalcon
      -- classes show as undefined until you add "phalcon" here.
      -- This is the default list plus phalcon and the DB extensions you use.
      stubs = {
        "apache",
        "bcmath",
        "bz2",
        "calendar",
        "com_dotnet",
        "Core",
        "ctype",
        "curl",
        "date",
        "dba",
        "dom",
        "enchant",
        "exif",
        "FFI",
        "fileinfo",
        "filter",
        "fpm",
        "ftp",
        "gd",
        "gettext",
        "gmp",
        "hash",
        "iconv",
        "imap",
        "intl",
        "json",
        "ldap",
        "libxml",
        "mbstring",
        "meta",
        "mysqli", -- MySQL (procedural/OO extension)
        "oci8",
        "odbc", -- used by some SQL Server setups
        "openssl",
        "pcntl",
        "pcre",
        "PDO", -- the PDO base classes
        "pdo_ibm",
        "pdo_mysql", -- PDO MySQL driver
        "pdo_pgsql", -- PDO PostgreSQL driver
        "pdo_sqlite", -- PDO SQLite driver
        "pdo_sqlsrv", -- PDO SQL Server driver
        "pgsql", -- PostgreSQL extension
        "Phar",
        "posix",
        "pspell",
        "readline",
        "Reflection",
        "session",
        "shmop",
        "SimpleXML",
        "snmp",
        "soap",
        "sockets",
        "sodium",
        "SPL",
        "sqlite3", -- SQLite
        "sqlsrv", -- SQL Server extension
        "standard",
        "superglobals",
        "sysvmsg",
        "sysvsem",
        "sysvshm",
        "tidy",
        "tokenizer",
        "xml",
        "xmlreader",
        "xmlrpc",
        "xmlwriter",
        "xsl",
        "Zend OPcache",
        "zip",
        "zlib",
        -- ── The one that matters for you ─────────────────────────────────
        "phalcon", -- Phalcon framework
        "psr", -- PSR interfaces (used by Phalcon 5)
        "redis", -- common alongside Phalcon for caching/sessions
        "memcached",
        "xdebug", -- so xdebug_* functions resolve while debugging
      },

      -- ── Environment ────────────────────────────────────────────────────
      environment = {
        -- Match your WAMP PHP version. Getting this wrong means the server
        -- either flags valid 8.x syntax as errors, or fails to warn about
        -- features your runtime doesn't have. Check with `php -v`.
        phpVersion = "8.2.0",
        -- Extra directories to index, equivalent to php.ini's include_path.
        -- This is what makes the Phalcon stubs visible.
        includePaths = include_paths,
        -- Uncomment and point at your WAMP document root if you keep shared
        -- includes outside the project:
        -- documentRoot = "C:/wamp64/www",
      },

      -- ── Files ──────────────────────────────────────────────────────────
      files = {
        -- Default is 1 MB; generated files (compiled Volt templates, large
        -- migration/seed files, vendor autoload maps) blow past that and are
        -- then silently un-indexed.
        maxSize = 5000000,
        -- Directories intelephense never indexes. `vendor` is deliberately NOT
        -- here: indexing it is what gives you completion for your dependencies.
        exclude = {
          "**/.git/**",
          "**/node_modules/**",
          "**/bower_components/**",
          "**/vendor/**/{Tests,tests}/**", -- but skip dependencies' test suites
          "**/cache/**",
          "**/var/cache/**",
          "**/storage/framework/**",
          "**/public/build/**",
          "**/*.min.js",
          -- Phalcon compiles Volt templates to PHP here; indexing them
          -- produces thousands of junk symbols.
          "**/cache/volt/**",
          "**/var/volt/**",
        },
      },

      -- ── Diagnostics ────────────────────────────────────────────────────
      diagnostics = {
        enable = true,
        -- Phalcon's DI container and magic getters produce a lot of
        -- false "undefined property" reports. Turn this off if your Phalcon
        -- code is drowning in them; leave it on for plain PHP.
        undefinedProperties = true,
        undefinedTypes = true,
        undefinedFunctions = true,
        undefinedConstants = true,
        undefinedClassConstants = true,
        undefinedMethods = true,
        undefinedVariables = true,
        unusedSymbols = true,
        unexpectedTokens = true,
        duplicateSymbols = true,
        argumentCount = true,
        typeErrors = true,
        -- Deprecation warnings on every legacy call are noisy on an older
        -- codebase; flip to true when you're actively modernising.
        deprecated = false,
      },

      -- ── Completion ─────────────────────────────────────────────────────
      completion = {
        insertUseDeclaration = true, -- auto-add `use Foo\Bar;` on accept
        fullyQualifyGlobalConstantsAndFunctions = false,
        triggerParameterHints = true,
        maxItems = 100,
      },

      format = {
        -- php-cs-fixer / pint does the formatting (plugins/format.lua).
        enable = false,
      },

      -- Inlay hints are a PREMIUM feature; harmless to leave configured.
      references = { exclude = { "**/vendor/**/{Tests,tests}/**" } },
      telemetry = { enabled = false },
    },
  },
}
