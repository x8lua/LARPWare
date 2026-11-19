local uiLoader = loadstring(game:HttpGet('https://api.x8stuff.lol/larpware/library.lua?t=' .. tostring(os.time()) .. '_' .. tostring(math.random(1000, 9999))))

local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'buildermono',
    scale = 1,
    textScale = 1
})

ui.autoDisableToggles = true
ui.setWatermark('LARPWare | v2.2 | build 1119', true)
ui.toggleKeybindList(true)

local window = ui.newWindow({
    text = 'LARPWare',
    resize = true,
    showSearch = true,
    size = Vector2.new(600, 420),
    position = nil
})

local combat = window:addMenu({
    text = 'combat'
})
do
    local mainSec = combat:addSection({
        text = 'aimbot',
        side = 'left',
        showMinButton = true,
        tooltip = 'Primary targeting, hitboxes, and smoothing controls'
    })
    do
        local aimToggle = mainSec:addToggle({
            text = 'enabled',
            state = false,
            tooltip = 'Master switch for the aimbot module'
        }, function(state)
            ui.notify({
                title = 'aimbot',
                message = 'Aimbot ' .. (state and 'enabled' or 'disabled'),
                duration = 2
            })
        end)
        aimToggle:addHotkey({bind = Enum.KeyCode.E, tooltip = 'Keybind to toggle aimbot on or off'})
        aimToggle:addColorPicker({color = Color3.fromRGB(168, 24, 36), tooltip = 'FOV ring overlay color'}, function(c)
            print('fov color:', c)
        end)

        local silentToggle = mainSec:addToggle({
            text = 'silent aim',
            state = true,
            tooltip = 'Redirects projectiles toward target without snapping camera'
        })
        silentToggle:addHotkey({bind = Enum.KeyCode.Q, tooltip = 'Keybind for silent aim toggle'})

        mainSec:addSegmented({
            text = 'targeting mode',
            options = {'silent', 'camlock', 'hybrid'},
            default = 'silent',
            tooltip = 'Selects how aim correction is applied'
        }, function(mode)
            ui.notify({
                title = 'aimbot',
                message = 'Mode set to ' .. mode,
                duration = 2
            })
        end)

        mainSec:addDivider('hitboxes & checks')

        mainSec:addMultiDropdown({
            text = 'hitboxes',
            options = {'Head', 'UpperTorso', 'LowerTorso', 'LeftArm', 'RightArm', 'Legs'},
            default = {'Head', 'UpperTorso'},
            tooltip = 'Body parts eligible for target lock'
        }, function(selected)
            print('hitboxes:', table.concat(selected, ', '))
        end)

        mainSec:addMultiDropdown({
            text = 'checks',
            options = {'Visible', 'Team Check', 'Alive', 'ForceField', 'Friends'},
            default = {'Visible', 'Team Check', 'Alive'},
            tooltip = 'Validation rules evaluated before acquiring a target'
        }, function(selected)
            print('checks:', table.concat(selected, ', '))
        end)

        mainSec:addDivider('smoothing')

        mainSec:addSlider({
            text = 'fov radius',
            min = 10,
            max = 360,
            step = 1,
            val = 120,
            suffix = 'px',
            tooltip = 'Acquisition cone radius in screen pixels. Right-click to type an exact value.'
        }, function(v)
            print('fov:', v)
        end)

        mainSec:addSlider({
            text = 'smoothness',
            min = 0,
            max = 1,
            step = 0.01,
            val = 0.24,
            tooltip = 'Higher values produce slower, more human-like tracking'
        }, function(v)
            print('smooth:', v)
        end)

        mainSec:addRangeSlider({
            text = 'reaction delay',
            min = 0,
            max = 250,
            step = 5,
            low = 35,
            high = 110,
            suffix = 'ms',
            tooltip = 'Randomized min/max reaction window before locking onto a new target'
        }, function(lo, hi)
            print('delay range:', lo, hi)
        end)
    end

    local weaponSec = combat:addSection({
        text = 'trigger & weapon',
        side = 'right',
        showMinButton = true,
        tooltip = 'Auto-fire logic, priority sorting, and live hit telemetry'
    })
    do
        local trigToggle = weaponSec:addToggle({
            text = 'triggerbot',
            state = false,
            tooltip = 'Automatically fires when crosshair passes over a valid hitbox'
        })
        trigToggle:addHotkey({bind = Enum.KeyCode.T, tooltip = 'Keybind to toggle triggerbot'})

        weaponSec:addDropdown({
            text = 'target priority',
            options = {'Closest to Crosshair', 'Lowest Health', 'Shortest Distance', 'Threat Score'},
            default = 'Closest to Crosshair',
            tooltip = 'Sorting heuristic used when multiple targets are in range'
        }, function(v)
            print('priority:', v)
        end)

        weaponSec:addRangeSlider({
            text = 'hitchance window',
            min = 10,
            max = 100,
            step = 1,
            low = 65,
            high = 92,
            suffix = '%',
            tooltip = 'Target accuracy percentage bounds for spread compensation'
        }, function(lo, hi)
            print('hitchance:', lo, hi)
        end)

        weaponSec:addDivider('live telemetry')

        local hpBar = weaponSec:addProgressBar({
            text = 'target health',
            value = 78,
            max = 100,
            suffix = '%',
            tooltip = 'Remaining HP percentage of the current locked target'
        })

        local hitBar = weaponSec:addProgressBar({
            text = 'hit ratio',
            value = 64,
            max = 100,
            suffix = '%',
            tooltip = 'Session shot-to-hit ratio'
        })

        weaponSec:addDualButton({
            left = 'simulate hit',
            right = 'reset stats',
            tooltip = 'Test telemetry bars or reset counters back to baseline'
        }, function()
            hpBar:setValue(math.max(0, hpBar:getValue() - 18))
            hitBar:setValue(math.min(100, hitBar:getValue() + 6))
        end, function()
            hpBar:setValue(100)
            hitBar:setValue(50)
        end)

        weaponSec:addTextbox({
            text = 'override target',
            placeholder = 'enter username...',
            tooltip = 'Force priority lock onto a specific player username'
        }):bindToEvent('onFocusLost', function(text)
            if (text ~= '') then
                ui.notify({
                    title = 'target lock',
                    message = 'Priority locked on ' .. text,
                    duration = 3
                })
            end
        end)

        weaponSec:addButton({
            text = 'clear target override',
            style = 'small',
            tooltip = 'Removes any manual player target lock'
        }, function()
            ui.notify({
                title = 'target lock',
                message = 'Override cleared',
                duration = 2
            })
        end)
    end
