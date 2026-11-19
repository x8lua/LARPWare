# LARPWare

Refined Roblox UI library rebuilt from Dollarware with crisp tactical dark styling, live font switching (`.code`, `.gotham`), full UI scaling, and an expanded control suite.

## Quick Start

```lua
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'roboto',
    scale = 1
})
```

## Controls & Features

- **Core Controls**: `addLabel`, `addToggle` (supports inline `toggle:addHotkey()` & `toggle:addColorPicker()`), `addButton` (`small` / `large`), `addDualButton`, `addSlider` (inline bar value + right-click numeric input), `addRangeSlider`, `addColorPicker`, `addTextbox`, `addHotkey`, `addDropdown`, `addMultiDropdown`, `addSegmented`, `addListbox` (with live search filter), `addProgressBar`, `addDivider`, `addParagraph`.
- **Font Selector**: Switch live between `.roboto` (default), `.robotomono`, `.ubuntu`, `.arimo`, `.code`, and `.gotham` via `ui.setFont(ui.fonts.roboto)`, `section:addFontSelector()`, or the titlebar appearance popover.
- **UI Scaler**: Scale everything inside the main UI without resizing the outer window (`0.5x` – `2.5x`) via `ui.setScale(1.15)`, `section:addUIScaler()`, or the titlebar appearance popover.
- **Draggable HUD Panels**: `ui.setWatermark(text, visible)`, `ui.toggleWatermark(bool)`, and `ui.toggleKeybindList(bool)`.
