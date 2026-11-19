# LARPWare

Refined dark-crimson tactical Roblox UI library with `Builder Mono` default typography, a sliding active-pill tabbar, live theme/color/font/scale engines, top-bar global control search, animated collapsible sections, tooltips on every element, an in-window `L A R P` launch intro, and a duplicate-instance guard with full process termination.

> Full API reference and starter template: **[DOCS.md](./DOCS.md)**

## Quick Start

```lua
local uiLoader = loadstring(game:HttpGet('https://api.x8stuff.lol/larpware/library.lua?t=' .. tostring(os.time())))
local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'buildermono',
    scale = 1,
    textScale = 1,
    intro = true
})
```

Try the full showcase directly:

```lua
loadstring(game:HttpGet('https://api.x8stuff.lol/larpware/example.lua?t=' .. tostring(os.time())))()
```

## Highlights

- **Premium Tactical Tabbar**: Vector tab icons, `NAVIGATION` header, liquid-sliding active highlight pill with elastic accent indicator, and clickable version footer.
- **In-Window `L A R P` Intro**: Optically aligned chrome-blue 4-letter launch sequence rendered cleanly inside the UI window (skippable on click, replayable via `ui.playIntro()` / `win:playIntro()`).
- **Live Theme & Color Engine**: 8 built-in presets (`crimson`, `cobalt`, `emerald`, `amber`, `violet`, `cherry`, `rose`, `monochrome`), live primary/secondary/surface/stroke/text pickers, live transparency, live corner rounding, and 7 quick swatches in the titlebar popover.
- **Full Font & Scale Suite**: `Builder Mono` default + 130+ built-in and Creator Store fonts with live-preview search, inner content scaler (`ui.setScale`), and global text scaler (`ui.setTextScale`).
- **Duplicate Instance Guard**: Centered dark-crimson confirmation modal (`cancel [esc]` / `proceed & terminate [enter]`) that cleanly disables old toggles, disconnects tracked connections, cancels tracked threads, and destroys the old session before launching.
- **Complete Control Suite**: `addToggle` (inline hotkey & color picker), `addButton`, `addDualButton`, `addSlider` (inline value + right-click input), `addRangeSlider`, `addDropdown`, `addMultiDropdown`, `addSegmented`, `addColorPicker`, `addTextbox`, `addHotkey` (double-click to cancel), `addListbox`, `addProgressBar`, `addLabel`, `addDivider`, `addParagraph`, `addFontSelector`, `addUIScaler`, `addTextScaler`.
