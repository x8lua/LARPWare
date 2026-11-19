# LARPWare

Refined dark-crimson Roblox UI library rebuilt from Dollarware with live font switching (built-in + Creator Store fonts), inner content scaling, global text scaling, top-bar control search, animated collapsible sections, element tooltips, and a hidden overscroll easter egg.

## Quick Start

```lua
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'inter',
    scale = 1,
    textScale = 1
})
```

## Controls & Features

- **Core Controls**: `addLabel`, `addToggle` (supports inline `toggle:addHotkey()` & `toggle:addColorPicker()`), `addButton` (`small` / `large`), `addDualButton`, `addSlider` (inline bar value + right-click numeric input), `addRangeSlider`, `addColorPicker`, `addTextbox`, `addHotkey`, `addDropdown`, `addMultiDropdown`, `addSegmented`, `addListbox` (with live search filter), `addProgressBar`, `addDivider`, `addParagraph`, `addUIScaler`, `addTextScaler`, `addFontSelector`.
- **Tooltips Everywhere**: Every section and control supports `tooltip = '...'` in its settings table as well as `:setTooltip('...')` chaining, with automatic text-scale sizing.
- **Top-Bar Global Search**: Click the magnifying glass icon in the titlebar to search every control across all tabs, auto-switch tabs, expand minimized sections, scroll to the match, and flash-highlight it.
- **Animated Collapsible Sections**: Smooth height, slide, chevron rotation, accent trim, and separator fade transitions with rapid-click race protection.
- **Full Font Library (Built-in + Marketplace)**: Includes every built-in `Enum.Font` plus all 91 official Roblox Creator Store fonts (`Inter` default, `Builder Mono`, `Builder Sans`, `IBM Plex Sans JP`, `Fira Sans`, `Barlow`, `Rajdhani`, `Sono Monospace`, `Silkscreen`, `DotGothic16`, `Work Sans`, `Montserrat`, `Poppins`, `Open Sans`, `Lato`, and more) with a live-preview searchable picker in both `section:addFontSelector()` and the titlebar appearance popover.
- **UI & Text Scalers**: Scale everything inside the main UI without resizing the outer window (`ui.setScale(1.15)` / `section:addUIScaler()`) and scale all UI text globally (`ui.setTextScale(1.15)` / `section:addTextScaler()`), both also accessible live from the titlebar settings popover.
- **Draggable HUD Panels**: `ui.setWatermark(text, visible)`, `ui.toggleWatermark(bool)`, and `ui.toggleKeybindList(bool)`.
- **Hidden Overscroll Easter Egg**: Automatically caches `assets/larp.png` into the executor workspace (`LARPWare/larp.png`) via `getcustomasset`. Scrolling past the bottom of a tab reveals the hidden LARP tab underneath the main UI, and scrolling back up immediately tucks it back under.
