-- Local builds only: no downloads, package installs, or upstream executables.
local M = {}

local source = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
M.root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
M.dir = M.root .. "/.build"
M.language = "dkarter_kulala_http"
M.parser = M.dir .. "/" .. M.language .. ".so"
M.parser_ready = M.dir .. "/parser.ready"
M.scripts_ready = M.dir .. "/scripts.ready"

local function run(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  assert(result.code == 0, table.concat(cmd, " ") .. "\n" .. (result.stderr or ""))
end

function M.build()
  local grammar = M.dir .. "/grammar"
  vim.fn.mkdir(grammar, "p")
  -- Invalidate old helpers even if a later build step fails or Bun is missing.
  assert(vim.fn.writefile({ "incomplete" }, M.scripts_ready) == 0)
  assert(vim.fn.writefile({ "incomplete" }, M.parser_ready) == 0)
  assert(vim.fn.executable("tree-sitter") == 1, "Install tree-sitter-cli from a trusted source first")
  for _, file in ipairs { "grammar.js", "tree-sitter.json" } do
    assert(vim.uv.fs_copyfile(M.root .. "/lua/tree-sitter/" .. file, grammar .. "/" .. file))
  end

  -- Regenerate C rather than trusting the upstream-generated parser.c.
  run({ "tree-sitter", "generate", "--abi", "14" }, grammar)
  run({ "tree-sitter", "build", "--output", M.parser }, grammar)
  assert(vim.fn.writefile({ "ready" }, M.parser_ready) == 0)

  if vim.fn.executable("bun") == 1 then
    local scripts = M.root .. "/lua/kulala/parser/scripts/engines/javascript/lib/src"
    run({
      "bun",
      "build",
      "--target=node",
      "--format=cjs",
      "--env=disable",
      -- Helpers are appended to a request script in the cache. Preserve its
      -- runtime directory, not Bun's build-time source directory.
      "--define=__dirname=__kulala_script_dir",
      "--banner=const __kulala_script_dir = __dirname;",
      "--outdir",
      M.dir .. "/scripts",
      scripts .. "/pre_request.ts",
      scripts .. "/post_request.ts",
    }, M.root)
    assert(vim.fn.writefile({ "ready" }, M.scripts_ready) == 0)
  else
    print("Bun not found: skipped optional JavaScript scripting build")
  end

  print("Built Kulala from local source: " .. M.dir)
end

return M
