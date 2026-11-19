local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))

local ui = uiLoader({
    rounding = false,
    smoothDragging = false,
    font = 'gotham',
    scale = 1
})

ui.autoDisableToggles = true
ui.setWatermark('LARPWare | v2.0 | build 1119', true)
ui.toggleKeybindList(true)

local window = ui.newWindow({
    text = 'LARPWare',
    resize = true,
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
        showMinButton = true
    })
    do
        local aimToggle = mainSec:addToggle({
            text = 'enabled',
            state = false
        }, function(state)
            ui.notify({
                title = 'aimbot',
                message = 'Aimbot ' .. (state and 'enabled' or 'disabled'),
                duration = 2
            })
        end)
        aimToggle:addHotkey({bind = Enum.KeyCode.E})
        aimToggle:addColorPicker({color = Color3.fromRGB(168, 24, 36)}, function(c)
            print('fov color:', c)
        end)

        local silentToggle = mainSec:addToggle({
            text = 'silent aim',
            state = true
        })
        silentToggle:addHotkey({bind = Enum.KeyCode.Q})

        mainSec:addSegmented({
            text = 'targeting mode',
            options = {'silent', 'camlock', 'hybrid'},
            default = 'silent'
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
            default = {'Head', 'UpperTorso'}
        }, function(selected)
            print('hitboxes:', table.concat(selected, ', '))
        end)

        mainSec:addMultiDropdown({
            text = 'checks',
            options = {'Visible', 'Team Check', 'Alive', 'ForceField', 'Friends'},
            default = {'Visible', 'Team Check', 'Alive'}
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
            suffix = 'px'
        }, function(v)
            print('fov:', v)
        end):setTooltip('Right click to enter exact number')

        mainSec:addSlider({
            text = 'smoothness',
            min = 0,
            max = 1,
            step = 0.01,
            val = 0.24
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
            suffix = 'ms'
        }, function(lo, hi)
            print('delay range:', lo, hi)
        end)
    end

    local weaponSec = combat:addSection({
        text = 'trigger & weapon',
        side = 'right',
        showMinButton = true
    })
    do
        local trigToggle = weaponSec:addToggle({
            text = 'triggerbot',
            state = false
        })
        trigToggle:addHotkey({bind = Enum.KeyCode.T})

        weaponSec:addDropdown({
            text = 'target priority',
            options = {'Closest to Crosshair', 'Lowest Health', 'Shortest Distance', 'Threat Score'},
            default = 'Closest to Crosshair'
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
            suffix = '%'
        }, function(lo, hi)
            print('hitchance:', lo, hi)
        end)

        weaponSec:addDivider('live telemetry')

        local hpBar = weaponSec:addProgressBar({
            text = 'target health',
            value = 78,
            max = 100,
            suffix = '%'
        })

        local hitBar = weaponSec:addProgressBar({
            text = 'hit ratio',
            value = 64,
            max = 100,
            suffix = '%'
        })

        weaponSec:addDualButton({
            left = 'simulate hit',
            right = 'reset stats'
        }, function()
            hpBar:setValue(math.max(0, hpBar:getValue() - 18))
            hitBar:setValue(math.min(100, hitBar:getValue() + 6))
        end, function()
            hpBar:setValue(100)
            hitBar:setValue(50)
        end)

        weaponSec:addTextbox({
            text = 'override target',
            placeholder = 'enter username...'
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
            style = 'small'
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
        showMinButton = true
    })
    do
        local masterEsp = espSec:addToggle({
            text = 'master switch',
            state = true
        })
        masterEsp:addHotkey({bind = Enum.KeyCode.V})

        local boxToggle = espSec:addToggle({
            text = 'bounding box',
            state = true
        })
        boxToggle:addColorPicker({color = Color3.fromRGB(188, 28, 42)}, function(c)
            print('box color:', c)
        end)

        local chamsToggle = espSec:addToggle({
            text = 'chams highlight',
            state = false
        })
        chamsToggle:addColorPicker({color = Color3.fromRGB(220, 60, 72)}, function(c)
            print('chams visible:', c)
        end)
        chamsToggle:addColorPicker({color = Color3.fromRGB(90, 14, 24)}, function(c)
            print('chams occluded:', c)
        end)

        espSec:addSegmented({
            text = 'box style',
            options = {'full', 'corner', '3d'},
            default = 'corner'
        }, function(style)
            print('box style:', style)
        end)

        espSec:addMultiDropdown({
            text = 'flags',
            options = {'Name', 'Distance', 'Weapon', 'Health Bar', 'Skeleton', 'Head Dot'},
            default = {'Name', 'Distance', 'Health Bar'}
        }, function(flags)
            print('esp flags:', table.concat(flags, ', '))
        end)

        espSec:addSlider({
            text = 'max distance',
            min = 50,
            max = 2500,
            step = 25,
            val = 1200,
            suffix = 'm'
        }, function(v)
            print('esp dist:', v)
        end)
    end

    local worldSec = visuals:addSection({
        text = 'world & camera',
        side = 'right',
        showMinButton = true
    })
    do
        worldSec:addLabel({
            text = 'lighting overrides',
            dim = true
        })

        worldSec:addToggle({
            text = 'custom ambient',
            state = false
        })

        worldSec:addColorPicker({
            text = 'ambient tint',
            color = Color3.fromRGB(140, 24, 34)
        }, function(c)
            print('ambient:', c)
        end)

        worldSec:addColorPicker({
            text = 'fog tint',
            color = Color3.fromRGB(22, 16, 18)
        }, function(c)
            print('fog:', c)
        end)

        worldSec:addDivider('camera')

        worldSec:addSlider({
            text = 'field of view',
            min = 60,
            max = 120,
            step = 1,
            val = 90
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
            suffix = 'h'
        }, function(lo, hi)
            print('time window:', lo, hi)
        end)

        worldSec:addButton({
            text = 'reset world visuals',
            style = 'large'
        }, function()
            ui.notify({
                title = 'visuals',
                message = 'World lighting restored to default',
                duration = 2
            })
        end):setTooltip('Restores default Lighting properties')
    end
