-- Standalone regression checks; no plugin manager or network bootstrap.
-- Re-exec before loading any plugin code so the documented command cannot read
-- personal environment values, request state, or Node configuration.
if vim.env.KULALA_COMPAT_ISOLATED ~= "1" then
  local home = vim.fn.tempname()
  vim.fn.mkdir(home, "p", 448)
  local env = {
    HOME = home,
    PATH = vim.env.PATH,
    TMPDIR = home,
    KULALA_COMPAT_ISOLATED = "1",
    KULALA_TEST_URL = vim.env.KULALA_TEST_URL,
  }
  local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local result = vim
    .system({ vim.v.progpath, "--headless", "-u", "NONE", "-l", script }, {
      env = env,
      clear_env = true,
      text = true,
    })
    :wait()
  io.stdout:write(result.stdout or "")
  io.stderr:write(result.stderr or "")
  os.exit(result.code)
end

local root = vim.fn.fnamemodify(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))), ":p")
vim.opt.runtimepath:prepend(root)
vim.o.swapfile = false
vim.o.modeline = false
vim.o.exrc = false

local passed = 0
local function test(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  assert(ok, name .. ": " .. tostring(err))
  passed = passed + 1
  print("ok: " .. name)
end

require("kulala").setup { global_keymaps = false }
local Fs = require("kulala.utils.fs")
local Globals = require("kulala.globals")

test("locally compiled parser parses HTTP", function()
  vim.cmd.cd(vim.fn.stdpath("cache"))
  assert(vim.treesitter.language.get_lang("http") == "dkarter_kulala_http")
  local parser =
    vim.treesitter.get_string_parser("GET https://example.invalid/test HTTP/1.1\n\n", "dkarter_kulala_http")
  local tree = parser:parse()[1]
  assert(not tree:root():has_error())
  assert(tree:root():named_child(0):type() == "section")
end)

local Crypto = require("kulala.cmd.crypto")
test("PKCE RFC 7636 test vector", function()
  assert(
    Crypto.pkce_challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
      == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  )
  assert(#Crypto.pkce_verifier() == 43)
end)

test("HMAC treats shell metacharacters as key data", function()
  local marker = vim.fn.tempname()
  local key = 'synthetic"; touch ' .. marker .. "; #"
  local jwt = Crypto.jwt_encode({ alg = "HS256", typ = "JWT" }, { sub = "test user with spaces" }, key)
  assert(jwt and jwt:match("^[%w_-]+%.[%w_-]+%.[%w_-]+$"))
  assert(vim.fn.filereadable(marker) == 0)
  local header, payload, signature = jwt:match("^([^.]+)%.([^.]+)%.([^.]+)$")
  local result = vim
    .system({ "openssl", "dgst", "-sha256", "-hmac", key, "-binary" }, { stdin = header .. "." .. payload })
    :wait()
  assert(result.code == 0 and Crypto.base64_encode(result.stdout) == signature)
  local padding = string.rep("=", (4 - #payload % 4) % 4)
  local decoded = vim.json.decode(vim.base64.decode(payload:gsub("-", "+"):gsub("_", "/") .. padding))
  assert(decoded.sub == "test user with spaces")
end)

test("RSA signs with a synthetic key and cleans up", function()
  local generated = vim.system({ "openssl", "genpkey", "-algorithm", "RSA", "-pkeyopt", "rsa_keygen_bits:2048" }):wait()
  assert(generated.code == 0)
  local jwt = Crypto.jwt_encode({ alg = "RS256", typ = "JWT" }, { sub = "test" }, generated.stdout)
  assert(jwt and jwt:match("^[%w_-]+%.[%w_-]+%.[%w_-]+$"))
end)

test("JavaScript request helpers built from TypeScript", function()
  Fs.write_json(
    Globals.REQUEST_FILE,
    { headers = {}, headers_raw = {}, environment = {}, method = "GET", url = "https://example.invalid" }
  )
  Fs.write_json(Fs.get_request_scripts_variables_file_path(), {})
  local engine = require("kulala.parser.scripts.engines.javascript")
  assert(engine.install_dependencies())
  assert(engine.run("pre_request", {
    inline = { 'request.variables.set("result", "from-local-build"); client.global.set("global_test", "ok");' },
    files = {},
    priority = "inline",
  }))
  assert(Fs.read_json(Fs.get_request_scripts_variables_file_path()).result == "from-local-build")
  assert(Fs.read_json(Fs.get_global_scripts_variables_file_path()).global_test == "ok")
end)

test("response redirects treat shell characters as a filename", function()
  assert(vim.fn.executable("jq") == 1, "jq is required for this formatter regression check")
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  vim.cmd.cd(dir)
  Fs.write_file(Globals.BODY_FILE, '{"message":"hello"}')
  local target = dir .. "/response'; touch marker; #.json"
  require("kulala.internal_processing").redirect_response_body_to_file { { file = target, overwrite = true } }
  assert(vim.wait(2000, function()
    return (Fs.read_file(target) or ""):find('"message": "hello"', 1, true) ~= nil
  end))
  assert(vim.fn.filereadable(dir .. "/marker") == 0)
end)

test("LSP attaches and formats HTTP with local parser", function()
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. ".http")
  vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    { "GET https://example.invalid HTTP/1.1", "accept: application/json", "", "" }
  )
  vim.bo.filetype = "http"
  assert(vim.wait(2000, function()
    return #vim.lsp.get_clients { bufnr = 0 } > 0
  end))
  assert(
    vim.lsp.get_clients({ bufnr = 0 })[1].server_capabilities.documentFormattingProvider,
    vim.inspect(vim.lsp.get_clients({ bufnr = 0 })[1].server_capabilities)
  )
  local replies =
    vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", { textDocument = { uri = vim.uri_from_bufnr(0) } }, 2000)
  assert(replies and next(replies))
  for _, reply in pairs(replies) do
    assert(not reply.err)
  end
  local edits = vim.lsp.buf_request_sync(0, "textDocument/formatting", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    options = { tabSize = 2, insertSpaces = true },
  }, 2000)
  assert(edits and next(edits), vim.inspect(edits))
  for _, reply in pairs(edits) do
    assert(not reply.err and reply.result and #reply.result > 0, vim.inspect(reply))
    vim.lsp.util.apply_text_edits(reply.result, vim.api.nvim_get_current_buf(), "utf-16")
  end
  local formatted = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(formatted:find("Accept: application/json", 1, true), formatted)
end)

local url = vim.env.KULALA_TEST_URL
if url then
  assert(url:match("^http://127%.0%.0%.1:%d+/"), "HTTP smoke tests require a loopback-only URL")
  test("HTTP POST through the full request runner", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. ".http")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "POST " .. url .. " HTTP/1.1",
      "Content-Type: application/json",
      "",
      '{"message":"local-test"}',
      "",
    })
    vim.bo.filetype = "http"
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    require("kulala").run()
    assert(vim.wait(5000, function()
      return #require("kulala.db").global_data.responses > 0
    end))
    local response = require("kulala.db").global_data.responses[1]
    assert(response.response_code == 200, vim.inspect(response))
    assert(response.json.message == "local-test")
  end)
end

print(("Passed %d compatibility checks"):format(passed))
