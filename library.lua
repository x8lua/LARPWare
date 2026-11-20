local inputService = game:GetService('UserInputService')
local renderService = game:GetService('RunService')
local tweenService = game:GetService('TweenService')
local guiService = game:GetService('GuiService')

local tween
do
    local styleEnum = Enum.EasingStyle
    local dirEnum = Enum.EasingDirection
    local direction = dirEnum.Out
    local styles = {styleEnum.Exponential, styleEnum.Linear, styleEnum.Quad, styleEnum.Back, styleEnum.Quint}

    function tween(object, props, duration, style)
        local tweenInfo = TweenInfo.new(duration, styles[style or 1] or styleEnum.Exponential, direction)
        local tw = tweenService:Create(object, tweenInfo, props)
        tw:Play()
        return tw
    end
end

local currentTextScale = 1
local currentTransparency = 0
local enableIntro = true
local enableMobileButton = (inputService.TouchEnabled and not inputService.KeyboardEnabled)
local enableCursorUnlock = true
local theme

local function isPrimaryInput(io)
    return io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch
end

local function isMoveInput(io)
    return io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch
end

local function getViewportInfo()
    local cam = workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or guiService:GetScreenResolution()
    local inset = guiService:GetGuiInset()
    local topInset = (inset and inset.Y) or 0
    return math.max(320, vp.X), math.max(200, vp.Y - topInset), topInset
end

local function isCompactViewport()
    local vpX, availH = getViewportInfo()
    return vpX <= 980 or availH <= 540 or (inputService.TouchEnabled and not inputService.MouseEnabled)
end

local function getHudScale()
    local vpX, availH = getViewportInfo()
    if (isCompactViewport()) then
        return math.clamp(math.min(vpX / 960, availH / 460), 0.68, 0.86)
    end
    return 1
end
local rounding
local cornerPx = 0

local themeKeyOrder = {
    'Primary', 'Secondary', 'StrokeHover',
    'Window1', 'Window2', 'Window3',
    'Button1', 'Button2', 'Button3', 'Button4',
    'Stroke', 'Inset1', 'Inset2', 'Inset3',
    'TextPrimary', 'TextDim', 'TextStroke'
}

local function findThemeKey(val)
    if (typeof(val) ~= 'Color3' or typeof(theme) ~= 'table') then
        return nil
    end
    for i = 1, #themeKeyOrder do
        local k = themeKeyOrder[i]
        if (theme[k] == val) then
            return k
        end
    end
    return nil
end

local function create(className, props, parent)
    local inst = Instance.new(className)
    if (props) then
        for k, v in pairs(props) do
            if (k == 'Font' and typeof(v) == 'Font') then
                inst.FontFace = v
            elseif (k == 'TextSize' and typeof(v) == 'number') then
                inst:SetAttribute('BaseTextSize', v)
                inst.TextSize = math.max(6, math.floor(v * currentTextScale + 0.5))
            else
                inst[k] = v
                if (typeof(v) == 'Color3' and typeof(theme) == 'table') then
                    local tk = findThemeKey(v)
                    if (tk) then
                        if (k == 'BackgroundColor3') then
                            inst:SetAttribute('ThemeBG', tk)
                        elseif (k == 'TextColor3') then
                            inst:SetAttribute('ThemeText', tk)
                        elseif (k == 'ScrollBarImageColor3') then
                            inst:SetAttribute('ThemeScroll', tk)
                        elseif (k == 'BorderColor3') then
                            inst:SetAttribute('ThemeBorder', tk)
                        end
                    end
                end
            end
        end
    end
    if (parent) then
        inst.Parent = parent
    end
    return inst
end

local function makeCorner(parent, radius, fixed)
    local c = create('UICorner', {
        Name = '#round',
        CornerRadius = UDim.new(0, radius)
    }, parent)
    if (not fixed and radius == cornerPx) then
        c:SetAttribute('ThemeCorner', true)
    end
    return c
end

local function makeStroke(parent, color, thickness)
    local s = create('UIStroke', {
        Name = '#stroke',
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Thickness = thickness or 1
    }, parent)
    local tk = findThemeKey(color)
    if (tk) then
        s:SetAttribute('ThemeStroke', tk)
    end
    return s
end

local function makeGradient(parent, c1, c2, rotation)
    local g = create('UIGradient', {
        Name = '#gradient',
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 0,
        Enabled = true
    }, parent)
    if (typeof(theme) == 'table' and c1 == theme.Primary and c2 == theme.Secondary) then
        g:SetAttribute('ThemeAccentGrad', true)
    end
    return g
end

local function makeTopSheen(parent, zIndex)
    return create('Frame', {
        Name = '#sheen',
        Active = false,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.93,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = zIndex
    }, parent)
end

local function blendColor(c1, c2, alpha)
    return c1:Lerp(c2, alpha)
end

local args = {...}
local animSpeed = 1e-12

local function makePresetTheme(primary, secondary, surface)
    local base = surface or Color3.fromRGB(11, 11, 12)
    local function shift(c, d)
        return Color3.new(
            math.clamp(c.R + d, 0, 1),
            math.clamp(c.G + d, 0, 1),
            math.clamp(c.B + d, 0, 1)
        )
    end
    return {
        Primary = primary,
        Secondary = secondary,

        Window1 = shift(base, 0.012),
        Window2 = shift(base, -0.012),
        Window3 = base,

        Button1 = shift(base, 0.018),
        Button2 = shift(base, 0.042),
        Button3 = blendColor(shift(base, 0.025), primary, 0.14),
        Button4 = blendColor(shift(base, 0.045), primary, 0.22),

        Stroke = shift(base, 0.075),
        StrokeHover = blendColor(shift(base, 0.08), primary, 0.45),

        Inset1 = shift(base, -0.02),
        Inset2 = shift(base, -0.03),
        Inset3 = shift(base, -0.024),

        TextPrimary = Color3.fromRGB(240, 240, 244),
        TextStroke = Color3.fromRGB(0, 0, 0),
        TextDim = Color3.fromRGB(146, 146, 154),

        ControlGradient1 = Color3.fromRGB(255, 255, 255),
        ControlGradient2 = Color3.fromRGB(190, 190, 190)
    }
end

local themePresets = {
    crimson = makePresetTheme(Color3.fromRGB(168, 24, 36), Color3.fromRGB(108, 12, 22)),
    cobalt = makePresetTheme(Color3.fromRGB(42, 122, 238), Color3.fromRGB(22, 68, 158)),
    emerald = makePresetTheme(Color3.fromRGB(26, 184, 108), Color3.fromRGB(14, 108, 64)),
    amber = makePresetTheme(Color3.fromRGB(228, 132, 28), Color3.fromRGB(154, 72, 14)),
    violet = makePresetTheme(Color3.fromRGB(142, 74, 242), Color3.fromRGB(82, 34, 166)),
    cherry = makePresetTheme(Color3.fromRGB(235, 28, 72), Color3.fromRGB(156, 14, 62)),
    rose = makePresetTheme(Color3.fromRGB(214, 84, 122), Color3.fromRGB(128, 38, 68)),
    monochrome = makePresetTheme(Color3.fromRGB(218, 222, 230), Color3.fromRGB(124, 130, 142))
}
local themePresetOrder = {'crimson', 'cobalt', 'emerald', 'amber', 'violet', 'cherry', 'rose', 'monochrome'}
local currentThemeName = 'crimson'

local fontMap = {}
local fontDisplayNames = {}
local fontOrder = {}

local function normalizeFontKey(str)
    return tostring(str):lower():gsub('^%.', ''):gsub('[^%w]', '')
end

local function makeCloudFont(id)
    local ok, f = pcall(function()
        return Font.new('rbxassetid://' .. tostring(id), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if (ok and f) then
        return f
    end
    return Enum.Font.Roboto
end

local function makeEnumFont(enumItem)
    local ok, f = pcall(function()
        return Font.fromEnum(enumItem)
    end)
    if (ok and f) then
        return f
    end
    return enumItem
end

do
    local marketplaceFonts = {
        {'Inter', 12187365364},
        {'Builder Mono', 16658246179},
        {'Builder Sans', 16658221428},
        {'Builder Extended', 16658237174},
        {'IBM Plex Sans JP', 12187364147},
        {'Fira Sans', 12187374954},
        {'Barlow', 12187372847},
        {'Rajdhani', 12187375422},
        {'Sono Monospace', 12187362578},
        {'Sono', 12187374537},
        {'Silkscreen', 12187371840},
        {'DotGothic16', 115505072169205},
        {'Work Sans', 12187373327},
        {'Montserrat', 11702779517},
        {'Poppins', 11702779409},
        {'Open Sans', 11598121416},
        {'Lato', 11598289817},
        {'Noto Sans', 12187370747},
        {'Nunito Sans', 12187363368},
        {'Mulish', 12187372629},
        {'PT Sans', 12187606934},
        {'PT Serif', 12187606624},
        {'Rubik', 12187365977},
        {'Kanit', 12187373592},
        {'Cairo', 12187377099},
        {'Mukta', 12187365559},
        {'Hind', 12187361116},
        {'Hind Siliguri', 12187361378},
        {'Prompt', 12187607287},
        {'Raleway', 11702779240},
        {'Quicksand', 12187371324},
        {'Goldman', 115884882777577},
        {'Audiowide', 12187360881},
        {'Teko', 12187376174},
        {'Antonio', 122516982241677},
        {'Unica One', 12187364842},
        {'Roboto Slab', 12187368625},
        {'Arimo', 16658254058},
        {'Tajawal', 12187377588},
        {'Nanum Gothic', 12187361718},
        {'Noto Sans HK', 12187362892},
        {'Noto Serif HK', 12187366846},
        {'Noto Serif JP', 12187369639},
        {'Noto Serif SC', 12187376739},
        {'Noto Serif TC', 12187368093},
        {'M PLUS Rounded 1c', 12188570269},
        {'Lora', 12187366657},
        {'Libre Baskerville', 12187365769},
        {'Playfair Display', 12187374765},
        {'Akronim', 12187368317},
        {'Are You Serious', 12187363616},
        {'Barrio', 12187371991},
        {'Blaka', 12187365104},
        {'Bungee Inline', 12187370000},
        {'Bungee Shade', 12187367666},
        {'Caesar Dressing', 12187368843},
        {'Caveat', 12187369802},
        {'Codystar', 12187363887},
        {'Comic Neue', 127896232205472},
        {'Damion', 12187607722},
        {'Dancing Script', 8764312106},
        {'Eater', 12187372382},
        {'Faster One', 12187370928},
        {'Finger Paint', 12187375716},
        {'Frijole', 12187375194},
        {'Fuzzy Bubbles', 11322590111},
        {'Great Vibes', 12187375958},
        {'Irish Grover', 12187376910},
        {'Italianno', 12187374273},
        {'Jolly Lodger', 77368255811694},
        {'Kings', 12187371622},
        {'La Belle Aurore', 12187607116},
        {'Lobster', 8836875837},
        {'Londrina Solid', 113086061264643},
        {'Marhey', 12187364648},
        {'Monofett', 12187606783},
        {'Monoton', 12187374098},
        {'Nosifer', 12187377325},
        {'Nothing You Could Do', 12187367901},
        {'Pacifico', 12187367362},
        {'Parisienne', 12187361943},
        {'Rubik Burned', 12187363148},
        {'Rubik Iso', 12187362120},
        {'Rubik Marker Hatch', 12187367066},
        {'Rubik Maze', 12187366475},
        {'Rubik Wet Paint', 12187369046},
        {'Rye', 12187372175},
        {'Sedgwick Ave Display', 12187376357},
        {'Shadows Into Light', 12187607493},
        {'Tangerine', 12187376545},
        {'Yellowtail', 12187373881}
    }

    for _, item in ipairs(Enum.Font:GetEnumItems()) do
        if (item ~= Enum.Font.Unknown) then
            local k = normalizeFontKey(item.Name)
            if (not fontMap[k]) then
                fontMap[k] = makeEnumFont(item)
                fontDisplayNames[k] = item.Name
            end
        end
    end

    for _, entry in ipairs(marketplaceFonts) do
        local name, id = entry[1], entry[2]
        local k = normalizeFontKey(name)
        if (not fontMap[k]) then
            fontMap[k] = makeCloudFont(id)
            fontDisplayNames[k] = name
        end
    end

    local featured = {
        'buildermono', 'buildersans', 'inter', 'roboto', 'robotomono', 'robotocondensed',
        'ibmplexsansjp', 'firasans', 'barlow', 'rajdhani', 'titilliumweb', 'ubuntu',
        'arimo', 'jura', 'sarpanch', 'worksans', 'montserrat', 'opensans', 'notosans',
        'lato', 'sonomonospace', 'silkscreen', 'dotgothic16', 'code', 'gotham'
    }
    local added = {}
    for _, k in ipairs(featured) do
        if (fontMap[k] and not added[k]) then
            table.insert(fontOrder, k)
            added[k] = true
        end
    end

    local rest = {}
    for k in pairs(fontMap) do
        if (not added[k]) then
            table.insert(rest, k)
        end
    end
    table.sort(rest, function(a, b)
        return (fontDisplayNames[a] or a):lower() < (fontDisplayNames[b] or b):lower()
    end)
    for _, k in ipairs(rest) do
        table.insert(fontOrder, k)
    end
end

local currentFontKey = fontMap.buildermono and 'buildermono' or (fontMap.inter and 'inter' or 'roboto')
local currentFont = fontMap[currentFontKey] or Enum.Font.RobotoMono
local currentScale = 1

local function resolveFont(input)
    if (typeof(input) == 'Font') then
        for k, v in pairs(fontMap) do
            if (v == input) then
                return k, v
            end
        end
        return 'custom', input
    elseif (typeof(input) == 'EnumItem' and input.EnumType == Enum.Font) then
        local k = normalizeFontKey(input.Name)
        if (fontMap[k]) then
            return k, fontMap[k]
        end
        return k, makeEnumFont(input)
    elseif (typeof(input) == 'number') then
        return tostring(input), makeCloudFont(input)
    elseif (typeof(input) == 'string') then
        local trimmed = input:gsub('^%s+', ''):gsub('%s+$', '')
        if (trimmed:match('^rbxassetid://%d+$') or trimmed:match('^rbxasset://')) then
            local ok, f = pcall(function()
                return Font.new(trimmed, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end)
            if (ok and f) then
                return trimmed, f
            end
        end
        local numId = tonumber(trimmed)
        if (numId) then
            return trimmed, makeCloudFont(numId)
        end
        local cleaned = normalizeFontKey(trimmed)
        if (fontMap[cleaned]) then
            return cleaned, fontMap[cleaned]
        end
        local ok, enumFont = pcall(function()
            return Enum.Font[trimmed]
        end)
        if (ok and enumFont) then
            return cleaned, makeEnumFont(enumFont)
        end
    end
    return currentFontKey, currentFont
end

do
    if (#args > 0 and typeof(args[1]) == 'table') then
        local settings = args[1]
        theme = settings.theme
        rounding = settings.rounding
        if (settings.smoothDragging == nil) then
            settings.smoothDragging = true
        end
        animSpeed = settings.smoothDragging and 1e-12 or 0
        if (settings.font ~= nil) then
            currentFontKey, currentFont = resolveFont(settings.font)
        end
        if (typeof(settings.scale) == 'number') then
            currentScale = math.clamp(settings.scale, 0.5, 2.5)
        end
        if (typeof(settings.textScale) == 'number') then
            currentTextScale = math.clamp(settings.textScale, 0.6, 2.0)
        end
        if (settings.intro ~= nil) then
            enableIntro = settings.intro and true or false
        end
        if (settings.mobileButton ~= nil) then
            enableMobileButton = settings.mobileButton and true or false
        end
        if (settings.unlockCursor ~= nil) then
            enableCursorUnlock = settings.unlockCursor and true or false
        elseif (settings.forceCursor ~= nil) then
            enableCursorUnlock = settings.forceCursor and true or false
        end
        if (typeof(theme) == 'string') then
            if (theme == 'cherry') then
                theme = {
                    Primary = Color3.fromRGB(249, 22, 52),
                    Secondary = Color3.fromRGB(247, 22, 149),

                    Window1 = Color3.fromRGB(14, 14, 15),
                    Window2 = Color3.fromRGB(8, 8, 9),
                    Window3 = Color3.fromRGB(11, 11, 12),

                    Button1 = Color3.fromRGB(16, 16, 18),
                    Button2 = Color3.fromRGB(22, 22, 25),
                    Button3 = Color3.fromRGB(28, 22, 25),
                    Button4 = Color3.fromRGB(36, 26, 30),

                    Stroke = Color3.fromRGB(32, 32, 35),
                    StrokeHover = Color3.fromRGB(108, 30, 44),

                    Inset1 = Color3.fromRGB(6, 6, 7),
                    Inset2 = Color3.fromRGB(3, 3, 4),
                    Inset3 = Color3.fromRGB(5, 5, 6),

                    TextPrimary = Color3.fromRGB(242, 242, 245),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(148, 148, 156),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(195, 195, 195)
                }
            elseif (theme == 'orange') then
                theme = {
                    Primary = Color3.fromRGB(244, 148, 22),
                    Secondary = Color3.fromRGB(247, 57, 22),

                    Window1 = Color3.fromRGB(20, 20, 22),
                    Window2 = Color3.fromRGB(11, 11, 13),
                    Window3 = Color3.fromRGB(15, 15, 17),

                    Button1 = Color3.fromRGB(20, 20, 23),
                    Button2 = Color3.fromRGB(27, 27, 31),
                    Button3 = Color3.fromRGB(33, 29, 26),
                    Button4 = Color3.fromRGB(42, 35, 30),

                    Stroke = Color3.fromRGB(48, 48, 52),
                    StrokeHover = Color3.fromRGB(130, 82, 42),

                    Inset1 = Color3.fromRGB(9, 9, 11),
                    Inset2 = Color3.fromRGB(5, 5, 7),
                    Inset3 = Color3.fromRGB(7, 7, 9),

                    TextPrimary = Color3.fromRGB(244, 244, 246),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(156, 156, 162),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'lemon') then
                theme = {
                    Primary = Color3.fromRGB(220, 255, 66),
                    Secondary = Color3.fromRGB(232, 173, 25),

                    Window1 = Color3.fromRGB(24, 24, 24),
                    Window2 = Color3.fromRGB(15, 15, 15),
                    Window3 = Color3.fromRGB(19, 19, 19),

                    Button1 = Color3.fromRGB(28, 28, 28),
                    Button2 = Color3.fromRGB(36, 36, 36),
                    Button3 = Color3.fromRGB(42, 42, 38),
                    Button4 = Color3.fromRGB(50, 50, 44),

                    Stroke = Color3.fromRGB(50, 50, 50),
                    StrokeHover = Color3.fromRGB(115, 118, 56),

                    Inset1 = Color3.fromRGB(12, 12, 12),
                    Inset2 = Color3.fromRGB(7, 7, 7),
                    Inset3 = Color3.fromRGB(10, 10, 10),

                    TextPrimary = Color3.fromRGB(245, 245, 245),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(160, 160, 160),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'lime') then
                theme = {
                    Primary = Color3.fromRGB(33, 255, 120),
                    Secondary = Color3.fromRGB(120, 255, 33),

                    Window1 = Color3.fromRGB(22, 23, 24),
                    Window2 = Color3.fromRGB(14, 15, 16),
                    Window3 = Color3.fromRGB(18, 19, 20),

                    Button1 = Color3.fromRGB(26, 28, 29),
                    Button2 = Color3.fromRGB(34, 36, 38),
                    Button3 = Color3.fromRGB(32, 42, 36),
                    Button4 = Color3.fromRGB(38, 50, 43),

                    Stroke = Color3.fromRGB(48, 52, 50),
                    StrokeHover = Color3.fromRGB(52, 128, 76),

                    Inset1 = Color3.fromRGB(11, 12, 13),
                    Inset2 = Color3.fromRGB(7, 8, 9),
                    Inset3 = Color3.fromRGB(9, 10, 11),

                    TextPrimary = Color3.fromRGB(244, 246, 245),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(154, 160, 156),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'raspberry') then
                theme = {
                    Primary = Color3.fromRGB(0, 190, 255),
                    Secondary = Color3.fromRGB(0, 255, 190),

                    Window1 = Color3.fromRGB(20, 22, 25),
                    Window2 = Color3.fromRGB(12, 14, 16),
                    Window3 = Color3.fromRGB(16, 18, 21),

                    Button1 = Color3.fromRGB(22, 24, 28),
                    Button2 = Color3.fromRGB(28, 32, 36),
                    Button3 = Color3.fromRGB(26, 38, 44),
                    Button4 = Color3.fromRGB(32, 46, 54),

                    Stroke = Color3.fromRGB(44, 50, 56),
                    StrokeHover = Color3.fromRGB(42, 118, 145),

                    Inset1 = Color3.fromRGB(10, 11, 13),
                    Inset2 = Color3.fromRGB(6, 7, 9),
                    Inset3 = Color3.fromRGB(8, 9, 11),

                    TextPrimary = Color3.fromRGB(242, 246, 250),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(150, 160, 170),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'blueberry') then
                theme = {
                    Primary = Color3.fromRGB(91, 77, 249),
                    Secondary = Color3.fromRGB(130, 76, 247),

                    Window1 = Color3.fromRGB(18, 18, 22),
                    Window2 = Color3.fromRGB(10, 10, 13),
                    Window3 = Color3.fromRGB(14, 14, 18),

                    Button1 = Color3.fromRGB(18, 18, 23),
                    Button2 = Color3.fromRGB(24, 24, 31),
                    Button3 = Color3.fromRGB(28, 26, 44),
                    Button4 = Color3.fromRGB(36, 33, 56),

                    Stroke = Color3.fromRGB(42, 42, 52),
                    StrokeHover = Color3.fromRGB(84, 76, 158),

                    Inset1 = Color3.fromRGB(9, 9, 12),
                    Inset2 = Color3.fromRGB(5, 5, 8),
                    Inset3 = Color3.fromRGB(7, 7, 10),

                    TextPrimary = Color3.fromRGB(242, 242, 248),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(152, 152, 168),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'grape') then
                theme = {
                    Primary = Color3.fromRGB(148, 66, 255),
                    Secondary = Color3.fromRGB(211, 53, 255),

                    Window1 = Color3.fromRGB(18, 16, 20),
                    Window2 = Color3.fromRGB(10, 9, 12),
                    Window3 = Color3.fromRGB(14, 12, 16),

                    Button1 = Color3.fromRGB(18, 16, 22),
                    Button2 = Color3.fromRGB(25, 22, 30),
                    Button3 = Color3.fromRGB(34, 25, 44),
                    Button4 = Color3.fromRGB(42, 31, 56),

                    Stroke = Color3.fromRGB(42, 36, 50),
                    StrokeHover = Color3.fromRGB(108, 60, 170),

                    Inset1 = Color3.fromRGB(8, 7, 10),
                    Inset2 = Color3.fromRGB(4, 3, 6),
                    Inset3 = Color3.fromRGB(6, 5, 8),

                    TextPrimary = Color3.fromRGB(245, 242, 250),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(152, 138, 174),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'watermelon') then
                theme = {
                    Primary = Color3.fromRGB(38, 233, 195),
                    Secondary = Color3.fromRGB(233, 38, 115),

                    Window1 = Color3.fromRGB(24, 24, 28),
                    Window2 = Color3.fromRGB(15, 15, 19),
                    Window3 = Color3.fromRGB(19, 19, 23),

                    Button1 = Color3.fromRGB(27, 27, 32),
                    Button2 = Color3.fromRGB(35, 35, 42),
                    Button3 = Color3.fromRGB(38, 44, 48),
                    Button4 = Color3.fromRGB(46, 54, 60),

                    Stroke = Color3.fromRGB(46, 46, 54),
                    StrokeHover = Color3.fromRGB(78, 84, 96),

                    Inset1 = Color3.fromRGB(12, 12, 15),
                    Inset2 = Color3.fromRGB(8, 8, 11),
                    Inset3 = Color3.fromRGB(10, 10, 13),

                    TextPrimary = Color3.fromRGB(244, 244, 248),
                    TextStroke = Color3.fromRGB(0, 0, 0),
                    TextDim = Color3.fromRGB(156, 156, 166),

                    ControlGradient1 = Color3.fromRGB(255, 255, 255),
                    ControlGradient2 = Color3.fromRGB(192, 192, 192)
                }
            elseif (theme == 'darkred' or theme == 'crimson' or theme == 'larp' or theme == 'default') then
                theme = nil
            end
        end
    end

    if (rounding == nil) then
        rounding = true
    end
    if (typeof(theme) ~= 'table') then
        theme = {
            Primary = Color3.fromRGB(168, 24, 36),
            Secondary = Color3.fromRGB(108, 12, 22),

            Window1 = Color3.fromRGB(13, 13, 14),
            Window2 = Color3.fromRGB(8, 8, 9),
            Window3 = Color3.fromRGB(11, 11, 12),

            Button1 = Color3.fromRGB(15, 15, 17),
            Button2 = Color3.fromRGB(21, 21, 24),
            Button3 = Color3.fromRGB(28, 17, 19),
            Button4 = Color3.fromRGB(36, 20, 23),

            Stroke = Color3.fromRGB(30, 30, 33),
            StrokeHover = Color3.fromRGB(104, 24, 34),

            Inset1 = Color3.fromRGB(6, 6, 7),
            Inset2 = Color3.fromRGB(3, 3, 4),
            Inset3 = Color3.fromRGB(5, 5, 6),

            TextPrimary = Color3.fromRGB(240, 240, 243),
            TextStroke = Color3.fromRGB(0, 0, 0),
            TextDim = Color3.fromRGB(146, 146, 154),

            ControlGradient1 = Color3.fromRGB(255, 255, 255),
            ControlGradient2 = Color3.fromRGB(190, 190, 190)
        }
    end
end

cornerPx = rounding and 2 or 0

local function getGlobalEnv()
    if (typeof(getgenv) == 'function') then
        local ok, g = pcall(getgenv)
        if (ok and typeof(g) == 'table') then
            return g
        end
    end
    return _G
end

local function randomGuiName()
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local str = ''
    for i = 1, 14 do
        local idx = math.random(1, #chars)
        str = str .. chars:sub(idx, idx)
    end
    return str
end

local function resolveUiContainer()
    if (typeof(gethui) == 'function') then
        local ok, hui = pcall(gethui)
        if (ok and typeof(hui) == 'Instance') then
            return hui
        end
    end
    local ok, cg = pcall(function()
        return game:GetService('CoreGui')
    end)
    if (ok and cg) then
        return cg
    end
    return game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
end

local globalEnv = getGlobalEnv()
local REG_KEY = '__LARPWareActiveInstance'
local PROMPT_KEY = '__LARPWareDuplicatePrompt'
local targetParent = resolveUiContainer()

local function findExistingInstances()
    local existing = globalEnv[REG_KEY]
    local orphans = {}
    if (targetParent) then
        for _, child in ipairs(targetParent:GetChildren()) do
            if (child:IsA('ScreenGui') and child:GetAttribute('LARPWareInstance') == true) then
                table.insert(orphans, child)
            end
        end
    end
    local hasActive = false
    if (typeof(existing) == 'table' and existing.active) then
        if (not existing.screenGui or existing.screenGui.Parent ~= nil) then
            hasActive = true
        end
    end
    if (not hasActive and #orphans > 0) then
        hasActive = true
    end
    return hasActive, existing, orphans
end

local function showDuplicateWarning(existing)
    if (globalEnv[PROMPT_KEY]) then
        pcall(function()
            globalEnv[PROMPT_KEY]:Destroy()
        end)
        globalEnv[PROMPT_KEY] = nil
    end

    local modalGui = Instance.new('ScreenGui')
    modalGui.Name = randomGuiName()
    modalGui.IgnoreGuiInset = true
    modalGui.OnTopOfCoreBlur = true
    modalGui.DisplayOrder = 100500
    modalGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    modalGui.ResetOnSpawn = false
    modalGui.Parent = targetParent
    globalEnv[PROMPT_KEY] = modalGui

    local backdrop = create('TextButton', {
        Active = true,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Name = '#backdrop',
        Size = UDim2.fromScale(1, 1),
        Text = '',
        ZIndex = 5000
    }, modalGui)

    local card = create('Frame', {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Window1,
        BorderSizePixel = 0,
        Name = '#dup-card',
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(378, 198),
        ZIndex = 5010
    }, modalGui)
    makeCorner(card, cornerPx)
    makeStroke(card, theme.StrokeHover, 1)
    local cardScale = create('UIScale', {Name = '#scale', Scale = 0.92}, card)

    create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = 'rbxassetid://7331400934',
        ImageColor3 = Color3.fromRGB(0, 0, 5),
        ImageTransparency = 0.12,
        Name = '#shadow',
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 56, 1, 56),
        SliceCenter = Rect.new(40, 40, 260, 260),
        SliceScale = 1,
        ZIndex = 5005
    }, card)

    local topTrim = create('Frame', {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Name = '#trim',
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 5015
    }, card)
    makeGradient(topTrim, theme.Primary, theme.Secondary, 0)

    local header = create('Frame', {
        BackgroundColor3 = theme.Window3,
        BorderSizePixel = 0,
        Name = '#header',
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 5012
    }, card)
    makeGradient(header, Color3.fromRGB(255, 255, 255), Color3.fromRGB(228, 228, 228), 90)
    create('Frame', {
        BackgroundColor3 = theme.Stroke,
        BorderSizePixel = 0,
        Name = '#sep',
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 5013
    }, header)

    local badge = create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = theme.Button3,
        BorderSizePixel = 0,
        Name = '#badge',
        Position = UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 5014
    }, header)
    makeCorner(badge, cornerPx)
    makeStroke(badge, theme.Primary, 1)
    create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.TextPrimary,
        BorderSizePixel = 0,
        Name = '#ex-bar',
        Position = UDim2.new(0.5, 0, 0, 4),
        Size = UDim2.fromOffset(2, 7),
        ZIndex = 5015
    }, badge)
    create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.Primary,
        BorderSizePixel = 0,
        Name = '#ex-dot',
        Position = UDim2.new(0.5, 0, 0, 13),
        Size = UDim2.fromOffset(2, 2),
        ZIndex = 5015
    }, badge)

    create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#title',
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -110, 1, 0),
        Text = 'DUPLICATE UI DETECTED',
        TextColor3 = theme.TextPrimary,
        TextSize = 12,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5014
    }, header)

    local pill = create('Frame', {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Inset1,
        BorderSizePixel = 0,
        Name = '#pill',
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(62, 18),
        ZIndex = 5014
    }, header)
    makeCorner(pill, cornerPx)
    makeStroke(pill, theme.StrokeHover, 1)
    local pillDot = create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = theme.Primary,
        BorderSizePixel = 0,
        Name = '#dot',
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.fromOffset(5, 5),
        ZIndex = 5015
    }, pill)
    makeCorner(pillDot, 3)
    create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#label',
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Text = 'ACTIVE',
        TextColor3 = theme.TextPrimary,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5015
    }, pill)

    local body = create('Frame', {
        BackgroundColor3 = theme.Window2,
        BorderSizePixel = 0,
        Name = '#body',
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 1, -38),
        ZIndex = 5011
    }, card)

    create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#desc',
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 52),
        Text = 'An active LARPWare instance is already running. Proceeding will terminate all processes, keybinds, toggles, and connections on the previous session.',
        TextColor3 = theme.TextDim,
        TextSize = 11,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 5013
    }, body)

    local meta = create('Frame', {
        BackgroundColor3 = theme.Inset1,
        BorderSizePixel = 0,
        Name = '#meta',
        Position = UDim2.fromOffset(14, 72),
        Size = UDim2.new(1, -28, 0, 26),
        ZIndex = 5012
    }, body)
    makeCorner(meta, cornerPx)
    makeStroke(meta, theme.Stroke, 1)
    create('Frame', {
        BackgroundColor3 = theme.Primary,
        BorderSizePixel = 0,
        Name = '#bar',
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        ZIndex = 5013
    }, meta)

    local sessionTitle = (typeof(existing) == 'table' and existing.title) or 'LARPWare'
    local uptimeStr = 'running'
    if (typeof(existing) == 'table' and typeof(existing.createdAt) == 'number') then
        local elapsed = math.max(0, os.time() - existing.createdAt)
        if (elapsed >= 60) then
            uptimeStr = string.format('%dm %ds', math.floor(elapsed / 60), elapsed % 60)
        else
            uptimeStr = string.format('%ds', elapsed)
        end
    end
    create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#info',
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Text = 'session: ' .. tostring(sessionTitle) .. '  |  uptime: ' .. uptimeStr,
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5013
    }, meta)

    local actions = create('Frame', {
        BackgroundTransparency = 1,
        Name = '#actions',
        Position = UDim2.new(0, 14, 1, -44),
        Size = UDim2.new(1, -28, 0, 30),
        ZIndex = 5012
    }, body)

    local cancelBtn = create('TextButton', {
        AutoButtonColor = false,
        BackgroundColor3 = theme.Button1,
        BorderSizePixel = 0,
        Font = currentFont,
        Name = '#cancel',
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.new(0.42, -4, 1, 0),
        Text = 'cancel [esc]',
        TextColor3 = theme.TextDim,
        TextSize = 11,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        ZIndex = 5014
    }, actions)
    makeCorner(cancelBtn, cornerPx)
    makeStroke(cancelBtn, theme.Stroke, 1)
    makeTopSheen(cancelBtn, 5015)

    local proceedBtn = create('TextButton', {
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Font = currentFont,
        Name = '#proceed',
        Position = UDim2.new(0.42, 4, 0, 0),
        Size = UDim2.new(0.58, -4, 1, 0),
        Text = 'proceed & terminate [enter]',
        TextColor3 = theme.TextPrimary,
        TextSize = 11,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.75,
        ZIndex = 5014
    }, actions)
    makeCorner(proceedBtn, cornerPx)
    makeStroke(proceedBtn, blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.18), 1)
    local proceedGrad = makeGradient(proceedBtn, theme.Primary, theme.Secondary, 90)
    makeTopSheen(proceedBtn, 5015)

    local dupVpX, dupAvailH = getViewportInfo()
    local dupTargetScale = math.clamp(math.min(1, (dupVpX - 24) / 378, (dupAvailH - 24) / 198), 0.55, 1)
    tween(backdrop, {BackgroundTransparency = 0.45}, 0.22, 1)
    tween(cardScale, {Scale = dupTargetScale}, 0.28, 1)

    local decided = false
    local decision = false
    local signal = Instance.new('BindableEvent')
    local keyCon

    local function finish(result)
        if (decided) then return end
        decided = true
        decision = result
        if (keyCon) then
            keyCon:Disconnect()
            keyCon = nil
        end
        tween(backdrop, {BackgroundTransparency = 1}, 0.16, 1)
        tween(cardScale, {Scale = 0.94}, 0.16, 1)
        task.delay(0.17, function()
            if (globalEnv[PROMPT_KEY] == modalGui) then
                globalEnv[PROMPT_KEY] = nil
            end
            if (modalGui and modalGui.Parent) then
                modalGui:Destroy()
            end
            signal:Fire()
        end)
    end

    cancelBtn.MouseEnter:Connect(function()
        tween(cancelBtn, {BackgroundColor3 = theme.Button2, TextColor3 = theme.TextPrimary}, 0.14, 1)
        tween(cancelBtn['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
    end)
    cancelBtn.MouseLeave:Connect(function()
        tween(cancelBtn, {BackgroundColor3 = theme.Button1, TextColor3 = theme.TextDim}, 0.14, 1)
        tween(cancelBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
    end)
    cancelBtn.MouseButton1Click:Connect(function()
        finish(false)
    end)

    proceedBtn.MouseEnter:Connect(function()
        proceedGrad.Color = ColorSequence.new(
            blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.14),
            blendColor(theme.Secondary, Color3.fromRGB(255, 255, 255), 0.12)
        )
        tween(proceedBtn['#stroke'], {Color = Color3.fromRGB(255, 190, 195)}, 0.14, 1)
    end)
    proceedBtn.MouseLeave:Connect(function()
        proceedGrad.Color = ColorSequence.new(theme.Primary, theme.Secondary)
        tween(proceedBtn['#stroke'], {Color = blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.18)}, 0.14, 1)
    end)
    proceedBtn.MouseButton1Click:Connect(function()
        finish(true)
    end)

    keyCon = inputService.InputBegan:Connect(function(io)
        if (io.UserInputType == Enum.UserInputType.Keyboard) then
            if (io.KeyCode == Enum.KeyCode.Escape) then
                finish(false)
            elseif (io.KeyCode == Enum.KeyCode.Return or io.KeyCode == Enum.KeyCode.KeypadEnter) then
                finish(true)
            end
        end
    end)

    signal.Event:Wait()
    signal:Destroy()
    return decision
end

do
    local hasDup, existing, orphans = findExistingInstances()
    if (hasDup) then
        local proceed = showDuplicateWarning(existing)
        if (not proceed) then
            if (#args > 0 and typeof(args[1]) == 'table' and typeof(args[1].onCancel) == 'function') then
                args[1].onCancel()
                return nil
            end
            coroutine.yield()
            return nil
        end
        if (typeof(existing) == 'table' and typeof(existing.terminate) == 'function') then
            pcall(existing.terminate)
        end
        globalEnv[REG_KEY] = nil
        for _, gui in ipairs(orphans) do
            if (gui and gui.Parent) then
                pcall(function()
                    gui:Destroy()
                end)
            end
        end
        if (targetParent) then
            for _, child in ipairs(targetParent:GetChildren()) do
                if (child:IsA('ScreenGui') and child:GetAttribute('LARPWareInstance') == true) then
                    pcall(function()
                        child:Destroy()
                    end)
                end
            end
        end
    end
end

local uiScreen = Instance.new('ScreenGui')
local hudScreen = Instance.new('ScreenGui')
local cursorScreen = Instance.new('ScreenGui')
local cursorStepName = 'LARPWare_CursorUnlock_' .. tostring(math.random(100000, 999999))
local cursorUnlockBound = false
local cursorModalBtn
local cursorRoot
local notifContainer
local notifScale
local nestedScrolls = {}

local function registerNestedScroll(sf)
    if (sf) then
        table.insert(nestedScrolls, sf)
    end
    return sf
end

local introAssetMap = {}
local introAssetsReady = false
local introLoading = false

local function loadIntroAssets()
    if (introAssetsReady) then
        return introAssetMap
    end
    if (introLoading) then
        local t0 = os.clock()
        while (not introAssetsReady and (os.clock() - t0) < 3.5) do
            task.wait(0.02)
        end
        return introAssetMap
    end
    introLoading = true
    local getAsset = (typeof(getcustomasset) == 'function' and getcustomasset)
        or (typeof(getsynasset) == 'function' and getsynasset)
    if (not getAsset or typeof(writefile) ~= 'function') then
        introAssetsReady = true
        introLoading = false
        return introAssetMap
    end

    local folder = 'LARPWare'
    if (typeof(isfolder) == 'function' and typeof(makefolder) == 'function' and not isfolder(folder)) then
        pcall(makefolder, folder)
    end

    local letters = {'L', 'A', 'R', 'P'}
    local doneCount = 0
    for _, ch in ipairs(letters) do
        task.spawn(function()
            local filePath = folder .. '/intro_' .. ch .. '.png'
            local needDl = true
            if (typeof(isfile) == 'function' and isfile(filePath)) then
                if (typeof(readfile) == 'function') then
                    local okRead, existing = pcall(readfile, filePath)
                    if (okRead and typeof(existing) == 'string' and #existing > 500) then
                        needDl = false
                    end
                else
                    needDl = false
                end
            end
            if (needDl) then
                local okReq, data = pcall(function()
                    return game:HttpGet('https://api.x8stuff.lol/larpware/assets/intro_' .. ch .. '.png')
                end)
                if (not okReq or typeof(data) ~= 'string' or #data <= 500) then
                    okReq, data = pcall(function()
                        return game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/assets/intro_' .. ch .. '.png')
                    end)
                end
                if (okReq and typeof(data) == 'string' and #data > 500) then
                    pcall(writefile, filePath, data)
                end
            end
            if (typeof(isfile) ~= 'function' or isfile(filePath)) then
                local okAsset, assetId = pcall(getAsset, filePath)
                if (okAsset and typeof(assetId) == 'string' and assetId ~= '') then
                    introAssetMap[ch] = assetId
                end
            end
            doneCount += 1
        end)
    end

    local waitStart = os.clock()
    while (doneCount < #letters and (os.clock() - waitStart) < 3.5) do
        task.wait(0.02)
    end

    local preloadList = {}
    for _, ch in ipairs(letters) do
        if (introAssetMap[ch]) then
            table.insert(preloadList, introAssetMap[ch])
        end
    end
    if (#preloadList > 0) then
        pcall(function()
            game:GetService('ContentProvider'):PreloadAsync(preloadList)
        end)
    end
    introAssetsReady = true
    introLoading = false
    return introAssetMap
end

task.spawn(loadIntroAssets)

local function playLarpIntro(targetWin, isReplay)
    if (not targetWin or not targetWin.instances or not targetWin.instances.mainFrame) then
        return
    end
    local mf = targetWin.instances.mainFrame
    if (not mf or not mf.Parent) then return end

    local prevOverlay = mf:FindFirstChild('#intro-overlay')
    if (prevOverlay) then
        prevOverlay:Destroy()
    end

    local electricBlue = Color3.fromRGB(22, 118, 255)
    local electricCyan = Color3.fromRGB(130, 224, 255)

    local overlay = create('TextButton', {
        Active = true,
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(7, 8, 12),
        BackgroundTransparency = isReplay and 1 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Name = '#intro-overlay',
        Position = UDim2.fromOffset(0, 1),
        Size = UDim2.new(1, 0, 1, -1),
        Text = '',
        ZIndex = 120
    }, mf)
    makeCorner(overlay, cornerPx)

    local auraOuter = create('ImageLabel', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://7331400934',
        ImageColor3 = electricBlue,
        ImageTransparency = 1,
        Name = '#aura-outer',
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Stretch,
        Size = UDim2.fromOffset(420, 190),
        ZIndex = 121
    }, overlay)

    local auraCore = create('ImageLabel', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = 'rbxassetid://7331400934',
        ImageColor3 = electricCyan,
        ImageTransparency = 1,
        Name = '#aura-core',
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Stretch,
        Size = UDim2.fromOffset(250, 105),
        ZIndex = 122
    }, overlay)

    local horizon = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Name = '#horizon',
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 1),
        ZIndex = 123
    }, overlay)
    create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, electricBlue),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 248, 255)),
            ColorSequenceKeypoint.new(1, electricBlue)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.15),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(0.8, 0.15),
            NumberSequenceKeypoint.new(1, 1)
        })
    }, horizon)

    local stage = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Name = '#stage',
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(540, 180),
        ZIndex = 125
    }, overlay)
    local stageScale = create('UIScale', {Name = '#stage-scale', Scale = 1}, stage)

    local glintClip = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Name = '#glint-clip',
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(520, 128),
        ZIndex = 135
    }, stage)
    local glintBar = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(235, 248, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Name = '#glint',
        Position = UDim2.new(0, -110, 0.5, 0),
        Rotation = 22,
        Size = UDim2.fromOffset(56, 190),
        ZIndex = 136
    }, glintClip)
    create('UIGradient', {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.56),
            NumberSequenceKeypoint.new(1, 1)
        })
    }, glintBar)

    local underline = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Name = '#underline',
        Position = UDim2.new(0.5, 0, 0.5, 62),
        Size = UDim2.fromOffset(0, 2),
        ZIndex = 134
    }, stage)
    create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, electricBlue),
            ColorSequenceKeypoint.new(0.5, electricCyan),
            ColorSequenceKeypoint.new(1, theme.Primary)
        })
    }, underline)

    local skipped = false
    overlay.MouseButton1Click:Connect(function()
        skipped = true
    end)

    task.spawn(function()
        if (isReplay) then
            tween(overlay, {BackgroundTransparency = 0}, 0.18, 1)
            task.wait(0.14)
        else
            task.wait(0.16)
        end

        local assets = loadIntroAssets()
        if (not overlay or not overlay.Parent) then return end

        local letterSpecs = {
            {ch = 'L', x = -130, dx = -22, dy = -38, rot = -15, exitX = -160},
            {ch = 'A', x = -45, dx = -8, dy = 40, rot = 12, exitX = -56},
            {ch = 'R', x = 45, dx = 8, dy = -40, rot = -12, exitX = 56},
            {ch = 'P', x = 135, dx = 22, dy = 38, rot = 15, exitX = 166}
        }

        local letterNodes = {}
        for idx, spec in ipairs(letterSpecs) do
            local assetId = assets[spec.ch]
            local slot = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = '#slot-' .. spec.ch,
                Position = UDim2.new(0.5, spec.x + spec.dx, 0.5, spec.dy),
                Rotation = spec.rot,
                Size = UDim2.fromOffset(102, 102),
                ZIndex = 127 + idx
            }, stage)
            local lScale = create('UIScale', {Name = '#lscale', Scale = 1.68}, slot)

            local mainObj
            local echoObj
            local echoScale
            if (assetId and assetId ~= '') then
                echoObj = create('ImageLabel', {
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = assetId,
                    ImageColor3 = electricCyan,
                    ImageTransparency = 1,
                    Name = '#echo',
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 126
                }, slot)
                echoScale = create('UIScale', {Name = '#escale', Scale = 1}, echoObj)

                mainObj = create('ImageLabel', {
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = assetId,
                    ImageTransparency = 1,
                    Name = '#letter',
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 129 + idx
                }, slot)
            else
                mainObj = create('TextLabel', {
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Font = currentFont,
                    Name = '#letter',
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(1, 1),
                    Text = spec.ch,
                    TextColor3 = Color3.fromRGB(238, 244, 255),
                    TextSize = 64,
                    TextStrokeColor3 = electricBlue,
                    TextStrokeTransparency = 1,
                    TextTransparency = 1,
                    ZIndex = 129 + idx
                }, slot)
            end

            letterNodes[idx] = {
                spec = spec,
                slot = slot,
                lScale = lScale,
                main = mainObj,
                echo = echoObj,
                echoScale = echoScale,
                isImage = (assetId and assetId ~= '')
            }
        end

        local function sleepInterruptible(dur)
            local t0 = os.clock()
            while (not skipped and overlay and overlay.Parent and (os.clock() - t0) < dur) do
                task.wait(0.015)
            end
        end

        tween(auraOuter, {ImageTransparency = 0.58, Size = UDim2.fromOffset(480, 215)}, 0.36, 1)
        tween(horizon, {Size = UDim2.fromOffset(420, 1)}, 0.28, 5)
        sleepInterruptible(0.16)

        for idx, node in ipairs(letterNodes) do
            if (skipped or not overlay or not overlay.Parent) then break end
            local spec = node.spec
            tween(node.slot, {Position = UDim2.new(0.5, spec.x, 0.5, 0), Rotation = 0}, 0.32, 5)
            if (node.isImage) then
                tween(node.main, {ImageTransparency = 0}, 0.18, 1)
            else
                tween(node.main, {TextTransparency = 0, TextStrokeTransparency = 0.65}, 0.18, 1)
            end
            tween(node.lScale, {Scale = 0.94}, 0.20, 5)

            task.delay(0.15, function()
                if (skipped or not overlay or not overlay.Parent) then return end
                tween(node.lScale, {Scale = 1.0}, 0.22, 4)
                if (node.echo and node.echoScale) then
                    node.echo.ImageTransparency = 0.34
                    node.echoScale.Scale = 1.0
                    tween(node.echo, {ImageTransparency = 1}, 0.40, 1)
                    tween(node.echoScale, {Scale = 1.46}, 0.40, 1)
                end
                auraCore.ImageTransparency = 0.52
                tween(auraCore, {ImageTransparency = 0.84}, 0.32, 1)
                local punchY = (idx % 2 == 0) and 2.5 or -2.5
                stage.Position = UDim2.new(0.5, 0, 0.5, punchY)
                tween(stage, {Position = UDim2.fromScale(0.5, 0.5)}, 0.16, 1)
            end)

            sleepInterruptible(0.09)
        end

        if (not skipped and overlay and overlay.Parent) then
            sleepInterruptible(0.22)
        end

        if (not skipped and overlay and overlay.Parent) then
            glintBar.BackgroundTransparency = 0
            glintBar.Position = UDim2.new(0, -110, 0.5, 0)
            tween(glintBar, {Position = UDim2.new(1, 110, 0.5, 0)}, 0.44, 5)
            tween(underline, {Size = UDim2.fromOffset(335, 2)}, 0.34, 5)
            tween(stageScale, {Scale = 1.045}, 0.68, 2)
            tween(auraOuter, {ImageTransparency = 0.48}, 0.28, 1)
            sleepInterruptible(0.64)
        end

        if (not overlay or not overlay.Parent) then return end

        local exitDur = skipped and 0.18 or 0.40
        tween(stageScale, {Scale = 1.14}, exitDur, 1)
        for _, node in ipairs(letterNodes) do
            tween(node.slot, {Position = UDim2.new(0.5, node.spec.exitX, 0.5, 0)}, exitDur, 1)
            if (node.isImage) then
                tween(node.main, {ImageTransparency = 1}, exitDur * 0.82, 1)
            else
                tween(node.main, {TextTransparency = 1, TextStrokeTransparency = 1}, exitDur * 0.82, 1)
            end
        end
        tween(underline, {Size = UDim2.fromOffset(0, 2), BackgroundTransparency = 1}, exitDur * 0.78, 1)
        tween(horizon, {Size = UDim2.fromOffset(0, 1), BackgroundTransparency = 1}, exitDur * 0.78, 1)
        tween(auraOuter, {ImageTransparency = 1}, exitDur * 0.85, 1)
        tween(auraCore, {ImageTransparency = 1}, exitDur * 0.75, 1)
        tween(overlay, {BackgroundTransparency = 1}, exitDur, 1)

        task.wait(exitDur + 0.03)
        if (overlay and overlay.Parent) then
            overlay:Destroy()
        end
    end)
end

do
    uiScreen.OnTopOfCoreBlur = true
    uiScreen.DisplayOrder = 100000
    uiScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    uiScreen.ResetOnSpawn = false
    uiScreen.Name = randomGuiName()
    uiScreen:SetAttribute('LARPWareInstance', true)
    uiScreen.Parent = targetParent

    hudScreen.OnTopOfCoreBlur = true
    hudScreen.DisplayOrder = 100100
    hudScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    hudScreen.ResetOnSpawn = false
    hudScreen.Name = randomGuiName()
    hudScreen:SetAttribute('LARPWareInstance', true)
    hudScreen.Parent = targetParent

    cursorScreen.OnTopOfCoreBlur = true
    cursorScreen.IgnoreGuiInset = true
    cursorScreen.DisplayOrder = 100999
    cursorScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    cursorScreen.ResetOnSpawn = false
    cursorScreen.Enabled = false
    cursorScreen.Name = randomGuiName()
    cursorScreen:SetAttribute('LARPWareInstance', true)
    cursorScreen.Parent = targetParent

    cursorModalBtn = create('TextButton', {
        Active = false,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Modal = false,
        Name = '#modal-unlock',
        Position = UDim2.fromOffset(0, 0),
        Selectable = false,
        Size = UDim2.fromOffset(0, 0),
        Text = '',
        Visible = false,
        ZIndex = 0
    }, cursorScreen)

    cursorRoot = create('Frame', {
        Active = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Name = '#larp-cursor',
        Position = UDim2.fromOffset(-100, -100),
        Size = UDim2.fromOffset(20, 20),
        Visible = false,
        ZIndex = 99995
    }, cursorScreen)

    local function addCursorBar(name, pos, size, color, rot, z, anchor)
        return create('Frame', {
            Active = false,
            AnchorPoint = anchor or Vector2.new(0, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Name = name,
            Position = pos,
            Rotation = rot or 0,
            Size = size,
            ZIndex = z
        }, cursorRoot)
    end

    local outlineCol = Color3.fromRGB(0, 0, 0)
    local coreCol = Color3.fromRGB(255, 255, 255)
    addCursorBar('#ol-v', UDim2.fromOffset(-1, -1), UDim2.fromOffset(4, 15), outlineCol, 0, 99996)
    addCursorBar('#ol-h', UDim2.fromOffset(-1, -1), UDim2.fromOffset(13, 4), outlineCol, 0, 99996)
    addCursorBar('#ol-d', UDim2.fromOffset(0, 2), UDim2.fromOffset(4, 15), outlineCol, -45, 99996)
    addCursorBar('#fg-v', UDim2.fromOffset(0, 0), UDim2.fromOffset(2, 13), coreCol, 0, 99998)
    addCursorBar('#fg-h', UDim2.fromOffset(0, 0), UDim2.fromOffset(11, 2), coreCol, 0, 99998)
    addCursorBar('#fg-d', UDim2.fromOffset(1, 2), UDim2.fromOffset(2, 13), coreCol, -45, 99998)
    local cursorCore = addCursorBar('#accent-core', UDim2.fromOffset(4, 4), UDim2.fromOffset(4, 4), theme.Primary, 45, 99999, Vector2.new(0.5, 0.5))
    create('UIStroke', {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = outlineCol,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Name = '#stroke',
        Thickness = 1
    }, cursorCore)

    notifContainer = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Name = '#notif-container',
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.fromOffset(220, 1000),
        ZIndex = 2900
    }, hudScreen)

    notifScale = create('UIScale', {
        Name = '#scale',
        Scale = 1
    }, notifContainer)
end

local lastCursorX, lastCursorY = nil, nil
local savedMouseIconEnabled = nil
local savedMouseBehavior = nil
local cursorTerminated = false

local function syncCursorUnlock(shouldActive)
    local active = (shouldActive == true) and (enableCursorUnlock == true) and (not cursorTerminated)
    if (active) then
        local hasMouse = inputService.MouseEnabled == true
        if (savedMouseIconEnabled == nil) then
            savedMouseIconEnabled = inputService.MouseIconEnabled
        end
        if (savedMouseBehavior == nil) then
            savedMouseBehavior = inputService.MouseBehavior
        end
        if (cursorModalBtn and cursorModalBtn.Parent) then
            cursorModalBtn.Modal = true
            cursorModalBtn.Visible = true
        end
        if (cursorScreen and cursorScreen.Parent) then
            cursorScreen.Enabled = true
        end
        pcall(function()
            inputService.MouseBehavior = Enum.MouseBehavior.Default
            if (hasMouse) then
                inputService.MouseIconEnabled = false
            end
        end)
        if (cursorRoot and cursorRoot.Parent) then
            cursorRoot.Visible = hasMouse
            if (hasMouse) then
                local mpos = inputService:GetMouseLocation()
                lastCursorX, lastCursorY = mpos.X, mpos.Y
                cursorRoot.Position = UDim2.fromOffset(mpos.X, mpos.Y)
            end
        end
        if (not cursorUnlockBound) then
            cursorUnlockBound = true
            renderService:BindToRenderStep(cursorStepName, Enum.RenderPriority.Last.Value + 100, function()
                if (cursorTerminated or not enableCursorUnlock) then
                    return
                end
                if (inputService.MouseBehavior ~= Enum.MouseBehavior.Default) then
                    inputService.MouseBehavior = Enum.MouseBehavior.Default
                end
                local mouseOn = inputService.MouseEnabled == true
                if (mouseOn) then
                    if (inputService.MouseIconEnabled ~= false) then
                        inputService.MouseIconEnabled = false
                    end
                    if (cursorRoot and cursorRoot.Parent) then
                        if (not cursorRoot.Visible) then
                            cursorRoot.Visible = true
                        end
                        local mpos = inputService:GetMouseLocation()
                        if (mpos.X ~= lastCursorX or mpos.Y ~= lastCursorY) then
                            lastCursorX, lastCursorY = mpos.X, mpos.Y
                            cursorRoot.Position = UDim2.fromOffset(mpos.X, mpos.Y)
                        end
                    end
                elseif (cursorRoot and cursorRoot.Parent and cursorRoot.Visible) then
                    cursorRoot.Visible = false
                end
            end)
        end
    else
        if (cursorUnlockBound) then
            cursorUnlockBound = false
            pcall(renderService.UnbindFromRenderStep, renderService, cursorStepName)
        end
        lastCursorX, lastCursorY = nil, nil
        if (cursorRoot and cursorRoot.Parent) then
            cursorRoot.Visible = false
        end
        if (cursorModalBtn and cursorModalBtn.Parent) then
            cursorModalBtn.Modal = false
            cursorModalBtn.Visible = false
        end
        if (cursorScreen and cursorScreen.Parent) then
            cursorScreen.Enabled = false
        end
        if (savedMouseIconEnabled ~= nil) then
            local restoreIcon = savedMouseIconEnabled
            savedMouseIconEnabled = nil
            pcall(function()
                inputService.MouseIconEnabled = (restoreIcon ~= false)
            end)
        end
        if (savedMouseBehavior ~= nil) then
            local restoreBehavior = savedMouseBehavior
            savedMouseBehavior = nil
            if (restoreBehavior ~= Enum.MouseBehavior.Default) then
                pcall(function()
                    inputService.MouseBehavior = restoreBehavior
                end)
                task.defer(function()
                    if (not cursorUnlockBound and not cursorTerminated) then
                        pcall(function()
                            inputService.MouseBehavior = restoreBehavior
                        end)
                    end
                end)
            end
        end
    end
end

local function makeCloseGlyph(parent, zIndex)
    local holder = create('Frame', {
        Name = '#icon',
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = zIndex
    }, parent)
    for _, rot in ipairs({45, -45}) do
        create('Frame', {
            Name = '#bar',
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.TextDim,
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.5, 0.5),
            Rotation = rot,
            Size = UDim2.fromOffset(10, 1),
            ZIndex = zIndex
        }, holder)
    end
    return holder
end

local function setGlyphColor(holder, color, dur)
    for _, child in ipairs(holder:GetChildren()) do
        if (child:IsA('Frame')) then
            if (dur and dur > 0) then
                tween(child, {BackgroundColor3 = color}, dur, 1)
            else
                child.BackgroundColor3 = color
            end
        end
    end
end

local function makeMinGlyph(parent, zIndex)
    local holder = create('Frame', {
        Name = '#icon',
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = zIndex
    }, parent)
    create('Frame', {
        Name = '#h',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.TextDim,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(8, 1),
        ZIndex = zIndex
    }, holder)
    create('Frame', {
        Name = '#v',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.TextDim,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 8),
        ZIndex = zIndex
    }, holder)
    return holder
end

local function makeSettingsGlyph(parent, zIndex)
    local holder = create('Frame', {
        Name = '#icon',
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = zIndex
    }, parent)
    local offsets = {
        {y = -3, x = -2},
        {y = 0, x = 2},
        {y = 3, x = -1}
    }
    for idx, cfg in ipairs(offsets) do
        create('Frame', {
            Name = '#line' .. idx,
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.TextDim,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, cfg.y),
            Size = UDim2.fromOffset(10, 1),
            ZIndex = zIndex
        }, holder)
        create('Frame', {
            Name = '#dot' .. idx,
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.TextPrimary,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, cfg.x, 0.5, cfg.y),
            Size = UDim2.fromOffset(2, 3),
            ZIndex = zIndex + 1
        }, holder)
    end
    return holder
end

local function makeSearchGlyph(parent, zIndex)
    local holder = create('Frame', {
        Name = '#icon',
        Active = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = zIndex
    }, parent)
    local lens = create('Frame', {
        Name = '#lens',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -1, 0.5, -1),
        Size = UDim2.fromOffset(7, 7),
        ZIndex = zIndex
    }, holder)
    makeCorner(lens, 99)
    makeStroke(lens, theme.TextDim, 1)
    create('Frame', {
        Name = '#handle',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.TextDim,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 3, 0.5, 3),
        Rotation = 45,
        Size = UDim2.fromOffset(4, 1),
        ZIndex = zIndex
    }, holder)
    return holder
end

local function makeChevronGlyph(parent, zIndex, size)
    local s = size or 5
    local holder = create('Frame', {
        Name = '#icon',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = zIndex
    }, parent)
    create('Frame', {
        Name = '#a',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.TextDim,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -2, 0.5, 0),
        Rotation = 45,
        Size = UDim2.fromOffset(s, 1),
        ZIndex = zIndex
    }, holder)
    create('Frame', {
        Name = '#b',
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.TextDim,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 2, 0.5, 0),
        Rotation = -45,
        Size = UDim2.fromOffset(s, 1),
        ZIndex = zIndex
    }, holder)
    return holder
end

local tooltip = {}
do
    local instances = {}

    local main = create('Frame', {
        BackgroundColor3 = theme.Window2,
        BorderColor3 = theme.Inset2,
        BorderMode = Enum.BorderMode.Inset,
        BorderSizePixel = 1,
        Name = '#main',
        Size = UDim2.fromOffset(160, 56),
        Visible = false,
        ZIndex = 3800
    }, uiScreen)

    create('UIScale', {Name = '#scale', Scale = 1}, main)
    makeCorner(main, cornerPx)
    makeStroke(main, theme.Stroke, 1)

    create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = 'rbxassetid://7331400934',
        ImageColor3 = Color3.fromRGB(0, 0, 5),
        ImageTransparency = 0.25,
        Name = '#shadow',
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 40, 1, 40),
        SliceCenter = Rect.new(40, 40, 260, 260),
        SliceScale = 1,
        ZIndex = 3799
    }, main)

    local trim = create('Frame', {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Name = '#trim',
        Position = UDim2.fromOffset(0, -1),
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 3805
    }, main)
    makeGradient(trim, theme.Primary, theme.Secondary, 0)

    local titleBar = create('Frame', {
        BackgroundColor3 = theme.Window3,
        BorderSizePixel = 0,
        Name = '#title-bar',
        Position = UDim2.fromOffset(0, 1),
        Size = UDim2.new(1, 0, 0, 19),
        ZIndex = 3801
    }, main)
    create('Frame', {
        BackgroundColor3 = theme.Stroke,
        BorderSizePixel = 0,
        Name = '#sep',
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 3802
    }, titleBar)

    local title = create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#title',
        RichText = true,
        Size = UDim2.fromScale(1, 1),
        Text = 'tooltip',
        TextColor3 = theme.TextPrimary,
        TextSize = 12,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 3802
    }, titleBar)
    create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, title)
    instances.title = title

    local menu = create('Frame', {
        BackgroundColor3 = theme.Window2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Name = '#menu',
        Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 1, -20),
        ZIndex = 3801
    }, main)

    local desc = create('TextLabel', {
        BackgroundTransparency = 1,
        Font = currentFont,
        Name = '#desc',
        RichText = true,
        Size = UDim2.fromScale(1, 1),
        Text = '',
        TextColor3 = theme.TextDim,
        TextSize = 12,
        TextStrokeColor3 = theme.TextStroke,
        TextStrokeTransparency = 0.85,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 3802
    }, menu)
    create('UIPadding', {
        Name = '#padding',
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4)
    }, desc)
    instances.desc = desc

    instances.main = main
    tooltip.instances = instances
    tooltip.handle = nil
    tooltip.showing = false
    tooltip.update = nil
end

local hint = {}
do
    local instances = {}
    local main = create('Frame', {
        BackgroundColor3 = theme.Window2,
        BorderColor3 = theme.Inset2,
        BorderMode = Enum.BorderMode.Inset,
        BorderSizePixel = 1,
        Name = '#main',
        Size = UDim2.fromOffset(140, 84),
        Visible = false,
        ZIndex = 3900
    }, uiScreen)
    create('UIScale', {Name = '#scale', Scale = 1}, main)
    makeStroke(main, theme.Stroke, 1)
    instances.main = main
    hint.instances = instances
    hint.selection = 1
    hint.handle = nil
    hint.hintCount = 0
    hint.showing = false
    hint.hints = {}
end

local defaultWinPos = UDim2.fromScale(0.32, 0.28)
local ui = {}
local easterEggAsset = ''
local easterEggLabels = {}

task.spawn(function()
    local ok, asset = pcall(function()
        local getAsset = (typeof(getcustomasset) == 'function' and getcustomasset)
            or (typeof(getsynasset) == 'function' and getsynasset)
        if (not getAsset or typeof(writefile) ~= 'function') then
            return nil
        end
        local folder = 'LARPWare'
        local filePath = folder .. '/larp.png'
        if (typeof(isfolder) == 'function' and typeof(makefolder) == 'function' and not isfolder(folder)) then
            pcall(makefolder, folder)
        end
        local needDownload = true
        if (typeof(isfile) == 'function' and isfile(filePath)) then
            if (typeof(readfile) == 'function') then
                local existing = readfile(filePath)
                if (typeof(existing) == 'string' and #existing > 100) then
                    needDownload = false
                end
            else
                needDownload = false
            end
        end
        if (needDownload) then
            local okReq, data = pcall(function()
                return game:HttpGet('https://api.x8stuff.lol/larpware/assets/larp.png')
            end)
            if (not okReq or typeof(data) ~= 'string' or #data <= 100) then
                okReq, data = pcall(function()
                    return game:HttpGet('https://raw.githubusercontent.com/x8lua/LARPWare/main/assets/larp.png')
                end)
            end
            if (okReq and typeof(data) == 'string' and #data > 100) then
                writefile(filePath, data)
            end
        end
        if (typeof(isfile) ~= 'function' or isfile(filePath)) then
            return getAsset(filePath)
        end
        return nil
    end)
    if (ok and typeof(asset) == 'string' and asset ~= '') then
        easterEggAsset = asset
        for _, img in ipairs(easterEggLabels) do
            if (img and img.Parent) then
                img.Image = asset
            end
        end
    end
end)

local fontListeners = {}
local scaleListeners = {}
local textScaleListeners = {}
local themeListeners = {}

local function emitFontChanged()
    for i = 1, #fontListeners do
        task.spawn(fontListeners[i], currentFontKey, currentFont)
    end
end

local function emitScaleChanged()
    for i = 1, #scaleListeners do
        task.spawn(scaleListeners[i], currentScale)
    end
end

local function emitTextScaleChanged()
    for i = 1, #textScaleListeners do
        task.spawn(textScaleListeners[i], currentTextScale)
    end
end

local function emitThemeChanged()
    for i = 1, #themeListeners do
        task.spawn(themeListeners[i], currentThemeName, theme)
    end
end

local function makeTabGlyph(parent, hintStr, zIndex)
    for _, ch in ipairs(parent:GetChildren()) do
        ch:Destroy()
    end
    local key = tostring(hintStr or ''):lower()
    local holder = create('Frame', {
        Active = false,
        BackgroundTransparency = 1,
        Name = '#glyph',
        Size = UDim2.fromScale(1, 1),
        ZIndex = zIndex
    }, parent)

    if (key:find('combat') or key:find('aim') or key:find('rage') or key:find('legit') or key:find('weapon')) then
        local ring = create('Frame', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = '#g-ring',
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(8, 8),
            ZIndex = zIndex
        }, holder)
        makeCorner(ring, 5, true)
        makeStroke(ring, theme.TextDim, 1)
        for _, cfg in ipairs({
            {UDim2.new(0.5, 0, 0, 1), UDim2.fromOffset(1, 3)},
            {UDim2.new(0.5, 0, 1, -1), UDim2.fromOffset(1, 3)},
            {UDim2.new(0, 1, 0.5, 0), UDim2.fromOffset(3, 1)},
            {UDim2.new(1, -1, 0.5, 0), UDim2.fromOffset(3, 1)}
        }) do
            create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.TextDim,
                BorderSizePixel = 0,
                Name = '#g-bar',
                Position = cfg[1],
                Size = cfg[2],
                ZIndex = zIndex
            }, holder)
        end
    elseif (key:find('visual') or key:find('esp') or key:find('world') or key:find('render') or key:find('cam')) then
        local outer = create('Frame', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = '#g-diamond',
            Position = UDim2.fromScale(0.5, 0.5),
            Rotation = 45,
            Size = UDim2.fromOffset(8, 8),
            ZIndex = zIndex
        }, holder)
        makeStroke(outer, theme.TextDim, 1)
        local core = create('Frame', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.TextDim,
            BorderSizePixel = 0,
            Name = '#g-dot',
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 3),
            ZIndex = zIndex
        }, holder)
        makeCorner(core, 2, true)
    elseif (key:find('setting') or key:find('pref') or key:find('config') or key:find('theme') or key:find('system')) then
        for idx, yPos in ipairs({3, 7, 11}) do
            create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.TextDim,
                BorderSizePixel = 0,
                Name = '#g-bar',
                Position = UDim2.new(0.5, 0, 0, yPos),
                Size = UDim2.fromOffset(10, 1),
                ZIndex = zIndex
            }, holder)
            local knobX = (idx == 1 and 4) or (idx == 2 and 10) or 6
            create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.TextDim,
                BorderSizePixel = 0,
                Name = '#g-bar',
                Position = UDim2.fromOffset(knobX, yPos),
                Size = UDim2.fromOffset(3, 3),
                ZIndex = zIndex + 1
            }, holder)
        end
    elseif (key:find('misc') or key:find('move') or key:find('player') or key:find('util')) then
        for _, cfg in ipairs({
            {UDim2.fromOffset(4, 4), UDim2.fromOffset(4, 4)},
            {UDim2.fromOffset(10, 4), UDim2.fromOffset(4, 4)},
            {UDim2.fromOffset(4, 10), UDim2.fromOffset(4, 4)},
            {UDim2.fromOffset(10, 10), UDim2.fromOffset(4, 4)}
        }) do
            local sq = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = '#g-sq',
                Position = cfg[1],
                Size = cfg[2],
                ZIndex = zIndex
            }, holder)
            makeStroke(sq, theme.TextDim, 1)
        end
    else
        local box = create('Frame', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Name = '#g-box',
            Position = UDim2.fromScale(0.5, 0.5),
            Rotation = 45,
            Size = UDim2.fromOffset(7, 7),
            ZIndex = zIndex
        }, holder)
        makeStroke(box, theme.TextDim, 1)
    end
    return holder
end

local function setTabGlyphColor(wrap, color, dur)
    if (not wrap) then return end
    for _, desc in ipairs(wrap:GetDescendants()) do
        if (desc:IsA('UIStroke')) then
            if (dur and dur > 0) then
                tween(desc, {Color = color}, dur, 1)
            else
                desc.Color = color
            end
        elseif (desc:IsA('Frame') and desc.BackgroundTransparency < 0.5) then
            if (dur and dur > 0) then
                tween(desc, {BackgroundColor3 = color}, dur, 1)
            else
                desc.BackgroundColor3 = color
            end
        end
    end
end

local elemClasses = {}
do
    do
        local baseElement = {}
        baseElement.__index = baseElement
        baseElement.bindToEvent = function(self, event, callback)
            self.binds[event] = callback
            return self
        end
        baseElement.fireEvent = function(self, event, ...)
            local t = self.binds[event]
            if (t) then
                task.spawn(t, ...)
            end
            return self
        end
        baseElement.name = ''
        baseElement.tooltip = nil
        baseElement.setTooltip = function(self, tip)
            self.tooltip = tostring(tip)
            return self
        end
        baseElement.showTooltip = function(self)
            if (self.tooltip) then
                if (tooltip.update) then
                    tooltip.update:Disconnect()
                    tooltip.update = nil
                end
                tooltip.showing = true
                tooltip.handle = self
                local desc, title, main = tooltip.instances.desc, tooltip.instances.title, tooltip.instances.main
                local barH = math.max(19, math.floor(19 * currentTextScale + 0.5))
                local tipW = math.clamp(math.floor(176 * math.max(1, currentTextScale) + 0.5), 170, 260)
                local stepH = math.max(14, math.floor(16 * currentTextScale + 0.5))
                main['#title-bar'].Size = UDim2.new(1, 0, 0, barH)
                main['#menu'].Position = UDim2.fromOffset(0, barH + 1)
                main['#menu'].Size = UDim2.new(1, 0, 1, -(barH + 1))

                title.Text = self.name
                main.Size = UDim2.fromOffset(tipW, barH + 8)
                desc.Text = self.tooltip

                local c = 0
                while (true) do
                    c += 1
                    main.Size += UDim2.fromOffset(0, stepH)
                    if (c > 24) then
                        main.Size = UDim2.fromOffset(tipW, barH + stepH * 4)
                        break
                    end
                    local _ = desc.TextFits
                    if (desc.TextFits == true) then
                        break
                    end
                end

                main.Visible = true
                local lastTx, lastTy
                tooltip.update = renderService.RenderStepped:Connect(function()
                    if (not main or not main.Parent or not main.Visible) then
                        if (tooltip.update) then
                            tooltip.update:Disconnect()
                            tooltip.update = nil
                        end
                        return
                    end
                    local mpos = inputService:GetMouseLocation()
                    local inset = guiService:GetGuiInset()
                    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or guiService:GetScreenResolution()
                    local sz = main.AbsoluteSize
                    local x = math.clamp(mpos.X + 14, 4, math.max(4, vp.X - sz.X - 6))
                    local y = math.clamp(mpos.Y - inset.Y + 14, 4, math.max(4, vp.Y - inset.Y - sz.Y - 6))
                    if (x ~= lastTx or y ~= lastTy) then
                        lastTx = x
                        lastTy = y
                        main.Position = UDim2.fromOffset(x, y)
                    end
                end)
            end
            return self
        end
        baseElement.hideTooltip = function(self)
            if (tooltip.handle == self) then
                tooltip.showing = false
                tooltip.handle = nil
                if (tooltip.update) then
                    tooltip.update:Disconnect()
                    tooltip.update = nil
                end
                tooltip.instances.main.Visible = false
            end
            return self
        end
        elemClasses.baseElement = baseElement
    end

    do
        local window = {}
        window.__index = window
        setmetatable(window, elemClasses.baseElement)

        window.class = 'window'
        window.minimized = false
        window.size = UDim2.fromOffset(550, 376)
        window.icon = nil
        window.minFocused = false
        window.settingsOpen = false
        window.settingsFocused = false
        window.searchOpen = false
        window.searchFocused = false

        local instances = {}
        do
            local mainFrame = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Name = '#main_frame',
                Position = UDim2.fromScale(0.32, 0.28),
                Size = UDim2.fromOffset(550, 376),
                Visible = true,
                ZIndex = 5
            })

            create('UIScale', {
                Name = '#scale',
                Scale = 1
            }, mainFrame)

            makeCorner(mainFrame, cornerPx)

            local bg = create('Frame', {
                BackgroundTransparency = 0,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Name = '#background',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = true,
                ZIndex = 4
            }, mainFrame)
            makeCorner(bg, cornerPx)

            makeStroke(mainFrame, theme.Stroke, 1)

            create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = 'rbxassetid://7331400934',
                ImageColor3 = Color3.fromRGB(0, 0, 5),
                ImageTransparency = 0.2,
                Name = '#shadow',
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.new(1, 54, 1, 54),
                SliceCenter = Rect.new(40, 40, 260, 260),
                SliceScale = 1,
                ZIndex = 3
            }, mainFrame)

            local trimLine = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 66
            }, mainFrame)
            makeGradient(trimLine, theme.Primary, theme.Secondary, 0)

            local titleBar = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Window1,
                BorderColor3 = theme.Inset1,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#title-bar',
                Position = UDim2.fromOffset(0, 1),
                Selectable = true,
                Size = UDim2.new(1, 0, 0, 28),
                ZIndex = 50
            }, mainFrame)
            makeGradient(titleBar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 224), 90)
            makeTopSheen(titleBar, 51)
            create('Frame', {
                Name = '#bottom-line',
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 53
            }, titleBar)

            create('Frame', {
                BackgroundColor3 = theme.Window1,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#fade',
                Size = UDim2.new(1, 4, 1, 4),
                Position = UDim2.fromOffset(-2, -2),
                Visible = false,
                ZIndex = 60
            }, titleBar)

            local buttonClose = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-close',
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 52
            }, titleBar)
            makeCorner(buttonClose, cornerPx)
            makeStroke(buttonClose, theme.Stroke, 1)
            makeCloseGlyph(buttonClose, 53)

            local buttonMin = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-min',
                Position = UDim2.new(1, -27, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 52
            }, titleBar)
            makeCorner(buttonMin, cornerPx)
            makeStroke(buttonMin, theme.Stroke, 1)
            makeMinGlyph(buttonMin, 53)

            local buttonSettings = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-settings',
                Position = UDim2.new(1, -49, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 52
            }, titleBar)
            makeCorner(buttonSettings, cornerPx)
            makeStroke(buttonSettings, theme.Stroke, 1)
            makeSettingsGlyph(buttonSettings, 53)

            local buttonSearch = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-search',
                Position = UDim2.new(1, -71, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 52
            }, titleBar)
            makeCorner(buttonSearch, cornerPx)
            makeStroke(buttonSearch, theme.Stroke, 1)
            makeSearchGlyph(buttonSearch, 53)

            local searchBar = create('Frame', {
                Active = true,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#search-bar',
                Position = UDim2.new(1, -93, 0.5, 0),
                Size = UDim2.fromOffset(0, 18),
                Visible = false,
                ZIndex = 54
            }, titleBar)
            makeCorner(searchBar, cornerPx)
            makeStroke(searchBar, theme.Primary, 1)

            local searchInput = create('TextBox', {
                Active = true,
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#input',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'search controls...',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 55
            }, searchBar)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, searchInput)

            local icon = create('ImageLabel', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = '',
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                Name = '#icon',
                Position = UDim2.new(0, 7, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Visible = false,
                ZIndex = 52
            }, titleBar)

            local titleAccent = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#title-accent',
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(2, 12),
                ZIndex = 52
            }, titleBar)
            makeGradient(titleAccent, theme.Primary, theme.Secondary, 90)

            local title = create('TextLabel', {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = currentFont,
                Name = '#title',
                Position = UDim2.fromOffset(16, 0),
                RichText = true,
                Size = UDim2.new(1, -112, 1, 0),
                Text = 'LARPWare',
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 52
            }, titleBar)

            local pageRegion = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderColor3 = theme.Inset2,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#page-region',
                Position = UDim2.new(0, 138, 0, 29),
                Size = UDim2.new(1, -138, 1, -29),
                Visible = true,
                ZIndex = 30
            }, mainFrame)

            local easterEgg = create('Frame', {
                Active = false,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#easter-egg',
                Position = UDim2.new(0, 0, 1, 2),
                Size = UDim2.new(1, 0, 0, 124),
                Visible = false,
                ZIndex = 44
            }, pageRegion)
            create('ImageLabel', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = easterEggAsset,
                ImageTransparency = 0,
                Name = '#logo',
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.new(0.9, 0, 0, 96),
                ZIndex = 45
            }, easterEgg)

            local sideBar = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderColor3 = theme.Inset3,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#sidebar',
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(0, 138, 1, -29),
                Visible = true,
                ZIndex = 48
            }, mainFrame)
            makeGradient(sideBar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(214, 214, 220), 90)
            create('Frame', {
                Name = '#right-line',
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -1, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 50
            }, sideBar)

            local navHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#nav-header',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, -1, 0, 24),
                ZIndex = 49
            }, sideBar)
            local navDot = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = theme.Primary,
                BorderSizePixel = 0,
                Name = '#dot',
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(4, 4),
                ZIndex = 50
            }, navHeader)
            makeCorner(navDot, 2, true)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(19, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Text = 'NAVIGATION',
                TextColor3 = theme.TextDim,
                TextSize = 9,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 50
            }, navHeader)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                Name = '#sep',
                Position = UDim2.new(0, 8, 1, -1),
                Size = UDim2.new(1, -16, 0, 1),
                ZIndex = 50
            }, navHeader)

            local menuClip = create('Frame', {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Name = '#menu-clip',
                Position = UDim2.fromOffset(0, 24),
                Size = UDim2.new(1, -1, 1, -50),
                ZIndex = 49
            }, sideBar)

            local menu = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#menu',
                Position = UDim2.fromScale(0, 0),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.5,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollingEnabled = true,
                Size = UDim2.fromScale(1 / currentScale, 1 / currentScale),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 49
            }, menuClip)

            create('UIScale', {
                Name = '#content-scale',
                Scale = currentScale
            }, menu)

            local activePill = create('Frame', {
                Active = false,
                BackgroundColor3 = theme.Button3,
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#active-pill',
                Position = UDim2.new(0, 7, 0, 7),
                Size = UDim2.new(1, -14, 0, 30),
                Visible = false,
                ZIndex = 51
            }, menu)
            makeCorner(activePill, cornerPx)
            makeStroke(activePill, theme.StrokeHover, 1)

            local pillWash = create('Frame', {
                Active = false,
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Name = '#active-bg',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromScale(1, 1),
                ZIndex = 51
            }, activePill)
            create('UIGradient', {
                Name = '#wash',
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.70),
                    NumberSequenceKeypoint.new(0.58, 0.90),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = 0
            }, pillWash)

            local pillInd = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#indicator',
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 3, 0, 18),
                ZIndex = 53
            }, activePill)
            makeCorner(pillInd, 2, true)
            makeGradient(pillInd, theme.Primary, theme.Secondary, 90)

            local pillDot = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = theme.Primary,
                BorderSizePixel = 0,
                Name = '#active-dot',
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(4, 4),
                ZIndex = 53
            }, activePill)
            makeCorner(pillDot, 2, true)

            local tabButtons = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = '#tab-buttons',
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 0),
                ZIndex = 52
            }, menu)

            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Name = '#layout',
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, tabButtons)

            create('UIPadding', {
                Name = '#padding',
                PaddingTop = UDim.new(0, 7),
                PaddingBottom = UDim.new(0, 7)
            }, tabButtons)

            local sideFooter = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Inset1,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Name = '#sidebar-footer',
                Position = UDim2.new(0, 0, 1, -26),
                Size = UDim2.new(1, -1, 0, 26),
                Text = '',
                ZIndex = 49
            }, sideBar)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                Name = '#sep',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 50
            }, sideFooter)
            local footDot = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = theme.Primary,
                BorderSizePixel = 0,
                Name = '#dot',
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(5, 5),
                ZIndex = 50
            }, sideFooter)
            makeCorner(footDot, 3, true)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#brand',
                Position = UDim2.fromOffset(20, 0),
                Size = UDim2.new(0.62, -16, 1, 0),
                Text = 'LARPWare',
                TextColor3 = theme.TextPrimary,
                TextSize = 10,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 50
            }, sideFooter)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#ver',
                Position = UDim2.new(0.62, 0, 0, 0),
                Size = UDim2.new(0.38, -8, 1, 0),
                Text = 'v2.2',
                TextColor3 = theme.TextDim,
                TextSize = 9,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 50
            }, sideFooter)

            local resizeHandle = create('Frame', {
                Active = true,
                BackgroundTransparency = 1,
                Name = '#resize-handle',
                Position = UDim2.new(1, -12, 1, -12),
                Size = UDim2.fromOffset(12, 12),
                ZIndex = 55
            }, mainFrame)
            for idx = 0, 1 do
                create('Frame', {
                    Name = '#grip' .. idx,
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = theme.StrokeHover,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -4 - idx * 3, 1, -4 - idx * 3),
                    Rotation = -45,
                    Size = UDim2.fromOffset(4 + idx * 4, 1),
                    ZIndex = 56
                }, resizeHandle)
            end

            local popover = create('Frame', {
                Active = true,
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Window1,
                BorderColor3 = theme.Inset1,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                Name = '#settings-popover',
                Position = UDim2.new(1, -6, 0, 34),
                Size = UDim2.fromOffset(214, 294),
                Visible = false,
                ZIndex = 80
            }, mainFrame)
            makeCorner(popover, cornerPx)
            makeStroke(popover, theme.Stroke, 1)

            create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = 'rbxassetid://7331400934',
                ImageColor3 = Color3.fromRGB(0, 0, 5),
                ImageTransparency = 0.25,
                Name = '#shadow',
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.new(1, 32, 1, 32),
                SliceCenter = Rect.new(40, 40, 260, 260),
                SliceScale = 1,
                ZIndex = 79
            }, popover)

            local popTrim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 83
            }, popover)
            makeGradient(popTrim, theme.Primary, theme.Secondary, 0)

            local popHeader = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                Name = '#header',
                Position = UDim2.fromOffset(0, 1),
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 81
            }, popover)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 82
            }, popHeader)
            local popTitle = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#title',
                Size = UDim2.fromScale(1, 1),
                Text = 'appearance',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, popHeader)
            create('UIPadding', {PaddingLeft = UDim.new(0, 7)}, popTitle)

            local popBody = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#body',
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1, 0, 1, -22),
                ZIndex = 81
            }, popover)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6)
            }, popBody)

            local fontHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#font-header',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = 82
            }, popBody)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#font-label',
                Size = UDim2.new(0.4, 0, 1, 0),
                Text = 'font',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, fontHeader)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#font-active',
                Position = UDim2.fromScale(0.35, 0),
                Size = UDim2.new(0.65, 0, 1, 0),
                Text = '.' .. currentFontKey,
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 82
            }, fontHeader)

            local fontGroup = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#font-group',
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, 0, 0, 126),
                ZIndex = 82
            }, popBody)
            makeCorner(fontGroup, cornerPx)
            makeStroke(fontGroup, theme.Stroke, 1)

            local fSearchWrap = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                Name = '#search-wrap',
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 83
            }, fontGroup)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 84
            }, fSearchWrap)
            local fSearch = create('TextBox', {
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#search',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'search fonts...',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 84
            }, fSearchWrap)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, fSearch)

            local fList = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#list',
                Position = UDim2.fromOffset(0, 20),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.45,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, 0, 1, -20),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 83
            }, fontGroup)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, fList)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 4)
            }, fList)

            local scaleHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#scale-header',
                Position = UDim2.fromOffset(0, 148),
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = 82
            }, popBody)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#scale-label',
                Size = UDim2.new(0.6, 0, 1, 0),
                Text = 'ui scale',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, scaleHeader)
            create('TextButton', {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#scale-val',
                Position = UDim2.fromScale(0.6, 0),
                Size = UDim2.new(0.4, 0, 1, 0),
                Text = '1.00x',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 83
            }, scaleHeader)

            local scaleTrack = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#scale-track',
                Position = UDim2.fromOffset(0, 164),
                Size = UDim2.new(1, 0, 0, 12),
                ZIndex = 82
            }, popBody)
            makeCorner(scaleTrack, cornerPx)
            makeStroke(scaleTrack, theme.Stroke, 1)

            local scaleFill = create('Frame', {
                Active = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Name = '#fill',
                Size = UDim2.fromScale(0.333, 1),
                ZIndex = 83
            }, scaleTrack)
            makeCorner(scaleFill, cornerPx)
            makeGradient(scaleFill, theme.Primary, theme.Secondary, 0)
            create('Frame', {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Name = '#cap',
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 84
            }, scaleFill)

            local tScaleHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#tscale-header',
                Position = UDim2.fromOffset(0, 182),
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = 82
            }, popBody)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#tscale-label',
                Size = UDim2.new(0.6, 0, 1, 0),
                Text = 'text scale',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, tScaleHeader)
            create('TextButton', {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#tscale-val',
                Position = UDim2.fromScale(0.6, 0),
                Size = UDim2.new(0.4, 0, 1, 0),
                Text = '1.00x',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 83
            }, tScaleHeader)

            local tScaleTrack = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#tscale-track',
                Position = UDim2.fromOffset(0, 198),
                Size = UDim2.new(1, 0, 0, 12),
                ZIndex = 82
            }, popBody)
            makeCorner(tScaleTrack, cornerPx)
            makeStroke(tScaleTrack, theme.Stroke, 1)

            local tScaleFill = create('Frame', {
                Active = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Name = '#fill',
                Size = UDim2.fromScale(0.333, 1),
                ZIndex = 83
            }, tScaleTrack)
            makeCorner(tScaleFill, cornerPx)
            makeGradient(tScaleFill, theme.Primary, theme.Secondary, 0)
            create('Frame', {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Name = '#cap',
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 84
            }, tScaleFill)

            local accentHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#accent-header',
                Position = UDim2.fromOffset(0, 218),
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = 82
            }, popBody)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#accent-label',
                Size = UDim2.new(0.5, 0, 1, 0),
                Text = 'accent',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, accentHeader)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#accent-active',
                Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                Text = currentThemeName,
                TextColor3 = theme.TextPrimary,
                TextSize = 10,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 82
            }, accentHeader)

            local accentSwatches = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#accent-swatches',
                Position = UDim2.fromOffset(0, 236),
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 82
            }, popBody)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center
            }, accentSwatches)

            local searchResults = create('Frame', {
                Active = true,
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Window1,
                BorderColor3 = theme.Inset1,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#search-results',
                Position = UDim2.new(1, -71, 0, 34),
                Size = UDim2.fromOffset(236, 0),
                Visible = false,
                ZIndex = 86
            }, mainFrame)
            makeCorner(searchResults, cornerPx)
            makeStroke(searchResults, theme.Stroke, 1)
            local srTrim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 88
            }, searchResults)
            makeGradient(srTrim, theme.Primary, theme.Secondary, 0)

            local srList = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#list',
                Position = UDim2.fromOffset(0, 2),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.45,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, 0, 1, -2),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 87
            }, searchResults)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, srList)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 5)
            }, srList)

            instances.mainFrame = mainFrame
        end
        window.instances = instances

        window.signals = {
            buttonClose = {
                MouseEnter = function(self)
                    tween(self, {BackgroundColor3 = theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Primary}, 0.16, 1)
                    setGlyphColor(self['#icon'], theme.Primary, 0.16)
                end,
                MouseLeave = function(self)
                    tween(self, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    setGlyphColor(self['#icon'], theme.TextDim, 0.16)
                end,
                MouseButton1Click = function(_, self)
                    self:destroy()
                end
            },
            buttonMin = {
                MouseEnter = function(self, w)
                    w.minFocused = true
                    tween(self, {BackgroundColor3 = w.minimized and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                    setGlyphColor(self['#icon'], w.minimized and theme.Primary or theme.TextPrimary, 0.16)
                end,
                MouseLeave = function(self, w)
                    w.minFocused = false
                    tween(self, {BackgroundColor3 = w.minimized and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    setGlyphColor(self['#icon'], w.minimized and theme.Primary or theme.TextDim, 0.16)
                end,
                MouseButton1Click = function(_, self)
                    self:minimize()
                end
            },
            buttonSettings = {
                MouseEnter = function(self, w)
                    w.settingsFocused = true
                    tween(self, {BackgroundColor3 = w.settingsOpen and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.settingsOpen and theme.Primary or theme.StrokeHover}, 0.16, 1)
                end,
                MouseLeave = function(self, w)
                    w.settingsFocused = false
                    tween(self, {BackgroundColor3 = w.settingsOpen and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.settingsOpen and theme.Primary or theme.Stroke}, 0.16, 1)
                end,
                MouseButton1Click = function(_, self)
                    self:toggleSettings()
                end
            },
            buttonSearch = {
                MouseEnter = function(self, w)
                    w.searchFocused = true
                    tween(self, {BackgroundColor3 = w.searchOpen and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.searchOpen and theme.Primary or theme.StrokeHover}, 0.16, 1)
                    local icon = self['#icon']
                    tween(icon['#lens']['#stroke'], {Color = w.searchOpen and theme.Primary or theme.TextPrimary}, 0.16, 1)
                    tween(icon['#handle'], {BackgroundColor3 = w.searchOpen and theme.Primary or theme.TextPrimary}, 0.16, 1)
                end,
                MouseLeave = function(self, w)
                    w.searchFocused = false
                    tween(self, {BackgroundColor3 = w.searchOpen and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.searchOpen and theme.Primary or theme.Stroke}, 0.16, 1)
                    local icon = self['#icon']
                    tween(icon['#lens']['#stroke'], {Color = w.searchOpen and theme.Primary or theme.TextDim}, 0.16, 1)
                    tween(icon['#handle'], {BackgroundColor3 = w.searchOpen and theme.Primary or theme.TextDim}, 0.16, 1)
                end,
                MouseButton1Click = function(_, self)
                    self:toggleSearch()
                end
            }
        }

        window.toggleSearch = function(self, forceState)
            local nextState = (forceState ~= nil) and forceState or (not self.searchOpen)
            if (self.minimized) then
                nextState = false
            end
            self.searchOpen = nextState
            local btn = self.instances.buttonSearch
            local bar = self.instances.searchBar
            local inp = self.instances.searchInput
            local res = self.instances.searchResults
            local icon = btn['#icon']

            if (nextState) then
                if (self.settingsOpen) then
                    self:toggleSettings()
                end
                bar.Visible = true
                tween(bar, {Size = UDim2.fromOffset(162, 18)}, 0.24, 1)
                tween(btn, {BackgroundColor3 = self.searchFocused and theme.Button4 or theme.Button3}, 0.16, 1)
                tween(btn['#stroke'], {Color = theme.Primary}, 0.16, 1)
                tween(icon['#lens']['#stroke'], {Color = theme.Primary}, 0.16, 1)
                tween(icon['#handle'], {BackgroundColor3 = theme.Primary}, 0.16, 1)
                task.defer(function()
                    if (self.searchOpen and inp and inp.Parent) then
                        inp:CaptureFocus()
                    end
                end)
            else
                inp.Text = ''
                tween(bar, {Size = UDim2.fromOffset(0, 18)}, 0.2, 1)
                tween(res, {Size = UDim2.fromOffset(236, 0)}, 0.16, 1)
                tween(btn, {BackgroundColor3 = self.searchFocused and theme.Button2 or theme.Button1}, 0.16, 1)
                tween(btn['#stroke'], {Color = self.searchFocused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                tween(icon['#lens']['#stroke'], {Color = self.searchFocused and theme.TextPrimary or theme.TextDim}, 0.16, 1)
                tween(icon['#handle'], {BackgroundColor3 = self.searchFocused and theme.TextPrimary or theme.TextDim}, 0.16, 1)
                task.delay(0.2, function()
                    if (not self.searchOpen and bar and bar.Parent) then
                        bar.Visible = false
                    end
                    if (not self.searchOpen and res and res.Parent) then
                        res.Visible = false
                    end
                end)
            end
            return self
        end

        window.toggleSettings = function(self)
            self.settingsOpen = not self.settingsOpen
            local pop = self.instances.settingsPopover
            local btn = self.instances.buttonSettings
            if (self.minimized) then
                self.settingsOpen = false
            end
            if (self.settingsOpen and self._buildPopoverFonts) then
                self._buildPopoverFonts()
            end
            if (self.settingsOpen and self.searchOpen) then
                self:toggleSearch(false)
            end
            pop.Visible = self.settingsOpen
            if (self.settingsOpen) then
                tween(btn, {BackgroundColor3 = self.settingsFocused and theme.Button4 or theme.Button3}, 0.16, 1)
                tween(btn['#stroke'], {Color = theme.Primary}, 0.16, 1)
            else
                tween(btn, {BackgroundColor3 = self.settingsFocused and theme.Button2 or theme.Button1}, 0.16, 1)
                tween(btn['#stroke'], {Color = self.settingsFocused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
            end
            return self
        end

        window.setEasterEgg = function(self, visible)
            local ee = self.instances and self.instances.easterEgg
            if (not ee or not ee.Parent) then return self end
            local nextState = visible and (not self.minimized)
            self._eeIdleId = (self._eeIdleId or 0) + 1
            local idleId = self._eeIdleId

            if (nextState) then
                task.delay(0.55, function()
                    if (not ui._terminated and self._eeIdleId == idleId and self.easterEggVisible) then
                        self:setEasterEgg(false)
                    end
                end)
            end

            if (self.easterEggVisible == nextState) then
                return self
            end
            self.easterEggVisible = nextState
            self._eeAnimId = (self._eeAnimId or 0) + 1
            local animId = self._eeAnimId

            local activeMenu
            for _, m in ipairs(self.menus) do
                if (m.selected) then
                    activeMenu = m
                    break
                end
            end

            if (nextState) then
                ee.Visible = true
                tween(ee, {Position = UDim2.new(0, 0, 1, -124)}, 0.26, 1)
                if (activeMenu and activeMenu.instances and activeMenu.instances.menuFrame) then
                    tween(activeMenu.instances.menuFrame, {Position = UDim2.new(0, 0, 0, -124)}, 0.26, 1)
                end
            else
                tween(ee, {Position = UDim2.new(0, 0, 1, 2)}, 0.22, 1)
                if (activeMenu and activeMenu.instances and activeMenu.instances.menuFrame) then
                    tween(activeMenu.instances.menuFrame, {Position = UDim2.fromScale(0, 0)}, 0.22, 1)
                end
                task.delay(0.23, function()
                    if (self._eeAnimId == animId and not self.easterEggVisible and ee and ee.Parent) then
                        ee.Visible = false
                    end
                end)
            end
            return self
        end

        window.destroy = function(self)
            if (self._wheelCon) then
                self._wheelCon:Disconnect()
                self._wheelCon = nil
            end
            if (ui.autoDisableToggles) then
                for _, m in ipairs(self.menus) do
                    for _, sec in ipairs(m.sections) do
                        for _, ctrl in ipairs(sec.controls) do
                            if (ctrl.class == 'picker') then
                                if (ctrl.chromaCon) then
                                    ctrl.chromaCon:Disconnect()
                                end
                                local pwin = ctrl.pickerWindow
                                if (pwin) then
                                    if (pwin.chromaCon) then
                                        pwin.chromaCon:Disconnect()
                                    end
                                    pwin:bindToEvent('close', nil)
                                    pwin:destroy()
                                end
                            elseif (ctrl.class == 'toggle') then
                                if (ctrl.toggled) then
                                    ctrl:disable()
                                end
                            end
                        end
                    end
                end
            end

            local mainFrame = self.instances.mainFrame
            task.spawn(function()
                local animCon
                task.spawn(function()
                    local backgroundTransparency = {}
                    local scrollBarImageTransparency = {}
                    local imageTransparency = {}
                    local transparency = {}
                    local textTransparency = {}

                    local s = {
                        Frame = {backgroundTransparency},
                        ImageButton = {backgroundTransparency, imageTransparency},
                        ImageLabel = {backgroundTransparency, imageTransparency},
                        TextButton = {backgroundTransparency, textTransparency},
                        TextLabel = {backgroundTransparency, textTransparency},
                        TextBox = {backgroundTransparency, textTransparency},
                        ScrollingFrame = {backgroundTransparency, scrollBarImageTransparency},
                        UIStroke = {transparency}
                    }
                    local d = mainFrame:GetDescendants()
                    table.insert(d, mainFrame)

                    for _, v in ipairs(d) do
                        local a = s[v.ClassName]
                        if (a) then
                            for idx = 1, #a do
                                table.insert(a[idx], v)
                            end
                        end
                    end

                    for _, v in ipairs(transparency) do
                        v.Transparency = 1
                    end
                    for _, v in ipairs(scrollBarImageTransparency) do
                        v.ScrollBarImageTransparency = 1
                    end

                    animCon = renderService.RenderStepped:Connect(function(dt)
                        dt *= 8
                        for i = 1, #backgroundTransparency do
                            backgroundTransparency[i].BackgroundTransparency += dt
                        end
                        for i = 1, #imageTransparency do
                            imageTransparency[i].ImageTransparency += dt
                        end
                        for i = 1, #textTransparency do
                            textTransparency[i].TextTransparency += dt
                        end
                    end)
                end)
                tween(mainFrame['#scale'], {Scale = 0.6}, 0.45, 1).Completed:Wait()
                if (animCon) then
                    animCon:Disconnect()
                end
                mainFrame:Destroy()
            end)

            local idx = table.find(ui.windows, self)
            if (idx) then
                table.remove(ui.windows, idx)
            end
            if (ui._syncScreenState) then
                ui._syncScreenState()
            end
            if (#ui.windows == 0) then
                task.wait(0.3)
                ui.destroy(true)
            end

            self:fireEvent('destroyInternal')
            return self
        end

        window.setTitle = function(self, text)
            self.instances.title.Text = tostring(text)
            return self
        end

        local function syncUiScreenEnabled()
            if (not uiScreen or not uiScreen.Parent) then
                syncCursorUnlock(false)
                return
            end
            local anyVis = false
            for _, w in ipairs(ui.windows) do
                if (w.instances and w.instances.mainFrame and w.instances.mainFrame.Visible) then
                    anyVis = true
                    break
                end
            end
            uiScreen.Enabled = anyVis
            syncCursorUnlock(anyVis)
            if (not anyVis) then
                tooltip.showing = false
                tooltip.handle = nil
                if (tooltip.update) then
                    tooltip.update:Disconnect()
                    tooltip.update = nil
                end
                if (tooltip.instances and tooltip.instances.main) then
                    tooltip.instances.main.Visible = false
                end
            end
        end
        ui._syncScreenState = syncUiScreenEnabled

        window.setVisible = function(self, state)
            local mf = self.instances and self.instances.mainFrame
            if (not mf or not mf.Parent) then return self end
            mf.Visible = state and true or false
            syncUiScreenEnabled()
            if (ui.syncMobileButtonState) then
                ui.syncMobileButtonState()
            end
            return self
        end

        window.toggle = function(self)
            local mf = self.instances and self.instances.mainFrame
            if (not mf or not mf.Parent) then return self end
            mf.Visible = not mf.Visible
            syncUiScreenEnabled()
            if (ui.syncMobileButtonState) then
                ui.syncMobileButtonState()
            end
            return self
        end
        window.__hotkeyFunc = window.toggle

        window.playIntro = function(self)
            playLarpIntro(self, true)
            return self
        end

        window.getPreferenceMenu = function(self)
            return self._defaultSettingsMenu
        end
        window.getSettingsMenu = window.getPreferenceMenu

        window.popup = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for popup settings', 2)
            end
            local mf = self.instances and self.instances.mainFrame
            if (not mf or not mf.Parent) then return nil end

            if (not settings.stack and self._activePopup and typeof(self._activePopup.close) == 'function') then
                self._activePopup:close(true)
            end

            local s_title = tostring(settings.title or settings.text or 'notice')
            local s_content = tostring(settings.content or settings.message or settings.desc or '')
            local s_badge = settings.badge
            local s_width = math.clamp(settings.width or 336, 220, math.max(240, math.floor(mf.AbsoluteSize.X - 36)))
            local s_dismissBackdrop = (settings.dismissOnBackdrop == nil) and true or (settings.dismissOnBackdrop and true or false)
            local s_dismissEsc = (settings.dismissOnEscape == nil) and true or (settings.dismissOnEscape and true or false)
            local s_showClose = (settings.showClose == nil) and true or (settings.showClose and true or false)
            local s_buttons = settings.buttons
            if (typeof(s_buttons) ~= 'table' or #s_buttons == 0) then
                s_buttons = {{text = 'ok', style = 'primary'}}
            end

            local overlay = create('TextButton', {
                Active = true,
                AutoButtonColor = false,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#popup-overlay',
                Position = UDim2.fromOffset(0, 1),
                Size = UDim2.new(1, 0, 1, -1),
                Text = '',
                ZIndex = 110
            }, mf)
            makeCorner(overlay, cornerPx)

            local card = create('Frame', {
                Active = true,
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Window1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#popup-card',
                Position = UDim2.fromScale(0.5, 0.53),
                Size = UDim2.fromOffset(s_width, 0),
                ZIndex = 112
            }, overlay)
            makeCorner(card, cornerPx)
            makeStroke(card, theme.StrokeHover, 1)
            local cardScale = create('UIScale', {Name = '#scale', Scale = 0.90}, card)

            local inner = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = '#popup-inner',
                Size = UDim2.fromScale(1, 0),
                ZIndex = 113
            }, card)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, inner)

            local header = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                LayoutOrder = 1,
                Name = '#header',
                Size = UDim2.new(1, 0, 0, 32),
                ZIndex = 114
            }, inner)
            makeGradient(header, Color3.fromRGB(255, 255, 255), Color3.fromRGB(228, 228, 228), 90)
            local pTrim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 116
            }, header)
            makeGradient(pTrim, theme.Primary, theme.Secondary, 0)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Name = '#sep',
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 115
            }, header)

            local titleAccent = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#title-accent',
                Position = UDim2.new(0, 10, 0.5, 1),
                Size = UDim2.fromOffset(2, 12),
                ZIndex = 115
            }, header)
            makeGradient(titleAccent, theme.Primary, theme.Secondary, 90)

            local rightReserved = s_showClose and 32 or 12
            if (s_badge and tostring(s_badge) ~= '') then
                rightReserved += 64
            end

            local titleLbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#title',
                Position = UDim2.fromOffset(18, 1),
                RichText = true,
                Size = UDim2.new(1, -18 - rightReserved, 1, -1),
                Text = s_title,
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 115
            }, header)

            if (s_badge and tostring(s_badge) ~= '') then
                local pill = create('Frame', {
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = theme.Inset1,
                    BorderSizePixel = 0,
                    Name = '#badge',
                    Position = UDim2.new(1, s_showClose and -32 or -10, 0.5, 1),
                    Size = UDim2.fromOffset(0, 17),
                    ZIndex = 115
                }, header)
                makeCorner(pill, cornerPx)
                makeStroke(pill, theme.StrokeHover, 1)
                local bLbl = create('TextLabel', {
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Font = currentFont,
                    Name = '#label',
                    Size = UDim2.fromOffset(0, 17),
                    Text = tostring(s_badge),
                    TextColor3 = theme.Primary,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 116
                }, pill)
                create('UIPadding', {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, bLbl)
            end

            local closeBtn
            if (s_showClose) then
                closeBtn = create('TextButton', {
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Name = '#close',
                    Position = UDim2.new(1, -8, 0.5, 1),
                    Size = UDim2.fromOffset(18, 18),
                    Text = '',
                    ZIndex = 115
                }, header)
                makeCorner(closeBtn, cornerPx)
                makeStroke(closeBtn, theme.Stroke, 1)
                makeCloseGlyph(closeBtn, 116)
            end

            local bodyWrap = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                LayoutOrder = 2,
                Name = '#content-wrap',
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 113
            }, inner)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 11),
                PaddingBottom = UDim.new(0, 11)
            }, bodyWrap)

            local contentLbl = create('TextLabel', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#content',
                RichText = true,
                Size = UDim2.new(1, 0, 0, 0),
                Text = s_content,
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 114
            }, bodyWrap)

            local actionsWrap = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                LayoutOrder = 3,
                Name = '#actions-wrap',
                Size = UDim2.new(1, 0, 0, 40),
                ZIndex = 113
            }, inner)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 10)
            }, actionsWrap)

            local actionsRow = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#actions',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 114
            }, actionsWrap)
            local gap = 6
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, gap),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center
            }, actionsRow)

            local pop = setmetatable({
                binds = {},
                open = true,
                window = self,
                instances = {
                    overlay = overlay,
                    card = card,
                    title = titleLbl,
                    content = contentLbl,
                    actions = actionsRow
                }
            }, elemClasses.baseElement)
            pop.class = 'popup'
            pop.name = s_title

            local escCon
            pop.close = function(pSelf, instant)
                if (not pSelf.open) then return pSelf end
                pSelf.open = false
                if (self._activePopup == pSelf) then
                    self._activePopup = nil
                end
                if (escCon) then
                    escCon:Disconnect()
                    escCon = nil
                end
                if (instant) then
                    if (overlay and overlay.Parent) then
                        overlay:Destroy()
                    end
                    pSelf:fireEvent('onClose')
                    return pSelf
                end
                tween(overlay, {BackgroundTransparency = 1}, 0.16, 1)
                tween(cardScale, {Scale = 0.92}, 0.16, 1)
                tween(card, {Position = UDim2.fromScale(0.5, 0.52)}, 0.16, 1)
                task.delay(0.17, function()
                    if (overlay and overlay.Parent) then
                        overlay:Destroy()
                    end
                    pSelf:fireEvent('onClose')
                end)
                return pSelf
            end

            pop.setTitle = function(pSelf, txt)
                titleLbl.Text = tostring(txt or '')
                pSelf.name = titleLbl.Text
                return pSelf
            end

            pop.setContent = function(pSelf, txt)
                contentLbl.Text = tostring(txt or '')
                return pSelf
            end

            pop.isOpen = function(pSelf)
                return pSelf.open == true
            end

            local btnCount = #s_buttons
            local perOffset = -math.floor(gap * (btnCount - 1) / btnCount + 0.5)
            for idx, bCfg in ipairs(s_buttons) do
                local bText = tostring(bCfg.text or 'button')
                local bStyle = tostring(bCfg.style or 'secondary'):lower()
                local bAutoClose = (bCfg.autoClose == nil) and true or (bCfg.autoClose and true or false)

                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = (bStyle == 'primary' or bStyle == 'danger') and Color3.fromRGB(255, 255, 255) or theme.Button1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    LayoutOrder = idx,
                    Name = '#pbtn-' .. idx,
                    Size = UDim2.new(1 / btnCount, perOffset, 1, 0),
                    Text = bText,
                    TextColor3 = (bStyle == 'primary' or bStyle == 'danger') and theme.TextPrimary or theme.TextDim,
                    TextSize = 11,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = (bStyle == 'primary' or bStyle == 'danger') and 0.72 or 0.85,
                    ZIndex = 115
                }, actionsRow)
                makeCorner(btn, cornerPx)
                makeTopSheen(btn, 116)

                if (bStyle == 'primary') then
                    local grad = makeGradient(btn, theme.Primary, theme.Secondary, 90)
                    local st = makeStroke(btn, blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.16), 1)
                    st:SetAttribute('ThemeStroke', nil)
                    btn.MouseEnter:Connect(function()
                        grad.Color = ColorSequence.new(
                            blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.14),
                            blendColor(theme.Secondary, Color3.fromRGB(255, 255, 255), 0.12)
                        )
                        tween(st, {Color = Color3.fromRGB(255, 200, 205)}, 0.14, 1)
                    end)
                    btn.MouseLeave:Connect(function()
                        grad.Color = ColorSequence.new(theme.Primary, theme.Secondary)
                        tween(st, {Color = blendColor(theme.Primary, Color3.fromRGB(255, 255, 255), 0.16)}, 0.14, 1)
                    end)
                elseif (bStyle == 'danger') then
                    local d1, d2 = Color3.fromRGB(196, 28, 42), Color3.fromRGB(122, 14, 26)
                    local grad = makeGradient(btn, d1, d2, 90)
                    local st = makeStroke(btn, Color3.fromRGB(224, 72, 86), 1)
                    st:SetAttribute('ThemeStroke', nil)
                    btn.MouseEnter:Connect(function()
                        grad.Color = ColorSequence.new(blendColor(d1, Color3.fromRGB(255, 255, 255), 0.14), blendColor(d2, Color3.fromRGB(255, 255, 255), 0.10))
                        tween(st, {Color = Color3.fromRGB(255, 165, 175)}, 0.14, 1)
                    end)
                    btn.MouseLeave:Connect(function()
                        grad.Color = ColorSequence.new(d1, d2)
                        tween(st, {Color = Color3.fromRGB(224, 72, 86)}, 0.14, 1)
                    end)
                else
                    makeStroke(btn, theme.Stroke, 1)
                    btn.MouseEnter:Connect(function()
                        tween(btn, {BackgroundColor3 = theme.Button2, TextColor3 = theme.TextPrimary}, 0.14, 1)
                        tween(btn['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
                    end)
                    btn.MouseLeave:Connect(function()
                        tween(btn, {BackgroundColor3 = theme.Button1, TextColor3 = theme.TextDim}, 0.14, 1)
                        tween(btn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                    end)
                end

                btn.MouseButton1Click:Connect(function()
                    if (typeof(bCfg.callback) == 'function') then
                        task.spawn(bCfg.callback, pop)
                    end
                    if (bAutoClose) then
                        pop:close()
                    end
                end)
            end

            if (closeBtn) then
                closeBtn.MouseEnter:Connect(function()
                    tween(closeBtn, {BackgroundColor3 = theme.Button2}, 0.14, 1)
                    tween(closeBtn['#stroke'], {Color = theme.Primary}, 0.14, 1)
                    setGlyphColor(closeBtn['#icon'], theme.Primary, 0.14)
                end)
                closeBtn.MouseLeave:Connect(function()
                    tween(closeBtn, {BackgroundColor3 = theme.Button1}, 0.14, 1)
                    tween(closeBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                    setGlyphColor(closeBtn['#icon'], theme.TextDim, 0.14)
                end)
                closeBtn.MouseButton1Click:Connect(function()
                    pop:close()
                end)
            end

            if (s_dismissBackdrop) then
                overlay.MouseButton1Click:Connect(function()
                    pop:close()
                end)
            end

            if (s_dismissEsc) then
                escCon = inputService.InputBegan:Connect(function(io)
                    if (io.UserInputType == Enum.UserInputType.Keyboard and io.KeyCode == Enum.KeyCode.Escape) then
                        pop:close()
                    end
                end)
                ui.trackConnection(escCon)
            end

            if (not settings.stack) then
                self._activePopup = pop
            end

            tween(overlay, {BackgroundTransparency = 0.44}, 0.22, 1)
            tween(cardScale, {Scale = 1}, 0.26, 4)
            tween(card, {Position = UDim2.fromScale(0.5, 0.5)}, 0.26, 1)
            return pop
        end
        window.showPopup = window.popup

        window.setIcon = function(self, newIcon)
            local iconInst = self.instances.titleBar['#icon']
            local accentInst = self.instances.titleBar['#title-accent']
            local titleInst = self.instances.title
            if (newIcon and newIcon ~= '') then
                iconInst.Image = newIcon
                iconInst.Visible = true
                accentInst.Visible = false
                titleInst.Position = UDim2.fromOffset(28, 0)
            else
                iconInst.Visible = false
                accentInst.Visible = true
                titleInst.Position = UDim2.fromOffset(16, 0)
            end
            return self
        end

        window.fitToViewport = function(self, forceCenter)
            local mf = self.instances and self.instances.mainFrame
            if (not mf or not mf.Parent) then return self end
            local vpX, availH = getViewportInfo()
            local compact = isCompactViewport()
            local logicalW = math.max(1, (self.size and self.size.X.Offset) or mf.Size.X.Offset or 550)
            local logicalH = math.max(1, (self.size and self.size.Y.Offset) or mf.Size.Y.Offset or 376)

            local maxW = compact and math.floor(vpX * 0.84) or math.max(360, vpX - 24)
            local maxH = compact and math.floor(availH * 0.84) or math.max(260, availH - 24)
            local fitScale = math.min(1, maxW / logicalW, maxH / logicalH)
            fitScale = math.clamp(fitScale, 0.42, 1)

            local scObj = mf:FindFirstChild('#scale')
            if (scObj) then
                scObj.Scale = fitScale
            end
            self.viewportScale = fitScale

            local visW = logicalW * fitScale
            local visH = logicalH * fitScale
            local curPos = mf.Position
            local curX = curPos.X.Scale * vpX + curPos.X.Offset
            local curY = curPos.Y.Scale * availH + curPos.Y.Offset
            local outOfBounds = (curX < 4) or (curY < 4) or (curX + visW > vpX - 4) or (curY + visH > availH - 4)

            if (forceCenter or compact or outOfBounds) then
                local cx = math.max(4, math.floor((vpX - visW) * 0.5))
                local cy = math.max(4, math.floor((availH - visH) * 0.5))
                mf.Position = UDim2.fromOffset(cx, cy)
            end
            return self
        end

        window.setPosition = function(self, newPosition)
            if (typeof(newPosition) == 'Vector2') then
                newPosition = UDim2.fromOffset(newPosition.X, newPosition.Y)
            elseif (typeof(newPosition) ~= 'UDim2') then
                return error('expected type UDim2 or Vector2', 2)
            end
            self.instances.mainFrame.Position = newPosition
            return self
        end

        window.setSize = function(self, size)
            if (typeof(size) == 'Vector2') then
                size = UDim2.fromOffset(size.X, size.Y)
            elseif (typeof(size) ~= 'UDim2') then
                return error('expected type UDim2 or Vector2', 2)
            end
            self.size = size
            self.instances.mainFrame.Size = size
            self:fitToViewport(false)
            return self
        end

        window.getPosition = function(self)
            return self.instances.mainFrame.Position
        end

        window.getSize = function(self, targetSize)
            return targetSize and self.size or self.instances.mainFrame.Size
        end

        window.new = function(self, resize, showSettings, showSearch)
            local new = setmetatable({}, self)
            new.menus = {}
            new.binds = {}
            new.resizable = resize and true or false
            new.settingsOpen = false
            new.settingsFocused = false
            new.searchOpen = false
            new.searchFocused = false
            new.easterEggVisible = false
            table.insert(ui.windows, new)

            local insts = {}
            insts.mainFrame = self.instances.mainFrame:Clone()
            insts.mainFrame['#scale'].Scale = 1
            insts.mainFrame:GetPropertyChangedSignal('Visible'):Connect(function()
                if (ui._syncScreenState) then
                    ui._syncScreenState()
                end
            end)

            local titleBar = insts.mainFrame['#title-bar']
            insts.buttonClose = titleBar['#button-close']
            insts.buttonMin = titleBar['#button-min']
            insts.buttonSettings = titleBar['#button-settings']
            insts.buttonSearch = titleBar['#button-search']
            insts.searchBar = titleBar['#search-bar']
            insts.searchInput = insts.searchBar['#input']
            insts.searchResults = insts.mainFrame['#search-results']
            insts.pageRegion = insts.mainFrame['#page-region']
            insts.easterEgg = insts.pageRegion['#easter-egg']
            insts.easterEggLogo = insts.easterEgg['#logo']
            if (easterEggAsset ~= '') then
                insts.easterEggLogo.Image = easterEggAsset
            end
            table.insert(easterEggLabels, insts.easterEggLogo)

            insts.titleBar = titleBar
            insts.title = titleBar['#title']
            insts.gradient = insts.mainFrame['#trim']['#gradient']
            insts.sideBar = insts.mainFrame['#sidebar']
            insts.sideFooter = insts.sideBar['#sidebar-footer']
            insts.tabMenu = insts.sideBar['#menu-clip']['#menu']
            registerNestedScroll(insts.tabMenu)
            if (insts.searchResults and insts.searchResults:FindFirstChild('#list')) then
                registerNestedScroll(insts.searchResults['#list'])
            end
            insts.tabButtons = insts.tabMenu['#tab-buttons']
            insts.activePill = insts.tabMenu['#active-pill']
            insts.tabMenu['#content-scale'].Scale = currentScale
            insts.tabMenu.Size = UDim2.fromScale(1 / currentScale, 1 / currentScale)
            insts.resizeHandle = insts.mainFrame['#resize-handle']
            insts.settingsPopover = insts.mainFrame['#settings-popover']

            insts.sideFooter.MouseEnter:Connect(function()
                tween(insts.sideFooter, {BackgroundTransparency = 0.1}, 0.16, 1)
            end)
            insts.sideFooter.MouseLeave:Connect(function()
                tween(insts.sideFooter, {BackgroundTransparency = 0.35}, 0.16, 1)
            end)
            insts.sideFooter.MouseButton1Click:Connect(function()
                new:toggleSettings()
            end)

            if (showSettings == false) then
                insts.buttonSettings.Visible = false
            end
            if (showSearch == false) then
                insts.buttonSearch.Visible = false
            end

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            do
                local popBody = insts.settingsPopover['#body']
                local fontHeader = popBody['#font-header']
                local fontActiveLbl = fontHeader['#font-active']
                local fontGroup = popBody['#font-group']
                local fSearch = fontGroup['#search-wrap']['#search']
                local fList = fontGroup['#list']
                local scaleHeader = popBody['#scale-header']
                local scaleValBtn = scaleHeader['#scale-val']
                local scaleTrack = popBody['#scale-track']
                local scaleFill = scaleTrack['#fill']

                local popFontBtns = {}
                local popFontsBuilt = false
                local activePopFontKey = nil

                local function setPopBtnState(fk, active)
                    local btn = popFontBtns[fk]
                    if (not btn or not btn.Parent) then return end
                    btn.BackgroundColor3 = active and theme.Button3 or theme.Window3
                    btn.BackgroundTransparency = active and 0 or 1
                    btn.TextColor3 = active and theme.TextPrimary or theme.TextDim
                    btn['#ind'].BackgroundTransparency = active and 0 or 1
                end

                local function syncPopoverFont(fKey)
                    fontActiveLbl.Text = '.' .. tostring(fKey)
                    if (not popFontsBuilt) then
                        activePopFontKey = fKey
                        return
                    end
                    if (activePopFontKey and activePopFontKey ~= fKey) then
                        setPopBtnState(activePopFontKey, false)
                    end
                    activePopFontKey = fKey
                    setPopBtnState(fKey, true)
                end

                new._buildPopoverFonts = function()
                    if (popFontsBuilt) then return end
                    popFontsBuilt = true
                    registerNestedScroll(fList)
                    for idx, fk in ipairs(fontOrder) do
                        local disp = fontDisplayNames[fk] or fk
                        local isAct = (fk == currentFontKey)
                        local btn = create('TextButton', {
                            AutoButtonColor = false,
                            BackgroundColor3 = isAct and theme.Button3 or theme.Window3,
                            BackgroundTransparency = isAct and 0 or 1,
                            BorderSizePixel = 0,
                            Font = currentFont,
                            LayoutOrder = idx,
                            Name = '#fopt-' .. fk,
                            Size = UDim2.new(1, 0, 0, 19),
                            Text = disp,
                            TextColor3 = isAct and theme.TextPrimary or theme.TextDim,
                            TextSize = 11,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 84
                        }, fList)
                        create('UIPadding', {PaddingLeft = UDim.new(0, 8)}, btn)
                        create('Frame', {
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundColor3 = theme.Primary,
                            BackgroundTransparency = isAct and 0 or 1,
                            BorderSizePixel = 0,
                            Name = '#ind',
                            Position = UDim2.new(0, -8, 0.5, 0),
                            Size = UDim2.new(0, 2, 0, 11),
                            ZIndex = 85
                        }, btn)

                        btn.MouseButton1Click:Connect(function()
                            ui.setFont(fk)
                        end)
                        btn.MouseEnter:Connect(function()
                            if (currentFontKey ~= fk) then
                                btn.BackgroundColor3 = theme.Button2
                                btn.BackgroundTransparency = 0
                                btn.TextColor3 = theme.TextPrimary
                            end
                        end)
                        btn.MouseLeave:Connect(function()
                            if (currentFontKey ~= fk) then
                                btn.BackgroundTransparency = 1
                                btn.TextColor3 = theme.TextDim
                            end
                        end)
                        popFontBtns[fk] = btn
                    end
                    activePopFontKey = currentFontKey
                end

                fSearch:GetPropertyChangedSignal('Text'):Connect(function()
                    if (not popFontsBuilt) then new._buildPopoverFonts() end
                    local q = fSearch.Text:lower():gsub('^%.', '')
                    for fk, btn in pairs(popFontBtns) do
                        local disp = (fontDisplayNames[fk] or fk):lower()
                        btn.Visible = (q == '' or disp:find(q, 1, true) ~= nil or fk:find(q, 1, true) ~= nil)
                    end
                end)

                local minS, maxS, stepS = 0.5, 2.0, 0.05
                local function syncPopoverScale(sc)
                    local ratio = math.clamp((sc - minS) / (maxS - minS), 0, 1)
                    scaleFill.Size = UDim2.fromScale(ratio, 1)
                    scaleValBtn.Text = ('%.2fx'):format(sc)
                end

                scaleValBtn.MouseButton1Click:Connect(function()
                    ui.setScale(1)
                end)

                local draggingScale = false
                local sMoveCon
                local sEndCon

                local function applyScaleFromX(x)
                    local pos = scaleTrack.AbsolutePosition.X
                    local width = math.max(1, scaleTrack.AbsoluteSize.X)
                    local r = math.clamp((x - pos) / width, 0, 1)
                    local raw = minS + r * (maxS - minS)
                    local snapped = math.floor((raw + stepS * 0.5) / stepS) * stepS
                    snapped = math.clamp(math.floor(snapped * 100 + 0.5) / 100, minS, maxS)
                    ui.setScale(snapped)
                end

                scaleTrack.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        draggingScale = true
                        tween(scaleTrack['#stroke'], {Color = theme.Primary}, 0.14, 1)
                        applyScaleFromX(io.Position.X)
                        if (sMoveCon) then sMoveCon:Disconnect() end
                        if (sEndCon) then sEndCon:Disconnect() end
                        sMoveCon = inputService.InputChanged:Connect(function(mio)
                            if (draggingScale and isMoveInput(mio)) then
                                applyScaleFromX(mio.Position.X)
                            end
                        end)
                        sEndCon = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                draggingScale = false
                                tween(scaleTrack['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                                if (sMoveCon) then sMoveCon:Disconnect(); sMoveCon = nil end
                                if (sEndCon) then sEndCon:Disconnect(); sEndCon = nil end
                            end
                        end)
                    end
                end)

                local tScaleHeader = popBody['#tscale-header']
                local tScaleValBtn = tScaleHeader['#tscale-val']
                local tScaleTrack = popBody['#tscale-track']
                local tScaleFill = tScaleTrack['#fill']

                local minTS, maxTS, stepTS = 0.6, 1.8, 0.05
                local function syncPopoverTextScale(ts)
                    local ratio = math.clamp((ts - minTS) / (maxTS - minTS), 0, 1)
                    tScaleFill.Size = UDim2.fromScale(ratio, 1)
                    tScaleValBtn.Text = ('%.2fx'):format(ts)
                end

                tScaleValBtn.MouseButton1Click:Connect(function()
                    ui.setTextScale(1)
                end)

                local draggingTScale = false
                local tsMoveCon
                local tsEndCon

                local function applyTScaleFromX(x)
                    local pos = tScaleTrack.AbsolutePosition.X
                    local width = math.max(1, tScaleTrack.AbsoluteSize.X)
                    local r = math.clamp((x - pos) / width, 0, 1)
                    local raw = minTS + r * (maxTS - minTS)
                    local snapped = math.floor((raw + stepTS * 0.5) / stepTS) * stepTS
                    snapped = math.clamp(math.floor(snapped * 100 + 0.5) / 100, minTS, maxTS)
                    ui.setTextScale(snapped)
                end

                tScaleTrack.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        draggingTScale = true
                        tween(tScaleTrack['#stroke'], {Color = theme.Primary}, 0.14, 1)
                        applyTScaleFromX(io.Position.X)
                        if (tsMoveCon) then tsMoveCon:Disconnect() end
                        if (tsEndCon) then tsEndCon:Disconnect() end
                        tsMoveCon = inputService.InputChanged:Connect(function(mio)
                            if (draggingTScale and isMoveInput(mio)) then
                                applyTScaleFromX(mio.Position.X)
                            end
                        end)
                        tsEndCon = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                draggingTScale = false
                                tween(tScaleTrack['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                                if (tsMoveCon) then tsMoveCon:Disconnect(); tsMoveCon = nil end
                                if (tsEndCon) then tsEndCon:Disconnect(); tsEndCon = nil end
                            end
                        end)
                    end
                end)

                local accentActiveLbl = popBody['#accent-header']['#accent-active']
                local accentRow = popBody['#accent-swatches']
                local swatchMap = {}
                local quickPresets = {'crimson', 'cobalt', 'emerald', 'amber', 'violet', 'cherry', 'monochrome'}
                for idx, pName in ipairs(quickPresets) do
                    local preset = themePresets[pName]
                    if (preset) then
                        local sw = create('TextButton', {
                            AutoButtonColor = false,
                            BackgroundColor3 = preset.Primary,
                            BorderSizePixel = 0,
                            LayoutOrder = idx,
                            Name = '#sw-' .. pName,
                            Size = UDim2.fromOffset(22, 16),
                            Text = '',
                            ZIndex = 83
                        }, accentRow)
                        makeCorner(sw, cornerPx)
                        local swStroke = makeStroke(sw, pName == currentThemeName and Color3.fromRGB(255, 255, 255) or theme.Stroke, 1)
                        sw:SetAttribute('ThemeBG', nil)
                        swStroke:SetAttribute('ThemeStroke', nil)
                        swatchMap[pName] = sw
                        sw.MouseButton1Click:Connect(function()
                            ui.setThemePreset(pName)
                        end)
                    end
                end

                local function syncPopoverTheme(tName)
                    accentActiveLbl.Text = tostring(tName or 'custom')
                    for pName, sw in pairs(swatchMap) do
                        local st = sw:FindFirstChild('#stroke')
                        if (st) then
                            tween(st, {Color = (pName == tName) and Color3.fromRGB(255, 255, 255) or theme.Stroke}, 0.14, 1)
                        end
                    end
                end

                syncPopoverFont(currentFontKey)
                syncPopoverScale(currentScale)
                syncPopoverTextScale(currentTextScale)
                syncPopoverTheme(currentThemeName)
                table.insert(fontListeners, function(fKey)
                    if (insts.mainFrame and insts.mainFrame.Parent) then
                        syncPopoverFont(fKey)
                    end
                end)
                table.insert(scaleListeners, function(sc)
                    if (insts.mainFrame and insts.mainFrame.Parent) then
                        syncPopoverScale(sc)
                    end
                end)
                table.insert(themeListeners, function(tName)
                    if (insts.mainFrame and insts.mainFrame.Parent) then
                        syncPopoverTheme(tName)
                    end
                end)
                table.insert(textScaleListeners, function(ts)
                    if (insts.mainFrame and insts.mainFrame.Parent) then
                        syncPopoverTextScale(ts)
                    end
                end)
            end

            do
                local sInput = insts.searchInput
                local sResults = insts.searchResults
                local srList = sResults['#list']
                local topAction = nil

                local function jumpToMatch(m, sec, ctrl)
                    m:select()
                    if (sec.minimized) then
                        sec:minimize()
                    end
                    task.delay(0.06, function()
                        local mf = m.instances.menuFrame
                        local cf = ctrl.instances and ctrl.instances.controlFrame
                        if (mf and cf and cf.Parent) then
                            local relY = (cf.AbsolutePosition.Y - mf.AbsolutePosition.Y) / currentScale + mf.CanvasPosition.Y
                            tween(mf, {CanvasPosition = Vector2.new(0, math.max(0, relY - 24))}, 0.28, 1)
                            local flash = create('Frame', {
                                Active = false,
                                BackgroundColor3 = theme.Primary,
                                BackgroundTransparency = 0.72,
                                BorderSizePixel = 0,
                                Name = '#flash',
                                Size = UDim2.fromScale(1, 1),
                                ZIndex = 45
                            }, cf)
                            makeCorner(flash, cornerPx)
                            tween(flash, {BackgroundTransparency = 1}, 0.65, 1).Completed:Connect(function()
                                if (flash and flash.Parent) then
                                    flash:Destroy()
                                end
                            end)
                        end
                    end)
                    new:toggleSearch(false)
                end

                local function updateSearch()
                    for _, ch in ipairs(srList:GetChildren()) do
                        if (ch:IsA('TextButton') or ch:IsA('TextLabel')) then
                            ch:Destroy()
                        end
                    end
                    topAction = nil
                    local q = sInput.Text:lower():gsub('^%s+', ''):gsub('%s+$', '')
                    if (q == '' or not new.searchOpen) then
                        tween(sResults, {Size = UDim2.fromOffset(236, 0)}, 0.14, 1)
                        task.delay(0.14, function()
                            if (sInput.Text == '' and sResults and sResults.Parent) then
                                sResults.Visible = false
                            end
                        end)
                        return
                    end

                    local matches = {}
                    for _, m in ipairs(new.menus) do
                        for _, sec in ipairs(m.sections) do
                            for _, ctrl in ipairs(sec.controls) do
                                local cName = tostring(ctrl.name or '')
                                local sName = tostring(sec.instances.title.Text or '')
                                local mName = tostring(m.name or '')
                                if (cName ~= '' and (cName:lower():find(q, 1, true) or sName:lower():find(q, 1, true) or mName:lower():find(q, 1, true))) then
                                    table.insert(matches, {menu = m, section = sec, control = ctrl, label = cName, path = mName .. ' / ' .. sName})
                                    if (#matches >= 24) then
                                        break
                                    end
                                end
                            end
                            if (#matches >= 24) then break end
                        end
                        if (#matches >= 24) then break end
                    end

                    sResults.Visible = true
                    if (#matches == 0) then
                        create('TextLabel', {
                            BackgroundTransparency = 1,
                            Font = currentFont,
                            Size = UDim2.new(1, 0, 0, 22),
                            Text = 'no matching elements',
                            TextColor3 = theme.TextDim,
                            TextSize = 11,
                            ZIndex = 88
                        }, srList)
                        tween(sResults, {Size = UDim2.fromOffset(236, 32)}, 0.16, 1)
                        return
                    end

                    for idx, item in ipairs(matches) do
                        if (idx == 1) then
                            topAction = function()
                                jumpToMatch(item.menu, item.section, item.control)
                            end
                        end
                        local row = create('TextButton', {
                            AutoButtonColor = false,
                            BackgroundColor3 = theme.Window3,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            LayoutOrder = idx,
                            Name = '#sr-' .. idx,
                            Size = UDim2.new(1, 0, 0, 22),
                            Text = '',
                            ZIndex = 88
                        }, srList)
                        makeCorner(row, cornerPx)
                        create('TextLabel', {
                            BackgroundTransparency = 1,
                            Font = currentFont,
                            Position = UDim2.fromOffset(6, 0),
                            Size = UDim2.new(0.55, -6, 1, 0),
                            Text = item.label,
                            TextColor3 = theme.TextPrimary,
                            TextSize = 11,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 89
                        }, row)
                        create('TextLabel', {
                            BackgroundTransparency = 1,
                            Font = currentFont,
                            Position = UDim2.fromScale(0.55, 0),
                            Size = UDim2.new(0.45, -6, 1, 0),
                            Text = item.path,
                            TextColor3 = theme.TextDim,
                            TextSize = 10,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            TextXAlignment = Enum.TextXAlignment.Right,
                            ZIndex = 89
                        }, row)
                        row.MouseEnter:Connect(function()
                            tween(row, {BackgroundColor3 = theme.Button3, BackgroundTransparency = 0}, 0.12, 1)
                        end)
                        row.MouseLeave:Connect(function()
                            tween(row, {BackgroundTransparency = 1}, 0.12, 1)
                        end)
                        row.MouseButton1Click:Connect(function()
                            jumpToMatch(item.menu, item.section, item.control)
                        end)
                    end

                    local targetH = math.min(#matches * 24 + 10, 178)
                    tween(sResults, {Size = UDim2.fromOffset(236, targetH)}, 0.18, 1)
                end

                sInput:GetPropertyChangedSignal('Text'):Connect(updateSearch)
                sInput.FocusLost:Connect(function(enterPressed)
                    if (enterPressed and topAction) then
                        topAction()
                    end
                end)
            end

            do
                local mf = insts.mainFrame
                local function isVisiblyHovered(gui, x, y)
                    if (not gui or not gui.Parent) then return false end
                    local cur = gui
                    while (cur and cur:IsA('GuiObject')) do
                        if (not cur.Visible) then return false end
                        cur = cur.Parent
                    end
                    local ap = gui.AbsolutePosition
                    local as = gui.AbsoluteSize
                    if (as.X <= 0 or as.Y <= 0) then return false end
                    return (x >= ap.X and x <= ap.X + as.X and y >= ap.Y and y <= ap.Y + as.Y)
                end

                new._wheelCon = inputService.InputChanged:Connect(function(io)
                    if (ui._terminated) then return end
                    if (io.UserInputType ~= Enum.UserInputType.MouseWheel) then return end
                    if (new.minimized or not mf or not mf.Parent) then return end
                    local mPos = inputService:GetMouseLocation()
                    local inset = guiService:GetGuiInset()
                    local mx, my = mPos.X, mPos.Y - inset.Y
                    local p = mf.AbsolutePosition
                    local sz = mf.AbsoluteSize
                    local inside = (mx >= p.X and mx <= p.X + sz.X and my >= p.Y and my <= p.Y + sz.Y)
                    if (not inside) then return end

                    if (io.Position.Z > 0) then
                        new:setEasterEgg(false)
                    elseif (io.Position.Z < 0) then
                        local pr = insts.pageRegion
                        local overContent = pr and (mx >= pr.AbsolutePosition.X and mx <= pr.AbsolutePosition.X + pr.AbsoluteSize.X
                            and my >= pr.AbsolutePosition.Y and my <= pr.AbsolutePosition.Y + pr.AbsoluteSize.Y)
                        if (not overContent) then return end
                        if (new.settingsOpen and isVisiblyHovered(insts.settingsPopover, mx, my)) then return end
                        if (new.searchOpen and isVisiblyHovered(insts.searchResults, mx, my)) then return end

                        local activeMenu
                        for _, m in ipairs(new.menus) do
                            if (m.selected) then
                                activeMenu = m
                                break
                            end
                        end
                        local checkFrame = activeMenu and activeMenu.instances.menuFrame
                        if (not checkFrame) then return end

                        for i = #nestedScrolls, 1, -1 do
                            local sf = nestedScrolls[i]
                            if (not sf or not sf.Parent) then
                                table.remove(nestedScrolls, i)
                            elseif (sf ~= checkFrame and sf.ScrollingEnabled and isVisiblyHovered(sf, mx, my)) then
                                return
                            end
                        end

                        local sc = (currentScale and currentScale > 0) and currentScale or 1
                        local maxY = math.max(0, (checkFrame.AbsoluteCanvasSize.Y - checkFrame.AbsoluteWindowSize.Y) / sc)
                        if (maxY <= 2 or checkFrame.CanvasPosition.Y >= maxY - 8) then
                            new:setEasterEgg(true)
                        end
                    end
                end)
            end

            do
                local dCon
                local aCon
                local eCon
                local mainFrame = insts.mainFrame
                local targetPos

                titleBar.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        local rootPos = mainFrame.AbsolutePosition
                        local startPos = Vector2.new(io.Position.X, io.Position.Y)
                        targetPos = UDim2.fromOffset(rootPos.X, rootPos.Y)

                        if (aCon) then aCon:Disconnect() end
                        if (dCon) then dCon:Disconnect() end
                        if (eCon) then eCon:Disconnect() end

                        aCon = renderService.RenderStepped:Connect(function(dt)
                            mainFrame.Position = mainFrame.Position:lerp(targetPos, 1 - animSpeed ^ dt)
                        end)

                        dCon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                local curPos = Vector2.new(mio.Position.X, mio.Position.Y)
                                local dest = rootPos + (curPos - startPos)
                                local vpX, availH = getViewportInfo()
                                local sz = mainFrame.AbsoluteSize
                                local cx = math.clamp(dest.X, math.min(4, -sz.X + 80), math.max(4, vpX - 80))
                                local cy = math.clamp(dest.Y, 4, math.max(4, availH - 34))
                                targetPos = UDim2.fromOffset(cx, cy)
                            end
                        end)

                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dCon) then dCon:Disconnect(); dCon = nil end
                                if (aCon) then aCon:Disconnect(); aCon = nil end
                                if (eCon) then eCon:Disconnect(); eCon = nil end
                                if (targetPos) then
                                    tween(mainFrame, {Position = targetPos}, 0.16, 1)
                                end
                            end
                        end)
                    end
                end)
            end

            if (resize) then
                local dCon
                local aCon
                local eCon
                local mainFrame = insts.mainFrame
                local resizeHandle = insts.resizeHandle
                local targetSize

                resizeHandle.MouseEnter:Connect(function()
                    setGlyphColor(resizeHandle, theme.Primary, 0.16)
                end)
                resizeHandle.MouseLeave:Connect(function()
                    setGlyphColor(resizeHandle, theme.StrokeHover, 0.16)
                end)

                resizeHandle.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io) and not new.minimized) then
                        local sc = (mainFrame:FindFirstChild('#scale') and mainFrame['#scale'].Scale) or 1
                        if (sc <= 0) then sc = 1 end
                        local rootSize = Vector2.new(mainFrame.Size.X.Offset, mainFrame.Size.Y.Offset)
                        local startPos = Vector2.new(io.Position.X, io.Position.Y)
                        targetSize = UDim2.fromOffset(rootSize.X, rootSize.Y)

                        if (aCon) then aCon:Disconnect() end
                        if (dCon) then dCon:Disconnect() end
                        if (eCon) then eCon:Disconnect() end

                        aCon = renderService.RenderStepped:Connect(function(dt)
                            mainFrame.Size = mainFrame.Size:lerp(targetSize, 1 - animSpeed ^ dt)
                            new.size = mainFrame.Size
                        end)

                        dCon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                local curPos = Vector2.new(mio.Position.X, mio.Position.Y)
                                local dest = rootSize + (curPos - startPos) / sc
                                targetSize = UDim2.fromOffset(math.clamp(dest.X, 400, 900), math.clamp(dest.Y, 280, 720))
                            end
                        end)

                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dCon) then dCon:Disconnect(); dCon = nil end
                                if (aCon) then aCon:Disconnect(); aCon = nil end
                                if (eCon) then eCon:Disconnect(); eCon = nil end
                                if (targetSize) then
                                    tween(mainFrame, {Size = targetSize}, 0.16, 1)
                                    new.size = targetSize
                                end
                            end
                        end)
                    end
                end)
            else
                insts.resizeHandle.Visible = false
            end

            insts.mainFrame.Parent = uiScreen
            new.instances = insts
            return new
        end

        window.minimize = function(self)
            local newState = not self.minimized
            local mf = self.instances.mainFrame
            local bmin = mf['#title-bar']['#button-min']
            local bminIcon = bmin['#icon']

            if (newState) then
                if (self.settingsOpen) then
                    self:toggleSettings()
                end
                if (self.searchOpen) then
                    self:toggleSearch(false)
                end
                self:setEasterEgg(false)
                tween(mf, {Size = UDim2.fromOffset(self.size.X.Offset, 29)}, 0.28, 1)
                tween(bminIcon['#v'], {BackgroundTransparency = 0, BackgroundColor3 = theme.Primary}, 0.2, 1)
                tween(bminIcon['#h'], {BackgroundColor3 = theme.Primary}, 0.2, 1)
                tween(bmin, {BackgroundColor3 = self.minFocused and theme.Button4 or theme.Button3}, 0.16, 1)
                mf['#page-region'].Visible = false
                mf['#sidebar'].Visible = false
                mf['#resize-handle'].Visible = false
            else
                tween(mf, {Size = self.size}, 0.28, 1)
                tween(bminIcon['#v'], {BackgroundTransparency = 1}, 0.2, 1)
                tween(bminIcon['#h'], {BackgroundColor3 = self.minFocused and theme.TextPrimary or theme.TextDim}, 0.2, 1)
                tween(bmin, {BackgroundColor3 = self.minFocused and theme.Button2 or theme.Button1}, 0.16, 1)
                mf['#page-region'].Visible = true
                mf['#sidebar'].Visible = true
                mf['#resize-handle'].Visible = self.resizable
            end
            self.minimized = newState
            return self
        end

        elemClasses.window = window
    end

    do
        local function polarToCart(r, theta)
            return r * math.cos(theta), r * math.sin(theta)
        end

        local function cartToPolar(x, y)
            return math.sqrt((x ^ 2) + (y ^ 2)), math.atan2(y, x)
        end

        local pickerWindow = {}
        pickerWindow.__index = pickerWindow
        setmetatable(pickerWindow, elemClasses.baseElement)

        pickerWindow.class = 'pickerWindow'
        pickerWindow.minimized = false
        pickerWindow.minFocused = false
        pickerWindow.hue = 0
        pickerWindow.sat = 0
        pickerWindow.val = 1
        pickerWindow.red = 255
        pickerWindow.green = 255
        pickerWindow.blue = 255
        pickerWindow.color = Color3.fromHSV(0, 0, 1)
        pickerWindow.chromaEnabled = false
        pickerWindow.chromaFocused = false
        pickerWindow.pickerMoving = false

        pickerWindow.toggleChroma = function(self)
            local newState = not self.chromaEnabled
            local chromaButton = self.instances.chromaButton
            if (newState) then
                tween(chromaButton, {BackgroundColor3 = self.chromaFocused and theme.Button4 or theme.Button3}, 0.18, 1)
                tween(chromaButton['#stroke'], {Color = theme.Primary}, 0.18, 1)
                tween(chromaButton['#label'], {TextColor3 = theme.Primary}, 0.18, 1)
                tween(self.instances.speedSlider, {Position = UDim2.new(0, 6, 1, -24)}, 0.35, 1)
                self:fireEvent('chroma', true)
            else
                tween(chromaButton, {BackgroundColor3 = self.chromaFocused and theme.Button2 or theme.Button1}, 0.18, 1)
                tween(chromaButton['#stroke'], {Color = theme.Stroke}, 0.18, 1)
                tween(chromaButton['#label'], {TextColor3 = theme.TextDim}, 0.18, 1)
                tween(self.instances.speedSlider, {Position = UDim2.new(0, -44, 1, -24)}, 0.35, 1)
                self:fireEvent('chroma', false)
            end
            self.chromaEnabled = newState
            return newState
        end

        pickerWindow.displayRGB = function(self)
            local r, g, b = self.red, self.green, self.blue
            self.color = Color3.fromRGB(r, g, b)
            local hue, sat, val = self.color:ToHSV()
            self.hue = hue
            self.sat = sat
            self.val = val

            local radius = sat / 2
            local theta = (hue * (math.pi * 2)) - (math.pi * 2)
            local x, y = radius * math.cos(theta), radius * math.sin(theta)

            self.instances.valSlider['#slider-container'].BackgroundColor3 = Color3.fromHSV(hue, sat, 1)
            tween(self.instances.valCursor, {Position = UDim2.fromScale(val, 0)}, 0.2, 1)
            tween(self.instances.pickerCursor, {Position = UDim2.fromScale(x + 0.5, y + 0.5)}, 0.2, 1)
            self:fireEvent('newColor', self.color, {hue, sat, val})
        end

        pickerWindow.displayHSV = function(self, moveCursor)
            local hue, sat, val = self.hue, self.sat, self.val
            self.color = Color3.fromHSV(hue, sat, val)
            local r, g, b = self.color.R * 255, self.color.G * 255, self.color.B * 255
            self.red = r
            self.green = g
            self.blue = b

            local insts = self.instances
            insts.valSlider['#slider-container'].BackgroundColor3 = Color3.fromHSV(hue, sat, 1)
            tween(insts.redFill, {Size = UDim2.fromScale(r / 255, 1)}, 0.2, 1)
            tween(insts.greenFill, {Size = UDim2.fromScale(g / 255, 1)}, 0.2, 1)
            tween(insts.blueFill, {Size = UDim2.fromScale(b / 255, 1)}, 0.2, 1)

            insts.redSlider['#val'].Text = tostring(math.floor(r + 0.5))
            insts.greenSlider['#val'].Text = tostring(math.floor(g + 0.5))
            insts.blueSlider['#val'].Text = tostring(math.floor(b + 0.5))

            if (moveCursor) then
                local radius = sat / 2
                local theta = (hue * (math.pi * 2)) - (math.pi * 2)
                local x, y = radius * math.cos(theta), radius * math.sin(theta)
                tween(insts.valCursor, {Position = UDim2.fromScale(val, 0)}, 0.2, 1)
                tween(insts.pickerCursor, {Position = UDim2.fromScale(x + 0.5, y + 0.5)}, 0.2, 1)
            end

            self:fireEvent('newColor', self.color, {hue, sat, val})
        end

        local function makeChannelSlider(parent, name, labelText, fillColor, posY)
            local holder = create('Frame', {
                BackgroundTransparency = 1,
                Name = name,
                Position = UDim2.fromOffset(0, posY),
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 104
            }, parent)

            local container = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#slider-container',
                Position = UDim2.fromOffset(4, 2),
                Size = UDim2.new(1, -8, 0, 16),
                ZIndex = 105
            }, holder)
            makeCorner(container, cornerPx)
            makeStroke(container, theme.Stroke, 1)

            local fill = create('Frame', {
                Active = false,
                BackgroundColor3 = fillColor,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                Name = '#slider-fill',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 106
            }, container)
            makeCorner(fill, cornerPx)
            makeGradient(fill, Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 185), 90)

            local inputBox = create('TextBox', {
                Active = true,
                BackgroundColor3 = theme.Window1,
                BackgroundTransparency = 0.05,
                ClearTextOnFocus = true,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#input-box',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = '0-255',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Center,
                Visible = false,
                ZIndex = 108
            }, container)
            makeCorner(inputBox, cornerPx)
            makeStroke(inputBox, theme.Primary, 1)

            local lbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Size = UDim2.fromScale(1, 1),
                Text = labelText,
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 107
            }, holder)
            create('UIPadding', {PaddingLeft = UDim.new(0, 9)}, lbl)

            local valLbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#val',
                Size = UDim2.fromScale(1, 1),
                Text = '255',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 107
            }, holder)
            create('UIPadding', {PaddingRight = UDim.new(0, 9)}, valLbl)

            return holder
        end

        local instances = {}
        do
            local main = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Name = '#main_frame',
                Size = UDim2.fromOffset(296, 304),
                Visible = true,
                ZIndex = 100
            })
            create('UIScale', {Name = '#scale', Scale = 1}, main)
            makeCorner(main, cornerPx)

            local bg = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Name = '#background',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 99
            }, main)
            makeCorner(bg, cornerPx)
            makeStroke(main, theme.Stroke, 1)

            create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = 'rbxassetid://7331400934',
                ImageColor3 = Color3.fromRGB(0, 0, 5),
                ImageTransparency = 0.2,
                Name = '#shadow',
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.new(1, 46, 1, 46),
                SliceCenter = Rect.new(40, 40, 260, 260),
                SliceScale = 1,
                ZIndex = 98
            }, main)

            local trim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 112
            }, main)
            makeGradient(trim, theme.Primary, theme.Secondary, 0)

            local titleBar = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Window1,
                BorderColor3 = theme.Inset1,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#title-bar',
                Position = UDim2.fromOffset(0, 1),
                Selectable = true,
                Size = UDim2.new(1, 0, 0, 28),
                ZIndex = 101
            }, main)
            makeGradient(titleBar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 224), 90)
            makeTopSheen(titleBar, 102)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 104
            }, titleBar)

            create('Frame', {
                BackgroundColor3 = theme.Window1,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#fade',
                Size = UDim2.new(1, 4, 1, 4),
                Position = UDim2.fromOffset(-2, -2),
                Visible = false,
                ZIndex = 110
            }, titleBar)

            local buttonClose = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-close',
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 103
            }, titleBar)
            makeCorner(buttonClose, cornerPx)
            makeStroke(buttonClose, theme.Stroke, 1)
            makeCloseGlyph(buttonClose, 104)

            local buttonMin = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#button-min',
                Position = UDim2.new(1, -27, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                Text = '',
                ZIndex = 103
            }, titleBar)
            makeCorner(buttonMin, cornerPx)
            makeStroke(buttonMin, theme.Stroke, 1)
            makeMinGlyph(buttonMin, 104)

            local tAccent = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#icon',
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(2, 12),
                ZIndex = 103
            }, titleBar)
            makeGradient(tAccent, theme.Primary, theme.Secondary, 90)

            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#title',
                Position = UDim2.fromOffset(16, 0),
                RichText = true,
                Size = UDim2.new(1, -68, 1, 0),
                Text = 'color picker',
                TextColor3 = theme.TextPrimary,
                TextSize = 13,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103
            }, titleBar)

            local region = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#region',
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(1, 0, 1, -29),
                ZIndex = 102
            }, main)

            local pickerRegion = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderColor3 = theme.Inset3,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#region-picker',
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.new(1, -12, 0, 192),
                ZIndex = 102
            }, region)
            makeCorner(pickerRegion, cornerPx)
            makeStroke(pickerRegion, theme.Stroke, 1)

            local picker = create('ImageLabel', {
                Active = true,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://9801454501',
                Name = '#picker',
                Position = UDim2.new(0.5, 0, 0.44, 0),
                Size = UDim2.fromOffset(142, 142),
                ZIndex = 104
            }, pickerRegion)

            local cursorInner = create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Name = '#cursor-inner',
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(8, 8),
                ZIndex = 106
            }, picker)
            makeCorner(cursorInner, 99)
            makeStroke(cursorInner, Color3.fromRGB(255, 255, 255), 1)
            local cursorOuter = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#cursor-outer',
                Position = UDim2.fromOffset(-1, -1),
                Size = UDim2.fromOffset(10, 10),
                ZIndex = 106
            }, cursorInner)
            makeCorner(cursorOuter, 99)
            makeStroke(cursorOuter, Color3.fromRGB(0, 0, 5), 1)

            local valueSlider = create('Frame', {
                AnchorPoint = Vector2.new(0.5, 1),
                BackgroundTransparency = 1,
                Name = '#value-slider',
                Position = UDim2.new(0.5, 0, 1, -4),
                Size = UDim2.new(0.84, 0, 0, 18),
                ZIndex = 104
            }, pickerRegion)

            local valContainer = create('Frame', {
                Active = true,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#slider-container',
                Position = UDim2.fromOffset(0, 3),
                Size = UDim2.new(1, 0, 0, 12),
                ZIndex = 104
            }, valueSlider)
            makeCorner(valContainer, cornerPx)
            makeStroke(valContainer, theme.Stroke, 1)

            local valGrad = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#value-gradient',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 105
            }, valContainer)
            makeCorner(valGrad, cornerPx)
            create('UIGradient', {
                Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = 0
            }, valGrad)

            local valCursor = create('Frame', {
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#cursor-inner',
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 4, 1, 0),
                ZIndex = 107
            }, valContainer)
            makeStroke(valCursor, Color3.fromRGB(0, 0, 0), 1)

            local speedSlider = create('Frame', {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                Name = '#speed-slider',
                Position = UDim2.new(0, -44, 1, -24),
                Size = UDim2.fromOffset(14, 140),
                ZIndex = 104
            }, pickerRegion)
            local speedContainer = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#slider-container',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 104
            }, speedSlider)
            makeCorner(speedContainer, cornerPx)
            makeStroke(speedContainer, theme.Stroke, 1)
            local speedGrad = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#speed-gradient',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 105
            }, speedContainer)
            makeCorner(speedGrad, cornerPx)
            makeGradient(speedGrad, theme.Primary, theme.Inset1, 90)
            local speedCursor = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#cursor-inner',
                Position = UDim2.fromScale(0, 0.9),
                Size = UDim2.new(1, 0, 0, 3),
                ZIndex = 106
            }, speedContainer)
            makeStroke(speedCursor, Color3.fromRGB(0, 0, 0), 1)

            local chromaBtn = create('TextButton', {
                AnchorPoint = Vector2.new(1, 0),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#chroma',
                Position = UDim2.new(1, -6, 0, 6),
                Size = UDim2.fromOffset(48, 18),
                Text = '',
                ZIndex = 105
            }, pickerRegion)
            makeCorner(chromaBtn, cornerPx)
            makeStroke(chromaBtn, theme.Stroke, 1)
            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Size = UDim2.fromScale(1, 1),
                Text = 'rgb',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                ZIndex = 106
            }, chromaBtn)

            local inputRegion = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderColor3 = theme.Inset3,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                Name = '#region-input',
                Position = UDim2.fromOffset(6, 203),
                Size = UDim2.new(1, -12, 0, 66),
                ZIndex = 102
            }, region)
            makeCorner(inputRegion, cornerPx)
            makeStroke(inputRegion, theme.Stroke, 1)

            makeChannelSlider(inputRegion, '#red-slider', 'R', Color3.fromRGB(235, 55, 65), 3)
            makeChannelSlider(inputRegion, '#green-slider', 'G', Color3.fromRGB(55, 210, 105), 23)
            makeChannelSlider(inputRegion, '#blue-slider', 'B', Color3.fromRGB(65, 130, 245), 43)

            instances.main = main
        end
        pickerWindow.instances = instances

        pickerWindow.signals = {
            buttonClose = {
                MouseEnter = function(self)
                    tween(self, {BackgroundColor3 = theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Primary}, 0.16, 1)
                    setGlyphColor(self['#icon'], theme.Primary, 0.16)
                end,
                MouseLeave = function(self)
                    tween(self, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    setGlyphColor(self['#icon'], theme.TextDim, 0.16)
                end,
                MouseButton1Click = function(_, self)
                    self:destroy()
                end
            },
            buttonMin = {
                MouseEnter = function(self, w)
                    w.minFocused = true
                    tween(self, {BackgroundColor3 = w.minimized and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                end,
                MouseLeave = function(self, w)
                    w.minFocused = false
                    tween(self, {BackgroundColor3 = w.minimized and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                end,
                MouseButton1Click = function(_, self)
                    self:minimize()
                end
            },
            chromaButton = {
                MouseEnter = function(self, w)
                    w.chromaFocused = true
                    tween(self, {BackgroundColor3 = w.chromaEnabled and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.chromaEnabled and theme.Primary or theme.StrokeHover}, 0.16, 1)
                end,
                MouseLeave = function(self, w)
                    w.chromaFocused = false
                    tween(self, {BackgroundColor3 = w.chromaEnabled and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(self['#stroke'], {Color = w.chromaEnabled and theme.Primary or theme.Stroke}, 0.16, 1)
                end,
                MouseButton1Click = function(_, self)
                    self:toggleChroma()
                end
            }
        }

        pickerWindow.destroy = function(self)
            self:fireEvent('close')
            local idx = table.find(ui.pickerWindows, self)
            if (idx) then
                table.remove(ui.pickerWindows, idx)
            end
            local main = self.instances.main
            task.spawn(function()
                tween(main['#scale'], {Scale = 0.6}, 0.3, 1).Completed:Wait()
                if (main and main.Parent) then
                    main:Destroy()
                end
            end)
            return self
        end

        pickerWindow.setTitle = function(self, text)
            self.instances.title.Text = tostring(text)
            return self
        end

        pickerWindow.setPosition = function(self, newPosition)
            if (typeof(newPosition) == 'Vector2') then
                newPosition = UDim2.fromOffset(newPosition.X, newPosition.Y)
            elseif (typeof(newPosition) ~= 'UDim2') then
                return error('expected type UDim2 or Vector2', 2)
            end
            self.instances.main.Position = newPosition
            return self
        end

        pickerWindow.minimize = function(self)
            local newState = not self.minimized
            local mf = self.instances.main
            local bmin = mf['#title-bar']['#button-min']
            local bminIcon = bmin['#icon']
            if (newState) then
                tween(mf, {Size = UDim2.fromOffset(296, 29)}, 0.25, 1)
                tween(bminIcon['#v'], {BackgroundTransparency = 0, BackgroundColor3 = theme.Primary}, 0.18, 1)
                tween(bminIcon['#h'], {BackgroundColor3 = theme.Primary}, 0.18, 1)
                mf['#region'].Visible = false
            else
                tween(mf, {Size = UDim2.fromOffset(296, 304)}, 0.25, 1)
                tween(bminIcon['#v'], {BackgroundTransparency = 1}, 0.18, 1)
                tween(bminIcon['#h'], {BackgroundColor3 = theme.TextDim}, 0.18, 1)
                mf['#region'].Visible = true
            end
            self.minimized = newState
            return self
        end

        pickerWindow.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            table.insert(ui.pickerWindows, new)

            local insts = {}
            insts.main = self.instances.main:Clone()
            insts.main['#scale'].Scale = getHudScale()

            local titleBar = insts.main['#title-bar']
            insts.buttonClose = titleBar['#button-close']
            insts.buttonMin = titleBar['#button-min']
            insts.titleBar = titleBar
            insts.title = titleBar['#title']

            insts.pickerRegion = insts.main['#region']['#region-picker']
            insts.inputRegion = insts.main['#region']['#region-input']
            insts.colorPicker = insts.pickerRegion['#picker']
            insts.pickerCursor = insts.colorPicker['#cursor-inner']
            insts.valSlider = insts.pickerRegion['#value-slider']
            insts.valCursor = insts.valSlider['#slider-container']['#cursor-inner']
            insts.speedSlider = insts.pickerRegion['#speed-slider']
            insts.speedCursor = insts.speedSlider['#slider-container']['#cursor-inner']
            insts.redSlider = insts.inputRegion['#red-slider']
            insts.greenSlider = insts.inputRegion['#green-slider']
            insts.blueSlider = insts.inputRegion['#blue-slider']
            insts.redFill = insts.redSlider['#slider-container']['#slider-fill']
            insts.greenFill = insts.greenSlider['#slider-container']['#slider-fill']
            insts.blueFill = insts.blueSlider['#slider-container']['#slider-fill']
            insts.chromaButton = insts.pickerRegion['#chroma']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            do
                local dCon, aCon, eCon
                local mainFrame = insts.main
                local targetPos
                titleBar.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        local rootPos = mainFrame.AbsolutePosition
                        local startPos = Vector2.new(io.Position.X, io.Position.Y)
                        targetPos = UDim2.fromOffset(rootPos.X, rootPos.Y)
                        if (aCon) then aCon:Disconnect() end
                        if (dCon) then dCon:Disconnect() end
                        if (eCon) then eCon:Disconnect() end
                        aCon = renderService.RenderStepped:Connect(function(dt)
                            mainFrame.Position = mainFrame.Position:lerp(targetPos, 1 - animSpeed ^ dt)
                        end)
                        dCon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                local dest = rootPos + (Vector2.new(mio.Position.X, mio.Position.Y) - startPos)
                                targetPos = UDim2.fromOffset(dest.X, dest.Y)
                            end
                        end)
                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dCon) then dCon:Disconnect(); dCon = nil end
                                if (aCon) then aCon:Disconnect(); aCon = nil end
                                if (eCon) then eCon:Disconnect(); eCon = nil end
                                if (targetPos) then
                                    tween(mainFrame, {Position = targetPos}, 0.16, 1)
                                end
                            end
                        end)
                    end
                end)
            end

            local function bindRGBChannel(sliderInst, propName)
                local container = sliderInst['#slider-container']
                local fill = container['#slider-fill']
                local valLbl = sliderInst['#val']
                local inputBox = container['#input-box']
                local dcon, acon, econ
                local targetSize

                inputBox.FocusLost:Connect(function()
                    local tx = inputBox.Text
                    local n = tonumber(tx)
                    inputBox.Visible = false
                    if (n) then
                        local clamped = math.floor(math.clamp(n, 0, 255) + 0.5)
                        tween(fill, {Size = UDim2.fromScale(clamped / 255, 1)}, 0.2, 1)
                        valLbl.Text = tostring(clamped)
                        new[propName] = clamped
                        new:displayRGB()
                    end
                end)

                local function applyX(posX)
                    local cPos = container.AbsolutePosition.X
                    local cWidth = math.max(1, container.AbsoluteSize.X)
                    local ratio = math.clamp((posX - cPos) / cWidth, 0, 1)
                    local newVal = math.floor(ratio * 255 + 0.5)
                    targetSize = UDim2.fromScale(newVal / 255, 1)
                    valLbl.Text = tostring(newVal)
                    new[propName] = newVal
                    new:displayRGB()
                end

                container.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        applyX(io.Position.X)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            fill.Size = fill.Size:lerp(targetSize, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                applyX(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dcon) then dcon:Disconnect(); dcon = nil end
                                if (acon) then acon:Disconnect(); acon = nil end
                                if (econ) then econ:Disconnect(); econ = nil end
                                if (targetSize) then
                                    tween(fill, {Size = targetSize}, 0.16, 1)
                                end
                            end
                        end)
                    elseif (io.UserInputType == Enum.UserInputType.MouseButton2) then
                        inputBox.Text = tostring(math.floor(new[propName] + 0.5))
                        inputBox.Visible = true
                        inputBox:CaptureFocus()
                    end
                end)
            end

            bindRGBChannel(insts.redSlider, 'red')
            bindRGBChannel(insts.greenSlider, 'green')
            bindRGBChannel(insts.blueSlider, 'blue')

            do
                local container = insts.valSlider['#slider-container']
                local cursor = insts.valCursor
                local dcon, acon, econ
                local targetPos

                local function applyVal(x)
                    local cPos = container.AbsolutePosition.X
                    local cWidth = math.max(1, container.AbsoluteSize.X)
                    local raw = math.clamp((x - cPos) / cWidth, 0, 1)
                    targetPos = UDim2.fromScale(raw, 0)
                    new.val = raw
                    new:displayHSV()
                end

                container.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        applyVal(io.Position.X)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                applyVal(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dcon) then dcon:Disconnect(); dcon = nil end
                                if (acon) then acon:Disconnect(); acon = nil end
                                if (econ) then econ:Disconnect(); econ = nil end
                                if (targetPos) then
                                    tween(cursor, {Position = targetPos}, 0.16, 1)
                                end
                            end
                        end)
                    end
                end)
            end

            do
                local container = insts.speedSlider['#slider-container']
                local cursor = insts.speedCursor
                local dcon, acon, econ
                local targetPos

                local function applySpd(y)
                    local cPos = container.AbsolutePosition.Y
                    local cHeight = math.max(1, container.AbsoluteSize.Y)
                    local raw = math.clamp((y - cPos) / cHeight, 0, 1)
                    targetPos = UDim2.fromScale(0, raw)
                    if (new.linkedPicker) then
                        new.linkedPicker.chromaSpeed = 1 - raw
                    end
                end

                container.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        applySpd(io.Position.Y)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                applySpd(mio.Position.Y)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                if (dcon) then dcon:Disconnect(); dcon = nil end
                                if (acon) then acon:Disconnect(); acon = nil end
                                if (econ) then econ:Disconnect(); econ = nil end
                                if (targetPos) then
                                    tween(cursor, {Position = targetPos}, 0.16, 1)
                                end
                            end
                        end)
                    end
                end)
            end

            do
                local picker = insts.colorPicker
                local cursor = insts.pickerCursor
                local center = Vector2.new(0.5, 0.5)
                local dcon, acon, econ
                local targetPos

                local function applyWheel(pos)
                    local pPos = picker.AbsolutePosition
                    local pW = math.max(1, picker.AbsoluteSize.X)
                    local fixed = Vector2.new(pos.X, pos.Y) - pPos
                    local x, y = fixed.X / pW, fixed.Y / pW
                    local radius, theta = cartToPolar(x - 0.5, y - 0.5)
                    local centerMag = (Vector2.new(x, y) - center).Magnitude
                    if (centerMag > 0.5) then
                        x, y = polarToCart(radius - (centerMag - 0.5), theta)
                        x += 0.5
                        y += 0.5
                        centerMag = (Vector2.new(x, y) - center).Magnitude
                    end
                    targetPos = UDim2.fromScale(x, y)
                    new.hue = ((theta / math.pi + 2) / 2) % 1
                    new.sat = math.clamp(centerMag * 2, 0, 1)
                    new:displayHSV()
                end

                picker.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        new.pickerMoving = true
                        applyWheel(io.Position)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                applyWheel(mio.Position)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                new.pickerMoving = false
                                if (dcon) then dcon:Disconnect(); dcon = nil end
                                if (acon) then acon:Disconnect(); acon = nil end
                                if (econ) then econ:Disconnect(); econ = nil end
                                if (targetPos) then
                                    tween(cursor, {Position = targetPos}, 0.16, 1)
                                end
                            end
                        end)
                    end
                end)
            end

            insts.main.Parent = uiScreen
            new.instances = insts
            return new
        end

        elemClasses.pickerWindow = pickerWindow
    end

    do
        local menu = {}
        menu.__index = menu
        setmetatable(menu, elemClasses.baseElement)
        menu.class = 'menu'
        menu.selectorFocused = false
        menu.selected = false

        local instances = {}
        do
            local menuFrame = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#menuFrame',
                Position = UDim2.fromScale(0, 0),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.5,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollingEnabled = true,
                Size = UDim2.fromScale(1 / currentScale, 1 / currentScale),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 30
            })
            create('UIScale', {
                Name = '#content-scale',
                Scale = currentScale
            }, menuFrame)
            instances.menuFrame = menuFrame

            local leftRegion = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#left-region',
                Size = UDim2.fromScale(0.5, 0),
                ZIndex = 31
            }, menuFrame)
            create('UIListLayout', {
                Name = '#layout',
                Padding = UDim.new(0, 7),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, leftRegion)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 3),
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 8)
            }, leftRegion)

            local rightRegion = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#right-region',
                Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.fromScale(0.5, 0),
                ZIndex = 31
            }, menuFrame)
            create('UIListLayout', {
                Name = '#layout',
                Padding = UDim.new(0, 7),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, rightRegion)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 8)
            }, rightRegion)

            local pageSelector = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#page-selector',
                Size = UDim2.new(1, -14, 0, 30),
                Text = '',
                TextColor3 = theme.TextDim,
                TextSize = 12,
                ZIndex = 52
            })
            makeCorner(pageSelector, cornerPx)
            local stroke = makeStroke(pageSelector, theme.Stroke, 1)
            stroke.Transparency = 1

            create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Name = '#icon-wrap',
                Position = UDim2.new(0, 9, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                ZIndex = 54
            }, pageSelector)

            create('TextLabel', {
                Active = false,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(29, 0),
                Size = UDim2.new(1, -42, 1, 0),
                Text = '',
                TextColor3 = theme.TextDim,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 54
            }, pageSelector)

            instances.pageSelector = pageSelector
        end
        menu.instances = instances

        menu.select = function(self)
            if (self.window and self.window.setEasterEgg) then
                self.window:setEasterEgg(false)
            end
            if (not self._lazyBuilt) then
                local function buildLazyControls()
                    if (self._lazyBuilt) then return end
                    self._lazyBuilt = true
                    for _, sec in ipairs(self.sections or {}) do
                        for _, ctrl in ipairs(sec.controls or {}) do
                            if (typeof(ctrl._buildFontList) == 'function') then
                                ctrl._buildFontList()
                            end
                        end
                    end
                end
                if (self._isDefaultSettings and #(self.window and self.window.menus or {}) <= 1) then
                    task.delay(0.25, function()
                        if (self.selected and not ui._terminated) then
                            buildLazyControls()
                        end
                    end)
                else
                    buildLazyControls()
                end
            end
            local win = self.window
            local prev = nil
            for _, m in ipairs(win.menus) do
                if (m.selected and m ~= self) then
                    prev = m
                    break
                end
            end
            win._tabHideId = (win._tabHideId or 0) + 1
            local hideId = win._tabHideId

            self.instances.menuFrame.Visible = true
            if (prev and prev.instances and prev.instances.menuFrame) then
                prev.instances.menuFrame.Visible = true
            end
            for _, m in ipairs(win.menus) do
                local mf = m.instances.menuFrame
                local targetPos = UDim2.fromScale(0, m.id - self.id)
                if (m == self or m == prev) then
                    tween(mf, {Position = targetPos}, 0.35, 1)
                else
                    mf.Position = targetPos
                    mf.Visible = false
                end
                if (m ~= self and m.selected) then
                    m:deselect()
                end
            end
            task.delay(0.37, function()
                if (win._tabHideId ~= hideId) then return end
                for _, m in ipairs(win.menus) do
                    if (m ~= self and m.instances and m.instances.menuFrame) then
                        m.instances.menuFrame.Visible = false
                    end
                end
            end)

            self.selected = true
            local ps = self.instances.pageSelector
            local lbl = ps['#label']
            tween(ps, {BackgroundTransparency = 1}, 0.16, 1)
            tween(ps['#stroke'], {Transparency = 1}, 0.16, 1)
            tween(lbl, {TextColor3 = theme.TextPrimary, Position = UDim2.fromOffset(32, 0)}, 0.22, 1)
            setTabGlyphColor(ps['#icon-wrap'], theme.Primary, 0.22)

            local pill = win.instances and win.instances.activePill
            if (pill and pill.Parent) then
                win._pillAnimId = (win._pillAnimId or 0) + 1
                local pAnimId = win._pillAnimId
                local targetY = 7 + (self.id - 1) * 35
                local ind = pill['#indicator']
                local dot = pill['#active-dot']
                if (not pill.Visible) then
                    pill.Position = UDim2.new(0, 7, 0, targetY)
                    pill.Visible = true
                    ind.Size = UDim2.new(0, 3, 0, 18)
                else
                    tween(pill, {Position = UDim2.new(0, 7, 0, targetY)}, 0.32, 1)
                    tween(ind, {Size = UDim2.new(0, 3, 0, 26)}, 0.10, 1)
                    dot.Size = UDim2.fromOffset(2, 2)
                    tween(dot, {Size = UDim2.fromOffset(4, 4)}, 0.28, 1)
                    task.delay(0.11, function()
                        if (win._pillAnimId == pAnimId and ind and ind.Parent) then
                            tween(ind, {Size = UDim2.new(0, 3, 0, 18)}, 0.24, 1)
                        end
                    end)
                end
            end
            return self
        end

        menu.deselect = function(self)
            self.selected = false
            local ps = self.instances.pageSelector
            local lbl = ps['#label']
            tween(ps, {
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = self.selectorFocused and 0.42 or 1
            }, 0.18, 1)
            tween(ps['#stroke'], {Color = theme.Stroke, Transparency = self.selectorFocused and 0.35 or 1}, 0.18, 1)
            tween(lbl, {
                TextColor3 = self.selectorFocused and theme.TextPrimary or theme.TextDim,
                Position = UDim2.fromOffset(self.selectorFocused and 31 or 29, 0)
            }, 0.18, 1)
            setTabGlyphColor(ps['#icon-wrap'], self.selectorFocused and theme.TextPrimary or theme.TextDim, 0.18)
        end

        menu.signals = {
            pageSelector = {
                MouseEnter = function(_, self)
                    self.selectorFocused = true
                    local ps = self.instances.pageSelector
                    local lbl = ps['#label']
                    if (self.selected) then
                        local pill = self.window and self.window.instances and self.window.instances.activePill
                        if (pill and pill.Parent) then
                            tween(pill, {BackgroundColor3 = theme.Button4, BackgroundTransparency = 0.04}, 0.16, 1)
                        end
                    else
                        tween(ps, {BackgroundColor3 = theme.Button2, BackgroundTransparency = 0.42}, 0.16, 1)
                        tween(ps['#stroke'], {Color = theme.Stroke, Transparency = 0.35}, 0.16, 1)
                        tween(lbl, {TextColor3 = theme.TextPrimary, Position = UDim2.fromOffset(31, 0)}, 0.16, 1)
                        setTabGlyphColor(ps['#icon-wrap'], theme.TextPrimary, 0.16)
                    end
                end,
                MouseLeave = function(_, self)
                    self.selectorFocused = false
                    local ps = self.instances.pageSelector
                    local lbl = ps['#label']
                    if (self.selected) then
                        local pill = self.window and self.window.instances and self.window.instances.activePill
                        if (pill and pill.Parent) then
                            tween(pill, {BackgroundColor3 = theme.Button3, BackgroundTransparency = 0.12}, 0.16, 1)
                        end
                    else
                        tween(ps, {BackgroundTransparency = 1}, 0.16, 1)
                        tween(ps['#stroke'], {Transparency = 1}, 0.16, 1)
                        tween(lbl, {TextColor3 = theme.TextDim, Position = UDim2.fromOffset(29, 0)}, 0.16, 1)
                        setTabGlyphColor(ps['#icon-wrap'], theme.TextDim, 0.16)
                    end
                end
            }
        }

        menu.new = function(self)
            local new = setmetatable({}, self)
            new.sections = {}
            new.binds = {}

            local insts = {}
            insts.menuFrame = self.instances.menuFrame:Clone()
            insts.menuFrame['#content-scale'].Scale = currentScale
            insts.menuFrame.Size = UDim2.fromScale(1 / currentScale, 1 / currentScale)
            insts.leftRegion = insts.menuFrame['#left-region']
            insts.rightRegion = insts.menuFrame['#right-region']
            insts.pageSelector = self.instances.pageSelector:Clone()

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            new.instances = insts
            return new
        end

        elemClasses.window.addMenu = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected table for settings', 2)
            end

            local s_text = settings.text or 'menu'
            local m = menu:new()
            m.window = self
            m.name = s_text
            m._isDefaultSettings = settings._isDefaultSettings and true or false

            if (self._defaultSettingsMenu and not settings._isDefaultSettings) then
                local defIdx = table.find(self.menus, self._defaultSettingsMenu)
                if (defIdx) then
                    table.insert(self.menus, defIdx, m)
                else
                    table.insert(self.menus, m)
                end
            else
                table.insert(self.menus, m)
            end

            local menuTab = m.instances.pageSelector
            local menuFrame = m.instances.menuFrame

            menuTab.MouseButton1Click:Connect(function()
                m:select()
            end)
            menuTab['#label'].Text = s_text
            makeTabGlyph(menuTab['#icon-wrap'], settings.icon or s_text, 54)
            menuFrame.Visible = false

            menuTab.Parent = self.instances.tabButtons
            menuFrame.Parent = self.instances.pageRegion

            menuFrame:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
                if (self.easterEggVisible) then
                    local sc = (currentScale and currentScale > 0) and currentScale or 1
                    local maxY = math.max(0, (menuFrame.AbsoluteCanvasSize.Y - menuFrame.AbsoluteWindowSize.Y) / sc)
                    if (menuFrame.CanvasPosition.Y < maxY - 8) then
                        self:setEasterEgg(false)
                    end
                end
            end)

            local activeMenu
            for idx, item in ipairs(self.menus) do
                item.id = idx
                item.instances.pageSelector.LayoutOrder = idx
                if (item.selected) then
                    activeMenu = item
                end
            end

            if (m.id == 1 and (not activeMenu or activeMenu == self._defaultSettingsMenu)) then
                m:select()
            elseif (activeMenu) then
                for _, item in ipairs(self.menus) do
                    item.instances.menuFrame.Position = UDim2.fromScale(0, item.id - activeMenu.id)
                end
                local pill = self.instances and self.instances.activePill
                if (pill and pill.Parent) then
                    pill.Position = UDim2.new(0, 7, 0, 7 + (activeMenu.id - 1) * 35)
                end
            end
            return m
        end

        elemClasses.menu = menu
    end

    do
        local section = {}
        section.__index = section
        setmetatable(section, elemClasses.baseElement)
        section.class = 'section'
        section.minimized = false
        section.minFocused = false

        local instances = {}
        do
            local sectionFrame = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#section',
                Size = UDim2.new(1, -2, 0, 22),
                ZIndex = 32
            })
            makeCorner(sectionFrame, cornerPx)
            makeStroke(sectionFrame, theme.Stroke, 1)
            instances.sectionFrame = sectionFrame

            local titleBar = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                Name = '#title-bar',
                Position = UDim2.fromOffset(0, 1),
                Size = UDim2.new(1, 0, 0, 21),
                ZIndex = 33
            }, sectionFrame)
            makeGradient(titleBar, Color3.fromRGB(255, 255, 255), Color3.fromRGB(228, 228, 228), 90)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Name = '#sep',
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 34
            }, titleBar)

            local trim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 35
            }, titleBar)
            makeGradient(trim, theme.Primary, theme.Secondary, 0)

            local minimize = create('TextButton', {
                Active = true,
                AnchorPoint = Vector2.new(1, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#min',
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Text = '',
                ZIndex = 35
            }, titleBar)
            makeCorner(minimize, cornerPx)
            makeStroke(minimize, theme.Stroke, 1)
            local chev = makeChevronGlyph(minimize, 36, 4)
            chev.Rotation = 180
            instances.minimizeButton = minimize

            local title = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#title',
                RichText = true,
                Size = UDim2.new(1, -24, 1, 0),
                Text = 'section',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 35
            }, titleBar)
            create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 7)}, title)
            instances.title = title

            local menu = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Name = '#menu',
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.fromScale(1, 0),
                ZIndex = 33
            }, sectionFrame)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Name = '#layout',
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, menu)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 3)
            }, menu)
        end
        section.instances = instances

        section.minimize = function(self)
            local newState = not self.minimized
            self.minimized = newState
            self._animId = (self._animId or 0) + 1
            local animId = self._animId

            local mf = self.instances.sectionFrame
            local tb = mf['#title-bar']
            local min = tb['#min']
            local menu = mf['#menu']
            local trim = tb['#trim']
            local sep = tb['#sep']
            local titleLbl = tb['#title']
            local sc = (currentScale and currentScale > 0) and currentScale or 1

            if (newState) then
                local curH = math.max(22, math.floor(mf.AbsoluteSize.Y / sc + 0.5))
                mf.AutomaticSize = Enum.AutomaticSize.None
                mf.Size = UDim2.new(1, -2, 0, curH)

                tween(mf, {Size = UDim2.new(1, -2, 0, 22)}, 0.30, 1)
                tween(menu, {Position = UDim2.fromOffset(0, 12)}, 0.24, 1)
                tween(min['#icon'], {Rotation = 0}, 0.26, 1)
                tween(min, {BackgroundColor3 = self.minFocused and theme.Button4 or theme.Button3}, 0.18, 1)
                tween(trim, {BackgroundTransparency = 0.55}, 0.22, 1)
                tween(sep, {BackgroundTransparency = 1}, 0.18, 1)
                tween(titleLbl, {TextColor3 = theme.TextDim}, 0.20, 1)

                task.delay(0.29, function()
                    if (self._animId == animId and self.minimized and menu and menu.Parent) then
                        menu.Visible = false
                    end
                end)
            else
                local curH = math.max(22, math.floor(mf.AbsoluteSize.Y / sc + 0.5))
                menu.Visible = true
                menu.Position = UDim2.fromOffset(0, 14)

                local layout = menu:FindFirstChild('#layout')
                local contentH = layout and math.floor(layout.AbsoluteContentSize.Y / sc + 0.5) or 0
                local targetH = math.max(34, 22 + contentH + 12)

                mf.AutomaticSize = Enum.AutomaticSize.None
                mf.Size = UDim2.new(1, -2, 0, curH)

                tween(mf, {Size = UDim2.new(1, -2, 0, targetH)}, 0.32, 1)
                tween(menu, {Position = UDim2.fromOffset(0, 22)}, 0.28, 1)
                tween(min['#icon'], {Rotation = 180}, 0.26, 1)
                tween(min, {BackgroundColor3 = self.minFocused and theme.Button2 or theme.Button1}, 0.18, 1)
                tween(trim, {BackgroundTransparency = 0}, 0.22, 1)
                tween(sep, {BackgroundTransparency = 0}, 0.22, 1)
                tween(titleLbl, {TextColor3 = theme.TextPrimary}, 0.20, 1)

                task.delay(0.33, function()
                    if (self._animId == animId and not self.minimized and mf and mf.Parent) then
                        mf.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end)
            end
            return self
        end

        section.signals = {
            minimizeButton = {
                MouseButton1Click = function(_, self)
                    self:minimize()
                end,
                MouseEnter = function(inst, self)
                    self.minFocused = true
                    tween(inst, {BackgroundColor3 = self.minimized and theme.Button4 or theme.Button2}, 0.16, 1)
                    tween(inst['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                    setGlyphColor(inst['#icon'], theme.TextPrimary, 0.16)
                end,
                MouseLeave = function(inst, self)
                    self.minFocused = false
                    tween(inst, {BackgroundColor3 = self.minimized and theme.Button3 or theme.Button1}, 0.16, 1)
                    tween(inst['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    setGlyphColor(inst['#icon'], theme.TextDim, 0.16)
                end
            }
        }

        section.new = function(self)
            local new = setmetatable({}, self)
            new.controls = {}
            new.binds = {}
            new.minimized = false
            new._animId = 0

            local insts = {}
            insts.sectionFrame = self.instances.sectionFrame:Clone()
            insts.titleBar = insts.sectionFrame['#title-bar']
            insts.title = insts.titleBar['#title']
            insts.minimizeButton = insts.titleBar['#min']
            insts.controlMenu = insts.sectionFrame['#menu']

            insts.titleBar.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.titleBar.MouseLeave:Connect(function()
                new:hideTooltip()
            end)

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            new.instances = insts
            return new
        end

        elemClasses.menu.addSection = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_text = settings.text or 'section'
            local s_side = settings.side or 'auto'
            local s_min = settings.showMinButton == nil and true or settings.showMinButton

            local sec = section:new()
            sec.menu = self
            sec.name = s_text
            table.insert(self.sections, sec)
            sec.id = #self.sections
            sec.instances.title.Text = s_text

            local sf = sec.instances.sectionFrame
            if (s_side == 'auto') then
                sf.Parent = (sec.id % 2 == 0) and self.instances.rightRegion or self.instances.leftRegion
            else
                sf.Parent = self.instances[s_side == 'left' and 'leftRegion' or 'rightRegion']
            end

            if (not s_min) then
                sec.instances.minimizeButton.Visible = false
            end
            if (settings.tooltip) then
                sec:setTooltip(settings.tooltip)
            end
            return sec
        end

        elemClasses.section = section
    end

    do
        local toggle = {}
        toggle.__index = toggle
        setmetatable(toggle, elemClasses.baseElement)
        toggle.class = 'toggle'

        local offTextColor = blendColor(theme.TextDim, theme.TextPrimary, 0.45)

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local backToggle = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#back-toggle',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                ZIndex = 34
            }, controlFrame)
            makeCorner(backToggle, cornerPx)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(1, -24, 1, 0),
                Text = 'toggle',
                TextColor3 = offTextColor,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 35
            }, backToggle)
            create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6)}, label)

            local addons = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(1, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Name = '#addons',
                Position = UDim2.new(1, -24, 0.5, 0),
                Size = UDim2.fromOffset(0, 16),
                ZIndex = 36
            }, backToggle)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center
            }, addons)

            local box = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#toggle',
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                ZIndex = 35
            }, backToggle)
            makeCorner(box, cornerPx)
            makeStroke(box, theme.Stroke, 1)

            local fill = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#fill',
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                ZIndex = 36
            }, box)
            makeCorner(fill, rounding and 1 or 0)
            makeGradient(fill, theme.Primary, theme.Secondary, 135)
            makeTopSheen(fill, 37)
        end
        toggle.instances = instances

        toggle.toggled = false
        toggle.focused = false

        local function applyToggleVisuals(self)
            local box = self.instances.toggle
            local fill = box['#fill']
            local lbl = self.instances.label

            if (self.toggled) then
                tween(fill, {Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 0}, 0.2, 1)
                tween(box, {BackgroundColor3 = self.focused and theme.Button3 or theme.Button1}, 0.16, 1)
                tween(box['#stroke'], {Color = self.focused and theme.Primary or theme.StrokeHover}, 0.16, 1)
                tween(lbl, {TextColor3 = theme.TextPrimary}, 0.16, 1)
            else
                tween(fill, {Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1}, 0.18, 1)
                tween(box, {BackgroundColor3 = self.focused and theme.Button1 or theme.Inset1}, 0.16, 1)
                tween(box['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                tween(lbl, {TextColor3 = self.focused and theme.TextPrimary or offTextColor}, 0.16, 1)
            end
        end

        toggle.toggle = function(self)
            local newState = not self.toggled
            self.toggled = newState
            applyToggleVisuals(self)
            self:fireEvent(newState and 'onEnable' or 'onDisable')
            self:fireEvent('onToggle', newState)
            if (ui.refreshKeybindList) then ui.refreshKeybindList() end
            return self
        end
        toggle.__hotkeyFunc = toggle.toggle

        toggle.enable = function(self, silent)
            self.toggled = true
            applyToggleVisuals(self)
            if (not silent) then
                self:fireEvent('onEnable')
                self:fireEvent('onToggle', true)
            end
            if (ui.refreshKeybindList) then ui.refreshKeybindList() end
            return self
        end

        toggle.disable = function(self, silent)
            self.toggled = false
            applyToggleVisuals(self)
            if (not silent) then
                self:fireEvent('onDisable')
                self:fireEvent('onToggle', false)
            end
            if (ui.refreshKeybindList) then ui.refreshKeybindList() end
            return self
        end

        toggle.reset = function(self)
            self:toggle()
            self:toggle()
        end

        toggle.signals = {
            backToggle = {
                MouseEnter = function(inst, self)
                    self.focused = true
                    self:showTooltip()
                    tween(inst, {BackgroundTransparency = 0.78}, 0.14, 1)
                    applyToggleVisuals(self)
                end,
                MouseLeave = function(inst, self)
                    self.focused = false
                    self:hideTooltip()
                    tween(inst, {BackgroundTransparency = 1}, 0.14, 1)
                    applyToggleVisuals(self)
                end,
                MouseButton1Click = function(_, self)
                    self:toggle()
                end
            }
        }

        toggle.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.backToggle = insts.controlFrame['#back-toggle']
            insts.label = insts.backToggle['#label']
            insts.addons = insts.backToggle['#addons']
            insts.toggle = insts.backToggle['#toggle']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            new.instances = insts
            return new
        end

        toggle.getState = function(self) return self.toggled end
        toggle.isEnabled = toggle.getState
        toggle.getValue = toggle.getState

        toggle.addColorPicker = function(self, settings, callback)
            settings = settings or {}
            local s_title = settings.text or self.name
            local s_color = settings.color or Color3.fromRGB(255, 255, 255)

            local p = elemClasses.picker:new()
            p.section = self.section
            p.name = s_title
            if (self.section) then
                table.insert(self.section.controls, p)
            end

            local swatchBtn = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#inline-picker',
                Size = UDim2.fromOffset(22, 13),
                Text = '',
                ZIndex = 37
            }, self.instances.addons)
            makeCorner(swatchBtn, cornerPx)
            makeStroke(swatchBtn, theme.Stroke, 1)

            local display = create('Frame', {
                Active = false,
                BackgroundColor3 = s_color,
                BorderSizePixel = 0,
                Name = '#display',
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 38
            }, swatchBtn)
            makeCorner(display, rounding and 1 or 0)
            makeGradient(display, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190), 90)

            p.instances.controlFrame:Destroy()
            p.instances.controlFrame = swatchBtn
            p.instances.picker = swatchBtn
            p.instances.display = display
            p:setColor(s_color)

            swatchBtn.MouseEnter:Connect(function()
                p.focused = true
                tween(swatchBtn['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
                p:showTooltip()
            end)
            swatchBtn.MouseLeave:Connect(function()
                p.focused = false
                tween(swatchBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                p:hideTooltip()
            end)
            swatchBtn.MouseButton1Click:Connect(function()
                p:click()
            end)

            if (typeof(callback) == 'function') then
                p:bindToEvent('onNewColor', callback)
            end
            if (settings.tooltip) then
                p:setTooltip(settings.tooltip)
            end
            return p
        end

        toggle.addHotkey = function(self, settings)
            settings = settings or {}
            local s_bind = settings.bind or settings.key or nil

            local hk = elemClasses.hotkey:new()
            hk.section = self.section
            hk.name = settings.text or self.name
            if (self.section) then
                table.insert(self.section.controls, hk)
            end

            local badgeBtn = create('TextButton', {
                AutoButtonColor = false,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#inline-hotkey',
                Size = UDim2.fromOffset(0, 15),
                Text = '',
                ZIndex = 37
            }, self.instances.addons)
            makeCorner(badgeBtn, cornerPx)
            makeStroke(badgeBtn, theme.Stroke, 1)

            local hkLbl = create('TextLabel', {
                Active = false,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#hotkey',
                Size = UDim2.fromOffset(0, 15),
                Text = '[None]',
                TextColor3 = theme.TextDim,
                TextSize = 10,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 38
            }, badgeBtn)
            create('UIPadding', {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}, hkLbl)

            hk.instances.controlFrame:Destroy()
            hk.instances.controlFrame = badgeBtn
            hk.instances.badge = badgeBtn
            hk.instances.hotkey = hkLbl
            hk:linkToControl(self)

            if (s_bind) then
                hk:setHotkey(s_bind)
            end

            badgeBtn.MouseEnter:Connect(function()
                hk.focused = true
                if (not hk.inputCon) then
                    tween(hkLbl, {TextColor3 = theme.TextPrimary}, 0.14, 1)
                    tween(badgeBtn['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
                end
                hk:showTooltip()
            end)
            badgeBtn.MouseLeave:Connect(function()
                hk.focused = false
                if (not hk.inputCon) then
                    tween(hkLbl, {TextColor3 = theme.TextDim}, 0.14, 1)
                    tween(badgeBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                end
                hk:hideTooltip()
            end)
            badgeBtn.MouseButton1Click:Connect(function()
                hk:click()
            end)

            if (settings.tooltip) then
                hk:setTooltip(settings.tooltip)
            end
            return hk
        end

        elemClasses.section.addToggle = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'toggle'
            local s_state = settings.state or false

            local t = toggle:new()
            t.section = self
            t.name = s_title
            table.insert(self.controls, t)

            t.instances.label.Text = s_title
            if (s_state) then
                t:enable(true)
            end
            t.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                t:bindToEvent('onToggle', callback)
            end
            if (settings.tooltip) then
                t:setTooltip(settings.tooltip)
            end
            return t
        end

        elemClasses.toggle = toggle
    end

    do
        do
            local buttonSmall = {}
            buttonSmall.__index = buttonSmall
            setmetatable(buttonSmall, elemClasses.baseElement)
            buttonSmall.class = 'buttonSmall'

            local instances = {}
            do
                local controlFrame = create('Frame', {
                    BackgroundTransparency = 1,
                    Name = '#control',
                    Size = UDim2.new(1, 0, 0, 22),
                    ZIndex = 34
                })
                instances.controlFrame = controlFrame

                local clickSensor = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#click-sensor',
                    Size = UDim2.fromScale(1, 1),
                    Text = '',
                    ZIndex = 34
                }, controlFrame)
                makeCorner(clickSensor, cornerPx)

                local label = create('TextLabel', {
                    BackgroundTransparency = 1,
                    Font = currentFont,
                    Name = '#label',
                    RichText = true,
                    Size = UDim2.new(1, -36, 1, 0),
                    Text = 'button',
                    TextColor3 = theme.TextPrimary,
                    TextSize = 12,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 35
                }, clickSensor)
                create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6)}, label)

                local btn = create('Frame', {
                    Active = false,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Name = '#button',
                    Position = UDim2.new(1, -5, 0.5, 0),
                    Size = UDim2.fromOffset(24, 15),
                    ZIndex = 35
                }, clickSensor)
                makeCorner(btn, cornerPx)
                makeStroke(btn, theme.Stroke, 1)
                makeGradient(btn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 215), 90)
                makeTopSheen(btn, 36)

                local chev = makeChevronGlyph(btn, 36, 4)
                chev.Rotation = -90
            end
            buttonSmall.instances = instances
            buttonSmall.focused = false

            buttonSmall.click = function(self)
                self:fireEvent('onClick')
                local btn = self.instances.button
                local icon = btn['#icon']

                btn.BackgroundColor3 = theme.Button4
                btn['#stroke'].Color = theme.Primary
                setGlyphColor(icon, theme.Primary, 0)

                tween(btn, {BackgroundColor3 = self.focused and theme.Button2 or theme.Button1}, 0.45, 1)
                tween(btn['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.45, 1)
                setGlyphColor(icon, self.focused and theme.TextPrimary or theme.TextDim, 0.45)
                return self
            end
            buttonSmall.__hotkeyFunc = buttonSmall.click

            buttonSmall.signals = {
                clickSensor = {
                    MouseEnter = function(inst, self)
                        self.focused = true
                        self:showTooltip()
                        tween(inst, {BackgroundTransparency = 0.78}, 0.14, 1)
                        local btn = self.instances.button
                        tween(btn, {BackgroundColor3 = theme.Button2}, 0.16, 1)
                        tween(btn['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                        setGlyphColor(btn['#icon'], theme.TextPrimary, 0.16)
                    end,
                    MouseLeave = function(inst, self)
                        self.focused = false
                        self:hideTooltip()
                        tween(inst, {BackgroundTransparency = 1}, 0.14, 1)
                        local btn = self.instances.button
                        tween(btn, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                        tween(btn['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                        setGlyphColor(btn['#icon'], theme.TextDim, 0.16)
                    end,
                    MouseButton1Click = function(_, self)
                        self:click()
                    end
                }
            }

            buttonSmall.new = function(self)
                local new = setmetatable({}, self)
                new.binds = {}
                local insts = {}
                insts.controlFrame = self.instances.controlFrame:Clone()
                insts.clickSensor = insts.controlFrame['#click-sensor']
                insts.label = insts.clickSensor['#label']
                insts.button = insts.clickSensor['#button']

                for key, signals in pairs(self.signals) do
                    local inst = insts[key]
                    for signal, func in pairs(signals) do
                        inst[signal]:Connect(function()
                            func(inst, new)
                        end)
                    end
                end

                new.instances = insts
                return new
            end
            elemClasses.buttonSmall = buttonSmall
        end

        do
            local buttonLarge = {}
            buttonLarge.__index = buttonLarge
            setmetatable(buttonLarge, elemClasses.baseElement)
            buttonLarge.class = 'buttonLarge'

            local instances = {}
            do
                local controlFrame = create('Frame', {
                    BackgroundTransparency = 1,
                    Name = '#control',
                    Size = UDim2.new(1, 0, 0, 24),
                    ZIndex = 34
                })
                instances.controlFrame = controlFrame

                local clickSensor = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Name = '#click-sensor',
                    Size = UDim2.fromScale(1, 1),
                    Text = '',
                    ZIndex = 34
                }, controlFrame)

                local btn = create('Frame', {
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Name = '#button',
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(1, -10, 0, 20),
                    ZIndex = 35
                }, clickSensor)
                makeCorner(btn, cornerPx)
                makeStroke(btn, theme.Stroke, 1)
                makeGradient(btn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(214, 214, 214), 90)
                makeTopSheen(btn, 36)

                create('TextLabel', {
                    BackgroundTransparency = 1,
                    Font = currentFont,
                    Name = '#label',
                    RichText = true,
                    Size = UDim2.fromScale(1, 1),
                    Text = 'button',
                    TextColor3 = theme.TextPrimary,
                    TextSize = 12,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    ZIndex = 36
                }, btn)
            end
            buttonLarge.instances = instances
            buttonLarge.focused = false

            buttonLarge.click = function(self)
                self:fireEvent('onClick')
                local btn = self.instances.button
                local lbl = btn['#label']

                btn.BackgroundColor3 = theme.Button4
                btn['#stroke'].Color = theme.Primary
                lbl.TextColor3 = theme.Primary

                tween(btn, {BackgroundColor3 = self.focused and theme.Button2 or theme.Button1}, 0.45, 1)
                tween(btn['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.45, 1)
                tween(lbl, {TextColor3 = theme.TextPrimary}, 0.45, 1)
                return self
            end
            buttonLarge.__hotkeyFunc = buttonLarge.click

            buttonLarge.signals = {
                clickSensor = {
                    MouseEnter = function(_, self)
                        self.focused = true
                        self:showTooltip()
                        local btn = self.instances.button
                        tween(btn, {BackgroundColor3 = theme.Button2}, 0.16, 1)
                        tween(btn['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                    end,
                    MouseLeave = function(_, self)
                        self.focused = false
                        self:hideTooltip()
                        local btn = self.instances.button
                        tween(btn, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                        tween(btn['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    end,
                    MouseButton1Click = function(_, self)
                        self:click()
                    end
                }
            }

            buttonLarge.new = function(self)
                local new = setmetatable({}, self)
                new.binds = {}
                local insts = {}
                insts.controlFrame = self.instances.controlFrame:Clone()
                insts.clickSensor = insts.controlFrame['#click-sensor']
                insts.button = insts.clickSensor['#button']
                insts.label = insts.button['#label']

                for key, signals in pairs(self.signals) do
                    local inst = insts[key]
                    for signal, func in pairs(signals) do
                        inst[signal]:Connect(function()
                            func(inst, new)
                        end)
                    end
                end

                new.instances = insts
                return new
            end
            elemClasses.buttonLarge = buttonLarge
        end

        elemClasses.section.addButton = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_title = settings.text or 'button'
            local s_style = settings.style or 'small'
            if (typeof(s_style) == 'number') then
                s_style = (s_style == 2) and 'large' or 'small'
            elseif (typeof(s_style) ~= 'string') then
                s_style = 'small'
            end

            local new = (s_style == 'large') and elemClasses.buttonLarge:new() or elemClasses.buttonSmall:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            new.instances.label.Text = s_title
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onClick', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end
    end

    do
        local label = {}
        label.__index = label
        setmetatable(label, elemClasses.baseElement)
        label.class = 'label'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 19),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local lbl = create('TextLabel', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(1, 0, 0, 19),
                Text = 'label',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {
                Name = '#padding',
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            }, lbl)
        end
        label.instances = instances

        label.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.label = insts.controlFrame['#label']
            insts.controlFrame.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.controlFrame.MouseLeave:Connect(function()
                new:hideTooltip()
            end)
            new.instances = insts
            return new
        end

        label.setText = function(self, newText)
            self.instances.label.Text = tostring(newText)
            return self
        end
        label.getText = function(self)
            return self.instances.label.Text
        end

        elemClasses.section.addLabel = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or ''
            local s_center = settings.center or false
            local s_dim = settings.dim or false

            local l = label:new()
            l.section = self
            l.name = s_title
            table.insert(self.controls, l)

            local li = l.instances.label
            li.Text = s_title
            if (s_dim) then
                li.TextColor3 = theme.TextDim
            end
            if (s_center) then
                li.TextXAlignment = Enum.TextXAlignment.Center
                li['#padding'].PaddingLeft = UDim.new(0, 4)
                li['#padding'].PaddingRight = UDim.new(0, 4)
            end
            l.instances.controlFrame.Parent = self.instances.controlMenu
            if (settings.tooltip) then
                l:setTooltip(settings.tooltip)
            end
            return l
        end

        elemClasses.label = label
    end

    do
        local dropdown = {}
        dropdown.__index = dropdown
        setmetatable(dropdown, elemClasses.baseElement)
        dropdown.class = 'dropdown'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local header = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#header',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 22),
                Text = '',
                ZIndex = 35
            }, controlFrame)
            makeCorner(header, cornerPx)
            makeStroke(header, theme.Stroke, 1)
            makeGradient(header, Color3.fromRGB(255, 255, 255), Color3.fromRGB(218, 218, 218), 90)
            makeTopSheen(header, 36)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(0.55, 0, 1, 0),
                Text = 'dropdown',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 36
            }, header)
            create('UIPadding', {PaddingLeft = UDim.new(0, 7)}, label)

            local selectedLbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#selected',
                Position = UDim2.fromScale(0.45, 0),
                Size = UDim2.new(0.55, -20, 1, 0),
                Text = 'none',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 36
            }, header)

            local chevHolder = create('Frame', {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Name = '#chev',
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                ZIndex = 36
            }, header)
            makeChevronGlyph(chevHolder, 36, 4)

            local list = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                ClipsDescendants = true,
                MidImage = 'rbxassetid://9416839567',
                Name = '#menu',
                Position = UDim2.fromOffset(5, 25),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.5,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, -10, 0, 0),
                TopImage = 'rbxassetid://9416839567',
                Visible = false,
                ZIndex = 35
            }, controlFrame)
            makeCorner(list, cornerPx)
            makeStroke(list, theme.Stroke, 1)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Name = '#layout',
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 3)
            }, list)
        end
        dropdown.instances = instances
        dropdown.focused = false
        dropdown.openState = false

        local function getMenuHeight(self)
            local count = #self.options
            if (count == 0) then
                return 22
            end
            return math.min(count * 20 + math.max(0, count - 1) * 2 + 6, 114)
        end

        dropdown.open = function(self)
            self.openState = true
            local h = getMenuHeight(self)
            local menu = self.instances.menu
            menu.Visible = true
            tween(self.instances.header, {BackgroundColor3 = theme.Button2}, 0.16, 1)
            tween(self.instances.header['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
            tween(self.instances.chev['#icon'], {Rotation = 180}, 0.2, 1)
            setGlyphColor(self.instances.chev['#icon'], theme.Primary, 0.2)
            tween(menu, {Size = UDim2.new(1, -10, 0, h)}, 0.2, 1)
            tween(self.instances.controlFrame, {Size = UDim2.new(1, 0, 0, 28 + h)}, 0.2, 1)
            self:fireEvent('onOpen')
            return self
        end

        dropdown.close = function(self)
            self.openState = false
            local menu = self.instances.menu
            tween(self.instances.header, {BackgroundColor3 = self.focused and theme.Button2 or theme.Button1}, 0.16, 1)
            tween(self.instances.header['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
            tween(self.instances.chev['#icon'], {Rotation = 0}, 0.2, 1)
            setGlyphColor(self.instances.chev['#icon'], self.focused and theme.TextPrimary or theme.TextDim, 0.2)
            tween(menu, {Size = UDim2.new(1, -10, 0, 0)}, 0.18, 1)
            tween(self.instances.controlFrame, {Size = UDim2.new(1, 0, 0, 26)}, 0.18, 1)
            task.delay(0.18, function()
                if (not self.openState and menu and menu.Parent) then
                    menu.Visible = false
                end
            end)
            self:fireEvent('onClose')
            return self
        end

        dropdown.isOpen = function(self)
            return self.openState
        end

        dropdown.getValue = function(self)
            return self.value
        end

        dropdown.setValue = function(self, val, silent)
            self.value = val
            self.instances.selected.Text = val ~= nil and tostring(val) or 'none'
            for optVal, btn in pairs(self.optionButtons) do
                local active = (optVal == val)
                tween(btn, {
                    BackgroundColor3 = active and theme.Button3 or theme.Window3,
                    BackgroundTransparency = active and 0 or 1,
                    TextColor3 = active and theme.TextPrimary or theme.TextDim
                }, 0.14, 1)
                tween(btn['#ind'], {BackgroundTransparency = active and 0 or 1}, 0.14, 1)
            end
            if (not silent) then
                self:fireEvent('onSelect', val)
            end
            return self
        end

        dropdown.setOptions = function(self, newOptions)
            for _, btn in pairs(self.optionButtons) do
                btn:Destroy()
            end
            table.clear(self.optionButtons)
            table.clear(self.options)

            for idx, opt in ipairs(newOptions) do
                table.insert(self.options, opt)
                local optStr = tostring(opt)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Window3,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    LayoutOrder = idx,
                    Name = '#opt-' .. idx,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = optStr,
                    TextColor3 = theme.TextDim,
                    TextSize = 12,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 36
                }, self.instances.menu)
                makeCorner(btn, cornerPx)
                create('UIPadding', {PaddingLeft = UDim.new(0, 8)}, btn)
                local ind = create('Frame', {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#ind',
                    Position = UDim2.new(0, -8, 0.5, 0),
                    Size = UDim2.new(0, 2, 0, 12),
                    ZIndex = 37
                }, btn)
                makeGradient(ind, theme.Primary, theme.Secondary, 90)

                btn.MouseEnter:Connect(function()
                    if (self.value ~= opt) then
                        tween(btn, {BackgroundColor3 = theme.Button2, BackgroundTransparency = 0, TextColor3 = theme.TextPrimary}, 0.12, 1)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if (self.value ~= opt) then
                        tween(btn, {BackgroundTransparency = 1, TextColor3 = theme.TextDim}, 0.12, 1)
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    self:setValue(opt)
                    self:close()
                end)
                self.optionButtons[opt] = btn
            end

            if (self.openState) then
                local h = getMenuHeight(self)
                self.instances.menu.Size = UDim2.new(1, -10, 0, h)
                self.instances.controlFrame.Size = UDim2.new(1, 0, 0, 28 + h)
            end
            return self
        end
        dropdown.refresh = dropdown.setOptions

        dropdown.click = function(self)
            if (self.openState) then
                self:close()
            else
                self:open()
            end
            return self
        end
        dropdown.__hotkeyFunc = dropdown.click

        dropdown.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            new.options = {}
            new.optionButtons = {}

            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.header = insts.controlFrame['#header']
            insts.label = insts.header['#label']
            insts.selected = insts.header['#selected']
            insts.chev = insts.header['#chev']
            insts.menu = insts.controlFrame['#menu']
            registerNestedScroll(insts.menu)

            insts.header.MouseEnter:Connect(function()
                new.focused = true
                new:showTooltip()
                tween(insts.header, {BackgroundColor3 = theme.Button2}, 0.14, 1)
                tween(insts.header['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
            end)
            insts.header.MouseLeave:Connect(function()
                new.focused = false
                new:hideTooltip()
                if (not new.openState) then
                    tween(insts.header, {BackgroundColor3 = theme.Button1}, 0.14, 1)
                    tween(insts.header['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                end
            end)
            insts.header.MouseButton1Click:Connect(function()
                new:click()
            end)

            new.instances = insts
            return new
        end

        elemClasses.section.addDropdown = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_title = settings.text or 'dropdown'
            local s_options = settings.options or {}
            local s_default = settings.value ~= nil and settings.value or settings.default

            local new = dropdown:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            new.instances.label.Text = s_title
            new:setOptions(s_options)
            if (s_default ~= nil) then
                new:setValue(s_default, true)
            elseif (#s_options > 0) then
                new:setValue(s_options[1], true)
            end
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onSelect', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end

        elemClasses.dropdown = dropdown
    end

    do
        local fontSelector = {}
        fontSelector.__index = fontSelector
        setmetatable(fontSelector, elemClasses.baseElement)
        fontSelector.class = 'fontSelector'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 146),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(0.45, 0, 0, 15),
                Text = 'font',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, label)

            local activeLbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#active',
                Position = UDim2.new(0.4, 0, 0, 0),
                Size = UDim2.new(0.6, 0, 0, 15),
                Text = '.' .. currentFontKey,
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {PaddingRight = UDim.new(0, 6)}, activeLbl)

            local group = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#group',
                Position = UDim2.fromOffset(5, 17),
                Size = UDim2.new(1, -10, 1, -19),
                ZIndex = 35
            }, controlFrame)
            makeCorner(group, cornerPx)
            makeStroke(group, theme.Stroke, 1)

            local searchWrap = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                Name = '#search-wrap',
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 36
            }, group)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 37
            }, searchWrap)

            local searchBox = create('TextBox', {
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#search',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'search fonts...',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 37
            }, searchWrap)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, searchBox)

            local list = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#list',
                Position = UDim2.fromOffset(0, 20),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.45,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, 0, 1, -20),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 36
            }, group)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, list)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 4)
            }, list)
        end
        fontSelector.instances = instances

        fontSelector.setFont = function(self, font)
            ui.setFont(font)
            return self
        end
        fontSelector.getFont = function(self)
            return ui.getFont()
        end

        fontSelector.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.label = insts.controlFrame['#label']
            insts.active = insts.controlFrame['#active']
            insts.group = insts.controlFrame['#group']
            insts.search = insts.group['#search-wrap']['#search']
            insts.list = insts.group['#list']

            local btns = {}
            local fontsBuilt = false
            local activeFontKey = nil

            local function setBtnState(fk, active)
                local btn = btns[fk]
                if (not btn or not btn.Parent) then return end
                btn.BackgroundColor3 = active and theme.Button3 or theme.Window3
                btn.BackgroundTransparency = active and 0 or 1
                btn.TextColor3 = active and theme.TextPrimary or theme.TextDim
                btn['#ind'].BackgroundTransparency = active and 0 or 1
            end

            local function sync(fKey)
                insts.active.Text = '.' .. tostring(fKey)
                if (not fontsBuilt) then
                    activeFontKey = fKey
                    return
                end
                if (activeFontKey and activeFontKey ~= fKey) then
                    setBtnState(activeFontKey, false)
                end
                activeFontKey = fKey
                setBtnState(fKey, true)
            end

            new._buildFontList = function()
                if (fontsBuilt) then return end
                fontsBuilt = true
                registerNestedScroll(insts.list)
                for idx, fk in ipairs(fontOrder) do
                    local disp = fontDisplayNames[fk] or fk
                    local isAct = (fk == currentFontKey)
                    local btn = create('TextButton', {
                        AutoButtonColor = false,
                        BackgroundColor3 = isAct and theme.Button3 or theme.Window3,
                        BackgroundTransparency = isAct and 0 or 1,
                        BorderSizePixel = 0,
                        Font = currentFont,
                        LayoutOrder = idx,
                        Name = '#fopt-' .. fk,
                        Size = UDim2.new(1, 0, 0, 19),
                        Text = disp,
                        TextColor3 = isAct and theme.TextPrimary or theme.TextDim,
                        TextSize = 11,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 37
                    }, insts.list)
                    create('UIPadding', {PaddingLeft = UDim.new(0, 8)}, btn)

                    create('Frame', {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = theme.Primary,
                        BackgroundTransparency = isAct and 0 or 1,
                        BorderSizePixel = 0,
                        Name = '#ind',
                        Position = UDim2.new(0, -8, 0.5, 0),
                        Size = UDim2.new(0, 2, 0, 11),
                        ZIndex = 38
                    }, btn)

                    btn.MouseButton1Click:Connect(function()
                        ui.setFont(fk)
                        new:fireEvent('onFontChange', fk, fontMap[fk])
                    end)
                    btn.MouseEnter:Connect(function()
                        new:showTooltip()
                        if (currentFontKey ~= fk) then
                            btn.BackgroundColor3 = theme.Button2
                            btn.BackgroundTransparency = 0
                            btn.TextColor3 = theme.TextPrimary
                        end
                    end)
                    btn.MouseLeave:Connect(function()
                        new:hideTooltip()
                        if (currentFontKey ~= fk) then
                            btn.BackgroundTransparency = 1
                            btn.TextColor3 = theme.TextDim
                        end
                    end)
                    btns[fk] = btn
                end
                activeFontKey = currentFontKey
            end

            insts.search.Focused:Connect(function()
                new._buildFontList()
            end)
            insts.group.InputBegan:Connect(function()
                new._buildFontList()
            end)

            insts.search:GetPropertyChangedSignal('Text'):Connect(function()
                new._buildFontList()
                local q = insts.search.Text:lower():gsub('^%.', '')
                for fk, btn in pairs(btns) do
                    local disp = (fontDisplayNames[fk] or fk):lower()
                    btn.Visible = (q == '' or disp:find(q, 1, true) ~= nil or fk:find(q, 1, true) ~= nil)
                end
            end)

            sync(currentFontKey)
            table.insert(fontListeners, function(fKey)
                if (insts.controlFrame and insts.controlFrame.Parent) then
                    sync(fKey)
                end
            end)

            new.instances = insts
            return new
        end

        elemClasses.section.addFontSelector = function(self, settings, callback)
            settings = settings or {}
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'font'
            local new = fontSelector:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            if (typeof(settings.height) == 'number') then
                new.instances.controlFrame.Size = UDim2.new(1, 0, 0, settings.height + 20)
            end
            new.instances.label.Text = s_title
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onFontChange', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end

        elemClasses.fontSelector = fontSelector
    end

    do
        local slider = {}
        slider.__index = slider
        setmetatable(slider, elemClasses.baseElement)
        slider.class = 'slider'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local sliderContainer = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#slider-container',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 20),
                ZIndex = 35
            }, controlFrame)
            makeCorner(sliderContainer, cornerPx)
            makeStroke(sliderContainer, theme.Stroke, 1)

            local sliderFill = create('Frame', {
                Active = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                Name = '#slider-fill',
                Size = UDim2.fromScale(0, 1),
                ZIndex = 36
            }, sliderContainer)
            makeCorner(sliderFill, cornerPx)
            makeGradient(sliderFill, theme.Primary, theme.Secondary, 0)
            makeTopSheen(sliderFill, 37)

            create('Frame', {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Name = '#cap',
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 37
            }, sliderFill)

            local title = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Size = UDim2.new(0.65, 0, 1, 0),
                Text = 'slider',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 38
            }, sliderContainer)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, title)

            local val = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#val',
                Position = UDim2.fromScale(0.55, 0),
                Size = UDim2.new(0.45, 0, 1, 0),
                Text = '0',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 38
            }, sliderContainer)
            create('UIPadding', {PaddingRight = UDim.new(0, 6)}, val)

            local inputBox = create('TextBox', {
                Active = true,
                BackgroundColor3 = theme.Window1,
                BackgroundTransparency = 0,
                ClearTextOnFocus = true,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#input-box',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'enter value',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Center,
                Visible = false,
                ZIndex = 39
            }, sliderContainer)
            makeCorner(inputBox, cornerPx)
            makeStroke(inputBox, theme.Primary, 1)
        end
        slider.instances = instances

        slider.focused = false
        slider.dragging = false
        slider.step = 1
        slider.min = 0
        slider.max = 100
        slider.format = '%d'
        slider.suffix = ''

        slider.signals = {
            container = {
                MouseEnter = function(inst, self)
                    self.focused = true
                    self:showTooltip()
                    tween(inst['#stroke'], {Color = self.dragging and theme.Primary or theme.StrokeHover}, 0.16, 1)
                    tween(self.instances.fill, {BackgroundTransparency = 0.14}, 0.16, 1)
                end,
                MouseLeave = function(inst, self)
                    self.focused = false
                    self:hideTooltip()
                    if (not self.dragging) then
                        tween(inst['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                        tween(self.instances.fill, {BackgroundTransparency = 0.25}, 0.16, 1)
                    end
                end
            }
        }

        slider.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}

            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.container = insts.controlFrame['#slider-container']
            insts.label = insts.container['#label']
            insts.value = insts.container['#val']
            insts.fill = insts.container['#slider-fill']
            insts.input = insts.container['#input-box']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            do
                local sliderInst = insts.container
                local fill = insts.fill
                local valLbl = insts.value
                local inputbox = insts.input
                local dcon, acon, econ
                local targetSize

                local function snapValue(raw)
                    local clamped = math.clamp(raw, new.min, new.max)
                    local rounded = math.floor((clamped + new.step / 2) / new.step) * new.step
                    return math.clamp(rounded, new.min, new.max)
                end

                local function applyAtX(x)
                    local sPos = sliderInst.AbsolutePosition.X
                    local sWidth = math.max(1, sliderInst.AbsoluteSize.X)
                    local ratio = math.clamp((x - sPos) / sWidth, 0, 1)
                    local scaled = ratio * (new.max - new.min) + new.min
                    local rounded = snapValue(scaled)
                    local fillRatio = (new.max == new.min) and 0 or ((rounded - new.min) / (new.max - new.min))

                    targetSize = UDim2.fromScale(fillRatio, 1)
                    valLbl.Text = new.format:format(rounded) .. new.suffix
                    if (new.value ~= rounded) then
                        new.value = rounded
                        new:fireEvent('onNewValue', rounded)
                    end
                end

                inputbox.FocusLost:Connect(function()
                    local tx = inputbox.Text
                    local n = tonumber(tx)
                    inputbox.Visible = false
                    if (n) then
                        new:setValue(n)
                    end
                end)

                sliderInst.InputBegan:Connect(function(io)
                    if (isPrimaryInput(io)) then
                        new.dragging = true
                        tween(sliderInst['#stroke'], {Color = theme.Primary}, 0.14, 1)
                        tween(fill, {BackgroundTransparency = 0.1}, 0.14, 1)
                        applyAtX(io.Position.X)

                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end

                        acon = renderService.RenderStepped:Connect(function(dt)
                            if (targetSize) then
                                fill.Size = fill.Size:lerp(targetSize, 1 - 1e-12 ^ dt)
                            end
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (isMoveInput(mio)) then
                                applyAtX(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (isPrimaryInput(eio)) then
                                new.dragging = false
                                if (dcon) then dcon:Disconnect(); dcon = nil end
                                if (acon) then acon:Disconnect(); acon = nil end
                                if (econ) then econ:Disconnect(); econ = nil end
                                if (targetSize) then
                                    tween(fill, {Size = targetSize}, 0.16, 1)
                                end
                                tween(sliderInst['#stroke'], {Color = new.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                                tween(fill, {BackgroundTransparency = new.focused and 0.14 or 0.25}, 0.16, 1)
                            end
                        end)
                    elseif (io.UserInputType == Enum.UserInputType.MouseButton2) then
                        inputbox.Text = new.format:format(new.value or new.min)
                        inputbox.Visible = true
                        inputbox:CaptureFocus()
                    end
                end)
            end

            new.instances = insts
            return new
        end

        slider.getValue = function(self)
            return self.value
        end

        slider.setValue = function(self, value, silent)
            local clamped = math.clamp(value, self.min, self.max)
            local rounded = math.clamp(math.floor((clamped + self.step / 2) / self.step) * self.step, self.min, self.max)
            local fillValue = (self.max == self.min) and 0 or ((rounded - self.min) / (self.max - self.min))

            self.value = rounded
            tween(self.instances.fill, {Size = UDim2.fromScale(fillValue, 1)}, 0.22, 1)
            self.instances.value.Text = self.format:format(rounded) .. self.suffix
            if (not silent) then
                self:fireEvent('onNewValue', rounded)
            end
            return self
        end

        elemClasses.section.addSlider = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_title = settings.text or 'slider'
            local s_min = settings.min or 0
            local s_max = settings.max or 100
            local s_step = settings.step or 1
            local s_value = settings.value ~= nil and settings.value or (settings.val ~= nil and settings.val or s_min)
            local s_suffix = settings.suffix or ''

            if (typeof(s_min) ~= 'number') then
                return error("expected type 'number' for setting 'min'", 2)
            end
            if (typeof(s_max) ~= 'number') then
                return error("expected type 'number' for setting 'max'", 2)
            end
            if (typeof(s_step) ~= 'number') then
                return error("expected type 'number' for setting 'step'", 2)
            end
            if (typeof(s_value) ~= 'number') then
                return error("expected type 'number' for setting 'value'", 2)
            end

            local s = slider:new()
            s.section = self
            s.name = s_title
            s.min = s_min
            s.max = s_max
            s.step = s_step
            s.suffix = tostring(s_suffix)

            if (s_step >= 1) then
                s.format = '%d'
            elseif (s_step >= 0.1) then
                s.format = '%.1f'
            elseif (s_step >= 0.01) then
                s.format = '%.2f'
            elseif (s_step >= 0.001) then
                s.format = '%.3f'
            else
                s.format = '%.4f'
            end

            table.insert(self.controls, s)
            s:setValue(s_value, true)
            s.instances.label.Text = s_title
            s.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                s:bindToEvent('onNewValue', callback)
            end
            if (settings.tooltip) then
                s:setTooltip(settings.tooltip)
            end
            return s
        end

        elemClasses.section.addUIScaler = function(self, settings, callback)
            settings = settings or {}
            local s_cfg = {
                text = settings.text or 'ui scale',
                min = settings.min or 0.5,
                max = settings.max or 2.0,
                step = settings.step or 0.05,
                value = settings.value or settings.val or currentScale,
                suffix = settings.suffix or 'x',
                tooltip = settings.tooltip
            }
            local s = self:addSlider(s_cfg, function(newVal)
                ui.setScale(newVal)
                if (typeof(callback) == 'function') then
                    callback(newVal)
                end
            end)
            table.insert(scaleListeners, function(sc)
                if (s.instances.controlFrame and s.instances.controlFrame.Parent and not s.dragging) then
                    s:setValue(sc, true)
                end
            end)
            return s
        end
        elemClasses.section.addScaleSlider = elemClasses.section.addUIScaler

        elemClasses.section.addTextScaler = function(self, settings, callback)
            settings = settings or {}
            local s_cfg = {
                text = settings.text or 'text scale',
                min = settings.min or 0.6,
                max = settings.max or 1.8,
                step = settings.step or 0.05,
                value = settings.value or settings.val or currentTextScale,
                suffix = settings.suffix or 'x',
                tooltip = settings.tooltip
            }
            local s = self:addSlider(s_cfg, function(newVal)
                ui.setTextScale(newVal)
                if (typeof(callback) == 'function') then
                    callback(newVal)
                end
            end)
            table.insert(textScaleListeners, function(ts)
                if (s.instances.controlFrame and s.instances.controlFrame.Parent and not s.dragging) then
                    s:setValue(ts, true)
                end
            end)
            return s
        end
        elemClasses.section.addTextScaleSlider = elemClasses.section.addTextScaler

        elemClasses.slider = slider
    end

    do
        local picker = {}
        picker.__index = picker
        setmetatable(picker, elemClasses.baseElement)
        picker.class = 'picker'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local clickRegion = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#click-region',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                ZIndex = 34
            }, controlFrame)
            makeCorner(clickRegion, cornerPx)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(1, -38, 1, 0),
                Text = 'color',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 35
            }, clickRegion)
            create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6)}, label)

            local swatch = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#picker',
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(26, 14),
                ZIndex = 35
            }, clickRegion)
            makeCorner(swatch, cornerPx)
            makeStroke(swatch, theme.Stroke, 1)

            local display = create('Frame', {
                Active = false,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Name = '#display',
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = 36
            }, swatch)
            makeCorner(display, rounding and 1 or 0)
            makeGradient(display, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190), 90)
        end
        picker.instances = instances

        picker.color = Color3.fromRGB(255, 255, 255)
        picker.hue = 0
        picker.sat = 0
        picker.val = 1
        picker.chroma = false
        picker.chromaSpeed = 0.1
        picker.focused = false
        picker.pickerWindow = nil

        picker.openPrompt = function(self)
            local pw = elemClasses.pickerWindow:new()
            local mouseLoc = inputService:GetMouseLocation()
            local inset = guiService:GetGuiInset()
            local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or guiService:GetScreenResolution()
            local margin = 310
            local pos = Vector2.new(
                math.clamp(mouseLoc.X + 12, 12, math.max(12, screenSize.X - margin)),
                math.clamp(mouseLoc.Y - inset.Y + 12, 12, math.max(12, screenSize.Y - inset.Y - margin))
            )

            pw:setPosition(pos)
            pw.hue = self.hue
            pw.sat = self.sat
            pw.val = self.val
            pw.linkedPicker = self
            pw.instances.speedCursor.Position = UDim2.fromScale(0, 1 - self.chromaSpeed)
            pw:displayHSV(true)
            pw:setTitle(self.name)

            pw:bindToEvent('newColor', function(color, HSV)
                self.color = color
                self.hue = HSV[1]
                self.sat = HSV[2]
                self.val = HSV[3]
                self:fireEvent('onNewColor', color)
                self.instances.display.BackgroundColor3 = color
            end)

            pw:bindToEvent('close', function()
                if (pw.chromaCon) then
                    pw.chromaCon:Disconnect()
                end
                self.pickerWindow = nil
                if (self.chroma) then
                    if (self.chromaCon) then self.chromaCon:Disconnect() end
                    self.chromaCon = renderService.RenderStepped:Connect(function(dt)
                        dt *= self.chromaSpeed
                        local h = self.hue + dt
                        h = (h > 1 and h - 1) or h
                        self.hue = h
                        self.color = Color3.fromHSV(h, self.sat, self.val)
                        self.instances.display.BackgroundColor3 = self.color
                        self:fireEvent('onNewColor', self.color)
                    end)
                end
            end)

            pw:bindToEvent('chroma', function(t)
                self.chroma = t
                if (t) then
                    if (pw.chromaCon) then pw.chromaCon:Disconnect() end
                    if (self.chromaCon) then self.chromaCon:Disconnect() end
                    pw.chromaCon = renderService.RenderStepped:Connect(function(dt)
                        dt *= self.chromaSpeed
                        if (pw.pickerMoving) then
                            return
                        end
                        local h = pw.hue + dt
                        h = (h > 1 and h - 1) or h
                        pw.hue = h
                        pw:displayHSV(true)
                    end)
                else
                    if (pw.chromaCon) then pw.chromaCon:Disconnect() end
                    if (self.chromaCon) then self.chromaCon:Disconnect() end
                end
            end)

            if (self.chroma) then
                pw:toggleChroma()
            end

            task.spawn(function()
                local main = pw.instances.main
                local offsetIndex = 50 * math.random(1, 12)
                main.ZIndex += offsetIndex
                for _, v in ipairs(main:GetDescendants()) do
                    if (v:IsA('GuiObject')) then
                        v.ZIndex += offsetIndex
                    end
                end
                main.Size = UDim2.fromOffset(296, 29)
                tween(main, {Size = UDim2.fromOffset(296, 304)}, 0.32, 1)
            end)

            return pw
        end

        picker.click = function(self)
            self:fireEvent('onClick')
            local pwin = self.pickerWindow
            if (pwin) then
                pwin:destroy()
            else
                self.pickerWindow = self:openPrompt()
            end
            return self
        end
        picker.__hotkeyFunc = picker.click

        picker.getColor = function(self)
            return self.color
        end

        picker.setColor = function(self, color)
            if (typeof(color) ~= 'Color3') then
                return error('expected Color3, got ' .. typeof(color), 2)
            end
            self.color = color
            local h, s, v = color:ToHSV()
            self.hue = h
            self.sat = s
            self.val = v
            self.instances.display.BackgroundColor3 = self.color
            return self
        end

        picker.signals = {
            clickRegion = {
                MouseEnter = function(inst, self)
                    self.focused = true
                    self:showTooltip()
                    tween(inst, {BackgroundTransparency = 0.78}, 0.14, 1)
                    tween(self.instances.picker['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                end,
                MouseLeave = function(inst, self)
                    self.focused = false
                    self:hideTooltip()
                    tween(inst, {BackgroundTransparency = 1}, 0.14, 1)
                    tween(self.instances.picker['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                end,
                MouseButton1Click = function(_, self)
                    self:click()
                end
            }
        }

        picker.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.clickRegion = insts.controlFrame['#click-region']
            insts.picker = insts.clickRegion['#picker']
            insts.label = insts.clickRegion['#label']
            insts.display = insts.picker['#display']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            new.instances = insts
            return new
        end

        elemClasses.section.addColorPicker = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_title = settings.text or 'color'
            local s_color = settings.color or Color3.fromRGB(255, 255, 255)

            local p = picker:new()
            p.section = self
            p.name = s_title
            table.insert(self.controls, p)

            p.instances.label.Text = s_title
            p:setColor(s_color)
            p.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                p:bindToEvent('onNewColor', callback)
            end
            if (settings.tooltip) then
                p:setTooltip(settings.tooltip)
            end
            return p
        end

        elemClasses.picker = picker
    end

    do
        local textbox = {}
        textbox.__index = textbox
        setmetatable(textbox, elemClasses.baseElement)
        textbox.class = 'textbox'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local boxWrap = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#wrap',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 22),
                ZIndex = 35
            }, controlFrame)
            makeCorner(boxWrap, cornerPx)
            makeStroke(boxWrap, theme.Stroke, 1)

            local focusBar = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#focus-bar',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 37
            }, boxWrap)
            makeGradient(focusBar, theme.Primary, theme.Secondary, 90)

            local inputBox = create('TextBox', {
                Active = true,
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#textbox',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'type here...',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 36
            }, boxWrap)
            create('UIPadding', {
                Name = '#padding',
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7)
            }, inputBox)
        end
        textbox.instances = instances
        textbox.hovering = false
        textbox.focused = false

        textbox.signals = {
            controlFrame = {
                MouseEnter = function(_, obj)
                    obj.hovering = true
                    obj:showTooltip()
                    if (not obj.focused) then
                        tween(obj.instances.wrap, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                        tween(obj.instances.wrap['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                    end
                end,
                MouseLeave = function(_, obj)
                    obj.hovering = false
                    obj:hideTooltip()
                    if (not obj.focused) then
                        tween(obj.instances.wrap, {BackgroundColor3 = theme.Inset1}, 0.16, 1)
                        tween(obj.instances.wrap['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    end
                end
            },
            textBox = {
                Focused = function(inst, obj)
                    obj.focused = true
                    obj.textUpdCn = inst:GetPropertyChangedSignal('Text'):Connect(function()
                        obj:fireEvent('onTextChange', inst.Text)
                    end)
                    tween(obj.instances.wrap, {BackgroundColor3 = theme.Window1}, 0.16, 1)
                    tween(obj.instances.wrap['#stroke'], {Color = theme.Primary}, 0.16, 1)
                    tween(obj.instances.focusBar, {BackgroundTransparency = 0}, 0.16, 1)
                    obj:fireEvent('onFocus')
                end,
                FocusLost = function(inst, obj)
                    obj.focused = false
                    if (obj.textUpdCn) then
                        obj.textUpdCn:Disconnect()
                        obj.textUpdCn = nil
                    end
                    tween(obj.instances.wrap, {BackgroundColor3 = obj.hovering and theme.Button1 or theme.Inset1}, 0.16, 1)
                    tween(obj.instances.wrap['#stroke'], {Color = obj.hovering and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                    tween(obj.instances.focusBar, {BackgroundTransparency = 1}, 0.16, 1)
                    obj:fireEvent('onFocusLost', inst.Text)
                end
            }
        }

        textbox.getText = function(self)
            return self.instances.textBox.Text
        end

        textbox.setText = function(self, newText)
            self.instances.textBox.Text = tostring(newText)
            self:fireEvent('onTextChange', tostring(newText))
            return self
        end

        textbox.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.wrap = insts.controlFrame['#wrap']
            insts.focusBar = insts.wrap['#focus-bar']
            insts.textBox = insts.wrap['#textbox']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function(...)
                        func(inst, new, ...)
                    end)
                end
            end

            new.instances = insts
            return new
        end

        elemClasses.section.addTextbox = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end

            local s_title = settings.text or 'textbox'
            local s_placeholder = settings.placeholder or s_title
            local s_default = settings.default or ''

            local new = textbox:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            new.instances.textBox.PlaceholderText = s_placeholder
            new.instances.textBox.Text = s_default
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onTextChange', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end

        elemClasses.textbox = textbox
    end

    do
        local notif = {}
        notif.__index = notif
        setmetatable(notif, elemClasses.baseElement)
        notif.class = 'notif'

        local instances = {}
        do
            local main = create('Frame', {
                AnchorPoint = Vector2.new(1, 1),
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                LayoutOrder = 50,
                Name = '#notif-frame',
                Size = UDim2.fromOffset(210, 68),
                ZIndex = 3000
            })
            makeCorner(main, cornerPx)

            local bg = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Name = '#background',
                Size = UDim2.fromScale(1, 1),
                ZIndex = 2999
            }, main)
            makeCorner(bg, cornerPx)
            makeStroke(main, theme.Stroke, 1)

            create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = 'rbxassetid://7331400934',
                ImageColor3 = Color3.fromRGB(0, 0, 5),
                ImageTransparency = 0.2,
                Name = '#shadow',
                Position = UDim2.fromScale(0.5, 0.5),
                ScaleType = Enum.ScaleType.Slice,
                Size = UDim2.new(1, 44, 1, 44),
                SliceCenter = Rect.new(40, 40, 260, 260),
                SliceScale = 1,
                ZIndex = 2998
            }, main)

            local trim = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#trim',
                Position = UDim2.fromOffset(0, -1),
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 3005
            }, main)
            makeGradient(trim, theme.Primary, theme.Secondary, 0)

            local titleBar = create('Frame', {
                BackgroundColor3 = theme.Window1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#title-bar',
                Position = UDim2.fromOffset(0, 1),
                Size = UDim2.new(1, 0, 0, 23),
                ZIndex = 3001
            }, main)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 3003
            }, titleBar)

            local accentDot = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#dot',
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(2, 10),
                ZIndex = 3002
            }, titleBar)
            makeGradient(accentDot, theme.Primary, theme.Secondary, 90)

            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#title',
                Position = UDim2.fromOffset(16, 0),
                RichText = true,
                Size = UDim2.new(1, -22, 1, 0),
                Text = 'notification',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3002
            }, titleBar)

            local region = create('Frame', {
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#region',
                Position = UDim2.fromOffset(0, 24),
                Size = UDim2.new(1, 0, 1, -24),
                ZIndex = 3001
            }, main)

            local desc = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#desc',
                RichText = true,
                Size = UDim2.fromScale(1, 1),
                Text = 'notification',
                TextColor3 = theme.TextDim,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 3002
            }, region)
            create('UIPadding', {
                Name = '#padding',
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6)
            }, desc)

            instances.main = main
        end
        notif.instances = instances

        notif.destroy = function(self)
            local main = self.instances.main
            local logicalW = main.Size.X.Offset
            task.spawn(function()
                local animCon
                task.spawn(function()
                    local backgroundTransparency = {}
                    local imageTransparency = {}
                    local textTransparency = {}

                    local s = {
                        Frame = {backgroundTransparency},
                        ImageButton = {backgroundTransparency, imageTransparency},
                        ImageLabel = {backgroundTransparency, imageTransparency},
                        TextButton = {backgroundTransparency, textTransparency},
                        TextLabel = {backgroundTransparency, textTransparency}
                    }
                    local d = main:GetDescendants()
                    table.insert(d, main)

                    for _, v in ipairs(d) do
                        if (v:IsA('UIStroke')) then
                            v:Destroy()
                        else
                            local a = s[v.ClassName]
                            if (a) then
                                for idx = 1, #a do
                                    table.insert(a[idx], v)
                                end
                            end
                        end
                    end

                    animCon = renderService.RenderStepped:Connect(function(dt)
                        dt *= 8
                        for i = 1, #backgroundTransparency do
                            backgroundTransparency[i].BackgroundTransparency += dt
                        end
                        for i = 1, #imageTransparency do
                            imageTransparency[i].ImageTransparency += dt
                        end
                        for i = 1, #textTransparency do
                            textTransparency[i].TextTransparency += dt
                        end
                    end)
                end)
                tween(main, {Size = UDim2.fromOffset(logicalW, 0)}, 0.4, 1).Completed:Wait()
                if (animCon) then
                    animCon:Disconnect()
                end
                if (main and main.Parent) then
                    main:Destroy()
                end
            end)
            return self
        end

        notif.setTitle = function(self, title)
            self.instances.title.Text = tostring(title)
            return self
        end

        notif.setDesc = function(self, text)
            local desc = self.instances.desc
            local main = self.instances.main
            desc.Text = tostring(text)
            local c = 0
            while (true) do
                c += 1
                if (c > 24) then
                    break
                end
                local _ = desc.TextFits
                if (desc.TextFits == true) then
                    break
                end
                main.Size += UDim2.fromOffset(0, 16)
            end
            return self
        end

        notif.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.main = self.instances.main:Clone()
            insts.title = insts.main['#title-bar']['#title']
            insts.desc = insts.main['#region']['#desc']
            insts.main.Parent = notifContainer
            new.instances = insts
            return new
        end

        elemClasses.notif = notif
    end

    do
        local hotkey = {}
        hotkey.__index = hotkey
        setmetatable(hotkey, elemClasses.baseElement)
        hotkey.class = 'hotkey'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local back = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#back',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                ZIndex = 34
            }, controlFrame)
            makeCorner(back, cornerPx)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(1, -60, 1, 0),
                Text = 'hotkey',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 35
            }, back)
            create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6)}, label)

            local badge = create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(1, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#badge',
                Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(0, 16),
                ZIndex = 35
            }, back)
            makeCorner(badge, cornerPx)
            makeStroke(badge, theme.Stroke, 1)

            local hkLbl = create('TextLabel', {
                Active = false,
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#hotkey',
                Size = UDim2.fromOffset(0, 16),
                Text = '[None]',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 36
            }, badge)
            create('UIPadding', {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, hkLbl)
        end
        hotkey.instances = instances

        hotkey.set = nil
        hotkey.hotkey = nil
        hotkey.focused = false
        hotkey.inputCon = nil

        hotkey.click = function(self)
            local display = self.instances.hotkey
            local badge = self.instances.badge
            if (self.inputCon) then
                self.inputCon:Disconnect()
                self.inputCon = nil
                display.Text = self.hotkey and ('[%s]'):format(self.hotkey.Name) or '[None]'
                tween(display, {TextColor3 = self.focused and theme.TextPrimary or theme.TextDim}, 0.16, 1)
                tween(badge['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                return self
            end

            display.Text = '[...]'
            tween(display, {TextColor3 = theme.Primary}, 0.16, 1)
            tween(badge['#stroke'], {Color = theme.Primary}, 0.16, 1)

            self.inputCon = inputService.InputBegan:Connect(function(io)
                if (io.UserInputType ~= Enum.UserInputType.Keyboard) then return end
                local kc = io.KeyCode.Name
                if (kc == 'Unknown' or kc == 'Escape') then
                    self.hotkey = nil
                    display.Text = '[None]'
                else
                    self.hotkey = io.KeyCode
                    self.set = time()
                    display.Text = ('[%s]'):format(kc)
                end
                self.inputCon:Disconnect()
                self.inputCon = nil
                tween(display, {TextColor3 = self.focused and theme.TextPrimary or theme.TextDim}, 0.18, 1)
                tween(badge['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.18, 1)
                if (ui.refreshKeybindList) then ui.refreshKeybindList() end
            end)
            return self
        end
        hotkey.__hotkeyFunc = hotkey.click

        hotkey.signals = {
            back = {
                MouseEnter = function(inst, self)
                    self.focused = true
                    self:showTooltip()
                    tween(inst, {BackgroundTransparency = 0.78}, 0.14, 1)
                    if (not self.inputCon) then
                        tween(self.instances.hotkey, {TextColor3 = theme.TextPrimary}, 0.16, 1)
                        tween(self.instances.badge['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                    end
                end,
                MouseLeave = function(inst, self)
                    self.focused = false
                    self:hideTooltip()
                    tween(inst, {BackgroundTransparency = 1}, 0.14, 1)
                    if (not self.inputCon) then
                        tween(self.instances.hotkey, {TextColor3 = theme.TextDim}, 0.16, 1)
                        tween(self.instances.badge['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                    end
                end,
                MouseButton1Click = function(_, self)
                    self:click()
                end
            }
        }

        hotkey.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.back = insts.controlFrame['#back']
            insts.label = insts.back['#label']
            insts.badge = insts.back['#badge']
            insts.hotkey = insts.badge['#hotkey']

            for key, signals in pairs(self.signals) do
                local inst = insts[key]
                for signal, func in pairs(signals) do
                    inst[signal]:Connect(function()
                        func(inst, new)
                    end)
                end
            end

            table.insert(ui.hotkeys, new)
            new.instances = insts
            return new
        end

        hotkey.linkToControl = function(self, control)
            if (control and control.__hotkeyFunc == nil) then
                return error("couldn't find control function", 2)
            elseif (not control) then
                control = nil
            end
            self.linkedControl = control
            return self
        end

        hotkey.setHotkey = function(self, key)
            if (key) then
                if (typeof(key) == 'EnumItem') then
                    if (key.EnumType ~= Enum.KeyCode) then
                        return error('expected EnumItem of EnumType KeyCode for hotkey', 2)
                    end
                else
                    if (Enum.KeyCode[key]) then
                        key = Enum.KeyCode[key]
                    else
                        return error('expected valid Enum.KeyCode Name, or Enum.KeyCode EnumItem', 2)
                    end
                end
                self.hotkey = key
                self.instances.hotkey.Text = ('[%s]'):format(key.Name)
            else
                self.hotkey = nil
                self.instances.hotkey.Text = '[None]'
            end
            if (ui.refreshKeybindList) then ui.refreshKeybindList() end
            return self
        end
        hotkey.getHotkey = function(self) return self.hotkey end

        elemClasses.section.addHotkey = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'hotkey'
            local s_bind = settings.bind or nil

            local hk = hotkey:new()
            hk.section = self
            hk.name = s_title
            table.insert(self.controls, hk)

            hk.instances.label.Text = s_title
            if (s_bind) then
                hk:setHotkey(s_bind)
            end
            hk.instances.controlFrame.Parent = self.instances.controlMenu
            if (settings.tooltip) then
                hk:setTooltip(settings.tooltip)
            end
            return hk
        end

        elemClasses.hotkey = hotkey
    end

    do
        local multiDropdown = {}
        multiDropdown.__index = multiDropdown
        setmetatable(multiDropdown, elemClasses.baseElement)
        multiDropdown.class = 'multiDropdown'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local header = create('TextButton', {
                AutoButtonColor = false,
                BackgroundColor3 = theme.Button1,
                BorderSizePixel = 0,
                Name = '#header',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 22),
                Text = '',
                ZIndex = 35
            }, controlFrame)
            makeCorner(header, cornerPx)
            makeStroke(header, theme.Stroke, 1)
            makeGradient(header, Color3.fromRGB(255, 255, 255), Color3.fromRGB(218, 218, 218), 90)
            makeTopSheen(header, 36)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(0.5, 0, 1, 0),
                Text = 'multi',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 36
            }, header)
            create('UIPadding', {PaddingLeft = UDim.new(0, 7)}, label)

            create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#selected',
                Position = UDim2.fromScale(0.45, 0),
                Size = UDim2.new(0.55, -20, 1, 0),
                Text = 'none',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 36
            }, header)

            local chevHolder = create('Frame', {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Name = '#chev',
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(12, 12),
                ZIndex = 36
            }, header)
            makeChevronGlyph(chevHolder, 36, 4)

            local list = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                ClipsDescendants = true,
                MidImage = 'rbxassetid://9416839567',
                Name = '#menu',
                Position = UDim2.fromOffset(5, 25),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.5,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, -10, 0, 0),
                TopImage = 'rbxassetid://9416839567',
                Visible = false,
                ZIndex = 35
            }, controlFrame)
            makeCorner(list, cornerPx)
            makeStroke(list, theme.Stroke, 1)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Name = '#layout',
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 3)
            }, list)
        end
        multiDropdown.instances = instances
        multiDropdown.focused = false
        multiDropdown.openState = false

        local function getMenuHeight(self)
            local count = #self.options
            if (count == 0) then
                return 22
            end
            return math.min(count * 20 + math.max(0, count - 1) * 2 + 6, 126)
        end

        local function updateSummary(self)
            local picked = {}
            for _, opt in ipairs(self.options) do
                if (self.selected[opt]) then
                    table.insert(picked, tostring(opt))
                end
            end
            if (#picked == 0) then
                self.instances.selected.Text = 'none'
            elseif (#picked <= 2) then
                self.instances.selected.Text = table.concat(picked, ', ')
            else
                self.instances.selected.Text = tostring(#picked) .. ' selected'
            end
        end

        local function syncOptionVisual(self, opt)
            local btn = self.optionButtons[opt]
            if (not btn) then return end
            local active = self.selected[opt] == true
            local box = btn['#box']
            local fill = box['#fill']
            tween(btn, {
                BackgroundColor3 = active and theme.Button3 or theme.Window3,
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and theme.TextPrimary or theme.TextDim
            }, 0.14, 1)
            tween(fill, {
                Size = active and UDim2.fromOffset(6, 6) or UDim2.fromOffset(0, 0),
                BackgroundTransparency = active and 0 or 1
            }, 0.16, 1)
            tween(box['#stroke'], {Color = active and theme.Primary or theme.Stroke}, 0.14, 1)
        end

        multiDropdown.open = function(self)
            self.openState = true
            local h = getMenuHeight(self)
            local menu = self.instances.menu
            menu.Visible = true
            tween(self.instances.header, {BackgroundColor3 = theme.Button2}, 0.16, 1)
            tween(self.instances.header['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
            tween(self.instances.chev['#icon'], {Rotation = 180}, 0.2, 1)
            setGlyphColor(self.instances.chev['#icon'], theme.Primary, 0.2)
            tween(menu, {Size = UDim2.new(1, -10, 0, h)}, 0.2, 1)
            tween(self.instances.controlFrame, {Size = UDim2.new(1, 0, 0, 28 + h)}, 0.2, 1)
            self:fireEvent('onOpen')
            return self
        end

        multiDropdown.close = function(self)
            self.openState = false
            local menu = self.instances.menu
            tween(self.instances.header, {BackgroundColor3 = self.focused and theme.Button2 or theme.Button1}, 0.16, 1)
            tween(self.instances.header['#stroke'], {Color = self.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
            tween(self.instances.chev['#icon'], {Rotation = 0}, 0.2, 1)
            setGlyphColor(self.instances.chev['#icon'], self.focused and theme.TextPrimary or theme.TextDim, 0.2)
            tween(menu, {Size = UDim2.new(1, -10, 0, 0)}, 0.18, 1)
            tween(self.instances.controlFrame, {Size = UDim2.new(1, 0, 0, 26)}, 0.18, 1)
            task.delay(0.18, function()
                if (not self.openState and menu and menu.Parent) then
                    menu.Visible = false
                end
            end)
            self:fireEvent('onClose')
            return self
        end

        multiDropdown.isOpen = function(self) return self.openState end

        multiDropdown.getValues = function(self)
            local out = {}
            for _, opt in ipairs(self.options) do
                if (self.selected[opt]) then
                    table.insert(out, opt)
                end
            end
            return out
        end

        multiDropdown.getValue = multiDropdown.getValues

        multiDropdown.isSelected = function(self, opt)
            return self.selected[opt] == true
        end

        multiDropdown.setValues = function(self, vals, silent)
            table.clear(self.selected)
            if (typeof(vals) == 'table') then
                for k, v in pairs(vals) do
                    if (typeof(k) == 'number') then
                        self.selected[v] = true
                    elseif (v == true) then
                        self.selected[k] = true
                    end
                end
            end
            for _, opt in ipairs(self.options) do
                syncOptionVisual(self, opt)
            end
            updateSummary(self)
            if (not silent) then
                self:fireEvent('onSelect', self:getValues(), self.selected)
            end
            return self
        end

        multiDropdown.toggleOption = function(self, opt, silent)
            self.selected[opt] = not self.selected[opt]
            syncOptionVisual(self, opt)
            updateSummary(self)
            if (not silent) then
                self:fireEvent('onSelect', self:getValues(), self.selected)
            end
            return self
        end

        multiDropdown.setOptions = function(self, newOptions)
            for _, btn in pairs(self.optionButtons) do
                btn:Destroy()
            end
            table.clear(self.optionButtons)
            table.clear(self.options)

            for idx, opt in ipairs(newOptions) do
                table.insert(self.options, opt)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Window3,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    LayoutOrder = idx,
                    Name = '#opt-' .. idx,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = tostring(opt),
                    TextColor3 = theme.TextDim,
                    TextSize = 12,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 36
                }, self.instances.menu)
                makeCorner(btn, cornerPx)
                create('UIPadding', {PaddingLeft = UDim.new(0, 22)}, btn)

                local box = create('Frame', {
                    Active = false,
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = theme.Window2,
                    BorderSizePixel = 0,
                    Name = '#box',
                    Position = UDim2.new(0, -16, 0.5, 0),
                    Size = UDim2.fromOffset(10, 10),
                    ZIndex = 37
                }, btn)
                makeCorner(box, rounding and 1 or 0)
                makeStroke(box, theme.Stroke, 1)

                local fill = create('Frame', {
                    Active = false,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#fill',
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 0),
                    ZIndex = 38
                }, box)
                makeGradient(fill, theme.Primary, theme.Secondary, 135)

                btn.MouseEnter:Connect(function()
                    if (not self.selected[opt]) then
                        tween(btn, {BackgroundColor3 = theme.Button2, BackgroundTransparency = 0, TextColor3 = theme.TextPrimary}, 0.12, 1)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if (not self.selected[opt]) then
                        tween(btn, {BackgroundTransparency = 1, TextColor3 = theme.TextDim}, 0.12, 1)
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    self:toggleOption(opt)
                end)

                self.optionButtons[opt] = btn
                syncOptionVisual(self, opt)
            end

            updateSummary(self)
            if (self.openState) then
                local h = getMenuHeight(self)
                self.instances.menu.Size = UDim2.new(1, -10, 0, h)
                self.instances.controlFrame.Size = UDim2.new(1, 0, 0, 28 + h)
            end
            return self
        end
        multiDropdown.refresh = multiDropdown.setOptions

        multiDropdown.click = function(self)
            if (self.openState) then self:close() else self:open() end
            return self
        end
        multiDropdown.__hotkeyFunc = multiDropdown.click

        multiDropdown.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            new.options = {}
            new.selected = {}
            new.optionButtons = {}

            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.header = insts.controlFrame['#header']
            insts.label = insts.header['#label']
            insts.selected = insts.header['#selected']
            insts.chev = insts.header['#chev']
            insts.menu = insts.controlFrame['#menu']
            registerNestedScroll(insts.menu)

            insts.header.MouseEnter:Connect(function()
                new.focused = true
                new:showTooltip()
                tween(insts.header, {BackgroundColor3 = theme.Button2}, 0.14, 1)
                tween(insts.header['#stroke'], {Color = theme.StrokeHover}, 0.14, 1)
            end)
            insts.header.MouseLeave:Connect(function()
                new.focused = false
                new:hideTooltip()
                if (not new.openState) then
                    tween(insts.header, {BackgroundColor3 = theme.Button1}, 0.14, 1)
                    tween(insts.header['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                end
            end)
            insts.header.MouseButton1Click:Connect(function()
                new:click()
            end)

            new.instances = insts
            return new
        end

        elemClasses.section.addMultiDropdown = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'multi'
            local s_options = settings.options or {}
            local s_default = settings.values or settings.default or {}

            local new = multiDropdown:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            new.instances.label.Text = s_title
            new:setOptions(s_options)
            new:setValues(s_default, true)
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onSelect', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end

        elemClasses.multiDropdown = multiDropdown
    end

    do
        local divider = {}
        divider.__index = divider
        setmetatable(divider, elemClasses.baseElement)
        divider.class = 'divider'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Name = '#line',
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.new(1, -10, 0, 1),
                ZIndex = 35
            }, controlFrame)

            local lbl = create('TextLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = theme.Window2,
                BorderSizePixel = 0,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 14),
                Text = '',
                TextColor3 = theme.TextDim,
                TextSize = 10,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                Visible = false,
                ZIndex = 36
            }, controlFrame)
            create('UIPadding', {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, lbl)
        end
        divider.instances = instances

        divider.setText = function(self, txt)
            local lbl = self.instances.label
            if (txt and tostring(txt) ~= '') then
                lbl.Text = tostring(txt)
                lbl.Visible = true
                self.instances.controlFrame.Size = UDim2.new(1, 0, 0, 16)
            else
                lbl.Text = ''
                lbl.Visible = false
                self.instances.controlFrame.Size = UDim2.new(1, 0, 0, 10)
            end
            return self
        end

        divider.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.line = insts.controlFrame['#line']
            insts.label = insts.controlFrame['#label']
            insts.controlFrame.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.controlFrame.MouseLeave:Connect(function()
                new:hideTooltip()
            end)
            new.instances = insts
            return new
        end

        elemClasses.section.addDivider = function(self, settings)
            settings = settings or {}
            local s_text = typeof(settings) == 'string' and settings or settings.text
            local d = divider:new()
            d.section = self
            d.name = s_text or ''
            table.insert(self.controls, d)
            d:setText(s_text)
            d.instances.controlFrame.Parent = self.instances.controlMenu
            if (typeof(settings) == 'table' and settings.tooltip) then
                d:setTooltip(settings.tooltip)
            end
            return d
        end

        elemClasses.divider = divider
    end

    do
        local segmented = {}
        segmented.__index = segmented
        setmetatable(segmented, elemClasses.baseElement)
        segmented.class = 'segmented'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 40),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 15),
                Text = 'mode',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, label)

            local group = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#group',
                Position = UDim2.fromOffset(5, 17),
                Size = UDim2.new(1, -10, 0, 21),
                ZIndex = 35
            }, controlFrame)
            makeCorner(group, cornerPx)
            makeStroke(group, theme.Stroke, 1)
        end
        segmented.instances = instances

        segmented.getValue = function(self)
            return self.value
        end

        segmented.setValue = function(self, val, silent)
            self.value = val
            for opt, btn in pairs(self.buttons) do
                local active = (opt == val)
                tween(btn, {
                    BackgroundColor3 = active and theme.Button3 or theme.Button1,
                    TextColor3 = active and theme.TextPrimary or theme.TextDim
                }, 0.16, 1)
                tween(btn['#ind'], {BackgroundTransparency = active and 0 or 1}, 0.16, 1)
            end
            if (not silent) then
                self:fireEvent('onSelect', val)
            end
            return self
        end

        segmented.setOptions = function(self, opts)
            for _, btn in pairs(self.buttons) do
                btn:Destroy()
            end
            table.clear(self.buttons)
            table.clear(self.options)

            local count = math.max(1, #opts)
            local frac = 1 / count
            for idx, opt in ipairs(opts) do
                table.insert(self.options, opt)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    Name = '#seg-' .. idx,
                    Position = UDim2.new((idx - 1) * frac, 1, 0, 1),
                    Size = UDim2.new(frac, -2, 1, -2),
                    Text = tostring(opt),
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 36
                }, self.instances.group)
                makeCorner(btn, cornerPx)
                local ind = create('Frame', {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#ind',
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(1, 0, 0, 2),
                    ZIndex = 37
                }, btn)
                makeGradient(ind, theme.Primary, theme.Secondary, 0)

                btn.MouseEnter:Connect(function()
                    self:showTooltip()
                    if (self.value ~= opt) then
                        tween(btn, {BackgroundColor3 = theme.Button2, TextColor3 = theme.TextPrimary}, 0.14, 1)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    self:hideTooltip()
                    if (self.value ~= opt) then
                        tween(btn, {BackgroundColor3 = theme.Button1, TextColor3 = theme.TextDim}, 0.14, 1)
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    self:setValue(opt)
                end)
                self.buttons[opt] = btn
            end
            return self
        end

        segmented.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            new.options = {}
            new.buttons = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.label = insts.controlFrame['#label']
            insts.group = insts.controlFrame['#group']
            new.instances = insts
            return new
        end

        elemClasses.section.addSegmented = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'mode'
            local s_options = settings.options or {'a', 'b'}
            local s_default = settings.value ~= nil and settings.value or (settings.default ~= nil and settings.default or s_options[1])

            local new = segmented:new()
            new.section = self
            new.name = s_title
            table.insert(self.controls, new)

            new.instances.label.Text = s_title
            new:setOptions(s_options)
            if (s_default ~= nil) then
                new:setValue(s_default, true)
            end
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onSelect', callback)
            end
            if (settings.tooltip) then
                new:setTooltip(settings.tooltip)
            end
            return new
        end

        elemClasses.segmented = segmented
    end

    do
        local rangeSlider = {}
        rangeSlider.__index = rangeSlider
        setmetatable(rangeSlider, elemClasses.baseElement)
        rangeSlider.class = 'rangeSlider'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local track = create('Frame', {
                Active = true,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#track',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 20),
                ZIndex = 35
            }, controlFrame)
            makeCorner(track, cornerPx)
            makeStroke(track, theme.Stroke, 1)

            local fill = create('Frame', {
                Active = false,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                Name = '#fill',
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ZIndex = 36
            }, track)
            makeCorner(fill, cornerPx)
            makeGradient(fill, theme.Primary, theme.Secondary, 0)
            makeTopSheen(fill, 37)

            create('Frame', {
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Name = '#cap-l',
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 37
            }, fill)

            create('Frame', {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = theme.Primary,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Name = '#cap-r',
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 37
            }, fill)

            local title = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Size = UDim2.new(0.55, 0, 1, 0),
                Text = 'range',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 38
            }, track)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, title)

            local val = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#val',
                Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                Text = '0 - 100',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 38
            }, track)
            create('UIPadding', {PaddingRight = UDim.new(0, 6)}, val)
        end
        rangeSlider.instances = instances

        rangeSlider.focused = false
        rangeSlider.dragging = false
        rangeSlider.min = 0
        rangeSlider.max = 100
        rangeSlider.step = 1
        rangeSlider.low = 20
        rangeSlider.high = 80
        rangeSlider.format = '%d'
        rangeSlider.suffix = ''

        local function updateRangeVisual(self, animate)
            local span = math.max(1e-6, self.max - self.min)
            local lRatio = math.clamp((self.low - self.min) / span, 0, 1)
            local hRatio = math.clamp((self.high - self.min) / span, 0, 1)
            local pos = UDim2.fromScale(lRatio, 0)
            local sz = UDim2.fromScale(math.max(0.01, hRatio - lRatio), 1)
            if (animate) then
                tween(self.instances.fill, {Position = pos, Size = sz}, 0.18, 1)
            else
                self.instances.fill.Position = pos
                self.instances.fill.Size = sz
            end
            self.instances.value.Text = (self.format:format(self.low) .. ' - ' .. self.format:format(self.high) .. self.suffix)
        end

        rangeSlider.getRange = function(self)
            return self.low, self.high
        end
        rangeSlider.getValue = rangeSlider.getRange

        rangeSlider.setRange = function(self, low, high, silent)
            local lo = math.clamp(math.floor((math.clamp(low, self.min, self.max) + self.step / 2) / self.step) * self.step, self.min, self.max)
            local hi = math.clamp(math.floor((math.clamp(high, self.min, self.max) + self.step / 2) / self.step) * self.step, self.min, self.max)
            if (lo > hi) then
                lo, hi = hi, lo
            end
            self.low = lo
            self.high = hi
            updateRangeVisual(self, true)
            if (not silent) then
                self:fireEvent('onNewRange', lo, hi)
            end
            return self
        end

        rangeSlider.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.track = insts.controlFrame['#track']
            insts.label = insts.track['#label']
            insts.value = insts.track['#val']
            insts.fill = insts.track['#fill']

            insts.track.MouseEnter:Connect(function()
                new.focused = true
                new:showTooltip()
                tween(insts.track['#stroke'], {Color = new.dragging and theme.Primary or theme.StrokeHover}, 0.14, 1)
                tween(insts.fill, {BackgroundTransparency = 0.14}, 0.14, 1)
            end)
            insts.track.MouseLeave:Connect(function()
                new.focused = false
                new:hideTooltip()
                if (not new.dragging) then
                    tween(insts.track['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                    tween(insts.fill, {BackgroundTransparency = 0.25}, 0.14, 1)
                end
            end)

            local dcon, econ
            local activeHandle = 'low'

            local function xToValue(x)
                local tPos = insts.track.AbsolutePosition.X
                local tW = math.max(1, insts.track.AbsoluteSize.X)
                local r = math.clamp((x - tPos) / tW, 0, 1)
                local raw = new.min + r * (new.max - new.min)
                return math.clamp(math.floor((raw + new.step / 2) / new.step) * new.step, new.min, new.max)
            end

            local function applyDrag(x)
                local v = xToValue(x)
                local oldL, oldH = new.low, new.high
                if (activeHandle == 'low') then
                    new.low = math.min(v, new.high)
                else
                    new.high = math.max(v, new.low)
                end
                updateRangeVisual(new, false)
                if (new.low ~= oldL or new.high ~= oldH) then
                    new:fireEvent('onNewRange', new.low, new.high)
                end
            end

            insts.track.InputBegan:Connect(function(io)
                if (isPrimaryInput(io)) then
                    local clickVal = xToValue(io.Position.X)
                    activeHandle = (math.abs(clickVal - new.low) <= math.abs(clickVal - new.high)) and 'low' or 'high'
                    new.dragging = true
                    tween(insts.track['#stroke'], {Color = theme.Primary}, 0.14, 1)
                    tween(insts.fill, {BackgroundTransparency = 0.1}, 0.14, 1)
                    applyDrag(io.Position.X)

                    if (dcon) then dcon:Disconnect() end
                    if (econ) then econ:Disconnect() end
                    dcon = inputService.InputChanged:Connect(function(mio)
                        if (isMoveInput(mio)) then
                            applyDrag(mio.Position.X)
                        end
                    end)
                    econ = inputService.InputEnded:Connect(function(eio)
                        if (isPrimaryInput(eio)) then
                            new.dragging = false
                            if (dcon) then dcon:Disconnect(); dcon = nil end
                            if (econ) then econ:Disconnect(); econ = nil end
                            tween(insts.track['#stroke'], {Color = new.focused and theme.StrokeHover or theme.Stroke}, 0.16, 1)
                            tween(insts.fill, {BackgroundTransparency = new.focused and 0.14 or 0.25}, 0.16, 1)
                        end
                    end)
                end
            end)

            new.instances = insts
            return new
        end

        elemClasses.section.addRangeSlider = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_title = settings.text or 'range'
            local s_min = settings.min or 0
            local s_max = settings.max or 100
            local s_step = settings.step or 1
            local s_low = settings.low ~= nil and settings.low or s_min
            local s_high = settings.high ~= nil and settings.high or s_max
            local s_suffix = settings.suffix or ''

            local rs = rangeSlider:new()
            rs.section = self
            rs.name = s_title
            rs.min = s_min
            rs.max = s_max
            rs.step = s_step
            rs.suffix = tostring(s_suffix)

            if (s_step >= 1) then
                rs.format = '%d'
            elseif (s_step >= 0.1) then
                rs.format = '%.1f'
            elseif (s_step >= 0.01) then
                rs.format = '%.2f'
            else
                rs.format = '%.3f'
            end

            table.insert(self.controls, rs)
            rs.instances.label.Text = s_title
            rs:setRange(s_low, s_high, true)
            rs.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                rs:bindToEvent('onNewRange', callback)
            end
            if (settings.tooltip) then
                rs:setTooltip(settings.tooltip)
            end
            return rs
        end

        elemClasses.rangeSlider = rangeSlider
    end

    do
        local dualButton = {}
        dualButton.__index = dualButton
        setmetatable(dualButton, elemClasses.baseElement)
        dualButton.class = 'dualButton'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local function makeHalf(name, pos, sz)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    Name = name,
                    Position = pos,
                    Size = sz,
                    Text = 'action',
                    TextColor3 = theme.TextPrimary,
                    TextSize = 12,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    ZIndex = 35
                }, controlFrame)
                makeCorner(btn, cornerPx)
                makeStroke(btn, theme.Stroke, 1)
                makeGradient(btn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(214, 214, 214), 90)
                makeTopSheen(btn, 36)
                return btn
            end

            makeHalf('#left', UDim2.fromOffset(5, 2), UDim2.new(0.5, -7, 0, 20))
            makeHalf('#right', UDim2.new(0.5, 2, 0, 2), UDim2.new(0.5, -7, 0, 20))
        end
        dualButton.instances = instances

        dualButton.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            new.leftFocused = false
            new.rightFocused = false

            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.left = insts.controlFrame['#left']
            insts.right = insts.controlFrame['#right']

            local function wire(btn, focusKey, eventName)
                btn.MouseEnter:Connect(function()
                    new[focusKey] = true
                    new:showTooltip()
                    tween(btn, {BackgroundColor3 = theme.Button2}, 0.16, 1)
                    tween(btn['#stroke'], {Color = theme.StrokeHover}, 0.16, 1)
                end)
                btn.MouseLeave:Connect(function()
                    new[focusKey] = false
                    new:hideTooltip()
                    tween(btn, {BackgroundColor3 = theme.Button1}, 0.16, 1)
                    tween(btn['#stroke'], {Color = theme.Stroke}, 0.16, 1)
                end)
                btn.MouseButton1Click:Connect(function()
                    btn.BackgroundColor3 = theme.Button4
                    btn['#stroke'].Color = theme.Primary
                    btn.TextColor3 = theme.Primary
                    tween(btn, {BackgroundColor3 = new[focusKey] and theme.Button2 or theme.Button1}, 0.4, 1)
                    tween(btn['#stroke'], {Color = new[focusKey] and theme.StrokeHover or theme.Stroke}, 0.4, 1)
                    tween(btn, {TextColor3 = theme.TextPrimary}, 0.4, 1)
                    new:fireEvent(eventName)
                end)
            end

            wire(insts.left, 'leftFocused', 'onLeftClick')
            wire(insts.right, 'rightFocused', 'onRightClick')

            new.instances = insts
            return new
        end

        elemClasses.section.addDualButton = function(self, settings, leftCb, rightCb)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local s_left = settings.left or 'left'
            local s_right = settings.right or 'right'

            local db = dualButton:new()
            db.section = self
            db.name = s_left .. ' / ' .. s_right
            table.insert(self.controls, db)

            db.instances.left.Text = s_left
            db.instances.right.Text = s_right
            db.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(leftCb) == 'function') then
                db:bindToEvent('onLeftClick', leftCb)
            end
            if (typeof(rightCb) == 'function') then
                db:bindToEvent('onRightClick', rightCb)
            end
            if (settings.tooltip) then
                db:setTooltip(settings.tooltip)
            end
            return db
        end

        elemClasses.dualButton = dualButton
    end

    do
        local progressBar = {}
        progressBar.__index = progressBar
        setmetatable(progressBar, elemClasses.baseElement)
        progressBar.class = 'progressBar'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local track = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#track',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 20),
                ZIndex = 35
            }, controlFrame)
            makeCorner(track, cornerPx)
            makeStroke(track, theme.Stroke, 1)

            local fill = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                Name = '#fill',
                Size = UDim2.fromScale(0, 1),
                ZIndex = 36
            }, track)
            makeCorner(fill, cornerPx)
            makeGradient(fill, theme.Primary, theme.Secondary, 0)
            makeTopSheen(fill, 37)

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Size = UDim2.new(0.65, 0, 1, 0),
                Text = 'progress',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 38
            }, track)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, label)

            local val = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#val',
                Position = UDim2.fromScale(0.55, 0),
                Size = UDim2.new(0.45, 0, 1, 0),
                Text = '0%',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.72,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 38
            }, track)
            create('UIPadding', {PaddingRight = UDim.new(0, 6)}, val)
        end
        progressBar.instances = instances
        progressBar.value = 0
        progressBar.max = 100
        progressBar.suffix = '%'

        progressBar.setText = function(self, txt)
            self.instances.label.Text = tostring(txt)
            return self
        end

        progressBar.getValue = function(self)
            return self.value
        end

        progressBar.setValue = function(self, val, newMax, customText)
            if (typeof(newMax) == 'number') then
                self.max = newMax
            end
            self.value = math.clamp(val, 0, self.max)
            local ratio = (self.max <= 0) and 0 or (self.value / self.max)
            tween(self.instances.fill, {Size = UDim2.fromScale(ratio, 1)}, 0.22, 1)
            if (customText ~= nil) then
                self.instances.value.Text = tostring(customText)
            elseif (self.suffix == '%') then
                self.instances.value.Text = tostring(math.floor(ratio * 100 + 0.5)) .. '%'
            else
                self.instances.value.Text = tostring(self.value) .. self.suffix
            end
            return self
        end

        progressBar.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.track = insts.controlFrame['#track']
            insts.label = insts.track['#label']
            insts.value = insts.track['#val']
            insts.fill = insts.track['#fill']
            insts.track.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.track.MouseLeave:Connect(function()
                new:hideTooltip()
            end)
            new.instances = insts
            return new
        end

        elemClasses.section.addProgressBar = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local pb = progressBar:new()
            pb.section = self
            pb.name = settings.text or 'progress'
            pb.max = settings.max or 100
            pb.suffix = settings.suffix or '%'
            table.insert(self.controls, pb)

            pb.instances.label.Text = pb.name
            pb:setValue(settings.value or settings.val or 0, pb.max, settings.display)
            pb.instances.controlFrame.Parent = self.instances.controlMenu
            if (settings.tooltip) then
                pb:setTooltip(settings.tooltip)
            end
            return pb
        end

        elemClasses.progressBar = progressBar
    end

    do
        local listbox = {}
        listbox.__index = listbox
        setmetatable(listbox, elemClasses.baseElement)
        listbox.class = 'listbox'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 126),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 15),
                Text = 'list',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6)}, label)

            local box = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Name = '#box',
                Position = UDim2.fromOffset(5, 17),
                Size = UDim2.new(1, -10, 1, -19),
                ZIndex = 35
            }, controlFrame)
            makeCorner(box, cornerPx)
            makeStroke(box, theme.Stroke, 1)

            local searchWrap = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderSizePixel = 0,
                Name = '#search-wrap',
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 36
            }, box)
            create('Frame', {
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 37
            }, searchWrap)

            local searchBox = create('TextBox', {
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = currentFont,
                Name = '#search',
                PlaceholderColor3 = theme.TextDim,
                PlaceholderText = 'filter...',
                Size = UDim2.fromScale(1, 1),
                Text = '',
                TextColor3 = theme.TextPrimary,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 37
            }, searchWrap)
            create('UIPadding', {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, searchBox)

            local list = create('ScrollingFrame', {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = 'rbxassetid://9416839567',
                CanvasSize = UDim2.fromOffset(0, 0),
                MidImage = 'rbxassetid://9416839567',
                Name = '#list',
                Position = UDim2.fromOffset(0, 20),
                ScrollBarImageColor3 = theme.StrokeHover,
                ScrollBarImageTransparency = 0.5,
                ScrollBarThickness = 2,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(1, 0, 1, -20),
                TopImage = 'rbxassetid://9416839567',
                ZIndex = 36
            }, box)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, list)
            create('UIPadding', {
                PaddingTop = UDim.new(0, 3),
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 4)
            }, list)
        end
        listbox.instances = instances

        listbox.getValue = function(self)
            return self.value
        end

        listbox.setValue = function(self, val, silent)
            self.value = val
            for item, btn in pairs(self.itemButtons) do
                local active = (item == val)
                tween(btn, {
                    BackgroundColor3 = active and theme.Button3 or theme.Window3,
                    BackgroundTransparency = active and 0 or 1,
                    TextColor3 = active and theme.TextPrimary or theme.TextDim
                }, 0.14, 1)
                tween(btn['#ind'], {BackgroundTransparency = active and 0 or 1}, 0.14, 1)
            end
            if (not silent) then
                self:fireEvent('onSelect', val)
            end
            return self
        end

        listbox.setItems = function(self, newItems)
            for _, btn in pairs(self.itemButtons) do
                btn:Destroy()
            end
            table.clear(self.itemButtons)
            table.clear(self.items)

            local filter = self.instances.search.Text:lower()
            for idx, item in ipairs(newItems) do
                table.insert(self.items, item)
                local text = tostring(item)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Window3,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = currentFont,
                    LayoutOrder = idx,
                    Name = '#item-' .. idx,
                    Size = UDim2.new(1, 0, 0, 19),
                    Text = text,
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = (filter == '' or text:lower():find(filter, 1, true) ~= nil),
                    ZIndex = 37
                }, self.instances.list)
                makeCorner(btn, cornerPx)
                create('UIPadding', {PaddingLeft = UDim.new(0, 8)}, btn)

                local ind = create('Frame', {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#ind',
                    Position = UDim2.new(0, -8, 0.5, 0),
                    Size = UDim2.new(0, 2, 0, 11),
                    ZIndex = 38
                }, btn)
                makeGradient(ind, theme.Primary, theme.Secondary, 90)

                btn.MouseEnter:Connect(function()
                    if (self.value ~= item) then
                        tween(btn, {BackgroundColor3 = theme.Button2, BackgroundTransparency = 0, TextColor3 = theme.TextPrimary}, 0.12, 1)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if (self.value ~= item) then
                        tween(btn, {BackgroundTransparency = 1, TextColor3 = theme.TextDim}, 0.12, 1)
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    self:setValue(item)
                end)
                self.itemButtons[item] = btn
            end
            if (self.value ~= nil) then
                self:setValue(self.value, true)
            end
            return self
        end
        listbox.refresh = listbox.setItems

        listbox.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            new.items = {}
            new.itemButtons = {}

            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.label = insts.controlFrame['#label']
            insts.box = insts.controlFrame['#box']
            insts.searchWrap = insts.box['#search-wrap']
            insts.search = insts.searchWrap['#search']
            insts.list = insts.box['#list']
            registerNestedScroll(insts.list)

            insts.search:GetPropertyChangedSignal('Text'):Connect(function()
                local q = insts.search.Text:lower()
                for item, btn in pairs(new.itemButtons) do
                    btn.Visible = (q == '' or tostring(item):lower():find(q, 1, true) ~= nil)
                end
            end)
            insts.controlFrame.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.controlFrame.MouseLeave:Connect(function()
                new:hideTooltip()
            end)

            new.instances = insts
            return new
        end

        elemClasses.section.addListbox = function(self, settings, callback)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local lb = listbox:new()
            lb.section = self
            lb.name = settings.text or 'list'
            table.insert(self.controls, lb)

            local height = settings.height or 106
            lb.instances.controlFrame.Size = UDim2.new(1, 0, 0, height + 20)
            lb.instances.label.Text = lb.name

            if (settings.searchable == false) then
                lb.instances.searchWrap.Visible = false
                lb.instances.list.Position = UDim2.fromOffset(0, 0)
                lb.instances.list.Size = UDim2.fromScale(1, 1)
            end

            lb:setItems(settings.items or settings.options or {})
            if (settings.default ~= nil or settings.value ~= nil) then
                lb:setValue(settings.value ~= nil and settings.value or settings.default, true)
            end
            lb.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                lb:bindToEvent('onSelect', callback)
            end
            if (settings.tooltip) then
                lb:setTooltip(settings.tooltip)
            end
            return lb
        end

        elemClasses.listbox = listbox
    end

    do
        local paragraph = {}
        paragraph.__index = paragraph
        setmetatable(paragraph, elemClasses.baseElement)
        paragraph.class = 'paragraph'

        local instances = {}
        do
            local controlFrame = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local card = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#card',
                Position = UDim2.fromOffset(5, 2),
                Size = UDim2.new(1, -10, 0, 0),
                ZIndex = 35
            }, controlFrame)
            makeCorner(card, cornerPx)
            makeStroke(card, theme.Stroke, 1)

            local bar = create('Frame', {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Name = '#accent',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 36
            }, card)
            makeGradient(bar, theme.Primary, theme.Secondary, 90)

            local inner = create('Frame', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = '#inner',
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 36
            }, card)
            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, inner)
            create('UIPadding', {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 6)
            }, inner)

            create('TextLabel', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = currentFont,
                LayoutOrder = 1,
                Name = '#title',
                RichText = true,
                Size = UDim2.new(1, 0, 0, 0),
                Text = 'info',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 36
            }, inner)

            create('TextLabel', {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = currentFont,
                LayoutOrder = 2,
                Name = '#body',
                RichText = true,
                Size = UDim2.new(1, 0, 0, 0),
                Text = '',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 36
            }, inner)

            create('UIPadding', {PaddingBottom = UDim.new(0, 2)}, controlFrame)
        end
        paragraph.instances = instances

        paragraph.setTitle = function(self, t)
            self.instances.title.Text = tostring(t or '')
            self.instances.title.Visible = (self.instances.title.Text ~= '')
            return self
        end

        paragraph.setBody = function(self, b)
            self.instances.body.Text = tostring(b or '')
            return self
        end

        paragraph.setContent = function(self, t, b)
            self:setTitle(t)
            self:setBody(b)
            return self
        end

        paragraph.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.card = insts.controlFrame['#card']
            insts.title = insts.card['#inner']['#title']
            insts.body = insts.card['#inner']['#body']
            insts.card.MouseEnter:Connect(function()
                new:showTooltip()
            end)
            insts.card.MouseLeave:Connect(function()
                new:hideTooltip()
            end)
            new.instances = insts
            return new
        end

        elemClasses.section.addParagraph = function(self, settings)
            if (typeof(settings) ~= 'table') then
                return error('expected type table for settings', 2)
            end
            local p = paragraph:new()
            p.section = self
            p.name = settings.title or settings.text or 'info'
            table.insert(self.controls, p)
            p:setTitle(settings.title or settings.text or '')
            p:setBody(settings.content or settings.body or settings.desc or '')
            p.instances.controlFrame.Parent = self.instances.controlMenu
            if (settings.tooltip) then
                p:setTooltip(settings.tooltip)
            end
            return p
        end

        elemClasses.paragraph = paragraph
    end
end

local function applyFontToTree(root, fontFace)
    if (not root) then return end
    local isFontObj = (typeof(fontFace) == 'Font')
    local function maybeApply(inst)
        if (inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox')) then
            if (isFontObj) then
                inst.FontFace = fontFace
            else
                inst.Font = fontFace
            end
        end
    end
    maybeApply(root)
    for _, desc in ipairs(root:GetDescendants()) do
        maybeApply(desc)
    end
end

local function applyTextScaleToTree(root, scale)
    if (not root) then return end
    local function maybeApply(inst)
        if (inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox')) then
            local base = inst:GetAttribute('BaseTextSize')
            if (typeof(base) ~= 'number') then
                base = inst.TextSize
                inst:SetAttribute('BaseTextSize', base)
            end
            inst.TextSize = math.max(6, math.floor(base * scale + 0.5))
        end
    end
    maybeApply(root)
    for _, desc in ipairs(root:GetDescendants()) do
        maybeApply(desc)
    end
end

do
    ui.__index = ui
    setmetatable(ui, elemClasses.baseElement)
    ui.class = 'ui'

    ui.binds = {}
    ui.windows = {}
    ui.pickerWindows = {}
    ui.notifs = {}
    ui.hotkeys = {}
    ui.scriptCns = {}
    ui._connections = {}
    ui._threads = {}
    ui._terminated = false

    ui.fonts = fontMap
    ui.Fonts = fontMap
    ui.autoDisableToggles = true

    local windows = ui.windows
    local notifs = ui.notifs

    local sessionRecord = {
        active = true,
        title = 'LARPWare',
        createdAt = os.time(),
        screenGui = uiScreen,
        terminate = nil
    }
    globalEnv[REG_KEY] = sessionRecord

    ui.trackConnection = function(con)
        if (con) then
            table.insert(ui._connections, con)
        end
        return con
    end

    ui.trackThread = function(th)
        if (th) then
            table.insert(ui._threads, th)
        end
        return th
    end

    ui.isTerminated = function()
        return ui._terminated == true
    end

    ui.getFonts = function()
        local list = {}
        for _, k in ipairs(fontOrder) do
            table.insert(list, {key = k, name = fontDisplayNames[k] or k, font = fontMap[k]})
        end
        return list
    end

    ui.getFont = function()
        return currentFont
    end

    ui.getFontName = function()
        return currentFontKey
    end

    ui.setFont = function(font)
        local key, fontEnum = resolveFont(font)
        currentFontKey = key
        currentFont = fontEnum

        if (uiScreen) then
            applyFontToTree(uiScreen, fontEnum)
        end
        if (hudScreen) then
            applyFontToTree(hudScreen, fontEnum)
        end
        if (elemClasses) then
            for _, cls in pairs(elemClasses) do
                if (typeof(cls) == 'table' and cls.instances) then
                    for _, inst in pairs(cls.instances) do
                        if (typeof(inst) == 'Instance') then
                            applyFontToTree(inst, fontEnum)
                        end
                    end
                end
            end
        end
        emitFontChanged()
        return currentFont
    end

    ui.getScale = function()
        return currentScale
    end

    ui.setScale = function(scale)
        if (typeof(scale) ~= 'number') then
            return error('expected type number for scale', 2)
        end
        currentScale = math.clamp(scale, 0.5, 2.5)
        local inv = 1 / currentScale

        for _, w in ipairs(ui.windows) do
            if (w.instances) then
                if (w.instances.tabMenu and w.instances.tabMenu:FindFirstChild('#content-scale')) then
                    w.instances.tabMenu['#content-scale'].Scale = currentScale
                    w.instances.tabMenu.Size = UDim2.fromScale(inv, inv)
                end
            end
            for _, m in ipairs(w.menus) do
                if (m.instances and m.instances.menuFrame and m.instances.menuFrame:FindFirstChild('#content-scale')) then
                    m.instances.menuFrame['#content-scale'].Scale = currentScale
                    m.instances.menuFrame.Size = UDim2.fromScale(inv, inv)
                end
            end
        end

        if (elemClasses) then
            if (elemClasses.window and elemClasses.window.instances.mainFrame) then
                local tm = elemClasses.window.instances.mainFrame['#sidebar']['#menu-clip']['#menu']
                if (tm:FindFirstChild('#content-scale')) then
                    tm['#content-scale'].Scale = currentScale
                    tm.Size = UDim2.fromScale(inv, inv)
                end
            end
            if (elemClasses.menu and elemClasses.menu.instances.menuFrame) then
                local mf = elemClasses.menu.instances.menuFrame
                if (mf:FindFirstChild('#content-scale')) then
                    mf['#content-scale'].Scale = currentScale
                    mf.Size = UDim2.fromScale(inv, inv)
                end
            end
        end

        emitScaleChanged()
        return currentScale
    end

    ui.getTextScale = function()
        return currentTextScale
    end

    ui.setTextScale = function(scale)
        if (typeof(scale) ~= 'number') then
            return error('expected type number for text scale', 2)
        end
        currentTextScale = math.clamp(scale, 0.6, 2.0)

        if (uiScreen) then
            applyTextScaleToTree(uiScreen, currentTextScale)
        end
        if (hudScreen) then
            applyTextScaleToTree(hudScreen, currentTextScale)
        end
        if (elemClasses) then
            for _, cls in pairs(elemClasses) do
                if (typeof(cls) == 'table' and cls.instances) then
                    for _, inst in pairs(cls.instances) do
                        if (typeof(inst) == 'Instance') then
                            applyTextScaleToTree(inst, currentTextScale)
                        end
                    end
                end
            end
        end

        emitTextScaleChanged()
        return currentTextScale
    end

    local function attachDefaultPreferenceTab(win, cfgOpts)
        local prefMenu = win:addMenu({
            text = 'Preference',
            icon = 'settings',
            _isDefaultSettings = true
        })
        win._defaultSettingsMenu = prefMenu
        win.preferenceMenu = prefMenu
        win.settingsMenu = prefMenu

        local appearance = prefMenu:addSection({
            text = 'appearance & theme',
            side = 'left',
            showMinButton = true,
            tooltip = 'Fonts, scaling, live accent colors, surface palette, and window style'
        })

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
            val = currentScale,
            tooltip = 'Scales everything inside the window without changing outer window size'
        })

        appearance:addTextScaler({
            text = 'text scale',
            min = 0.6,
            max = 1.8,
            step = 0.05,
            val = currentTextScale,
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
            val = currentTransparency,
            tooltip = 'Adjusts window backdrop translucency in real time'
        }, function(v)
            ui.setTransparency(v)
        end)

        appearance:addToggle({
            text = 'corner rounding',
            state = rounding and true or false,
            tooltip = 'Switches between sharp tactical edges and soft rounded corners live'
        }, function(state)
            ui.setRounding(state)
        end)

        appearance:addToggle({
            text = 'smooth dragging',
            state = animSpeed ~= 0,
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

        local cfgSec = prefMenu:addSection({
            text = 'hud, binds & configs',
            side = 'right',
            showMinButton = true,
            tooltip = 'Menu hotkey, HUD overlays, script-managed configs, and safe unload'
        })

        local menuKey = cfgSec:addHotkey({
            text = 'toggle menu bind',
            bind = Enum.KeyCode.K,
            tooltip = 'Show or hide the window. Click twice while listening to cancel input.'
        })
        menuKey:linkToControl(win)

        local wmVisible = (ui._watermarkFrame and ui._watermarkFrame.Visible) and true or false
        cfgSec:addToggle({
            text = 'watermark',
            state = wmVisible,
            tooltip = 'Toggles the draggable top-left LARPWare status bar'
        }, function(state)
            ui.toggleWatermark(state)
        end)

        local kbVisible = (ui._keybindListFrame and ui._keybindListFrame.Visible) and true or false
        cfgSec:addToggle({
            text = 'keybind list',
            state = kbVisible,
            tooltip = 'Toggles the draggable active keybinds HUD overlay'
        }, function(state)
            ui.toggleKeybindList(state)
        end)

        local mbVisible = (ui._mobileButton and ui._mobileButton.Visible) and true or false
        cfgSec:addToggle({
            text = 'mobile button',
            state = mbVisible,
            tooltip = 'Shows a draggable, resizable floating button to open or close the UI'
        }, function(state)
            ui.toggleMobileButton(state)
        end)

        cfgSec:addToggle({
            text = 'unlock cursor',
            state = enableCursorUnlock and true or false,
            tooltip = 'Forces free mouse movement and tactical cursor override even when ShiftLock is active'
        }, function(state)
            ui.setCursorUnlock(state)
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

        local httpService = game:GetService('HttpService')

        local function trimStr(s)
            return tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')
        end

        local function sanitizeFileName(s)
            local clean = trimStr(s):gsub('[\\/:%*%?"<>|]+', '_'):gsub('%s+', ' ')
            clean = clean:gsub('^%.+', ''):gsub('%.+$', '')
            return clean
        end

        local function ensureFolderPath(folderPath)
            if (typeof(makefolder) ~= 'function') then return false end
            local normalized = tostring(folderPath or ''):gsub('\\', '/'):gsub('^/+', ''):gsub('/+$', '')
            if (normalized == '') then return false end
            local acc = ''
            for part in normalized:gmatch('[^/]+') do
                acc = (acc == '') and part or (acc .. '/' .. part)
                local exists = false
                if (typeof(isfolder) == 'function') then
                    local okCheck, res = pcall(isfolder, acc)
                    exists = okCheck and res == true
                end
                if (not exists) then
                    pcall(makefolder, acc)
                end
            end
            return true
        end

        local cfgState = {
            items = {},
            folder = nil,
            includePreference = false,
            onSave = nil,
            onLoad = nil,
            onDelete = nil,
            onSelect = nil,
            onRefresh = nil,
            memConfigs = {}
        }

        if (cfgOpts ~= false) then
            local initCfg = (typeof(cfgOpts) == 'table') and cfgOpts or {}
            local hasInitialItems = (initCfg.items ~= nil or initCfg.options ~= nil)
            cfgState.items = initCfg.items or initCfg.options or {}
            cfgState.folder = initCfg.folder
            cfgState.includePreference = initCfg.includePreference == true
            cfgState.onSave = initCfg.onSave
            cfgState.onLoad = initCfg.onLoad
            cfgState.onDelete = initCfg.onDelete
            cfgState.onSelect = initCfg.onSelect
            cfgState.onRefresh = initCfg.onRefresh

            local function getConfigFolder()
                if (typeof(cfgState.folder) == 'string' and trimStr(cfgState.folder) ~= '') then
                    return trimStr(cfgState.folder):gsub('\\', '/'):gsub('/+$', '')
                end
                local rawTitle = (win.instances and win.instances.title and win.instances.title.Text) or 'default'
                local safeTitle = sanitizeFileName(rawTitle)
                if (safeTitle == '') then
                    safeTitle = 'default'
                end
                return 'LARPWare/configs/' .. safeTitle
            end

            local function getConfigPath(name)
                return getConfigFolder() .. '/' .. name .. '.json'
            end

            local function collectControls(fn)
                for _, m in ipairs(win.menus or {}) do
                    if (cfgState.includePreference or not m._isDefaultSettings) then
                        local mName = tostring(m.name or 'menu')
                        for _, sec in ipairs(m.sections or {}) do
                            local sName = tostring(sec.name or 'section')
                            local seen = {}
                            for _, ctrl in ipairs(sec.controls or {}) do
                                local cls = ctrl.class
                                if (cls == 'toggle' or cls == 'slider' or cls == 'rangeSlider' or cls == 'dropdown' or cls == 'multiDropdown' or cls == 'segmented' or cls == 'textbox' or cls == 'listbox' or cls == 'picker' or cls == 'hotkey') then
                                    local baseKey = (typeof(ctrl.flag) == 'string' and ctrl.flag ~= '') and ctrl.flag or (mName .. '::' .. sName .. '::' .. cls .. '::' .. tostring(ctrl.name or 'control'))
                                    seen[baseKey] = (seen[baseKey] or 0) + 1
                                    local key = (seen[baseKey] == 1) and baseKey or (baseKey .. '#' .. tostring(seen[baseKey]))
                                    fn(key, ctrl)
                                end
                            end
                        end
                    end
                end
            end

            win.serializeConfig = function()
                local data = {}
                collectControls(function(key, ctrl)
                    local cls = ctrl.class
                    if (cls == 'toggle') then
                        data[key] = ctrl.toggled == true
                    elseif (cls == 'slider') then
                        data[key] = ctrl.value
                    elseif (cls == 'rangeSlider') then
                        data[key] = {low = ctrl.low, high = ctrl.high}
                    elseif (cls == 'dropdown') then
                        data[key] = ctrl.value
                    elseif (cls == 'multiDropdown') then
                        data[key] = ctrl:getValues()
                    elseif (cls == 'segmented') then
                        data[key] = ctrl.value
                    elseif (cls == 'textbox') then
                        data[key] = ctrl:getText()
                    elseif (cls == 'listbox') then
                        data[key] = ctrl:getValue()
                    elseif (cls == 'picker') then
                        local c = ctrl:getColor()
                        if (typeof(c) == 'Color3') then
                            data[key] = {r = c.R, g = c.G, b = c.B}
                        end
                    elseif (cls == 'hotkey') then
                        data[key] = ctrl.hotkey and ctrl.hotkey.Name or ''
                    end
                end)
                return data
            end

            win.applyConfig = function(_, data)
                if (typeof(data) ~= 'table') then return false end
                collectControls(function(key, ctrl)
                    local val = data[key]
                    if (val == nil) then return end
                    local cls = ctrl.class
                    if (cls == 'toggle' and typeof(val) == 'boolean') then
                        if (val) then
                            pcall(function() ctrl:enable(false) end)
                        else
                            pcall(function() ctrl:disable(false) end)
                        end
                    elseif (cls == 'slider' and typeof(val) == 'number') then
                        pcall(function() ctrl:setValue(val, false) end)
                    elseif (cls == 'rangeSlider' and typeof(val) == 'table' and typeof(val.low) == 'number' and typeof(val.high) == 'number') then
                        pcall(function() ctrl:setRange(val.low, val.high, false) end)
                    elseif (cls == 'dropdown') then
                        pcall(function() ctrl:setValue(val, false) end)
                    elseif (cls == 'multiDropdown' and typeof(val) == 'table') then
                        pcall(function() ctrl:setValues(val, false) end)
                    elseif (cls == 'segmented') then
                        pcall(function() ctrl:setValue(val, false) end)
                    elseif (cls == 'textbox' and typeof(val) == 'string') then
                        pcall(function() ctrl:setText(val) end)
                    elseif (cls == 'listbox') then
                        pcall(function() ctrl:setValue(val, false) end)
                    elseif (cls == 'picker' and typeof(val) == 'table' and typeof(val.r) == 'number' and typeof(val.g) == 'number' and typeof(val.b) == 'number') then
                        local col = Color3.new(math.clamp(val.r, 0, 1), math.clamp(val.g, 0, 1), math.clamp(val.b, 0, 1))
                        pcall(function()
                            ctrl:setColor(col)
                            ctrl:fireEvent('onNewColor', col)
                        end)
                    elseif (cls == 'hotkey' and typeof(val) == 'string') then
                        if (val == '') then
                            pcall(function() ctrl:setHotkey(nil) end)
                        elseif (Enum.KeyCode[val]) then
                            pcall(function() ctrl:setHotkey(Enum.KeyCode[val]) end)
                        end
                    end
                end)
                if (ui.refreshKeybindList) then
                    ui.refreshKeybindList(true)
                end
                return true
            end

            local function scanDiskConfigs()
                local foundMap = {}
                local folder = getConfigFolder()
                local folderExists = true
                if (typeof(isfolder) == 'function') then
                    local okDir, resDir = pcall(isfolder, folder)
                    folderExists = okDir and resDir == true
                end
                if (folderExists and typeof(listfiles) == 'function') then
                    local okList, files = pcall(listfiles, folder)
                    if (okList and typeof(files) == 'table') then
                        for _, fp in ipairs(files) do
                            local norm = tostring(fp):gsub('\\', '/')
                            local fname = norm:match('([^/]+)$') or norm
                            local base = fname:match('^(.+)%.json$')
                            if (base and base ~= '') then
                                foundMap[base] = true
                            end
                        end
                    end
                end
                for k in pairs(cfgState.memConfigs) do
                    foundMap[k] = true
                end
                local names = {}
                for k in pairs(foundMap) do
                    table.insert(names, k)
                end
                table.sort(names, function(a, b)
                    return a:lower() < b:lower()
                end)
                return names
            end

            cfgSec:addDivider('profiles')

            local cfgName = cfgSec:addTextbox({
                text = 'config name',
                placeholder = initCfg.placeholder or 'new config name...',
                tooltip = 'Name used when saving a configuration profile'
            })

            local cfgList = cfgSec:addListbox({
                text = 'saved configs',
                items = cfgState.items,
                default = initCfg.default,
                searchable = initCfg.searchable == true,
                height = initCfg.height or 96,
                tooltip = 'Select a saved configuration profile'
            }, function(cfg)
                if (typeof(cfgState.onSelect) == 'function') then
                    cfgState.onSelect(cfg)
                end
                win:fireEvent('onConfigSelect', cfg)
            end)

            win.setConfigs = function(_, items, selected)
                cfgState.items = (typeof(items) == 'table') and items or {}
                cfgList:setItems(cfgState.items)
                if (cfgList.instances and cfgList.instances.list) then
                    cfgList.instances.list.CanvasPosition = Vector2.new(0, 0)
                end
                if (selected ~= nil) then
                    cfgList:setValue(selected, true)
                end
                return win
            end

            win.getConfigs = function()
                return cfgState.items
            end

            win.getSelectedConfig = function()
                return cfgList:getValue()
            end

            win.getConfigName = function()
                local tx = trimStr(cfgName:getText())
                if (tx ~= '') then
                    return tx
                end
                local sel = cfgList:getValue()
                return sel and tostring(sel) or ''
            end

            win.refreshConfigs = function(_, silent)
                local curSel = cfgList:getValue()
                if (typeof(cfgState.onRefresh) == 'function') then
                    local okRef, res = pcall(cfgState.onRefresh)
                    if (okRef and typeof(res) == 'table') then
                        local keepSel = (curSel ~= nil and table.find(res, curSel)) and curSel or nil
                        win:setConfigs(res, keepSel)
                    end
                    win:fireEvent('onConfigRefresh', cfgState.items)
                    if (not silent) then
                        ui.notify({
                            title = 'configs',
                            message = 'Refreshed config list (' .. tostring(#cfgState.items) .. ')',
                            duration = 2
                        })
                    end
                    return cfgState.items
                end
                local names = scanDiskConfigs()
                local keepSel = (curSel ~= nil and table.find(names, curSel)) and curSel or nil
                win:setConfigs(names, keepSel)
                win:fireEvent('onConfigRefresh', names)
                if (not silent) then
                    ui.notify({
                        title = 'configs',
                        message = 'Refreshed config list (' .. tostring(#names) .. ' found)',
                        duration = 2
                    })
                end
                return names
            end

            win.saveConfig = function(_, rawName, silent)
                local safeName = sanitizeFileName(rawName)
                if (safeName == '') then
                    if (not silent) then
                        ui.notify({
                            title = 'configs',
                            message = 'Enter a config name before saving',
                            duration = 2.5
                        })
                    end
                    return false
                end
                local payload = win:serializeConfig()
                cfgState.memConfigs[safeName] = payload
                local wroteDisk = false
                if (typeof(writefile) == 'function') then
                    local folder = getConfigFolder()
                    ensureFolderPath(folder)
                    local okEnc, encoded = pcall(function()
                        return httpService:JSONEncode(payload)
                    end)
                    if (okEnc and typeof(encoded) == 'string') then
                        local okWrite = pcall(writefile, getConfigPath(safeName), encoded)
                        wroteDisk = okWrite == true
                    end
                end
                local names = scanDiskConfigs()
                if (not table.find(names, safeName)) then
                    table.insert(names, safeName)
                    table.sort(names, function(a, b) return a:lower() < b:lower() end)
                end
                win:setConfigs(names, safeName)
                cfgName:setText('')
                if (not silent) then
                    ui.notify({
                        title = 'configs',
                        message = wroteDisk and ('Saved config: ' .. safeName) or ('Saved config (session): ' .. safeName),
                        duration = 2.2
                    })
                end
                return true
            end

            win.loadConfig = function(_, rawName, silent)
                local safeName = sanitizeFileName(rawName)
                if (safeName == '') then
                    if (not silent) then
                        ui.notify({
                            title = 'configs',
                            message = 'Select a config to load',
                            duration = 2.5
                        })
                    end
                    return false
                end
                local data = nil
                if (typeof(readfile) == 'function') then
                    local fp = getConfigPath(safeName)
                    local exists = true
                    if (typeof(isfile) == 'function') then
                        local okIs, resIs = pcall(isfile, fp)
                        exists = okIs and resIs == true
                    end
                    if (exists) then
                        local okRead, raw = pcall(readfile, fp)
                        if (okRead and typeof(raw) == 'string' and raw ~= '') then
                            local okDec, decoded = pcall(function()
                                return httpService:JSONDecode(raw)
                            end)
                            if (okDec and typeof(decoded) == 'table') then
                                data = decoded
                                cfgState.memConfigs[safeName] = decoded
                            end
                        end
                    end
                end
                if (not data) then
                    data = cfgState.memConfigs[safeName]
                end
                if (not data) then
                    if (not silent) then
                        ui.notify({
                            title = 'configs',
                            message = 'Config not found: ' .. safeName,
                            duration = 2.5
                        })
                    end
                    return false
                end
                win:applyConfig(data)
                if (not silent) then
                    ui.notify({
                        title = 'configs',
                        message = 'Loaded config: ' .. safeName,
                        duration = 2.2
                    })
                end
                return true
            end

            win.deleteConfig = function(_, rawName, silent)
                local safeName = sanitizeFileName(rawName)
                if (safeName == '') then
                    if (not silent) then
                        ui.notify({
                            title = 'configs',
                            message = 'Select a config to delete',
                            duration = 2.5
                        })
                    end
                    return false
                end
                cfgState.memConfigs[safeName] = nil
                if (typeof(delfile) == 'function') then
                    local fp = getConfigPath(safeName)
                    local exists = true
                    if (typeof(isfile) == 'function') then
                        local okIs, resIs = pcall(isfile, fp)
                        exists = okIs and resIs == true
                    end
                    if (exists) then
                        pcall(delfile, fp)
                    end
                end
                local names = scanDiskConfigs()
                win:setConfigs(names, names[1])
                if (not silent) then
                    ui.notify({
                        title = 'configs',
                        message = 'Deleted config: ' .. safeName,
                        duration = 2.2
                    })
                end
                return true
            end

            local saveLoadBtns = cfgSec:addDualButton({
                left = 'save config',
                right = 'load config',
                tooltip = 'Save current settings or load the highlighted profile'
            }, function()
                local name = trimStr(cfgName:getText())
                local sel = cfgList:getValue()
                if (name == '') then
                    name = sel and tostring(sel) or ''
                end
                local hasCustomSave = (typeof(cfgState.onSave) == 'function') or (win.binds and win.binds.onConfigSave ~= nil)
                if (hasCustomSave) then
                    if (typeof(cfgState.onSave) == 'function') then
                        cfgState.onSave(name, sel)
                    end
                    win:fireEvent('onConfigSave', name, sel)
                else
                    win:saveConfig(name, false)
                    win:fireEvent('onConfigSave', name, sel)
                end
            end, function()
                local sel = cfgList:getValue()
                local name = trimStr(cfgName:getText())
                local target = (sel ~= nil and tostring(sel) ~= '') and tostring(sel) or name
                local hasCustomLoad = (typeof(cfgState.onLoad) == 'function') or (win.binds and win.binds.onConfigLoad ~= nil)
                if (hasCustomLoad) then
                    if (typeof(cfgState.onLoad) == 'function') then
                        cfgState.onLoad(sel, name)
                    end
                    win:fireEvent('onConfigLoad', sel, name)
                else
                    win:loadConfig(target, false)
                    win:fireEvent('onConfigLoad', target, name)
                end
            end)

            local refreshDeleteBtns = cfgSec:addDualButton({
                left = 'refresh list',
                right = 'delete config',
                tooltip = 'Reload saved config files or delete the currently selected profile'
            }, function()
                win:refreshConfigs(false)
            end, function()
                local sel = cfgList:getValue()
                local hasCustomDelete = (typeof(cfgState.onDelete) == 'function') or (win.binds and win.binds.onConfigDelete ~= nil)
                if (hasCustomDelete) then
                    if (typeof(cfgState.onDelete) == 'function') then
                        cfgState.onDelete(sel)
                    end
                    win:fireEvent('onConfigDelete', sel)
                else
                    win:deleteConfig(sel, false)
                    win:fireEvent('onConfigDelete', sel)
                end
            end)

            win.configControls = {
                nameBox = cfgName,
                list = cfgList,
                buttons = saveLoadBtns,
                actionButtons = refreshDeleteBtns,
                refreshButton = refreshDeleteBtns.instances.left,
                deleteButton = refreshDeleteBtns.instances.right
            }

            win.configureConfigs = function(_, opts)
                if (typeof(opts) ~= 'table') then return win end
                if (opts.folder ~= nil) then cfgState.folder = opts.folder end
                if (opts.includePreference ~= nil) then cfgState.includePreference = opts.includePreference == true end
                if (opts.onSave ~= nil) then cfgState.onSave = opts.onSave end
                if (opts.onLoad ~= nil) then cfgState.onLoad = opts.onLoad end
                if (opts.onDelete ~= nil) then cfgState.onDelete = opts.onDelete end
                if (opts.onSelect ~= nil) then cfgState.onSelect = opts.onSelect end
                if (opts.onRefresh ~= nil) then cfgState.onRefresh = opts.onRefresh end
                if (opts.placeholder and cfgName.instances and cfgName.instances.textBox) then
                    cfgName.instances.textBox.PlaceholderText = tostring(opts.placeholder)
                end
                if (opts.items ~= nil or opts.options ~= nil) then
                    win:setConfigs(opts.items or opts.options, opts.default ~= nil and opts.default or opts.value)
                elseif (opts.folder ~= nil and typeof(cfgState.onRefresh) ~= 'function') then
                    win:refreshConfigs(true)
                    if (opts.default ~= nil or opts.value ~= nil) then
                        cfgList:setValue(opts.default ~= nil and opts.default or opts.value, true)
                    end
                elseif (opts.default ~= nil or opts.value ~= nil) then
                    cfgList:setValue(opts.default ~= nil and opts.default or opts.value, true)
                end
                return win
            end

            if (not hasInitialItems) then
                win:refreshConfigs(true)
            end
        end

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

        cfgSec:addButton({
            text = 'unload ui',
            style = 'large',
            tooltip = 'Cleanly terminates all connections, toggles, keybinds, and removes the UI'
        }, function()
            ui.terminate()
        end)

        return prefMenu
    end

    ui.newWindow = function(settings)
        if (typeof(settings) ~= 'table') then
            return error('expected type table for settings', 2)
        end

        local s_title = settings.text or 'LARPWare'
        local s_resize = settings.resize or false
        local s_showSettings = settings.showSettings
        local s_showSearch = settings.showSearch
        local s_defaultPref = settings.defaultPreference
        if (s_defaultPref == nil) then
            s_defaultPref = settings.defaultSettings
        end
        s_defaultPref = (s_defaultPref == nil) and true or (s_defaultPref and true or false)
        local s_position = settings.position
        if (not s_position) then
            s_position = defaultWinPos
            defaultWinPos += UDim2.fromScale(0.02, 0.02)
        end

        local win = elemClasses.window:new(s_resize, s_showSettings, s_showSearch)

        local s_winSize = settings.size or win.size
        if (typeof(s_winSize) == 'Vector2') then
            s_winSize = UDim2.fromOffset(s_winSize.X, s_winSize.Y)
        end
        local s_icon = settings.icon

        if (s_icon) then
            win:setIcon(s_icon)
        end
        win:setPosition(s_position)
        win:setTitle(s_title)
        win.size = s_winSize
        win:fitToViewport(settings.position == nil)
        if (sessionRecord) then
            sessionRecord.title = tostring(s_title)
        end

        if (s_defaultPref) then
            attachDefaultPreferenceTab(win, settings.configs)
        end

        local s_intro = (settings.intro == nil) and enableIntro or (settings.intro and true or false)
        if (s_intro) then
            playLarpIntro(win, false)
        end
        if (ui._syncScreenState) then
            ui._syncScreenState()
        end

        task.spawn(function()
            local insts = win.instances
            local mainFrame = insts.mainFrame
            local titleBar = insts.titleBar

            mainFrame.Size = UDim2.fromOffset(s_winSize.X.Offset, 29)
            tween(mainFrame, {Size = s_winSize}, 0.4, 1)

            task.spawn(function()
                local fade = titleBar['#fade']
                fade.BackgroundTransparency = 0
                fade.Visible = true
                tween(fade, {BackgroundTransparency = 1}, 0.6, 1).Completed:Wait()
                fade.Visible = false
            end)
        end)

        return win
    end

    ui.terminate = function()
        if (ui._terminated) then return end
        ui._terminated = true
        sessionRecord.active = false
        if (globalEnv[REG_KEY] == sessionRecord) then
            globalEnv[REG_KEY] = nil
        end

        if (ui.binds.onTerminate) then
            pcall(ui.binds.onTerminate)
        end
        if (ui.binds.onPreDestroy) then
            pcall(ui.binds.onPreDestroy)
        end

        for _, win in ipairs(windows) do
            if (win._wheelCon) then
                pcall(function() win._wheelCon:Disconnect() end)
                win._wheelCon = nil
            end
            for _, m in ipairs(win.menus or {}) do
                for _, sec in ipairs(m.sections or {}) do
                    for _, ctrl in ipairs(sec.controls or {}) do
                        if (ctrl.class == 'picker') then
                            if (ctrl.chromaCon) then
                                pcall(function() ctrl.chromaCon:Disconnect() end)
                                ctrl.chromaCon = nil
                            end
                            local pwin = ctrl.pickerWindow
                            if (pwin) then
                                if (pwin.chromaCon) then
                                    pcall(function() pwin.chromaCon:Disconnect() end)
                                    pwin.chromaCon = nil
                                end
                                pcall(function()
                                    pwin:bindToEvent('close', nil)
                                    pwin:destroy()
                                end)
                            end
                        elseif (ctrl.class == 'toggle') then
                            if (ctrl.toggled) then
                                pcall(function() ctrl:disable() end)
                            end
                        end
                    end
                end
            end
        end

        if (tooltip.update) then
            pcall(function() tooltip.update:Disconnect() end)
            tooltip.update = nil
        end
        if (ui.hkCon) then
            pcall(function() ui.hkCon:Disconnect() end)
            ui.hkCon = nil
        end
        for _, hk in ipairs(ui.hotkeys) do
            if (hk.inputCon) then
                pcall(function() hk.inputCon:Disconnect() end)
                hk.inputCon = nil
            end
        end
        for _, con in ipairs(ui._connections) do
            pcall(function() con:Disconnect() end)
        end
        for _, con in pairs(ui.scriptCns) do
            pcall(function() con:Disconnect() end)
        end
        for _, th in ipairs(ui._threads) do
            pcall(task.cancel, th)
        end

        table.clear(ui._connections)
        table.clear(ui._threads)
        table.clear(ui.scriptCns)
        table.clear(ui.hotkeys)
        table.clear(windows)
        table.clear(ui.pickerWindows)
        table.clear(notifs)
        table.clear(fontListeners)
        table.clear(scaleListeners)
        table.clear(textScaleListeners)
        table.clear(themeListeners)
        table.clear(easterEggLabels)
        table.clear(nestedScrolls)

        if (elemClasses) then
            for _, v in pairs(elemClasses) do
                if (typeof(v) == 'table' and v.instances) then
                    for _, inst in pairs(v.instances) do
                        if (typeof(inst) == 'Instance') then
                            pcall(function() inst:Destroy() end)
                        end
                    end
                end
            end
            elemClasses = nil
        end

        if (tooltip.instances and tooltip.instances.main) then
            pcall(function() tooltip.instances.main:Destroy() end)
        end
        if (hint.instances and hint.instances.main) then
            pcall(function() hint.instances.main:Destroy() end)
        end
        if (ui._watermarkFrame) then
            pcall(function() ui._watermarkFrame:Destroy() end)
            ui._watermarkFrame = nil
        end
        if (ui._keybindListFrame) then
            pcall(function() ui._keybindListFrame:Destroy() end)
            ui._keybindListFrame = nil
        end
        if (ui._mobileButton) then
            pcall(function() ui._mobileButton:Destroy() end)
            ui._mobileButton = nil
        end
        if (uiScreen) then
            pcall(function() uiScreen:Destroy() end)
            uiScreen = nil
        end
        if (hudScreen) then
            pcall(function() hudScreen:Destroy() end)
            hudScreen = nil
        end
        cursorTerminated = true
        syncCursorUnlock(false)
        if (cursorScreen) then
            pcall(function() cursorScreen:Destroy() end)
            cursorScreen = nil
        end

        if (ui.binds.onDestroy) then
            pcall(ui.binds.onDestroy)
        end
    end
    sessionRecord.terminate = ui.terminate

    ui.destroy = function(noWindows)
        if (ui._terminated) then return end
        ui._terminated = true
        cursorTerminated = true
        syncCursorUnlock(false)
        sessionRecord.active = false
        if (globalEnv[REG_KEY] == sessionRecord) then
            globalEnv[REG_KEY] = nil
        end

        ui:fireEvent('onPreDestroy')

        task.delay(0.4, function()
            if (uiScreen) then
                uiScreen:Destroy()
                uiScreen = nil
            end
            if (hudScreen) then
                hudScreen:Destroy()
                hudScreen = nil
            end
            if (cursorScreen) then
                cursorScreen:Destroy()
                cursorScreen = nil
            end
        end)

        if (noWindows ~= true) then
            for _, win in ipairs(windows) do
                win:destroy()
            end
        end

        if (elemClasses) then
            for _, v in pairs(elemClasses) do
                if (typeof(v) == 'table' and v.instances) then
                    for _, inst in pairs(v.instances) do
                        if (typeof(inst) == 'Instance') then
                            inst:Destroy()
                        end
                    end
                end
            end
        end

        if (tooltip.update) then
            tooltip.update:Disconnect()
            tooltip.update = nil
        end
        if (ui.hkCon) then
            ui.hkCon:Disconnect()
            ui.hkCon = nil
        end
        for _, hk in ipairs(ui.hotkeys) do
            if (hk.inputCon) then
                hk.inputCon:Disconnect()
            end
        end
        for _, con in ipairs(ui._connections) do
            pcall(function() con:Disconnect() end)
        end
        for _, th in ipairs(ui._threads) do
            pcall(task.cancel, th)
        end

        elemClasses = nil
        if (tooltip.instances and tooltip.instances.main) then
            tooltip.instances.main:Destroy()
        end
        if (hint.instances and hint.instances.main) then
            hint.instances.main:Destroy()
        end
        if (ui._watermarkFrame) then
            ui._watermarkFrame:Destroy()
            ui._watermarkFrame = nil
        end
        if (ui._keybindListFrame) then
            ui._keybindListFrame:Destroy()
            ui._keybindListFrame = nil
        end
        if (ui._mobileButton) then
            ui._mobileButton:Destroy()
            ui._mobileButton = nil
        end

        ui:fireEvent('onDestroy')
        for _, v in pairs(ui.scriptCns) do
            v:Disconnect()
        end
    end

    local function applyThemeToTree(root)
        if (not root) then return end
        local function applyOne(inst)
            if (inst:IsA('UIGradient') and inst:GetAttribute('ThemeAccentGrad') == true) then
                inst.Color = ColorSequence.new(theme.Primary, theme.Secondary)
                return
            end
            if (inst:IsA('UIStroke')) then
                local sk = inst:GetAttribute('ThemeStroke')
                if (sk and theme[sk]) then
                    inst.Color = theme[sk]
                end
                return
            end
            local bgk = inst:GetAttribute('ThemeBG')
            if (bgk and theme[bgk] and inst:IsA('GuiObject')) then
                inst.BackgroundColor3 = theme[bgk]
            end
            local bdk = inst:GetAttribute('ThemeBorder')
            if (bdk and theme[bdk] and inst:IsA('GuiObject')) then
                inst.BorderColor3 = theme[bdk]
            end
            local tk = inst:GetAttribute('ThemeText')
            if (tk and theme[tk] and (inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox'))) then
                inst.TextColor3 = theme[tk]
            end
            local sck = inst:GetAttribute('ThemeScroll')
            if (sck and theme[sck] and inst:IsA('ScrollingFrame')) then
                inst.ScrollBarImageColor3 = theme[sck]
            end
        end
        applyOne(root)
        for _, desc in ipairs(root:GetDescendants()) do
            applyOne(desc)
        end
    end

    local function resyncDynamicThemeStates()
        for _, w in ipairs(windows) do
            if (w.instances and w.instances.mainFrame and w.instances.mainFrame.Parent) then
                if (w.settingsOpen and w.instances.buttonSettings) then
                    w.instances.buttonSettings.BackgroundColor3 = theme.Button3
                    w.instances.buttonSettings['#stroke'].Color = theme.Primary
                end
                if (w.searchOpen and w.instances.buttonSearch) then
                    w.instances.buttonSearch.BackgroundColor3 = theme.Button3
                    w.instances.buttonSearch['#stroke'].Color = theme.Primary
                end
                if (w.instances.mainFrame:FindFirstChild('#background')) then
                    w.instances.mainFrame['#background'].BackgroundTransparency = currentTransparency
                end
                if (w.instances.pageRegion) then
                    w.instances.pageRegion.BackgroundTransparency = currentTransparency * 0.65
                end
                if (w.instances.sideBar) then
                    w.instances.sideBar.BackgroundTransparency = currentTransparency * 0.55
                end
                if (w.instances.activePill and w.instances.activePill.Parent) then
                    w.instances.activePill.BackgroundColor3 = theme.Button3
                    w.instances.activePill['#stroke'].Color = theme.StrokeHover
                    w.instances.activePill['#active-bg'].BackgroundColor3 = theme.Primary
                    w.instances.activePill['#active-dot'].BackgroundColor3 = theme.Primary
                end
            end
            for _, m in ipairs(w.menus or {}) do
                local ps = m.instances and m.instances.pageSelector
                if (ps and ps.Parent) then
                    if (m.selected) then
                        ps['#label'].TextColor3 = theme.TextPrimary
                        setTabGlyphColor(ps['#icon-wrap'], theme.Primary, 0)
                    else
                        ps['#label'].TextColor3 = theme.TextDim
                        setTabGlyphColor(ps['#icon-wrap'], theme.TextDim, 0)
                    end
                end
                for _, sec in ipairs(m.sections or {}) do
                    for _, ctrl in ipairs(sec.controls or {}) do
                        if (ctrl.class == 'toggle' and ctrl.instances and ctrl.instances.label) then
                            ctrl.instances.label.TextColor3 = ctrl.toggled and theme.TextPrimary or blendColor(theme.TextDim, theme.TextPrimary, 0.45)
                            if (ctrl.instances.box and ctrl.instances.box:FindFirstChild('#stroke')) then
                                ctrl.instances.box['#stroke'].Color = ctrl.toggled and theme.Primary or theme.Stroke
                            end
                        elseif (ctrl.class == 'segmented' and ctrl.optionButtons) then
                            for opt, btn in pairs(ctrl.optionButtons) do
                                local active = (ctrl.value == opt)
                                btn.BackgroundColor3 = active and theme.Button3 or theme.Inset1
                                btn.TextColor3 = active and theme.TextPrimary or theme.TextDim
                            end
                        elseif (ctrl.class == 'listbox' and ctrl.itemButtons) then
                            for item, btn in pairs(ctrl.itemButtons) do
                                local active = (ctrl.value == item)
                                btn.BackgroundColor3 = active and theme.Button3 or theme.Button1
                                btn.TextColor3 = active and theme.TextPrimary or theme.TextDim
                            end
                        end
                    end
                end
            end
        end
        if (ui.refreshKeybindList) then
            ui.refreshKeybindList(true)
        end
        if (ui.syncMobileButtonState) then
            ui.syncMobileButtonState()
        end
    end

    ui.getTheme = function()
        local copy = {}
        for k, v in pairs(theme) do
            copy[k] = v
        end
        return copy
    end

    ui.getThemes = function()
        local out = {}
        for i = 1, #themePresetOrder do
            out[i] = themePresetOrder[i]
        end
        return out
    end

    ui.getThemeName = function()
        return currentThemeName
    end

    ui.applyTheme = function(patch, presetName)
        if (typeof(patch) ~= 'table') then
            return error('expected type table for theme', 2)
        end
        for k, v in pairs(patch) do
            theme[k] = v
        end
        if (presetName) then
            currentThemeName = presetName
        else
            currentThemeName = 'custom'
        end
        if (uiScreen) then
            applyThemeToTree(uiScreen)
        end
        if (hudScreen) then
            applyThemeToTree(hudScreen)
        end
        if (cursorScreen) then
            applyThemeToTree(cursorScreen)
        end
        if (elemClasses) then
            for _, cls in pairs(elemClasses) do
                if (typeof(cls) == 'table' and cls.instances) then
                    for _, inst in pairs(cls.instances) do
                        if (typeof(inst) == 'Instance') then
                            applyThemeToTree(inst)
                        end
                    end
                end
            end
        end
        resyncDynamicThemeStates()
        emitThemeChanged()
        return ui.getTheme()
    end

    ui.setTheme = function(newTheme)
        if (typeof(newTheme) == 'string') then
            return ui.setThemePreset(newTheme)
        end
        return ui.applyTheme(newTheme)
    end

    ui.setThemePreset = function(name)
        local key = tostring(name or ''):lower()
        local preset = themePresets[key]
        if (not preset) then
            return ui.getTheme()
        end
        return ui.applyTheme(preset, key)
    end

    ui.setAccent = function(primary, secondary)
        if (typeof(primary) ~= 'Color3') then
            return error('expected Color3 for primary accent', 2)
        end
        local sec = (typeof(secondary) == 'Color3') and secondary or blendColor(primary, Color3.fromRGB(0, 0, 0), 0.38)
        local base = theme.Window3 or Color3.fromRGB(11, 11, 12)
        local function shift(c, d)
            return Color3.new(math.clamp(c.R + d, 0, 1), math.clamp(c.G + d, 0, 1), math.clamp(c.B + d, 0, 1))
        end
        return ui.applyTheme({
            Primary = primary,
            Secondary = sec,
            Button3 = blendColor(shift(base, 0.025), primary, 0.14),
            Button4 = blendColor(shift(base, 0.045), primary, 0.22),
            StrokeHover = blendColor(shift(base, 0.08), primary, 0.45)
        }, 'custom')
    end

    ui.setSurfaceColor = function(baseColor)
        if (typeof(baseColor) ~= 'Color3') then
            return error('expected Color3 for surface color', 2)
        end
        local derived = makePresetTheme(theme.Primary, theme.Secondary, baseColor)
        derived.TextPrimary = theme.TextPrimary
        derived.TextDim = theme.TextDim
        derived.TextStroke = theme.TextStroke
        return ui.applyTheme(derived, 'custom')
    end

    ui.setThemeColor = function(key, color)
        if (typeof(key) ~= 'string' or typeof(color) ~= 'Color3') then
            return error('expected (string, Color3) for setThemeColor', 2)
        end
        if (key == 'Primary') then
            return ui.setAccent(color, theme.Secondary)
        elseif (key == 'Secondary') then
            return ui.setAccent(theme.Primary, color)
        end
        return ui.applyTheme({[key] = color}, 'custom')
    end

    ui.getTransparency = function()
        return currentTransparency
    end

    ui.setTransparency = function(alpha)
        if (typeof(alpha) ~= 'number') then
            return error('expected number for transparency', 2)
        end
        currentTransparency = math.clamp(alpha, 0, 0.45)
        resyncDynamicThemeStates()
        return currentTransparency
    end

    ui.setRounding = function(enabled)
        rounding = enabled and true or false
        cornerPx = rounding and 4 or 0
        local function updateCorners(root)
            if (not root) then return end
            for _, desc in ipairs(root:GetDescendants()) do
                if (desc:IsA('UICorner') and desc:GetAttribute('ThemeCorner') == true) then
                    desc.CornerRadius = UDim.new(0, cornerPx)
                end
            end
        end
        updateCorners(uiScreen)
        updateCorners(hudScreen)
        if (elemClasses) then
            for _, cls in pairs(elemClasses) do
                if (typeof(cls) == 'table' and cls.instances) then
                    for _, inst in pairs(cls.instances) do
                        if (typeof(inst) == 'Instance') then
                            updateCorners(inst)
                        end
                    end
                end
            end
        end
        return rounding
    end

    ui.setSmoothDragging = function(enabled)
        animSpeed = (enabled and true or false) and 1e-12 or 0
        return enabled and true or false
    end

    ui.getCursorUnlock = function()
        return enableCursorUnlock and true or false
    end

    ui.setCursorUnlock = function(enabled)
        enableCursorUnlock = enabled and true or false
        if (ui._syncScreenState) then
            ui._syncScreenState()
        else
            syncCursorUnlock(enableCursorUnlock)
        end
        return enableCursorUnlock
    end

    ui.playIntro = function(targetWin)
        local w = targetWin or windows[1]
        if (w) then
            playLarpIntro(w, true)
        end
    end

    ui.popup = function(settings)
        if (typeof(settings) ~= 'table') then
            return error('expected type table for popup settings', 2)
        end
        local w = settings.window or windows[1]
        if (w) then
            return w:popup(settings)
        end
        return nil
    end
    ui.showPopup = ui.popup

    ui.resetTheme = function()
        ui.setThemePreset('crimson')
        ui.setFont('buildermono')
        ui.setScale(1)
        ui.setTextScale(1)
        ui.setTransparency(0)
        ui.setRounding(false)
        ui.setSmoothDragging(false)
        return ui.getTheme()
    end

    ui.notify = function(settings)
        if (ui._terminated or not elemClasses) then return end
        if (settings == ui) then
            return error('ui.notify is not a namecall function', 2)
        end

        local s_title = settings.title or 'notice'
        local s_desc = settings.message or ''
        local s_duration = settings.duration or 3

        if (typeof(s_duration) ~= 'number') then
            return error("expected type 'number' for setting 'duration'", 2)
        end

        local startingOffset = 0
        for _, n in ipairs(notifs) do
            startingOffset += n.size.Y.Offset + 10
        end

        local notif = elemClasses.notif:new()
        local main = notif.instances.main
        main.Position = UDim2.new(2.2, 0, 1, -startingOffset)
        main.Parent = notifContainer

        notif:setTitle(s_title)
        notif:setDesc(s_desc)
        notif.size = main.Size
        table.insert(notifs, notif)

        tween(main, {Position = UDim2.new(1, 0, 1, -startingOffset)}, 0.28, 1)
        task.delay(s_duration, function()
            local mainPos = main.AbsolutePosition.Y
            notif:destroy()
            local idx = table.find(notifs, notif)
            if (idx) then
                table.remove(notifs, idx)
            end

            for _, n in ipairs(notifs) do
                local nmain = n.instances.main
                if (nmain.AbsolutePosition.Y > mainPos) then continue end
                local p = UDim2.new(1, 0, 1, nmain.Position.Y.Offset + 10 + notif.size.Y.Offset)
                tween(nmain, {Position = p}, 0.25, 1)
            end
        end)
    end

    do
        local function makeDraggableHud(frame, handle)
            local dCon, aCon, eCon
            local targetPos
            handle.InputBegan:Connect(function(io)
                if (isPrimaryInput(io)) then
                    local rootPos = frame.AbsolutePosition
                    local startPos = Vector2.new(io.Position.X, io.Position.Y)
                    targetPos = UDim2.fromOffset(rootPos.X, rootPos.Y)
                    if (aCon) then aCon:Disconnect() end
                    if (dCon) then dCon:Disconnect() end
                    if (eCon) then eCon:Disconnect() end
                    aCon = renderService.RenderStepped:Connect(function(dt)
                        frame.Position = frame.Position:lerp(targetPos, 1 - animSpeed ^ dt)
                    end)
                    dCon = inputService.InputChanged:Connect(function(mio)
                        if (isMoveInput(mio)) then
                            local dest = rootPos + (Vector2.new(mio.Position.X, mio.Position.Y) - startPos)
                            targetPos = UDim2.fromOffset(dest.X, dest.Y)
                        end
                    end)
                    eCon = inputService.InputEnded:Connect(function(eio)
                        if (isPrimaryInput(eio)) then
                            if (dCon) then dCon:Disconnect(); dCon = nil end
                            if (aCon) then aCon:Disconnect(); aCon = nil end
                            if (eCon) then eCon:Disconnect(); eCon = nil end
                            if (targetPos) then
                                tween(frame, {Position = targetPos}, 0.16, 1)
                            end
                        end
                    end)
                end
            end)
        end

        local initHudScale = getHudScale()
        if (notifScale) then
            notifScale.Scale = initHudScale
        end

        local wmFrame = create('Frame', {
            Active = true,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = theme.Window1,
            BorderSizePixel = 0,
            Name = '#watermark',
            Position = UDim2.fromOffset(isCompactViewport() and 10 or 16, isCompactViewport() and 8 or 16),
            Size = UDim2.fromOffset(0, 24),
            Visible = false,
            ZIndex = 2600
        }, hudScreen)
        create('UIScale', {Name = '#scale', Scale = initHudScale}, wmFrame)
        makeCorner(wmFrame, cornerPx)
        makeStroke(wmFrame, theme.Stroke, 1)
        local wmTrim = create('Frame', {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Name = '#trim',
            Position = UDim2.fromOffset(0, -1),
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 2602
        }, wmFrame)
        makeGradient(wmTrim, theme.Primary, theme.Secondary, 0)
        local wmText = create('TextLabel', {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Font = currentFont,
            Name = '#text',
            RichText = true,
            Size = UDim2.fromOffset(0, 24),
            Text = 'LARPWare',
            TextColor3 = theme.TextPrimary,
            TextSize = 12,
            TextStrokeColor3 = theme.TextStroke,
            TextStrokeTransparency = 0.85,
            ZIndex = 2601
        }, wmFrame)
        create('UIPadding', {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)}, wmText)
        makeDraggableHud(wmFrame, wmFrame)
        ui._watermarkFrame = wmFrame

        ui.setWatermark = function(text, visible)
            local nextStr = tostring(text or 'LARPWare')
            if (wmText.Text ~= nextStr) then
                wmText.Text = nextStr
            end
            local nextVis = (visible ~= nil) and (visible and true or false) or true
            if (wmFrame.Visible ~= nextVis) then
                wmFrame.Visible = nextVis
            end
            return wmFrame
        end

        ui.toggleWatermark = function(state)
            if (state == nil) then
                wmFrame.Visible = not wmFrame.Visible
            else
                wmFrame.Visible = state and true or false
            end
            return wmFrame.Visible
        end

        local kbFrame = create('Frame', {
            Active = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = theme.Window2,
            BorderSizePixel = 0,
            Name = '#keybind-list',
            Position = UDim2.fromOffset(isCompactViewport() and 10 or 16, isCompactViewport() and 34 or 52),
            Size = UDim2.fromOffset(176, 22),
            Visible = false,
            ZIndex = 2500
        }, hudScreen)
        create('UIScale', {Name = '#scale', Scale = initHudScale}, kbFrame)
        makeCorner(kbFrame, cornerPx)
        makeStroke(kbFrame, theme.Stroke, 1)
        local kbTrim = create('Frame', {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Name = '#trim',
            Position = UDim2.fromOffset(0, -1),
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 2503
        }, kbFrame)
        makeGradient(kbTrim, theme.Primary, theme.Secondary, 0)
        local kbHeader = create('Frame', {
            Active = true,
            BackgroundColor3 = theme.Window1,
            BorderSizePixel = 0,
            Name = '#header',
            Position = UDim2.fromOffset(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            ZIndex = 2501
        }, kbFrame)
        create('Frame', {
            BackgroundColor3 = theme.Stroke,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 2502
        }, kbHeader)
        local kbTitle = create('TextLabel', {
            BackgroundTransparency = 1,
            Font = currentFont,
            Name = '#title',
            Size = UDim2.fromScale(1, 1),
            Text = 'keybinds',
            TextColor3 = theme.TextPrimary,
            TextSize = 11,
            TextStrokeColor3 = theme.TextStroke,
            TextStrokeTransparency = 0.85,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2502
        }, kbHeader)
        create('UIPadding', {PaddingLeft = UDim.new(0, 7)}, kbTitle)
        local kbBody = create('Frame', {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Name = '#body',
            Position = UDim2.fromOffset(0, 21),
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 2501
        }, kbFrame)
        create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, kbBody)
        create('UIPadding', {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 7),
            PaddingRight = UDim.new(0, 7)
        }, kbBody)
        makeDraggableHud(kbFrame, kbHeader)
        ui._keybindListFrame = kbFrame

        local lastKbSig = nil
        ui.refreshKeybindList = function(force)
            if (not kbFrame or not kbFrame.Parent or not kbFrame.Visible) then return end
            local parts = {}
            for idx, hk in ipairs(ui.hotkeys) do
                if (hk.hotkey) then
                    local active = false
                    if (hk.linkedControl and hk.linkedControl.class == 'toggle') then
                        active = hk.linkedControl.toggled == true
                    end
                    parts[#parts + 1] = tostring(idx) .. ':' .. tostring(hk.name or 'bind') .. ':' .. hk.hotkey.Name .. ':' .. (active and '1' or '0')
                end
            end
            local sig = table.concat(parts, '|')
            if (not force and sig == lastKbSig) then return end
            lastKbSig = sig
            for _, child in ipairs(kbBody:GetChildren()) do
                if (child:IsA('Frame')) then
                    child:Destroy()
                end
            end
            for idx, hk in ipairs(ui.hotkeys) do
                if (hk.hotkey) then
                    local active = false
                    if (hk.linkedControl and hk.linkedControl.class == 'toggle') then
                        active = hk.linkedControl.toggled == true
                    end
                    local row = create('Frame', {
                        BackgroundTransparency = 1,
                        LayoutOrder = idx,
                        Name = '#row',
                        Size = UDim2.new(1, 0, 0, 15),
                        ZIndex = 2502
                    }, kbBody)
                    create('TextLabel', {
                        BackgroundTransparency = 1,
                        Font = currentFont,
                        Name = '#name',
                        Size = UDim2.new(0.68, 0, 1, 0),
                        Text = tostring(hk.name or 'bind'),
                        TextColor3 = active and theme.TextPrimary or theme.TextDim,
                        TextSize = 11,
                        TextStrokeColor3 = theme.TextStroke,
                        TextStrokeTransparency = 0.85,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2502
                    }, row)
                    create('TextLabel', {
                        BackgroundTransparency = 1,
                        Font = currentFont,
                        Name = '#key',
                        Position = UDim2.fromScale(0.68, 0),
                        Size = UDim2.new(0.32, 0, 1, 0),
                        Text = ('[%s]'):format(hk.hotkey.Name),
                        TextColor3 = active and theme.Primary or theme.TextDim,
                        TextSize = 10,
                        TextStrokeColor3 = theme.TextStroke,
                        TextStrokeTransparency = 0.85,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 2502
                    }, row)
                end
            end
        end

        ui.toggleKeybindList = function(state)
            if (state == nil) then
                kbFrame.Visible = not kbFrame.Visible
            else
                kbFrame.Visible = state and true or false
            end
            if (kbFrame.Visible) then
                ui.refreshKeybindList()
            end
            return kbFrame.Visible
        end

        local mbDefaultSize = isCompactViewport() and 42 or 52
        local mbFrame = create('Frame', {
            Active = true,
            BackgroundColor3 = theme.Window1,
            BorderSizePixel = 0,
            Name = '#mobile-toggle',
            Position = UDim2.new(0, isCompactViewport() and 10 or 18, 0.5, -math.floor(mbDefaultSize * 0.5)),
            Size = UDim2.fromOffset(mbDefaultSize, mbDefaultSize),
            Visible = enableMobileButton,
            ZIndex = 2700
        }, hudScreen)
        local mbScale = create('UIScale', {Name = '#scale', Scale = 1}, mbFrame)
        makeCorner(mbFrame, cornerPx)
        local mbStroke = makeStroke(mbFrame, theme.StrokeHover, 1)

        create('ImageLabel', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://7331400934',
            ImageColor3 = Color3.fromRGB(0, 0, 5),
            ImageTransparency = 0.25,
            Name = '#shadow',
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Slice,
            Size = UDim2.new(1, 28, 1, 28),
            SliceCenter = Rect.new(40, 40, 260, 260),
            SliceScale = 1,
            ZIndex = 2698
        }, mbFrame)

        local mbInner = create('Frame', {
            Active = false,
            BackgroundColor3 = theme.Window2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Name = '#inner',
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(1, 1),
            ZIndex = 2701
        }, mbFrame)
        makeCorner(mbInner, cornerPx)
        makeGradient(mbInner, Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 222), 90)

        local mbTrim = create('Frame', {
            Active = false,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Name = '#trim',
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 2704
        }, mbInner)
        makeGradient(mbTrim, theme.Primary, theme.Secondary, 0)

        local mbDot = create('Frame', {
            Active = false,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = theme.Primary,
            BorderSizePixel = 0,
            Name = '#dot',
            Position = UDim2.new(1, -5, 0, 6),
            Size = UDim2.fromOffset(5, 5),
            ZIndex = 2705
        }, mbInner)
        makeCorner(mbDot, 3, true)

        local mbImg = create('ImageLabel', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = '',
            Name = '#logo',
            Position = UDim2.fromScale(0.5, 0.52),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromScale(0.64, 0.64),
            Visible = false,
            ZIndex = 2703
        }, mbInner)

        local mbLbl = create('TextLabel', {
            Active = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Font = currentFont,
            Name = '#label',
            Position = UDim2.fromScale(0.5, 0.52),
            Size = UDim2.fromScale(0.76, 0.56),
            Text = 'L',
            TextColor3 = theme.TextPrimary,
            TextScaled = true,
            TextStrokeColor3 = theme.TextStroke,
            TextStrokeTransparency = 0.8,
            ZIndex = 2703
        }, mbInner)

        local mbResize = create('Frame', {
            Active = true,
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Name = '#resize-grip',
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(16, 16),
            ZIndex = 2708
        }, mbFrame)
        for idx = 0, 1 do
            create('Frame', {
                Active = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.StrokeHover,
                BorderSizePixel = 0,
                Name = '#grip' .. idx,
                Position = UDim2.new(1, -4 - idx * 3, 1, -4 - idx * 3),
                Rotation = -45,
                Size = UDim2.fromOffset(4 + idx * 4, 1),
                ZIndex = 2709
            }, mbResize)
        end

        ui._mobileButton = mbFrame
        local mbTargetWin = nil
        local mbCustomIcon = false

        task.spawn(function()
            local assets = loadIntroAssets()
            if (not mbCustomIcon and assets and assets['L'] and assets['L'] ~= '' and mbImg and mbImg.Parent) then
                mbImg.Image = assets['L']
                mbImg.Visible = true
                mbLbl.Visible = false
            end
        end)

        local function getMobileTargetWindow()
            if (mbTargetWin and mbTargetWin.instances and mbTargetWin.instances.mainFrame and mbTargetWin.instances.mainFrame.Parent) then
                return mbTargetWin
            end
            return windows[1]
        end

        ui.syncMobileButtonState = function()
            if (not mbFrame or not mbFrame.Parent) then return end
            local w = getMobileTargetWindow()
            local isOpen = w and w.instances and w.instances.mainFrame and w.instances.mainFrame.Visible or false
            tween(mbDot, {BackgroundColor3 = isOpen and theme.Primary or theme.TextDim}, 0.16, 1)
            tween(mbStroke, {Color = isOpen and theme.StrokeHover or theme.Stroke}, 0.16, 1)
        end

        local function isPointerInput(io)
            return io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch
        end
        local function isMoveInput(io)
            return io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch
        end

        local mbResizing = false
        local mbDragging = false

        mbResize.InputBegan:Connect(function(io)
            if (not isPointerInput(io)) then return end
            mbResizing = true
            local startTouch = Vector2.new(io.Position.X, io.Position.Y)
            local startSize = Vector2.new(mbFrame.AbsoluteSize.X, mbFrame.AbsoluteSize.Y)
            tween(mbStroke, {Color = theme.Primary}, 0.14, 1)

            local mCon, eCon
            mCon = inputService.InputChanged:Connect(function(mio)
                if (not mbResizing or not isMoveInput(mio)) then return end
                local delta = Vector2.new(mio.Position.X, mio.Position.Y) - startTouch
                local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or guiService:GetScreenResolution()
                local maxW = math.max(44, math.min(160, vp.X - mbFrame.AbsolutePosition.X - 6))
                local maxH = math.max(44, math.min(160, vp.Y - mbFrame.AbsolutePosition.Y - 6))
                local nw = math.clamp(math.floor(startSize.X + delta.X + 0.5), 38, maxW)
                local nh = math.clamp(math.floor(startSize.Y + delta.Y + 0.5), 38, maxH)
                mbFrame.Size = UDim2.fromOffset(nw, nh)
            end)
            eCon = inputService.InputEnded:Connect(function(eio)
                if (not isPointerInput(eio)) then return end
                mbResizing = false
                if (mCon) then mCon:Disconnect(); mCon = nil end
                if (eCon) then eCon:Disconnect(); eCon = nil end
                ui.syncMobileButtonState()
            end)
            ui.trackConnection(mCon)
            ui.trackConnection(eCon)
        end)

        mbFrame.InputBegan:Connect(function(io)
            if (mbResizing or not isPointerInput(io)) then return end
            mbDragging = true
            local startInput = Vector2.new(io.Position.X, io.Position.Y)
            local startPos = Vector2.new(mbFrame.AbsolutePosition.X, mbFrame.AbsolutePosition.Y)
            local moved = false

            local mCon, eCon
            mCon = inputService.InputChanged:Connect(function(mio)
                if (not mbDragging or mbResizing or not isMoveInput(mio)) then return end
                local cur = Vector2.new(mio.Position.X, mio.Position.Y)
                local delta = cur - startInput
                if (not moved and delta.Magnitude > 6) then
                    moved = true
                end
                if (moved) then
                    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or guiService:GetScreenResolution()
                    local inset = guiService:GetGuiInset()
                    local sz = mbFrame.AbsoluteSize
                    local nx = math.clamp(math.floor(startPos.X + delta.X + 0.5), 4, math.max(4, vp.X - sz.X - 4))
                    local ny = math.clamp(math.floor(startPos.Y + delta.Y + 0.5), 4, math.max(4, vp.Y - inset.Y - sz.Y - 4))
                    mbFrame.Position = UDim2.fromOffset(nx, ny)
                end
            end)
            eCon = inputService.InputEnded:Connect(function(eio)
                if (not isPointerInput(eio)) then return end
                mbDragging = false
                if (mCon) then mCon:Disconnect(); mCon = nil end
                if (eCon) then eCon:Disconnect(); eCon = nil end
                if (not moved and not mbResizing) then
                    mbScale.Scale = 0.88
                    tween(mbScale, {Scale = 1}, 0.22, 4)
                    local w = getMobileTargetWindow()
                    if (w) then
                        w:toggle()
                    end
                end
            end)
            ui.trackConnection(mCon)
            ui.trackConnection(eCon)
        end)

        ui.toggleMobileButton = function(state)
            if (state == nil) then
                mbFrame.Visible = not mbFrame.Visible
            else
                mbFrame.Visible = state and true or false
            end
            ui.syncMobileButtonState()
            return mbFrame.Visible
        end

        ui.setMobileButton = function(opts)
            if (typeof(opts) ~= 'table') then return mbFrame end
            if (opts.visible ~= nil) then
                mbFrame.Visible = opts.visible and true or false
            end
            if (opts.size ~= nil) then
                if (typeof(opts.size) == 'Vector2') then
                    mbFrame.Size = UDim2.fromOffset(math.clamp(opts.size.X, 38, 160), math.clamp(opts.size.Y, 38, 160))
                elseif (typeof(opts.size) == 'UDim2') then
                    mbFrame.Size = opts.size
                end
            end
            if (opts.position ~= nil) then
                if (typeof(opts.position) == 'Vector2') then
                    mbFrame.Position = UDim2.fromOffset(opts.position.X, opts.position.Y)
                elseif (typeof(opts.position) == 'UDim2') then
                    mbFrame.Position = opts.position
                end
            end
            if (opts.image ~= nil) then
                mbCustomIcon = true
                if (opts.image ~= '') then
                    mbImg.Image = tostring(opts.image)
                    mbImg.Visible = true
                    mbLbl.Visible = false
                else
                    mbImg.Visible = false
                    mbLbl.Visible = true
                end
            elseif (opts.text ~= nil) then
                mbCustomIcon = true
                mbLbl.Text = tostring(opts.text)
                mbLbl.Visible = true
                mbImg.Visible = false
            end
            if (opts.window ~= nil) then
                mbTargetWin = opts.window
            end
            ui.syncMobileButtonState()
            return mbFrame
        end
        local function syncAllViewportFits()
            if (ui._terminated) then return end
            local hs = getHudScale()
            if (notifScale and notifScale.Parent) then
                notifScale.Scale = hs
            end
            if (wmFrame and wmFrame.Parent and wmFrame:FindFirstChild('#scale')) then
                wmFrame['#scale'].Scale = hs
            end
            if (kbFrame and kbFrame.Parent and kbFrame:FindFirstChild('#scale')) then
                kbFrame['#scale'].Scale = hs
            end
            for _, w in ipairs(windows) do
                if (w and typeof(w.fitToViewport) == 'function') then
                    w:fitToViewport(false)
                end
            end
        end

        local camVpCon
        local function hookCameraViewport()
            if (camVpCon) then
                camVpCon:Disconnect()
                camVpCon = nil
            end
            local cam = workspace.CurrentCamera
            if (cam) then
                camVpCon = cam:GetPropertyChangedSignal('ViewportSize'):Connect(syncAllViewportFits)
                ui.trackConnection(camVpCon)
            end
        end
        hookCameraViewport()
        ui.trackConnection(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
            hookCameraViewport()
            syncAllViewportFits()
        end))
    end

    do
        local hotkeys = ui.hotkeys
        ui.hkCon = inputService.InputBegan:Connect(function(io, gpe)
            if (ui._terminated) then return end
            if ((not gpe) and (io.UserInputType == Enum.UserInputType.Keyboard)) then
                local kc = io.KeyCode
                for i = 1, #hotkeys do
                    local hk = hotkeys[i]
                    if (hk.hotkey == kc and hk.set ~= time()) then
                        local linkedControl = hk.linkedControl
                        if (linkedControl) then
                            task.spawn(function()
                                linkedControl.__hotkeyFunc(linkedControl)
                                if (ui.refreshKeybindList) then
                                    ui.refreshKeybindList()
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end
end

return ui
