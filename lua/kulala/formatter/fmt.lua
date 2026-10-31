local Logger = require("kulala.logger")

local M = {}

M.check_formatter = function()
  return false
end

M.format = function(text)
  return text
end

M.convert = function()
  Logger.warn(
    "External kulala-fmt conversion is not included in this fork. The built-in Lua formatter is available via LSP."
  )
end

return M
