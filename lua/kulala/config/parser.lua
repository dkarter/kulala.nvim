local Build = require("kulala.build")

local M = {}

M.set_kulala_parser = function()
  -- Never accept an upstream parser from the runtime path or a shared cache.
  assert(
    vim.fn.filereadable(Build.parser) == 1
      and vim.fn.filereadable(Build.parser_ready) == 1
      and vim.fn.readfile(Build.parser_ready)[1] == "ready",
    "Kulala parser not built. Run: nvim --headless -u NONE -l scripts/build.lua (in the fork)"
  )

  -- A fork-specific language/symbol cannot collide with an already-loaded
  -- upstream kulala_http parser. Missing builds fail closed, without fallback.
  local ok, err = vim.treesitter.language.add(Build.language, { path = Build.parser })
  assert(ok, err)
  vim.treesitter.language.register(Build.language, { "http", "rest" })
  vim.opt.runtimepath:append(Build.root .. "/lua/tree-sitter")
end

return M
