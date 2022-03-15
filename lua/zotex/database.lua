local sqlite = require "sqlite"
local config = require "zotex.config"

local db = sqlite {
    uri = config.path,
    syncCache = {},
}

return db
