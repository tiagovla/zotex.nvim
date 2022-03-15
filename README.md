# Zotex.nvim

## Installation
Plugin to import references from the Zotero's local database.

```lua
use { "tiagovla/zotex.nvim", requires = "tami5/sqlite.lua" }
```

## Configuration
```lua
require("zotex").setup()

cmp.setup.filetype("tex", {
    sources = cmp.config.sources {
        { name = "zotex" },
    },
})
```
