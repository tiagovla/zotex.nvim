local cmp = require "cmp"
local utils = require "zotex.utils"
local core = require "zotex.core"
local default_config = require "zotex.config"

local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
    return { "{", "," }
end

function source:_fetch_items()
    local items = core.get_candidates()

    self.candidates = {}
    for k, v in pairs(items) do
        table.insert(self.candidates, { label = k, detail = v.title })
    end
    return self.candidates
end

function source._get_keyword_pattern()
    return [[\\cite{\(\k*,\=\)\+]]
end

function source:is_available()
    local ft = vim.bo.filetype
    return ft == "tex"
end

function source:complete(request, callback)
    if not vim.regex(self._get_keyword_pattern()):match_str(request.context.cursor_before_line) then
        return callback()
    end
    local items = self:_fetch_items()
    callback(items)
end

function source:execute(completion_item, callback)
    local cwd = vim.fn.getcwd(-1, -1)
    local paths = U.scandir(cwd)
    if #paths > 0 then
        vim.cmd(":e " .. paths[1])
    else
        return callback(completion_item)
    end
    local text_lines = vim.api.nvim_buf_get_text(0, 0, 0, -1, -1, {})
    if not utils.match_found(text_lines, completion_item.label) then
        local data = utils.split(core.get_entry(completion_item.label), "\n")
        vim.api.nvim_buf_set_lines(0, -1, -1, false, data)
    end
    vim.cmd [[$ | w | b# ]]
    return callback(completion_item)
end

source.config = default_config

function source.setup(config)
    source.config = vim.tbl_extend("force", source.config, config)
end

return source
