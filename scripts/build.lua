local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
-- Load the checked-out builder directly, not a previously cached Lua module.
dofile(root .. "/lua/kulala/build.lua").build()
