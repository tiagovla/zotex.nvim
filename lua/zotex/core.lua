local M = {}

local sql_query_data = [[
    SELECT
      DISTINCT items.key,
      fields.fieldName,
      parentItemDataValues.value,
      itemTypes.typeName
    FROM
      items
      INNER JOIN itemData ON itemData.itemID = items.itemID
      INNER JOIN itemDataValues ON itemData.valueID = itemDataValues.valueID
      INNER JOIN itemData as parentItemData ON parentItemData.itemID = items.itemID
      INNER JOIN itemDataValues as parentItemDataValues ON parentItemDataValues.valueID = parentItemData.valueID
      INNER JOIN fields ON fields.fieldID = parentItemData.fieldID
      INNER JOIN itemTypes ON itemTypes.itemTypeID = items.itemTypeID
    ]]

local sql_query_data_creators = [[
    SELECT
      DISTINCT items.key,
      creators.firstName,
      creators.lastName,
      itemCreators.orderIndex,
      creatorTypes.creatorType
    FROM
      items
      INNER JOIN itemData ON itemData.itemID = items.itemID
      INNER JOIN itemCreators ON itemCreators.itemID = items.itemID
      INNER JOIN creators ON creators.creatorID = itemCreators.creatorID
      INNER JOIN creatorTypes ON itemCreators.creatorTypeID = creatorTypes.creatorTypeID
    ]]

function M.get_candidates(db, translator)
    local items = {}
    if not db:exists "syncCache" then
        local items_ = {}
        local sql_data = db:eval(sql_query_data)
        local sql_data_creators = db:eval(sql_query_data_creators)
        for _, v in pairs(sql_data) do
            if items_[v.key] == nil then
                items_[v.key] = { creators = {} }
            end
            items_[v.key][v.fieldName] = v.value
            items_[v.key].itemType = v.typeName
        end
        for _, v in pairs(sql_data_creators) do
            if items_[v.key] ~= nil then
                items_[v.key].creators[v.orderIndex + 1] =
                    { firstName = v.firstName, lastName = v.lastName, creatorType = v.creatorType }
            end
        end
        for _, item in pairs(items_) do
            if vim.tbl_contains(translator.types, item.itemType) then
                local citekey = translator.citekey(item)
                items[citekey] = item
            end
        end
    else
        local cache = db:select "syncCache"
        for _, v in pairs(cache) do
            local item = vim.fn.json_decode(v.data).data
            if vim.tbl_contains(translator.types, item.itemType) then
                local citekey = translator.citekey(item)
                items[citekey] = item
            end
        end
    end
    M.items = items
    return items
end

function M.get_entry(translator, citekey)
    return translator.do_export(M.items[citekey])
end

return M
