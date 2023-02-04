local M = {}

local cite_key_format = "%a_%t_%y"

local field_map = {
    title = "title",
    volume = "volume",
    issn = "ISSN",
    doi = "DOI",
    abstract = "abstractNote",
    address = "place",
    chapter = "section",
    edition = "edition",
    type = "type",
    series = "series",
    copyright = "rights",
    isbn = "ISBN",
    shorttitle = "shortTitle",
    url = "url",
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

local always_map = {
    ["|"] = "{\\textbar}",
    ["<"] = "{\\textless}",
    [">"] = "{\\textgreater}",
    ["~"] = "{\\textasciitilde}",
    ["^"] = "{\\textasciicircum}",
    ["\\"] = "{\\textbackslash}",
    ["{"] = "{\\{\\vphantom{\\}}}",
    ["}"] = "{\\vphantom{\\{}\\}}",
}

local cite_key_title_banned_re = {
    ["on"] = "",
    ["an"] = "",
    ["the"] = "",
    ["some"] = "",
    ["from"] = "",
    ["in"] = "",
    ["to"] = "",
    ["of"] = "",
    ["do"] = "",
    ["with"] = "",
    ["der"] = "",
    ["die"] = "",
    ["das"] = "",
    ["ein"] = "",
    ["eine"] = "",
    ["einer"] = "",
    ["eines"] = "",
    ["einem"] = "",
    ["einen"] = "",
    ["un"] = "",
    ["une"] = "",
    ["la"] = "",
    ["le"] = "",
    ["l'"] = "",
    ["el"] = "",
    ["las"] = "",
    ["los"] = "",
    ["al"] = "",
    ["uno"] = "",
    ["una"] = "",
    ["unos"] = "",
    ["unas"] = "",
    ["de"] = "",
    ["des"] = "",
    ["del"] = "",
    ["d'"] = "",
}

local function escape_special_characters(str)
    local new_str = str:gsub("[|<>~^\\{}]", function(c)
        return always_map[c]
    end):gsub("[#%$&_]", "\\%1")
    new_str = new_str:gsub("\\vphantom{\\}}(.-)\\vphantom{\\{}", "%1")
    return new_str
end

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

local function map_HTML_markup(characters)
    characters = characters
        :gsub("{\\textless}i{\\textgreater}(.+?){\\textless}/i{\\textgreater}", "\\textit{%1}")
        :gsub("{\\textless}b{\\textgreater}(.+?){\\textless}/b{\\textgreater}", "\\textbf{%1}")
        :gsub("{\\textless}sup{\\textgreater}(.+?){\\textless}/sup{\\textgreater}", "$^{\\textrm{%1}}$")
        :gsub("{\\textless}sub{\\textgreater}(.+?){\\textless}/sub{\\textgreater}", "$_{\\textrm{%1}}$")
        :gsub(
            '{\\textless}span\\sstyle="small%-caps"{\\textgreater}(.+?){\\textless}/span{\\textgreater}',
            "\\textsc{%1}"
        )
        :gsub("{\\textless}sc{\\textgreater}(.+?){\\textless}/sc{\\textgreater}", "\\textsc{%1}")
    return characters
end

local function write_field(field, value, is_macro)
    local output = ""
    if value == nil or value == "" then
        return output
    end
    if not is_macro and not (field == "url" or field == "doi" or field == "file" or field == "lccn") then
        value = escape_special_characters(value)
    end
    if field ~= "url" and field ~= "doi" and field ~= "file" then
        value = map_HTML_markup(value)
    end
    output = output .. ",\n    " .. field .. " = "
    if not is_macro then
        output = output .. "{"
    end
    output = output .. value
    if not is_macro then
        output = output .. "}"
    end
    return output
end

local function parse_extra_fields(extra)
    local lines = extra:gmatch "[^\r\n]+"
    local fields = {}
    for line in lines do
        local rec = { raw = line }
        line = line:match "^%s*(.-)%s*$"
        local splitAt = line:find ":"
        if splitAt and splitAt > 1 then
            rec.field = line:sub(1, splitAt - 1):match "^%s*(.-)%s*$"
            rec.value = line:sub(splitAt + 1):match "^%s*(.-)%s*$"
        end
        table.insert(fields, rec)
    end
    return fields
end

local function tidy_accents(s)
    local r = string.lower(s)
    r = string.gsub(r, "[ä]", "ae")
    r = string.gsub(r, "[ö]", "oe")
    r = string.gsub(r, "[ü]", "ue")
    r = string.gsub(r, "[àáâãå]", "a")
    r = string.gsub(r, "æ", "ae")
    r = string.gsub(r, "ç", "c")
    r = string.gsub(r, "[èéêë]", "e")
    r = string.gsub(r, "[ìíîï]", "i")
    r = string.gsub(r, "ñ", "n")
    r = string.gsub(r, "[òóôõ]", "o")
    r = string.gsub(r, "œ", "oe")
    r = string.gsub(r, "[ùúû]", "u")
    r = string.gsub(r, "[ýÿ]", "y")
    return r
end

M.types = vim.tbl_keys(zotero2bibtex_type_map)

local cite_key_conversions = {
    a = function(flags, item)
        if item.creators and item.creators[1] and item.creators[1].lastName then
            return string.lower(item.creators[1].lastName:gsub(" ", "_"):gsub(",", ""))
        end
        return "noauthor"
    end,

    t = function(flags, item)
        if item.title then
            local title = item.title:lower():gsub("%S+", cite_key_title_banned_re)
            return string.match(title, "%w+") or ""
        end
        return "notitle"
    end,

    y = function(flags, item)
        if item.date then
            local year = string.match(item.date, "^[0-9]+")
            if year then
                return year
            end
        end
        return "nodate"
    end,
}

function M.citekey(item, extra_fields, citekeys)
    if extra_fields then
        for i, field in ipairs(extra_fields) do
            if field.field and field.value and string.lower(field.field) == "citation key" then
                return table.remove(extra_fields, i).value
            end
        end
    end
    if item.citationKey then
        return item.citationKey
    end
    local basekey = ""
    local ck_remaining = cite_key_format
    while ck_remaining:match "%%(%w)" do
        local s, e, r = ck_remaining:find "%%(%w)"
        basekey = basekey .. ck_remaining:sub(0, s - 1 or 0)
        local flags = ""
        local f = cite_key_conversions[r]
        if type(f) == "function" then
            local value = f(flags, item)
            basekey = basekey .. value
        end
        ck_remaining = ck_remaining:sub(e + 1)
    end
    if ck_remaining:len() > 0 then
        basekey = basekey .. ck_remaining
    end
    basekey = tidy_accents(basekey)
    basekey = basekey:gsub("[^a-z0-9!$&*+-./:;<>?[]^_`|]+", "")
    local citekey = basekey
    local i = 0
    citekeys = citekeys or {}
    while citekeys[citekey] do
        i = i + 1
        citekey = basekey .. "_" .. i
    end
    citekeys[citekey] = true
    return citekey
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

    if item.creators then
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

            creatorString = escape_special_characters(creatorString)

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
        date.month = string.match(item.date, "%d%d%d%d%-?(%d%d)")
        if date.month and tonumber(date.month) > 0 then
            local month = months[tonumber(date.month)]
            output = output .. write_field("month", month, true)
        end
        output = output .. write_field("year", date.year)
    end
    if item.tags and #item.tags > 0 then
        local tagString = ""
        for _, tag in ipairs(item.tags) do
            tagString = tagString .. ", " .. tag.tag
        end
        write_field("keywords", string.sub(tagString, 3))
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
