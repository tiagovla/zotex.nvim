U = {}

function U.match_found(line_list, match)
    for _, line in pairs(line_list) do
        if line:match(match) then
            return true
        end
    end
    return false
end

function U.scandir(directory, extension)
    local t, popen = {}, io.popen
    local pfile = popen('ls "' .. directory .. '"| grep ' .. extension)
    if pfile == nil then
        return {}
    end
    for filename in pfile:lines() do
        table.insert(t, directory .. "/" .. filename)
    end
    pfile:close()
    return t
end

function U.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

return U
