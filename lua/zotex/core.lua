local M = {}

function M.get_candidates(db, translator)
    local items = {}
    local cache = db.syncCache

    for _, v in pairs(cache:__get()) do
        local item = vim.fn.json_decode(v.data).data

        if vim.tbl_contains(translator.types, item.itemType) then
            local citekey = translator.citekey(item)
            items[citekey] = item
        end
    end
    M.items = items
    return items
end

function M.get_entry(translator, citekey)
    return translator.do_export(M.items[citekey])
end

return M
