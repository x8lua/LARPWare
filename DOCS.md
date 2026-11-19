# LARPWare UI Library Documentation

LARPWare is a dark-crimson tactical Roblox UI library with `Builder Mono` default typography, a sliding active-pill tabbar, live theme/color/font/scale engines, top-bar global control search, tooltips on every element, an in-window `L A R P` launch intro, and a duplicate-instance guard with full process termination.

---

## 1. Loading & Initialization

Load the library from the zero-cache VPS endpoint (recommended) or the GitHub mirror:

```lua
local uiLoader = loadstring(game:HttpGet('https://api.x8stuff.lol/larpware/library.lua?t=' .. tostring(os.time())))

local ui = uiLoader({
    theme = 'crimson',
    font = 'buildermono',
    scale = 1,
    textScale = 1,
    rounding = false,
    smoothDragging = false,
    intro = true
})
```

### `uiLoader(settings)` Options

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `theme` | `string \| table` | `'crimson'` | Preset name (`'crimson'`, `'cobalt'`, `'emerald'`, `'amber'`, `'violet'`, `'cherry'`, `'rose'`, `'monochrome'`) or custom theme color table. |
| `font` | `string \| number \| Font \| Enum.Font` | `'buildermono'` | Initial font across the entire UI. Accepts any built-in `Enum.Font`, Creator Store font name (e.g. `'inter'`, `'buildermono'`, `'firasans'`), or numeric asset ID. |
| `scale` | `number` | `1` | Inner content scale (`0.5` – `2.5`). Scales everything inside the window without changing the outer window size. |
| `textScale` | `number` | `1` | Global text size multiplier (`0.6` – `2.0`). |
| `rounding` | `boolean` | `true` | Enables subtle corner rounding on panels and controls. |
| `smoothDragging` | `boolean` | `true` | Enables smooth inertia while dragging windows and HUD panels. |
| `intro` | `boolean` | `true` | Plays the in-window `L A R P` intro animation when the window opens. |
| `mobileButton` | `boolean` | `TouchEnabled and not KeyboardEnabled` | Displays the draggable, resizable floating toggle button to open/close the UI. Auto-enabled on touch-only mobile devices and hidden by default on keyboard devices. |
| `onCancel` | `function` | `nil` | Optional callback invoked if the user clicks **Cancel** on the duplicate-instance warning modal. If omitted, the duplicate thread yields cleanly without errors. |

### Hosting & Parenting

- Automatically parents into `gethui()` when available, falling back to `CoreGui` and `PlayerGui`.
- Assigns a randomized 14-character alphanumeric `ScreenGui.Name` on every run.
- Automatically caches `LARPWare/intro_L.png`, `intro_A.png`, `intro_R.png`, `intro_P.png`, and `larp.png` inside the executor workspace via `getcustomasset` (`getsynasset` fallback).

---

## 2. Duplicate Session Guard & Lifecycle

Re-running a LARPWare script while an active session is already open displays a centered confirmation modal (`cancel [esc]` / `proceed & terminate [enter]`):

- **Cancel**: Keeps the existing UI untouched and halts the duplicate execution cleanly.
- **Proceed & Terminate**: Calls `oldInstance.terminate()`, disabling all active toggles, firing cleanup events, disconnecting all tracked connections, canceling all tracked threads, and immediately destroying the old UI before launching the new one.

### Process Tracking & Cleanup Helpers

Register your own script connections and background loops so they automatically shut down when the user unloads or replaces the UI:

```lua
local conn = game:GetService('RunService').RenderStepped:Connect(function()
    if (ui.isTerminated()) then return end
end)
ui.trackConnection(conn)

local worker = task.spawn(function()
    while (not ui.isTerminated()) do
        task.wait(1)
    end
end)
ui.trackThread(worker)

ui:bindToEvent('onTerminate', function()
    print('Session terminated cleanly')
end)
```

