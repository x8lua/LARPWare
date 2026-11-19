# LARPWare

Refined Roblox UI library rebuilt from Dollarware with crisp tactical dark styling, live font switching (`.code`, `.gotham`), full UI scaling, and an expanded control suite.

## Quick Start

```lua
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'inter',
    scale = 1
})
```

## Controls & Features

- **Core Controls**: `addLabel`, `addToggle` (supports inline `toggle:addHotkey()` & `toggle:addColorPicker()`), `addButton` (`small` / `large`), `addDualButton`, `addSlider` (inline bar value + right-click numeric input), `addRangeSlider`, `addColorPicker`, `addTextbox`, `addHotkey`, `addDropdown`, `addMultiDropdown`, `addSegmented`, `addListbox` (with live search filter), `addProgressBar`, `addDivider`, `addParagraph`.
- **Full Font Library (Built-in + Marketplace)**: Includes every built-in `Enum.Font` plus all 91 official Roblox Creator Store fonts (`Inter` default, `Builder Mono`, `Builder Sans`, `IBM Plex Sans JP`, `Fira Sans`, `Barlow`, `Rajdhani`, `Sono Monospace`, `Silkscreen`, `DotGothic16`, `Work Sans`, `Montserrat`, `Poppins`, `Open Sans`, `Lato`, and more) with a live-preview searchable picker in both `section:addFontSelector()` and the titlebar appearance popover. Supports `ui.setFont('inter')`, `ui.setFont(ui.fonts.buildermono)`, `ui.setFont(12187365364)`, or any `Font` / `Enum.Font`.
- **UI Scaler**: Scale everything inside the main UI without resizing the outer window (`0.5x` – `2.5x`) via `ui.setScale(1.15)`, `section:addUIScaler()`, or the titlebar appearance popover.
- **Draggable HUD Panels**: `ui.setWatermark(text, visible)`, `ui.toggleWatermark(bool)`, and `ui.toggleKeybindList(bool)`.
