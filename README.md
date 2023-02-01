# Zotex.nvim

## Installation

Plugin to import references from the Zotero's local database.

```lua
use {
    "tiagovla/zotex.nvim",
    config = function() require("zotex").setup {} end,
    requires = { "kkharji/sqlite.lua" },
}
```

## Configuration

```lua
cmp.setup.filetype("tex", {
    sources = cmp.config.sources {
        { name = "zotex" },
    },
})
```

## Defaults

```lua
require("zotex").setup {
    auto_save = true,
    path = "~/Zotero/zotero.sqlite",
    translator = "bibtex",
}
```

## TODO

### Features

- [x] Enable read-only for multiple connections

### Configs:

- [x] Optional auto save
- [x] Custom database path
- [ ] Configurable `citationkey` format

### Translators

- [x] BibTex
- [ ] BibLaTex
- [ ] BetterBibTex
- [ ] BetterBibLaTex

### Future

- [ ] Fetch from online Zotero