| Method / Property | Description |
| :--- | :--- |
| `ui.autoDisableToggles` | `boolean` (default `true`). Automatically disables active toggles when the window closes. |
| `ui.trackConnection(con)` | Registers an `RBXScriptConnection` for automatic `:Disconnect()` on `ui.terminate()` / `ui.destroy()`. Returns `con`. |
| `ui.trackThread(thread)` | Registers a `thread` for automatic `task.cancel()` on `ui.terminate()` / `ui.destroy()`. Returns `thread`. |
| `ui.isTerminated()` | Returns `true` once the session has been terminated or destroyed. |
| `ui.terminate()` | Immediately disables all toggles, disconnects all connections, cancels tracked threads, and destroys the entire UI. |
| `ui.destroy()` | Animated close and teardown of the UI. |

---

## 3. Windows, Tabs & Sections

### Creating a Window — `ui.newWindow(settings)`

```lua
local window = ui.newWindow({
    text = 'LARPWare',
    resize = true,
    showSettings = true,
    showSearch = true,
    intro = true,
    size = Vector2.new(600, 420),
    position = nil,
    icon = nil
})
```

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `text` | `string` | `'LARPWare'` | Window titlebar text. |
| `resize` | `boolean` | `false` | Shows bottom-right resize grip and enables window resizing. |
| `showSettings` | `boolean` | `true` | Shows titlebar appearance popover button. |
| `showSearch` | `boolean` | `true` | Shows titlebar global control search magnifying glass button. |
| `defaultPreference` | `boolean` | `true` | Automatically appends the built-in `Preference` tab (fonts, scaling, theme presets, live color pickers, transparency, rounding, smooth dragging, menu bind, HUD toggles, script-adjustable profiles, unload) pinned to the bottom of the sidebar. Alias: `defaultSettings`. |
| `configs` | `table \| false` | `{}` | Optional config profile controller options (`items`, `default`, `searchable`, `placeholder`, `height`, `onSave`, `onLoad`, `onDelete`, `onSelect`). Pass `false` to omit the profiles block completely, or configure dynamically anytime via `window:configureConfigs(opts)`. |
| `intro` | `boolean` | inherits `uiLoader` | Overrides whether this window plays the in-window `L A R P` intro on open. |
| `size` | `Vector2 \| UDim2` | `550x376` | Initial window size. |
| `position` | `UDim2` | auto-staggered | Initial window position. |
| `icon` | `string` | `nil` | Optional `rbxassetid://...` titlebar icon. |

**Window Methods**: `window:setTitle(text)`, `window:setIcon(asset)`, `window:setPosition(udim2)`, `window:getPosition()`, `window:setSize(vec2OrUdim2)`, `window:getSize()`, `window:setVisible(bool)`, `window:toggle()`, `window:minimize()`, `window:toggleSettings()`, `window:toggleSearch(forceState?)`, `window:popup(settings)`, `window:playIntro()`, `window:getPreferenceMenu()`, `window:configureConfigs(opts)`, `window:setConfigs(list, selected?)`, `window:getConfigs()`, `window:getSelectedConfig()`, `window:getConfigName()`, `window:destroy()`.

### Script-Adjustable Configs (`Preference` Tab)

Configs are never hardcoded by the library — your script supplies the profile list and hooks real file/JSON logic:

```lua
local profiles = {'default', 'farm', 'pvp'}
window:configureConfigs({
    items = profiles,
    default = 'default',
    onSelect = function(name)
        print('selected:', name)
    end,
    onSave = function(name, selected)
        if (name == '') then return end
        if (not table.find(profiles, name)) then
            table.insert(profiles, name)
            window:setConfigs(profiles, name)
        end
    end,
    onLoad = function(selected)
        print('load:', selected)
    end,
    onDelete = function(selected)
        local idx = table.find(profiles, selected)
        if (idx) then
            table.remove(profiles, idx)
            window:setConfigs(profiles, profiles[1])
        end
    end
})
```

You can also listen to `onConfigSave`, `onConfigLoad`, `onConfigDelete`, and `onConfigSelect` via `window:bindToEvent(...)`, or access the underlying controls directly through `window.configControls` (`nameBox`, `list`, `buttons`, `deleteButton`).

