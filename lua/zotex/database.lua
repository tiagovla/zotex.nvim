local sqlite = require "sqlite.db"

local M = {}

function M.new(config)
    if vim.fn.filereadable(config.path) == 0 then
        vim.notify(("zotex.nvim: could not open database at %s."):format(config.path))
        return nil
    end

    local ok, db = pcall(sqlite.open, sqlite, "file:" .. config.path .. "?immutable=1", { open_mode = "ro" })
    if ok then
        return db
    else
        vim.notify "zotex.nvim: could not open database."
        return nil
    end
end

return M
