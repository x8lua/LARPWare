# LARPWare

Refined Roblox UI library forked and rebuilt from Dollarware with cleaner controls, a live font selector (`.code`, `.gotham`), full UI scaling, and a working dropdown control.

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

## New Features

- **Font Selector**: Switch live between `.code` (`Enum.Font.Code`) and `.gotham` (`Enum.Font.Gotham`) via `ui.setFont(ui.fonts.code)`, `section:addFontSelector()`, or the built-in titlebar appearance popover.
- **UI Scaler**: Scale every window, control, color picker, tooltip, and notification cleanly (`0.5x` – `2.5x`) with exact mouse/resize math via `ui.setScale(1.25)`, `section:addUIScaler()`, or the built-in titlebar appearance popover.
- **Dropdown**: Full `section:addDropdown({ text = '...', options = {...}, default = '...' }, callback)` support.
- **Refined Controls**: Crisp procedural vector chrome, recessed checkbox indicators, two-tier precision sliders with right-click numeric input, bordered keybind badges, rectangular color swatches, focused textbox accent bars, and left-accented sidebar tabs.