end

local misc = window:addMenu({
    text = 'misc'
})
do
    local moveSec = misc:addSection({
        text = 'movement',
        side = 'left',
        showMinButton = true
    })
    do
        local speedToggle = moveSec:addToggle({
            text = 'walkspeed override',
            state = false
        })
        speedToggle:addHotkey({bind = Enum.KeyCode.X})

        moveSec:addSlider({
            text = 'walkspeed',
            min = 16,
            max = 120,
            step = 1,
            val = 32
        }, function(v)
            print('walkspeed:', v)
        end)

        moveSec:addToggle({
            text = 'infinite jump',
            state = false
        })

        moveSec:addSegmented({
            text = 'anti-aim yaw',
            options = {'off', 'back', 'spin', 'jitter'},
            default = 'off'
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
            right = 'server hop'
        }, function()
            ui.notify({title = 'network', message = 'Rejoining current instance...', duration = 2})
        end, function()
            ui.notify({title = 'network', message = 'Searching low-ping server...', duration = 2})
        end)
    end

    local listSec = misc:addSection({
        text = 'players & profiles',
        side = 'right',
        showMinButton = true
    })
    do
        local playerList = listSec:addListbox({
            text = 'player directory',
            items = {'x8lua', 'kestrel', 'vex_09', 'solaris', 'marrow', 'cinder', 'nullbyte', 'warden'},
            default = 'x8lua',
            searchable = true,
            height = 110
        }, function(plr)
            ui.notify({
                title = 'directory',
                message = 'Focused player: ' .. tostring(plr),
                duration = 2
            })
        end)

        listSec:addDualButton({
            left = 'whitelist',
            right = 'spectate'
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
            content = 'Right-click any slider bar to type an exact numeric value. All toggles automatically disable when the window closes.'
        })
    end
end

local settingsMenu = window:addMenu({
    text = 'settings'
})
do
    local appearance = settingsMenu:addSection({
        text = 'interface',
        side = 'left',
        showMinButton = true
    })
    do
        appearance:addFontSelector({
            text = 'font'
        }, function(name)
            ui.notify({
                title = 'font',
                message = 'Active font: .' .. name,
                duration = 2
            })
        end)

        appearance:addUIScaler({
            text = 'content scale',
            min = 0.5,
            max = 2.0,
            step = 0.05,
            val = 1
        }):setTooltip('Scales everything inside the window without changing window size')

        appearance:addDivider('hud overlays')

        appearance:addToggle({
            text = 'watermark',
            state = true
        }, function(state)
            ui.toggleWatermark(state)
        end)

        appearance:addToggle({
            text = 'keybind list',
            state = true
        }, function(state)
            ui.toggleKeybindList(state)
        end)

        appearance:addTextbox({
            text = 'watermark text',
            placeholder = 'custom watermark...'
        }):bindToEvent('onFocusLost', function(text)
            if (text ~= '') then
                ui.setWatermark(text, true)
            end
        end)
    end

    local cfgSec = settingsMenu:addSection({
        text = 'configs & system',
        side = 'right',
        showMinButton = false
    })
    do
        local cfgName = cfgSec:addTextbox({
            text = 'config name',
            placeholder = 'new config name...'
        })

        local cfgList = cfgSec:addListbox({
            text = 'saved configs',
            items = {'default', 'legit', 'rage', 'streamproof', 'tournament'},
            default = 'default',
            searchable = false,
            height = 96
        }, function(cfg)
            ui.notify({
                title = 'config',
                message = 'Selected profile: ' .. tostring(cfg),
                duration = 2
            })
        end)

        cfgSec:addDualButton({
            left = 'save config',
            right = 'load config'
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
            bind = Enum.KeyCode.G
        })
        notifyKey:linkToControl(cfgSec:addButton({
            text = 'send test notification',
            style = 'large'
        }, function()
            ui.notify({
                title = 'LARPWare',
                message = 'All systems nominal.',
                duration = 2
            })
        end))

        cfgSec:addParagraph({
            title = 'LARPWare v2.0',
            content = 'Dark crimson tactical UI library with live font switching (.code / .gotham), inner content scaling, inline toggle addons, and draggable HUD panels.'
        })
    end
end
