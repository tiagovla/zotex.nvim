local default_config = require "zotex.config"

local M = {}

function M.setup(overrides)
    local config = vim.tbl_extend("force", default_config, overrides or {})
    config.path = vim.fn.expand(config.path)
    if type(config.translator) == "string" then
        local ok, translator = pcall(require, "zotex.translators." .. config.translator)
        if ok then
            config.translator = translator
        else
            vim.notify("zotex.nvim: Could not find translator " .. config.translator)
            return
        end
    end
    require("cmp").register_source("zotex", require("zotex.source").new(config))
end

return M
