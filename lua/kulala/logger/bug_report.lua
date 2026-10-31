local Logger = require("kulala.logger")

local M = {}

M.create_issue = function()
  Logger.warn("Automatic issue uploads are disabled in this fork. Share a redacted reproducer manually.")
end

M.generate_bug_report = function(error)
  vim.cmd.new()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "markdown"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "# Local Kulala diagnostic",
    "",
    "No upload is performed. Error text can contain sensitive data; redact before sharing.",
    "Request bodies, environment values, and user configuration are not collected.",
    "",
    "```",
  })
  vim.api.nvim_buf_set_lines(0, -1, -1, false, vim.split(error or "", "\n"))
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { "```" })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true })
end

return M