> Tip: `window` supports `hotkey:linkToControl(window)` so a keybind (such as `Enum.KeyCode.RightShift`) can toggle the entire window open/closed.

### Adding Tabs — `window:addMenu(settings)`

```lua
local combat = window:addMenu({
    text = 'combat',
    icon = 'combat'
})
```

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `text` | `string` | `'menu'` | Tab label shown in the sidebar rail. |
| `icon` | `string` | auto-detected | Vector glyph hint: `'combat'`, `'visuals'`, `'misc'`, `'settings'`, or `'default'`. Auto-detected from `text` if omitted. |

**Menu Methods**: `menu:select()`, `menu:deselect()`, `menu:addSection(settings)`.

### Adding Sections — `menu:addSection(settings)`

```lua
local sec = combat:addSection({
    text = 'aimbot',
    side = 'left',
    showMinButton = true,
    tooltip = 'Primary targeting controls'
})
```

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `text` | `string` | `'section'` | Section header title. |
| `side` | `'left' \| 'right' \| 'auto'` | `'auto'` | Column placement (`'auto'` alternates left/right). |
| `showMinButton` | `boolean` | `true` | Displays the animated collapse/expand chevron button. |
| `tooltip` | `string` | `nil` | Hover tooltip shown on the section header. |

**Section Methods**: `sec:minimize()`, `sec:setTooltip(tip)`, plus all `sec:add*` control constructors below.

---

## 4. Controls Reference

Every control inherits from `baseElement`:
- Pass `tooltip = '...'` inside `settings`, or chain `:setTooltip('...')`.
- Bind additional handlers via `:bindToEvent(eventName, fn)`.

### Toggle — `sec:addToggle(settings, callback)`

Supports inline attached hotkeys and color pickers on the same row.

```lua
local aim = sec:addToggle({
    text = 'enabled',
    state = false,
    tooltip = 'Master aimbot switch'
}, function(state)
    print('aimbot:', state)
end)

aim:addHotkey({bind = Enum.KeyCode.E, tooltip = 'Toggle keybind'})
aim:addColorPicker({color = Color3.fromRGB(168, 24, 36), tooltip = 'FOV color'}, function(c)
    print(c)
end)
```

- **Methods**: `enable()`, `disable()`, `toggle()`, `reset()`, `getState()` / `isEnabled()` / `getValue()`, `addHotkey(settings)`, `addColorPicker(settings, cb)`.
- **Events**: `onToggle(state)`, `onEnable()`, `onDisable()`.

### Button — `sec:addButton(settings, callback)`

```lua
sec:addButton({
    text = 'reset world',
    style = 'large',
    tooltip = 'Restores default lighting'
}, function()
    print('clicked')
end)
```

- **Options**: `text` (`string`), `style` (`'small'` or `'large'`, default `'small'`), `tooltip`.
- **Events**: `onClick()`.

### Dual Button — `sec:addDualButton(settings, leftCb, rightCb)`

```lua
sec:addDualButton({
    left = 'save config',
    right = 'load config',
    tooltip = 'Save or load selected profile'
}, function()
    print('left')
end, function()
    print('right')
end)
```

- **Events**: `onLeftClick()`, `onRightClick()`.

### Slider — `sec:addSlider(settings, callback)`

Displays the numeric value directly inside the filled bar. Right-click the slider bar to type an exact number.

```lua
local fov = sec:addSlider({
    text = 'fov radius',
    min = 10,
    max = 360,
    step = 1,
    val = 120,
    suffix = 'px',
    tooltip = 'Right-click to type an exact value'
}, function(v)
    print('fov:', v)
end)
```

- **Options**: `text`, `min`, `max`, `step`, `val` (or `value`), `suffix`, `tooltip`.
- **Methods**: `setValue(num, silent?)`, `getValue()`.
- **Events**: `onNewValue(value)`.

### Range Slider — `sec:addRangeSlider(settings, callback)`

Dual-handle min/max slider with inline range display.

