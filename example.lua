local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/library.lua'))

local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false,
    font = 'gotham',
    scale = 1
})

ui.autoDisableToggles = true

local window = ui.newWindow({
    text = 'LARPWare demo',
    resize = true,
    size = Vector2.new(550, 376),
    position = nil
})

local menu = window:addMenu({
    text = 'menu 1'
})
do
    local section = menu:addSection({
        text = 'section 1',
        side = 'auto',
        showMinButton = true
    })

    do
        section:addLabel({
            text = 'text'
        })

        local toggle = section:addToggle({
            text = 'toggle',
            state = false
        })

        toggle:bindToEvent('onToggle', function(newState)
            ui.notify({
                title = 'toggle',
                message = 'Toggle was toggled to ' .. tostring(newState),
                duration = 3
            })
        end)

        section:addButton({
            text = 'button (small)',
            style = 'small'
        }):bindToEvent('onClick', function()
            ui.notify({
                title = 'button',
                message = 'The button got clicked!',
                duration = 3
            })
        end)

        section:addButton({
            text = 'button (large)',
            style = 'large'
        }, function()
            ui.notify({
                title = 'button',
                message = 'The large button got clicked!',
                duration = 3
            })
        end):setTooltip('this is a large button')

        local hotkey = section:addHotkey({
            text = 'hotkey'
        })
        hotkey:setHotkey(Enum.KeyCode.G)
        hotkey:setTooltip('This is a hotkey linked to the toggle!')
        hotkey:linkToControl(toggle)
    end

    local section2 = menu:addSection({
        text = 'section 2',
        side = 'right',
        showMinButton = false
    })
    do
        section2:addSlider({
            text = 'slider',
            min = 1,
            max = 150,
            step = 0.01,
            val = 50
        }, function(newValue)
            print(newValue)
        end):setTooltip('Heres a slider!')

        section2:addColorPicker({
            text = 'color picker',
            color = Color3.fromRGB(255, 0, 0)
        }, function(newColor)
            print(newColor)
        end)

        section2:addTextbox({
            text = 'textbox'
        }):bindToEvent('onFocusLost', function(text)
            ui.notify({
                title = 'textbox',
                message = text,
                duration = 4
            })
        end)

        section2:addDropdown({
            text = 'dropdown',
            options = {'option a', 'option b', 'option c'},
            default = 'option a'
        }, function(selected)
            ui.notify({
                title = 'dropdown',
                message = 'Selected: ' .. tostring(selected),
                duration = 3
            })
        end)
    end
end

local settingsMenu = window:addMenu({
    text = 'settings'
})
do
    local appearance = settingsMenu:addSection({
        text = 'appearance',
        side = 'left',
        showMinButton = true
    })

    appearance:addFontSelector({
        text = 'font'
    }, function(name)
        ui.notify({
            title = 'font',
            message = 'Switched font to .' .. name,
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
end
