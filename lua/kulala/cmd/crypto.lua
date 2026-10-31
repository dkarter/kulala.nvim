---@diagnostic disable: undefined-field
local Config = require("kulala.config")
local Json = require("kulala.utils.json")
local Logger = require("kulala.logger")

local M = {}

---Base64 encode the input string (standard encoding for OAuth2 Basic auth)
---@param input string Input string to be encoded
---@return string Standard Base64 encoded string
M.base64_encode_standard = function(input)
  return vim.base64.encode(input)
end

---Base64url encode the input string (URL-safe encoding for PKCE, JWT, etc.)
---@param input string Input string to be encoded
---@return string Base64url encoded string
M.base64_encode = function(input)
  return vim.base64.encode(input):gsub("+", "-"):gsub("/", "_"):gsub("=+$", "")
end

local function openssl_path()
  return Config.get().openssl_path or "openssl"
end

local function openssl(args, stdin)
  local cmd = vim.list_extend({ openssl_path() }, args)
  local ok, result = pcall(function()
    return vim.system(cmd, { stdin = stdin }):wait()
  end)
  if not ok or result.code ~= 0 then
    -- Do not log arguments or input: these can contain signing material.
    Logger.error("OpenSSL operation failed")
    return nil
  end
  return result.stdout
end

---Generate a random PKCE verifier
---@return string|nil PKCE verifier
M.pkce_verifier = function()
  local verifier = openssl { "rand", "32" }
  return verifier and M.base64_encode(verifier)
end

---Generate a PKCE challenge from the verifier
---@param verifier string PKCE verifier
---@param method string PKCE method "Plain"|"S256" (default: "S256")
---@return string|nil PKCE challenge
M.pkce_challenge = function(verifier, method)
  method = method or "S256"

  if method == "Plain" then return verifier end
  if method:lower() ~= "s256" then return Logger.error("Unsupported PKCE method: " .. method) end

  local hash = openssl({ "dgst", "-sha256", "-binary" }, verifier)
  return hash and M.base64_encode(hash)
end

---@class JWTPayload
---@field iss? string Issuer
---@field sub? string Subject
---@field scope? string Scope
---@field aud? string Audience
---@field exp? number Expiration time (in seconds since epoch)
---@field iat? number Issued at (in seconds since epoch)

---Generate a JWT token
---@param header {alg: string, typ: string} JWT header alg: "RS256"|"HS256", typ: "JWT"
---@param payload JWTPayload JWT payload
---@param key string Signing key
---@return string|nil JWT token
M.jwt_encode = function(header, payload, key)
  local err_msg = "Failure to encode JWT: "
  local supported_alg = { "RS256", "HS256" }

  if not vim.tbl_contains(supported_alg, header.alg) then
    return Logger.error("Unsupported Algorithm: " .. header.alg)
  end

  -- Base64url encode the header and payload
  local header_b64 = M.base64_encode(Json.encode(header, { sort = true }))
  local payload_b64 = M.base64_encode(Json.encode(payload, { sort = true }))

  local signing_input = header_b64 .. "." .. payload_b64
  local signature
  if header.alg == "HS256" then
    -- An argv array prevents shell expansion of untrusted key characters.
    signature = openssl({ "dgst", "-sha256", "-hmac", key, "-binary" }, signing_input)
  else
    local key_file = vim.fn.tempname()
    local fd = vim.uv.fs_open(key_file, "wx", 384) -- owner read/write only
    if not fd then return Logger.error(err_msg .. "failed to create private temporary file") end
    local written = vim.uv.fs_write(fd, key)
    vim.uv.fs_close(fd)
    if written == #key then signature = openssl({ "dgst", "-sha256", "-sign", key_file, "-binary" }, signing_input) end
    vim.uv.fs_unlink(key_file)
  end

  if not signature then return end

  return signing_input .. "." .. M.base64_encode(signature)
end

return M
