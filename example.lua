local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))

local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false,
    font = 'gotham',
    scale = 1
})

ui.autoDisableToggles = true
ui.setWatermark('LARPWare | v2.0 | cherry', true)
ui.toggleKeybindList(true)

local window = ui.newWindow({
    text = 'LARPWare',
    resize = true,
    size = Vector2.new(580, 410),
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
                message = 'State: ' .. tostring(state),
                duration = 2
            })
        end)
        aimToggle:addHotkey({bind = Enum.KeyCode.E})
        aimToggle:addColorPicker({color = Color3.fromRGB(249, 22, 52)}, function(c)
            print('fov color:', c)
        end)

        mainSec:addSegmented({
            text = 'mode',
            options = {'silent', 'camlock', 'hybrid'},
            default = 'silent'
        }, function(mode)
            ui.notify({
                title = 'mode',
                message = 'Switched to ' .. mode,
                duration = 2
            })
        end)

        mainSec:addDivider('targeting')

        mainSec:addMultiDropdown({
            text = 'hitboxes',
            options = {'Head', 'UpperTorso', 'LowerTorso', 'Arms', 'Legs'},
            default = {'Head', 'UpperTorso'}
        }, function(selected)
            print('hitboxes:', table.concat(selected, ', '))
        end)

        mainSec:addRangeSlider({
            text = 'delay range',
            min = 0,
            max = 250,
            step = 5,
            low = 35,
            high = 110,
            suffix = 'ms'
        }, function(lo, hi)
            print('delay:', lo, hi)
        end)

        mainSec:addSlider({
            text = 'fov radius',
            min = 10,
            max = 360,
            step = 1,
            val = 120
        }, function(v)
            print('fov:', v)
        end):setTooltip('Right click to type exact value')
    end

    local utilSec = combat:addSection({
        text = 'utilities',
        side = 'right',
        showMinButton = true
    })
    do
        local statusBar = utilSec:addProgressBar({
            text = 'target health',
            value = 78,
            max = 100,
            suffix = '%'
        })

        utilSec:addDualButton({
            left = 'refill',
            right = 'drain'
        }, function()
            statusBar:setValue(100)
        end, function()
            statusBar:setValue(24)
        end)

        utilSec:addDropdown({
            text = 'priority',
            options = {'Closest', 'Lowest HP', 'FOV'},
            default = 'FOV'
        }, function(v)
            print('priority:', v)
        end)

        utilSec:addTextbox({
            text = 'target name',
            placeholder = 'enter username...'
        }):bindToEvent('onFocusLost', function(text)
            if (text ~= '') then
                ui.notify({
                    title = 'target',
                    message = 'Locked: ' .. text,
                    duration = 3
                })
            end
        end)

        utilSec:addListbox({
            text = 'configs',
            items = {'default', 'legit', 'rage', 'hvh', 'streamproof', 'tournament'},
            default = 'default',
            searchable = true,
            height = 100
        }, function(cfg)
            ui.notify({
                title = 'config',
                message = 'Selected ' .. tostring(cfg),
                duration = 2
            })
        end)

        utilSec:addButton({
            text = 'small trigger',
            style = 'small'
        }, function()
            ui.notify({title = 'trigger', message = 'Fired small button', duration = 2})
        end)

        utilSec:addButton({
            text = 'execute action',
            style = 'large'
        }, function()
            ui.notify({title = 'action', message = 'Executed large button', duration = 2})
        end)
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
            text = 'ui scale',
            min = 0.5,
            max = 2.0,
            step = 0.05,
            val = 1
        })

        appearance:addDivider('hud')

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
    end

    local infoSec = settingsMenu:addSection({
        text = 'about',
        side = 'right',
        showMinButton = false
    })
    do
        infoSec:addParagraph({
            title = 'LARPWare UI',
            content = 'Refined dark tactical interface with live font switching (.code / .gotham), full UI scaling, inline toggle addons, range sliders, multi-select dropdowns, and draggable HUD panels.'
        })

        local hk = infoSec:addHotkey({
            text = 'menu notify key',
            bind = Enum.KeyCode.G
        })
        hk:linkToControl(infoSec:addButton({
            text = 'ping notification',
            style = 'large'
        }, function()
            ui.notify({
                title = 'LARPWare',
                message = 'Ping received',
                duration = 2
            })
        end))
    end
end
