local sqlite = require "sqlite"
local config = require "zotex.config"

local db = sqlite {
    uri = config.path,
    open_mode = "ro",
    syncCache = {},
}

return db
