# LARPWare

Refined Roblox UI library rebuilt from Dollarware with crisp tactical dark styling, live font switching (`.code`, `.gotham`), full UI scaling, and an expanded control suite.

## Quick Start

```lua
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false,
    font = 'gotham',
    scale = 1
})
```

## Controls & Features

- **Core Controls**: `addLabel`, `addToggle` (supports inline `toggle:addHotkey()` & `toggle:addColorPicker()`), `addButton` (`small` / `large`), `addDualButton`, `addSlider` (right-click numeric input), `addRangeSlider`, `addColorPicker`, `addTextbox`, `addHotkey`, `addDropdown`, `addMultiDropdown`, `addSegmented`, `addListbox` (with live search filter), `addProgressBar`, `addDivider`, `addParagraph`.
- **Font Selector**: Switch live between `.code` (`Enum.Font.Code`) and `.gotham` (`Enum.Font.Gotham`) via `ui.setFont(ui.fonts.code)`, `section:addFontSelector()`, or the titlebar appearance popover.
- **UI Scaler**: Scale windows, color pickers, tooltips, notifications, and HUD panels (`0.5x` – `2.5x`) via `ui.setScale(1.25)`, `section:addUIScaler()`, or the titlebar appearance popover.
- **Draggable HUD Panels**: `ui.setWatermark(text, visible)`, `ui.toggleWatermark(bool)`, and `ui.toggleKeybindList(bool)`.