end

local visuals = window:addMenu({
    text = 'visuals'
})
do
    local espSec = visuals:addSection({
        text = 'player esp',
        side = 'left',
        showMinButton = true,
        tooltip = '2D/3D overlays, chams, and player flag indicators'
    })
    do
        local masterEsp = espSec:addToggle({
            text = 'master switch',
            state = true,
            tooltip = 'Enables or disables all ESP rendering globally'
        })
        masterEsp:addHotkey({bind = Enum.KeyCode.V, tooltip = 'Quick toggle for all ESP visuals'})

        local boxToggle = espSec:addToggle({
            text = 'bounding box',
            state = true,
            tooltip = 'Draws a bounding box around tracked players'
        })
        boxToggle:addColorPicker({color = Color3.fromRGB(188, 28, 42), tooltip = 'Bounding box outline color'}, function(c)
            print('box color:', c)
        end)

        local chamsToggle = espSec:addToggle({
            text = 'chams highlight',
            state = false,
            tooltip = 'Renders material highlights through walls and obstacles'
        })
        chamsToggle:addColorPicker({color = Color3.fromRGB(220, 60, 72), tooltip = 'Visible chams color'}, function(c)
            print('chams visible:', c)
        end)
        chamsToggle:addColorPicker({color = Color3.fromRGB(90, 14, 24), tooltip = 'Occluded chams color'}, function(c)
            print('chams occluded:', c)
        end)

        espSec:addSegmented({
            text = 'box style',
            options = {'full', 'corner', '3d'},
            default = 'corner',
            tooltip = 'Visual framing style for player boxes'
        }, function(style)
            print('box style:', style)
        end)

        espSec:addMultiDropdown({
            text = 'flags',
            options = {'Name', 'Distance', 'Weapon', 'Health Bar', 'Skeleton', 'Head Dot'},
            default = {'Name', 'Distance', 'Health Bar'},
            tooltip = 'Additional data badges rendered beside each player'
        }, function(flags)
            print('esp flags:', table.concat(flags, ', '))
        end)

        espSec:addSlider({
            text = 'max distance',
            min = 50,
            max = 2500,
            step = 25,
            val = 1200,
            suffix = 'm',
            tooltip = 'Culls ESP overlays beyond this stud distance'
        }, function(v)
            print('esp dist:', v)
        end)
    end

    local worldSec = visuals:addSection({
        text = 'world & camera',
        side = 'right',
        showMinButton = true,
        tooltip = 'Environment atmosphere, lighting tint, and camera FOV'
    })
    do
        worldSec:addLabel({
            text = 'lighting overrides',
            dim = true,
            tooltip = 'Client-side atmosphere adjustments that never replicate'
        })

        worldSec:addToggle({
            text = 'custom ambient',
            state = false,
            tooltip = 'Overrides global Lighting Ambient and OutdoorAmbient colors'
        })

        worldSec:addColorPicker({
            text = 'ambient tint',
            color = Color3.fromRGB(140, 24, 34),
            tooltip = 'Custom world ambient light color'
        }, function(c)
            print('ambient:', c)
        end)

        worldSec:addColorPicker({
            text = 'fog tint',
            color = Color3.fromRGB(22, 16, 18),
            tooltip = 'Custom atmospheric fog tint'
        }, function(c)
            print('fog:', c)
        end)

        worldSec:addDivider('camera')

        worldSec:addSlider({
            text = 'field of view',
            min = 60,
            max = 120,
            step = 1,
            val = 90,
            tooltip = 'Overrides workspace CurrentCamera FieldOfView'
        }, function(v)
            print('cam fov:', v)
        end)

        worldSec:addRangeSlider({
            text = 'time of day cycle',
            min = 0,
            max = 24,
            step = 0.5,
            low = 6,
            high = 18,
            suffix = 'h',
            tooltip = 'Restricts local ClockTime between start and end hours'
        }, function(lo, hi)
            print('time window:', lo, hi)
        end)

        worldSec:addButton({
            text = 'reset world visuals',
            style = 'large',
            tooltip = 'Restores default Lighting and Camera properties'
        }, function()
            ui.notify({
                title = 'visuals',
                message = 'World lighting restored to default',
                duration = 2
            })
        end)
    end
