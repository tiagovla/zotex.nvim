local default_config = require "zotex.config"

local M = {}

function M.setup(overrides)
    local config = vim.tbl_extend("force", default_config, overrides or {})
    require("cmp").register_source("zotex", require("zotex.source").new(config))
end

return M
