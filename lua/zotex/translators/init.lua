local M = {}

function M.new(name)
    return require("zotex.translators." .. name)
end

return M
