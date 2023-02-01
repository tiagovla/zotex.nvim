local M = {}

local field_map = {
    address = "place",
    chapter = "section",
    edition = "edition",
    type = "type",
    series = "series",
    title = "title",
    volume = "volume",
    copyright = "rights",
    isbn = "ISBN",
    issn = "ISSN",
    shorttitle = "shortTitle",
    url = "url",
    doi = "DOI",
    abstract = "abstractNote",
    nationality = "country",
    language = "language",
    assignee = "assignee",
}

local months = {
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
}

local zotero2bibtex_type_map = setmetatable({
    book = "book",
    bookSection = "incollection",
    journalArticle = "article",
    magazineArticle = "article",
    newspaperArticle = "article",
    thesis = "phdthesis",
    letter = "misc",
    manuscript = "unpublished",
    patent = "patent",
    interview = "misc",
    film = "misc",
    artwork = "misc",
    webpage = "misc",
    conferencePaper = "inproceedings",
    report = "techreport",
}, {
    __index = function(t, k)
        return "misc"
    end,
})

local function write_field(field, value, isMacro)
    local output = ""
    if value == nil or value == "" then
        return output
    end
    output = output .. ",\n    " .. field .. " = "
    if not isMacro then
        output = output .. "{"
    end
    output = output .. value
    if not isMacro then
        output = output .. "}"
    end
    return output
end

M.types = vim.tbl_keys(zotero2bibtex_type_map)
function M.citekey(item)
    local output, count = "", 0
    for _, creator in pairs(item.creators) do
        if creator.name then
            output = output .. creator.name
        else
            output = output .. creator.lastName
        end
        count = count + 1
        if count == 2 then
            break
        end
    end
    if item.date then
        local year = string.match(item.date, "%d%d%d%d") or ""
        output = output .. year
    end
    return output:gsub("%s+", "")
end

function M.do_export(item)
    local output = ""
    local type = zotero2bibtex_type_map[item.itemType]
    for k, v in pairs(field_map) do
        output = output .. write_field(k, item[v])
    end
    local number = item.reportNumber or item.issue or item.seriesNumber or item.parentNumber
    output = output .. write_field("number", number)
    output = output .. write_field("urldate", item.accessDate)
    if item.publicationTitle then
        if item.itemType == "bookSection" or item.itemType == "conferencePaper" then
            output = output .. write_field("booktitle", item.publicationTitle)
        else
            output = output .. write_field("journal", item.publicationTitle)
        end
    end
    if item.publisher then
        if item.itemType == "thesis" then
            output = output .. write_field("school", item.publisher)
        elseif item.itemType == "report" then
            output = output .. write_field("institution", item.publisher)
        else
            output = output .. write_field("publisher", item.publisher)
        end
    end
    local authors, editors, translators, collaborators = {}, {}, {}, {}

    for _, creator in pairs(item.creators) do
        local creatorString = ""
        if creator.name then
            creatorString = creatorString .. creator.name
        else
            creatorString = creator.lastName .. ", " .. creator.firstName
        end
        if creator.fieldMode then
            creatorString = "{" .. creatorString .. "}"
        end

        if creator.creatorType == "editor" or creator.creatorType == "seriesEditor" then
            table.insert(editors, creatorString)
        elseif creator.creatorType == "translator" then
            table.insert(translators, creatorString)
        elseif creator.creatorType == "author" then
            table.insert(authors, creatorString)
        else
            table.insert(collaborators, creatorString)
        end
    end

    if #authors > 0 then
        local text = table.concat(authors, " and ")
        output = output .. write_field("author", "{" .. text .. "}", true)
    end
    if #editors > 0 then
        local text = table.concat(editors, " and ")
        output = output .. write_field("editor", "{" .. text .. "}", true)
    end
    if #translators > 0 then
        local text = table.concat(translators, " and ")
        output = output .. write_field("translator", "{" .. text .. "}", true)
    end
    if #collaborators > 0 then
        local text = table.concat(collaborators, " and ")
        output = output .. write_field("collaborator", "{" .. text .. "}", true)
    end

    local citekey = M.citekey(item)
    output = "\n" .. "@" .. type .. "{" .. citekey .. output
    if item.date then
        local date = {}
        date.year = string.match(item.date, "%d%d%d%d")
        output = output .. write_field("year", date.year)
    end
    if item.pages then
        local pages = string.gsub(item.pages, "[-]+", "--")
        output = output .. write_field("pages", pages)
    end
    output = output .. ",\n}"
    return output
end

M.extension = ".bib"

return M