end

local misc = window:addMenu({
    text = 'misc'
})
do
    local moveSec = misc:addSection({
        text = 'movement',
        side = 'left',
        showMinButton = true,
        tooltip = 'Character locomotion overrides and server utilities'
    })
    do
        local speedToggle = moveSec:addToggle({
            text = 'walkspeed override',
            state = false,
            tooltip = 'Continuously applies custom Humanoid WalkSpeed'
        })
        speedToggle:addHotkey({bind = Enum.KeyCode.X, tooltip = 'Keybind to toggle speed override'})

        moveSec:addSlider({
            text = 'walkspeed',
            min = 16,
            max = 120,
            step = 1,
            val = 32,
            tooltip = 'Target Humanoid WalkSpeed in studs per second'
        }, function(v)
            print('walkspeed:', v)
        end)

        moveSec:addToggle({
            text = 'infinite jump',
            state = false,
            tooltip = 'Allows mid-air jumping on every jump input'
        })

        moveSec:addSegmented({
            text = 'anti-aim yaw',
            options = {'off', 'back', 'spin', 'jitter'},
            default = 'off',
            tooltip = 'Character yaw orientation modifier'
        }, function(v)
            print('yaw:', v)
        end)

        moveSec:addDivider()

        moveSec:addLabel({
            text = 'quick actions',
            center = true,
            dim = true
        })

        moveSec:addDualButton({
            left = 'rejoin server',
            right = 'server hop',
            tooltip = 'Reconnect to this instance or migrate to a fresh server'
        }, function()
            ui.notify({title = 'network', message = 'Rejoining current instance...', duration = 2})
        end, function()
            ui.notify({title = 'network', message = 'Searching low-ping server...', duration = 2})
        end)
    end

    local listSec = misc:addSection({
        text = 'players & profiles',
        side = 'right',
        showMinButton = true,
        tooltip = 'Inspect players in the session and manage whitelists'
    })
    do
        local playerList = listSec:addListbox({
            text = 'player directory',
            items = {'x8lua', 'kestrel', 'vex_09', 'solaris', 'marrow', 'cinder', 'nullbyte', 'warden'},
            default = 'x8lua',
            searchable = true,
            height = 110,
            tooltip = 'Search and focus a player for whitelist or spectate actions'
        }, function(plr)
            ui.notify({
                title = 'directory',
                message = 'Focused player: ' .. tostring(plr),
                duration = 2
            })
        end)

        listSec:addDualButton({
            left = 'whitelist',
            right = 'spectate',
            tooltip = 'Exclude selected player from targeting or attach camera to them'
        }, function()
            ui.notify({
                title = 'whitelist',
                message = 'Added ' .. tostring(playerList:getValue()),
                duration = 2
            })
        end, function()
            ui.notify({
                title = 'camera',
                message = 'Spectating ' .. tostring(playerList:getValue()),
                duration = 2
            })
        end)

        listSec:addParagraph({
            title = 'session notice',
            content = 'Right-click any slider bar to type an exact numeric value. Use the top-right magnifying glass to jump to any control across tabs.',
            tooltip = 'Quick usage tips for LARPWare controls'
        })
    end