```lua
local delay = sec:addRangeSlider({
    text = 'reaction delay',
    min = 0,
    max = 250,
    step = 5,
    low = 35,
    high = 110,
    suffix = 'ms'
}, function(lo, hi)
    print(lo, hi)
end)
```

- **Methods**: `setRange(low, high, silent?)`, `getRange()` (returns `low, high`), `getValue()`.
- **Events**: `onNewRange(low, high)`.

### Dropdown — `sec:addDropdown(settings, callback)`

```lua
local prio = sec:addDropdown({
    text = 'target priority',
    options = {'Closest', 'Lowest HP', 'Shortest Distance'},
    default = 'Closest'
}, function(selected)
    print(selected)
end)
```

- **Methods**: `setOptions(list)` / `refresh(list)`, `setValue(val, silent?)`, `getValue()`, `open()`, `close()`, `isOpen()`.
- **Events**: `onSelect(value)`, `onOpen()`, `onClose()`.

### Multi-Dropdown — `sec:addMultiDropdown(settings, callback)`

```lua
local parts = sec:addMultiDropdown({
    text = 'hitboxes',
    options = {'Head', 'UpperTorso', 'LowerTorso'},
    default = {'Head', 'UpperTorso'}
}, function(selectedList)
    print(table.concat(selectedList, ', '))
end)
```

- **Methods**: `setOptions(list)` / `refresh(list)`, `setValues(list, silent?)`, `toggleOption(opt)`, `isSelected(opt)`, `getValues()` / `getValue()`, `open()`, `close()`, `isOpen()`.
- **Events**: `onSelect(selectedList)`, `onOpen()`, `onClose()`.

### Segmented Control — `sec:addSegmented(settings, callback)`

```lua
local mode = sec:addSegmented({
    text = 'mode',
    options = {'silent', 'camlock', 'hybrid'},
    default = 'silent'
}, function(val)
    print(val)
end)
```

- **Methods**: `setOptions(list)`, `setValue(val, silent?)`, `getValue()`.
- **Events**: `onSelect(value)`.

### Color Picker — `sec:addColorPicker(settings, callback)`

Includes HSV square, hue bar, RGB sliders, hex display, and built-in chroma mode.

```lua
local col = sec:addColorPicker({
    text = 'ambient tint',
    color = Color3.fromRGB(168, 24, 36)
}, function(c)
    print(c)
end)
```

- **Methods**: `setColor(color3)`, `getColor()`, `openPrompt()`, `click()`.
- **Events**: `onNewColor(color3)`.

### Textbox — `sec:addTextbox(settings, callback)`

```lua
local box = sec:addTextbox({
    text = 'target override',
    placeholder = 'enter username...'
}, function(text)
    print('typed:', text)
end)
box:bindToEvent('onFocusLost', function(text)
    print('submitted:', text)
end)
```

- **Methods**: `setText(str)`, `getText()`.
- **Events**: `onTextChange(text)`, `onFocus()`, `onFocusLost(text)`.

### Hotkey — `sec:addHotkey(settings)`

Click once to listen (`[...]`), press any key to bind, press `Escape` to clear (`[None]`), or **click a second time while listening to cancel** and keep the previous bind.

```lua
local bind = sec:addHotkey({
    text = 'toggle menu',
    bind = Enum.KeyCode.RightShift
})
bind:linkToControl(window)
```

- **Methods**: `setHotkey(keyCodeOrNameOrNil)`, `getHotkey()`, `linkToControl(controlOrWindow)`, `click()`.

### Listbox — `sec:addListbox(settings, callback)`

Scrollable list with optional live search input.

```lua
local list = sec:addListbox({
    text = 'players',
    items = {'x8lua', 'kestrel', 'solaris'},
    default = 'x8lua',
    searchable = true,
    height = 110
}, function(item)
    print(item)
end)
```

- **Methods**: `setItems(list)` / `refresh(list)`, `setValue(item, silent?)`, `getValue()`.
- **Events**: `onSelect(item)`.

### Progress Bar — `sec:addProgressBar(settings)`

