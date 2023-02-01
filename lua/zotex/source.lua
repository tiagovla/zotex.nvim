local core = require "zotex.core"
local db = require "zotex.database"
local utils = require "zotex.utils"

local source = {}

source.new = function(config)
    local self = setmetatable({}, { __index = source })
    self.config = config
    self.db = db.new(self.config)
    self.translator = self.config.translator
    return self
end

source.get_trigger_characters = function()
    return { "{", "," }
end

function source:_fetch_items()
    local items = core.get_candidates(self.db, self.translator)
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
    return ft == "tex" and self.db ~= nil
end

function source:complete(request, callback)
    if not vim.regex(self._get_keyword_pattern()):match_str(request.context.cursor_before_line) then
        return callback()
    end
    local items = self:_fetch_items()
    callback(items)
end

function source:get_debug_name()
    return "zotex"
end

function source:execute(completion_item, callback)
    local cwd = vim.fn.getcwd(-1, -1)
    local paths = U.scandir(cwd, self.translator.extension)
    local buf
    if #paths > 0 then
        buf = vim.fn.bufadd(paths[1])
    else
        vim.notify(("zotex.nvim: Could not find %s in %s."):format(self.translator.extension, vim.fn.expand "$PWD"))
        return callback(completion_item)
    end
    local text_lines = vim.api.nvim_buf_get_text(buf, 0, 0, -1, -1, {})
    if not utils.match_found(text_lines, completion_item.label) then
        local data = utils.split(core.get_entry(self.translator, completion_item.label), "\n")
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
    end
    if self.config.auto_save then
        vim.api.nvim_buf_call(buf, vim.cmd.write)
    end
    return callback(completion_item)
end

return source
