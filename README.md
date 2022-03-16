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
## TODO
### Features
- [ ] Enable read-only for multiple connections

### Configs:
- [ ] Optional auto save
- [ ] Custom database path
- [ ] Configurable `citationkey` format

### Translators
- [x] BibTex
- [ ] BibLaTex
- [ ] BetterBibTex
- [ ] BetterBibLaTex

### Future
- [ ] Fetch from online Zotero