```lua
local hp = sec:addProgressBar({
    text = 'target health',
    value = 78,
    max = 100,
    suffix = '%'
})
hp:setValue(45)
```

- **Methods**: `setValue(val, newMax?, customText?)`, `getValue()`, `setText(title)`.

### Label, Divider & Paragraph

```lua
local lbl = sec:addLabel({text = 'status: ready', center = false, dim = true})
lbl:setText('status: active')

sec:addDivider('section break')

local info = sec:addParagraph({
    title = 'notice',
    content = 'Right-click any slider to enter an exact number.'
})
info:setContent('updated title', 'updated body text')
```

### Built-in Appearance Controls

```lua
sec:addFontSelector({text = 'font'}, function(fontName) end)
sec:addUIScaler({text = 'content scale', min = 0.5, max = 2.0, step = 0.05, val = 1})
sec:addTextScaler({text = 'text scale', min = 0.6, max = 1.8, step = 0.05, val = 1})
```

---

## 5. Live Theme, Color, Font & Scale APIs

Every change updates all live windows, controls, HUD overlays, and future cloned elements immediately.

### Themes & Colors

| Function | Description |
| :--- | :--- |
| `ui.getThemes()` | Returns ordered list of built-in presets: `crimson`, `cobalt`, `emerald`, `amber`, `violet`, `cherry`, `rose`, `monochrome`. |
| `ui.getTheme()` | Returns a copy of the active theme table. |
| `ui.getThemeName()` | Returns the active preset name (or `'custom'`). |
| `ui.setThemePreset(name)` | Applies a built-in preset live. |
| `ui.setAccent(primary, secondary?)` | Updates primary accent, auto-derives secondary stop (if omitted), active fills, and hover strokes live. |
| `ui.setSurfaceColor(baseColor)` | Re-derives all dark window/panel/inset surfaces from a base `Color3` live. |
| `ui.setThemeColor(key, color3)` | Updates any individual theme key (`'Primary'`, `'Secondary'`, `'Stroke'`, `'TextPrimary'`, `'TextDim'`, `'Window1'`, `'Window2'`, `'Window3'`, etc.) live. |
| `ui.applyTheme(patchTable)` | Applies multiple theme key overrides in one pass. |
| `ui.setTransparency(alpha)` | Sets window backdrop translucency live (`0` – `0.45`). |
| `ui.getTransparency()` | Returns current transparency value. |
| `ui.setRounding(enabled)` | Toggles sharp (`0px`) vs rounded (`4px`) corners across the UI live. |
| `ui.setSmoothDragging(enabled)` | Toggles drag inertia live. |
| `ui.resetTheme()` | Restores default `crimson` preset, `buildermono` font, `1.0x` scales, `0` transparency, sharp corners. |

### Fonts & Scaling

| Function | Description |
| :--- | :--- |
| `ui.getFonts()` | Returns all 130+ registered built-in + Creator Store fonts (`{key, name, font}`). |
| `ui.getFont()` / `ui.getFontName()` | Returns active `Font` / key string. |
| `ui.setFont(font)` | Switches UI font live (accepts key name, `ui.fonts.<key>`, numeric Creator Store ID, `Font`, or `Enum.Font`). |
| `ui.setScale(scale)` / `ui.getScale()` | Sets/gets inner content scale (`0.5` – `2.5`) without resizing the outer window. |
| `ui.setTextScale(scale)` / `ui.getTextScale()` | Sets/gets global text scale (`0.6` – `2.0`). |

---

## 6. Popups, Notifications, HUD & Intro

### Centered In-Window Popup — `window:popup(settings)` / `ui.popup(settings)`

Displays a centered modal dialog directly inside the LARPWare window with a dimmed in-window scrim, title, optional badge, wrapped `RichText` content, and customizable action buttons.