end

local settingsMenu = window:addMenu({
    text = 'settings'
})
do
    local appearance = settingsMenu:addSection({
        text = 'appearance & theme',
        side = 'left',
        showMinButton = true,
        tooltip = 'Fonts, scaling, live accent colors, surface palette, and window style'
    })
    do
        appearance:addFontSelector({
            text = 'font',
            tooltip = 'Browse and live-preview 130+ built-in and Creator Store fonts'
        }, function(name)
            ui.notify({
                title = 'font',
                message = 'Active font: ' .. name,
                duration = 2
            })
        end)

        appearance:addUIScaler({
            text = 'content scale',
            min = 0.5,
            max = 2.0,
            step = 0.05,
            val = 1,
            tooltip = 'Scales everything inside the window without changing outer window size'
        })

        appearance:addTextScaler({
            text = 'text scale',
            min = 0.6,
            max = 1.8,
            step = 0.05,
            val = 1,
            tooltip = 'Scales every text label, button, and input across the entire UI'
        })

        appearance:addDivider('theme & colors')

        appearance:addDropdown({
            text = 'theme preset',
            options = ui.getThemes(),
            default = ui.getThemeName(),
            tooltip = 'Instantly switch between built-in tactical color palettes'
        }, function(preset)
            ui.setThemePreset(preset)
        end)

        appearance:addColorPicker({
            text = 'accent primary',
            color = ui.getTheme().Primary,
            tooltip = 'Live-updates primary accent color, indicators, sliders, and trims'
        }, function(c)
            ui.setAccent(c)
        end)

        appearance:addColorPicker({
            text = 'accent secondary',
            color = ui.getTheme().Secondary,
            tooltip = 'Live-updates the secondary gradient stop across accents'
        }, function(c)
            ui.setThemeColor('Secondary', c)
        end)

        appearance:addColorPicker({
            text = 'window surface',
            color = ui.getTheme().Window3,
            tooltip = 'Recolors the obsidian window, sidebar, and inset surfaces live'
        }, function(c)
            ui.setSurfaceColor(c)
        end)

        appearance:addColorPicker({
            text = 'border stroke',
            color = ui.getTheme().Stroke,
            tooltip = 'Live-updates panel and control border line colors'
        }, function(c)
            ui.setThemeColor('Stroke', c)
        end)

        appearance:addColorPicker({
            text = 'primary text',
            color = ui.getTheme().TextPrimary,
            tooltip = 'Live-updates main label and title text color'
        }, function(c)
            ui.setThemeColor('TextPrimary', c)
        end)

        appearance:addDivider('window style')

        appearance:addSlider({
            text = 'transparency',
            min = 0,
            max = 0.45,
            step = 0.01,
            val = 0,
            tooltip = 'Adjusts window backdrop translucency in real time'
        }, function(v)
            ui.setTransparency(v)
        end)

        appearance:addToggle({
            text = 'corner rounding',
            state = false,
            tooltip = 'Switches between sharp tactical edges and soft rounded corners live'
        }, function(state)
            ui.setRounding(state)
        end)

        appearance:addToggle({
            text = 'smooth dragging',
            state = false,
            tooltip = 'Enables spring-interpolated inertia while dragging the window'
        }, function(state)
            ui.setSmoothDragging(state)
        end)

        appearance:addButton({
            text = 'reset appearance',
            style = 'small',
            tooltip = 'Restores default dark-crimson palette, Builder Mono font, and 1.0x scale'
        }, function()
            ui.resetTheme()
            ui.notify({
                title = 'appearance',
                message = 'Restored default LARPWare crimson styling',
                duration = 2
            })
        end)
    end

    local cfgSec = settingsMenu:addSection({
        text = 'hud, binds & configs',
        side = 'right',
        showMinButton = true,
        tooltip = 'Menu hotkey, HUD overlays, config profiles, and safe unload'
    })
    do
        local menuKey = cfgSec:addHotkey({
            text = 'toggle menu bind',
            bind = Enum.KeyCode.RightShift,
            tooltip = 'Show or hide the window. Click twice while listening to cancel input.'
        })
        menuKey:linkToControl(window)

        cfgSec:addToggle({
            text = 'watermark',
            state = true,
            tooltip = 'Toggles the draggable top-left LARPWare status bar'
        }, function(state)
            ui.toggleWatermark(state)
        end)

        cfgSec:addToggle({
            text = 'keybind list',
            state = true,
            tooltip = 'Toggles the draggable active keybinds HUD overlay'
        }, function(state)
            ui.toggleKeybindList(state)
        end)

        cfgSec:addTextbox({
            text = 'watermark text',
            placeholder = 'custom watermark...',
            tooltip = 'Press Enter to customize the watermark label text'
        }):bindToEvent('onFocusLost', function(text)
            if (text ~= '') then
                ui.setWatermark(text, true)
            end
        end)

        cfgSec:addDivider('profiles')

        local cfgName = cfgSec:addTextbox({
            text = 'config name',
            placeholder = 'new config name...',
            tooltip = 'Optional name used when saving a new profile'
        })

        local cfgList = cfgSec:addListbox({
            text = 'saved configs',
            items = {'default', 'legit', 'rage', 'streamproof', 'tournament'},
            default = 'default',
            searchable = false,
            height = 96,
            tooltip = 'Click a saved configuration profile to select it'
        }, function(cfg)
            ui.notify({
                title = 'config',
                message = 'Selected profile: ' .. tostring(cfg),
                duration = 2
            })
        end)

        cfgSec:addDualButton({
            left = 'save config',
            right = 'load config',
            tooltip = 'Save current values or load the highlighted profile'
        }, function()
            local name = cfgName:getText()
            if (name == '') then
                name = tostring(cfgList:getValue() or 'default')
            end
            ui.notify({title = 'config', message = 'Saved ' .. name, duration = 2})
        end, function()
            ui.notify({title = 'config', message = 'Loaded ' .. tostring(cfgList:getValue()), duration = 2})
        end)

        local notifyKey = cfgSec:addHotkey({
            text = 'test notify bind',
            bind = Enum.KeyCode.G,
            tooltip = 'Press this key anytime to trigger the linked test notification. Click twice to cancel.'
        })
        notifyKey:linkToControl(cfgSec:addButton({
            text = 'send test notification',
            style = 'small',
            tooltip = 'Dispatches a sample toast notification in the bottom-right corner'
        }, function()
            ui.notify({
                title = 'LARPWare',
                message = 'All systems nominal.',
                duration = 2
            })
        end))

        cfgSec:addDualButton({
            left = 'replay intro',
            right = 'unload ui',
            tooltip = 'Replay the L A R P launch intro or cleanly terminate the UI'
        }, function()
            ui.playIntro()
        end, function()
            ui.terminate()
        end)

        cfgSec:addParagraph({
            title = 'LARPWare v2.2',
            content = 'Tactical dark-crimson UI with Builder Mono default, vector tab rail, live theme & accent color engine, 130+ fonts, global search, animated sections, and duplicate-session guard.',
            tooltip = 'Scroll past the bottom of any tab to reveal the LARP easter egg'
        })
    end
end