```lua
local pop = window:popup({
    title = 'confirm reset',
    badge = 'CONFIRM',
    content = 'This will restore all module settings back to default values. Continue?',
    width = 336,
    dismissOnBackdrop = true,
    dismissOnEscape = true,
    showClose = true,
    buttons = {
        {
            text = 'cancel',
            style = 'secondary',
            callback = function(p)
                print('cancelled')
            end
        },
        {
            text = 'reset',
            style = 'danger',
            callback = function(p)
                print('reset!')
            end
        },
        {
            text = 'confirm',
            style = 'primary',
            autoClose = true,
            callback = function(p)
                print('confirmed!')
            end
        }
    }
})
```

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `title` | `string` | `'notice'` | Header title (`RichText` supported). |
| `content` | `string` | `''` | Body message (`RichText` + auto-wrap supported; aliases: `message`, `desc`). |
| `badge` | `string` | `nil` | Optional compact accent badge shown in the header. |
| `width` | `number` | `336` | Card width in pixels (clamped automatically to fit inside the window). |
| `buttons` | `table` | `{{text='ok', style='primary'}}` | List of button tables `{ text, style = 'primary' \| 'danger' \| 'secondary', autoClose = true, callback = fn(pop) }`. |
| `dismissOnBackdrop` | `boolean` | `true` | Clicking the dimmed backdrop closes the popup. |
| `dismissOnEscape` | `boolean` | `true` | Pressing `Escape` closes the popup. |
| `showClose` | `boolean` | `true` | Displays the header `X` close button. |
| `stack` | `boolean` | `false` | By default, opening a new popup replaces the existing one on that window. Set `true` to stack. |

- **Popup Methods**: `pop:close()`, `pop:setTitle(text)`, `pop:setContent(text)`, `pop:isOpen()`, `pop:bindToEvent('onClose', fn)`.

### Notifications, HUD & Intro

```lua
ui.notify({
    title = 'LARPWare',
    message = 'Configuration loaded successfully.',
    duration = 3
})

ui.setWatermark('LARPWare | v2.2', true)
ui.toggleWatermark(true)

ui.toggleKeybindList(true)
ui.refreshKeybindList()

ui.toggleMobileButton(true)
ui.setMobileButton({
    visible = true,
    size = Vector2.new(52, 52),
    position = UDim2.new(0, 18, 0.5, -26)
})

ui.playIntro()
```

### Built-in UX Features

- **Top-Bar Global Search**: Click the magnifying glass in the titlebar to search every control across all tabs; clicking a result switches tabs, expands minimized sections, scrolls directly to the control, and flash-highlights it.
- **Quick Appearance Popover**: Click the titlebar gear icon (or sidebar footer) for instant searchable font switching, inner UI scale, text scale, and 7 one-click accent color swatches.
- **In-Content Overscroll Easter Egg**: Scrolling down past the bottom of the main tab content frame reveals the cached `LARP` banner inside `#page-region` (never triggered while scrolling nested listboxes, dropdowns, popovers, or the tabbar) and auto-retracts after `0.55s` of idle or on upward scroll.

---

## 7. Complete Starter Template

```lua
local uiLoader = loadstring(game:HttpGet('https://api.x8stuff.lol/larpware/library.lua?t=' .. tostring(os.time())))

local ui = uiLoader({
    font = 'buildermono',
    scale = 1,
    textScale = 1,
    rounding = false,
    smoothDragging = false,
    intro = true
})

ui.setWatermark('MyScript | LARPWare', true)
ui.toggleKeybindList(true)

local win = ui.newWindow({
    text = 'MyScript',
    resize = true,
    size = Vector2.new(600, 420)
})

local mainTab = win:addMenu({text = 'combat'})
local leftSec = mainTab:addSection({text = 'main', side = 'left'})

local enabled = leftSec:addToggle({
    text = 'master switch',
    state = false,
    tooltip = 'Enables the main loop'
}, function(state)
    ui.notify({
        title = 'main',
        message = state and 'Enabled' or 'Disabled',
        duration = 2
    })
end)
enabled:addHotkey({bind = Enum.KeyCode.E})

leftSec:addSlider({
    text = 'range',
    min = 10,
    max = 200,
    step = 1,
    val = 80,
    suffix = 'm'
}, function(v)
    print('range:', v)
end)
```
