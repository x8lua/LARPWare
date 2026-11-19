local inputService = game:GetService('UserInputService')
local renderService = game:GetService('RunService')
local tweenService = game:GetService('TweenService')
local guiService = game:GetService('GuiService')

local tween
do
    local styleEnum = Enum.EasingStyle
    local dirEnum = Enum.EasingDirection
    local direction = dirEnum.Out
    local styles = {styleEnum.Exponential, styleEnum.Linear, styleEnum.Quad}

    function tween(object, props, duration, style)
        local tweenInfo = TweenInfo.new(duration, styles[style or 1] or styleEnum.Exponential, direction)
        local tw = tweenService:Create(object, tweenInfo, props)
        tw:Play()
        return tw
    end
end

local function create(className, props, parent)
    local inst = Instance.new(className)
    if (props) then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if (parent) then
        inst.Parent = parent
    end
    return inst
end

local function makeCorner(parent, radius)
    return create('UICorner', {
        Name = '#round',
        CornerRadius = UDim.new(0, radius)
    }, parent)
end

local function makeStroke(parent, color, thickness)
    return create('UIStroke', {
        Name = '#stroke',
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Thickness = thickness or 1
    }, parent)
end

local function makeGradient(parent, c1, c2, rotation)
    return create('UIGradient', {
        Name = '#gradient',
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 0,
        Enabled = true
    }, parent)
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
local theme
local rounding
local animSpeed = 1e-12

local fontMap = {
    roboto = Enum.Font.Roboto,
    robotomono = Enum.Font.RobotoMono,
    ubuntu = Enum.Font.Ubuntu,
    arimo = Enum.Font.Arimo,
    code = Enum.Font.Code,
    gotham = Enum.Font.Gotham
}
local fontOrder = {'roboto', 'robotomono', 'ubuntu', 'arimo', 'code', 'gotham'}
local currentFontKey = 'roboto'
local currentFont = fontMap.roboto
local currentScale = 1

local function resolveFont(input)
    if (typeof(input) == 'EnumItem' and input.EnumType == Enum.Font) then
        for k, v in pairs(fontMap) do
            if (v == input) then
                return k, v
            end
        end
        return input.Name:lower(), input
    elseif (typeof(input) == 'string') then
        local cleaned = input:lower():gsub('^%.', '')
        if (fontMap[cleaned]) then
            return cleaned, fontMap[cleaned]
        end
        local ok, enumFont = pcall(function()
            return Enum.Font[input]
        end)
        if (ok and enumFont) then
            return cleaned, enumFont
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

local cornerPx = rounding and 2 or 0

local uiScreen = Instance.new('ScreenGui')
local notifContainer
local notifScale
do
    uiScreen.OnTopOfCoreBlur = true
    uiScreen.DisplayOrder = 9e9
    uiScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    uiScreen.ResetOnSpawn = false

    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local str = ''
    for i = 1, 14 do
        local idx = math.random(1, #chars)
        str = str .. chars:sub(idx, idx)
    end
    uiScreen.Name = str

    local targetParent
    if (typeof(gethui) == 'function') then
        local ok, hui = pcall(gethui)
        if (ok and typeof(hui) == 'Instance') then
            targetParent = hui
        end
    end
    if (not targetParent) then
        local ok, cg = pcall(function()
            return game:GetService('CoreGui')
        end)
        if (ok and cg) then
            targetParent = cg
        else
            targetParent = game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
        end
    end
    uiScreen.Parent = targetParent

    notifContainer = create('Frame', {
        Active = false,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Name = '#notif-container',
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.fromOffset(220, 1000),
        ZIndex = 2900
    }, uiScreen)

    notifScale = create('UIScale', {
        Name = '#scale',
        Scale = 1
    }, notifContainer)
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
local fontListeners = {}
local scaleListeners = {}

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

                title.Text = self.name
                main.Size = UDim2.fromOffset(170, 26)
                desc.Text = self.tooltip

                local c = 0
                while (true) do
                    c += 1
                    main.Size += UDim2.fromOffset(0, 16)
                    if (c > 24) then
                        main.Size = UDim2.fromOffset(170, 68)
                        break
                    end
                    local _ = desc.TextFits
                    if (desc.TextFits == true) then
                        break
                    end
                end

                main.Visible = true
                tooltip.update = renderService.RenderStepped:Connect(function()
                    local mpos = inputService:GetMouseLocation()
                    local inset = guiService:GetGuiInset()
                    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or guiService:GetScreenResolution()
                    local sz = main.AbsoluteSize
                    local x = math.clamp(mpos.X + 14, 4, math.max(4, vp.X - sz.X - 6))
                    local y = math.clamp(mpos.Y - inset.Y + 14, 4, math.max(4, vp.Y - inset.Y - sz.Y - 6))
                    main.Position = UDim2.fromOffset(x, y)
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
                Size = UDim2.new(1, -92, 1, 0),
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
                Position = UDim2.new(0, 128, 0, 29),
                Size = UDim2.new(1, -128, 1, -29),
                Visible = true,
                ZIndex = 30
            }, mainFrame)

            local sideBar = create('Frame', {
                BackgroundColor3 = theme.Window3,
                BorderColor3 = theme.Inset3,
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Name = '#sidebar',
                Position = UDim2.fromOffset(0, 29),
                Size = UDim2.new(0, 128, 1, -29),
                Visible = true,
                ZIndex = 48
            }, mainFrame)
            create('Frame', {
                Name = '#right-line',
                BackgroundColor3 = theme.Stroke,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -1, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 50
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
            }, sideBar)

            create('UIScale', {
                Name = '#content-scale',
                Scale = currentScale
            }, menu)

            create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Name = '#layout',
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Top
            }, menu)

            create('UIPadding', {
                Name = '#padding',
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6)
            }, menu)

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
                Size = UDim2.fromOffset(206, 152),
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

            local fontLabel = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#font-label',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 14),
                Text = 'font',
                TextColor3 = theme.TextDim,
                TextSize = 11,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 82
            }, popBody)

            local fontGroup = create('Frame', {
                BackgroundColor3 = theme.Inset1,
                BorderSizePixel = 0,
                Name = '#font-group',
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, 0, 0, 68),
                ZIndex = 82
            }, popBody)
            makeCorner(fontGroup, cornerPx)
            makeStroke(fontGroup, theme.Stroke, 1)

            for idx, fk in ipairs(fontOrder) do
                local col = (idx - 1) % 2
                local row = math.floor((idx - 1) / 2)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Font = fontMap[fk],
                    Name = '#fopt-' .. fk,
                    Position = UDim2.new(col * 0.5, col == 0 and 2 or 1, 0, 2 + row * 22),
                    Size = UDim2.new(0.5, -3, 0, 20),
                    Text = '.' .. fk,
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    ZIndex = 83
                }, fontGroup)
                makeCorner(btn, cornerPx)
                local ind = create('Frame', {
                    BackgroundColor3 = theme.Primary,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Name = '#ind',
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(1, 0, 0, 2),
                    ZIndex = 84
                }, btn)
                makeGradient(ind, theme.Primary, theme.Secondary, 0)
            end

            local scaleHeader = create('Frame', {
                BackgroundTransparency = 1,
                Name = '#scale-header',
                Position = UDim2.fromOffset(0, 90),
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
                Position = UDim2.fromOffset(0, 106),
                Size = UDim2.new(1, 0, 0, 10),
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
            }
        }

        window.toggleSettings = function(self)
            self.settingsOpen = not self.settingsOpen
            local pop = self.instances.settingsPopover
            local btn = self.instances.buttonSettings
            if (self.minimized) then
                self.settingsOpen = false
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

        window.destroy = function(self)
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
            return self
        end

        window.getPosition = function(self)
            return self.instances.mainFrame.Position
        end

        window.getSize = function(self, targetSize)
            return targetSize and self.size or self.instances.mainFrame.Size
        end

        window.new = function(self, resize, showSettings)
            local new = setmetatable({}, self)
            new.menus = {}
            new.binds = {}
            new.resizable = resize and true or false
            new.settingsOpen = false
            new.settingsFocused = false
            table.insert(ui.windows, new)

            local insts = {}
            insts.mainFrame = self.instances.mainFrame:Clone()
            insts.mainFrame['#scale'].Scale = 1

            local titleBar = insts.mainFrame['#title-bar']
            insts.buttonClose = titleBar['#button-close']
            insts.buttonMin = titleBar['#button-min']
            insts.buttonSettings = titleBar['#button-settings']
            insts.titleBar = titleBar
            insts.title = titleBar['#title']
            insts.gradient = insts.mainFrame['#trim']['#gradient']
            insts.sideBar = insts.mainFrame['#sidebar']
            insts.tabMenu = insts.sideBar['#menu']
            insts.tabMenu['#content-scale'].Scale = currentScale
            insts.tabMenu.Size = UDim2.fromScale(1 / currentScale, 1 / currentScale)
            insts.pageRegion = insts.mainFrame['#page-region']
            insts.resizeHandle = insts.mainFrame['#resize-handle']
            insts.settingsPopover = insts.mainFrame['#settings-popover']

            if (showSettings == false) then
                insts.buttonSettings.Visible = false
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
                local fontGroup = popBody['#font-group']
                local scaleHeader = popBody['#scale-header']
                local scaleValBtn = scaleHeader['#scale-val']
                local scaleTrack = popBody['#scale-track']
                local scaleFill = scaleTrack['#fill']

                local function syncPopoverFont(fKey)
                    for _, fk in ipairs(fontOrder) do
                        local btn = fontGroup['#fopt-' .. fk]
                        local active = (fk == fKey)
                        tween(btn, {
                            BackgroundColor3 = active and theme.Button3 or theme.Button1,
                            TextColor3 = active and theme.TextPrimary or theme.TextDim
                        }, 0.16, 1)
                        tween(btn['#ind'], {BackgroundTransparency = active and 0 or 1}, 0.16, 1)
                    end
                end

                for _, fk in ipairs(fontOrder) do
                    local btn = fontGroup['#fopt-' .. fk]
                    btn.MouseButton1Click:Connect(function()
                        ui.setFont(fk)
                    end)
                    btn.MouseEnter:Connect(function()
                        if (currentFontKey ~= fk) then
                            tween(btn, {BackgroundColor3 = theme.Button2, TextColor3 = theme.TextPrimary}, 0.14, 1)
                        end
                    end)
                    btn.MouseLeave:Connect(function()
                        if (currentFontKey ~= fk) then
                            tween(btn, {BackgroundColor3 = theme.Button1, TextColor3 = theme.TextDim}, 0.14, 1)
                        end
                    end)
                end

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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                        draggingScale = true
                        tween(scaleTrack['#stroke'], {Color = theme.Primary}, 0.14, 1)
                        applyScaleFromX(io.Position.X)
                        if (sMoveCon) then sMoveCon:Disconnect() end
                        if (sEndCon) then sEndCon:Disconnect() end
                        sMoveCon = inputService.InputChanged:Connect(function(mio)
                            if (draggingScale and mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applyScaleFromX(mio.Position.X)
                            end
                        end)
                        sEndCon = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
                                draggingScale = false
                                tween(scaleTrack['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                                if (sMoveCon) then sMoveCon:Disconnect(); sMoveCon = nil end
                                if (sEndCon) then sEndCon:Disconnect(); sEndCon = nil end
                            end
                        end)
                    end
                end)

                syncPopoverFont(currentFontKey)
                syncPopoverScale(currentScale)
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
            end

            do
                local dCon
                local aCon
                local eCon
                local mainFrame = insts.mainFrame
                local targetPos

                titleBar.InputBegan:Connect(function(io)
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
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
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                local curPos = Vector2.new(mio.Position.X, mio.Position.Y)
                                local dest = rootPos + (curPos - startPos)
                                targetPos = UDim2.fromOffset(dest.X, dest.Y)
                            end
                        end)

                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1 and not new.minimized) then
                        local rootSize = mainFrame.AbsoluteSize
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
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                local curPos = Vector2.new(mio.Position.X, mio.Position.Y)
                                local dest = rootSize + (curPos - startPos)
                                targetSize = UDim2.fromOffset(math.clamp(dest.X, 400, 900), math.clamp(dest.Y, 280, 720))
                            end
                        end)

                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
            insts.main['#scale'].Scale = 1

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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
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
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                local dest = rootPos + (Vector2.new(mio.Position.X, mio.Position.Y) - startPos)
                                targetPos = UDim2.fromOffset(dest.X, dest.Y)
                            end
                        end)
                        eCon = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                        applyX(io.Position.X)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            fill.Size = fill.Size:lerp(targetSize, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applyX(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                        applyVal(io.Position.X)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applyVal(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                        applySpd(io.Position.Y)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applySpd(mio.Position.Y)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                        new.pickerMoving = true
                        applyWheel(io.Position)
                        if (acon) then acon:Disconnect() end
                        if (dcon) then dcon:Disconnect() end
                        if (econ) then econ:Disconnect() end
                        acon = renderService.RenderStepped:Connect(function(dt)
                            cursor.Position = cursor.Position:lerp(targetPos, 1 - 1e-12 ^ dt)
                        end)
                        dcon = inputService.InputChanged:Connect(function(mio)
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applyWheel(mio.Position)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                BackgroundColor3 = theme.Button1,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = currentFont,
                Name = '#page-selector',
                Size = UDim2.new(1, -12, 0, 24),
                Text = '',
                TextColor3 = theme.TextDim,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 52
            })
            makeCorner(pageSelector, cornerPx)
            local stroke = makeStroke(pageSelector, theme.Stroke, 1)
            stroke.Transparency = 1
            create('UIPadding', {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6)}, pageSelector)
            local indicator = create('Frame', {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Name = '#indicator',
                Position = UDim2.new(0, -10, 0.5, 0),
                Size = UDim2.new(0, 2, 0, 12),
                ZIndex = 53
            }, pageSelector)
            makeGradient(indicator, theme.Primary, theme.Secondary, 90)
            instances.pageSelector = pageSelector
        end
        menu.instances = instances

        menu.select = function(self)
            for _, m in ipairs(self.window.menus) do
                tween(m.instances.menuFrame, {Position = UDim2.fromScale(0, m.id - self.id)}, 0.35, 1)
                if (m ~= self) then
                    m:deselect()
                end
            end

            self.selected = true
            local ps = self.instances.pageSelector
            tween(ps, {
                BackgroundColor3 = self.selectorFocused and theme.Button4 or theme.Button3,
                BackgroundTransparency = 0,
                TextColor3 = theme.TextPrimary
            }, 0.18, 1)
            tween(ps['#stroke'], {Color = theme.StrokeHover, Transparency = 0}, 0.18, 1)
            tween(ps['#indicator'], {BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0, 14)}, 0.2, 1)
        end

        menu.deselect = function(self)
            self.selected = false
            local ps = self.instances.pageSelector
            tween(ps, {
                BackgroundColor3 = theme.Button2,
                BackgroundTransparency = self.selectorFocused and 0 or 1,
                TextColor3 = self.selectorFocused and theme.TextPrimary or theme.TextDim
            }, 0.18, 1)
            tween(ps['#stroke'], {Color = theme.Stroke, Transparency = self.selectorFocused and 0 or 1}, 0.18, 1)
            tween(ps['#indicator'], {BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 6)}, 0.18, 1)
        end

        menu.signals = {
            pageSelector = {
                MouseEnter = function(_, self)
                    self.selectorFocused = true
                    local ps = self.instances.pageSelector
                    if (self.selected) then
                        tween(ps, {BackgroundColor3 = theme.Button4}, 0.16, 1)
                    else
                        tween(ps, {BackgroundColor3 = theme.Button2, BackgroundTransparency = 0, TextColor3 = theme.TextPrimary}, 0.16, 1)
                        tween(ps['#stroke'], {Color = theme.Stroke, Transparency = 0}, 0.16, 1)
                    end
                end,
                MouseLeave = function(_, self)
                    self.selectorFocused = false
                    local ps = self.instances.pageSelector
                    if (self.selected) then
                        tween(ps, {BackgroundColor3 = theme.Button3}, 0.16, 1)
                    else
                        tween(ps, {BackgroundTransparency = 1, TextColor3 = theme.TextDim}, 0.16, 1)
                        tween(ps['#stroke'], {Transparency = 1}, 0.16, 1)
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
            table.insert(self.menus, m)

            m.id = #self.menus
            local menuTab = m.instances.pageSelector
            local menuFrame = m.instances.menuFrame

            menuTab.MouseButton1Click:Connect(function()
                m:select()
            end)
            menuTab.Text = s_text
            menuFrame.Position = UDim2.fromScale(0, m.id - 1)

            menuTab.Parent = self.instances.tabMenu
            menuFrame.Parent = self.instances.pageRegion

            if (m.id == 1) then
                m:select()
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
            local mf = self.instances.sectionFrame
            local min = mf['#title-bar']['#min']
            if (newState) then
                tween(min['#icon'], {Rotation = 0}, 0.22, 1)
                mf['#menu'].Visible = false
                mf.AutomaticSize = Enum.AutomaticSize.None
                mf.Size = UDim2.new(1, -2, 0, 22)
            else
                tween(min['#icon'], {Rotation = 180}, 0.22, 1)
                tween(min, {BackgroundColor3 = self.minFocused and theme.Button2 or theme.Button1}, 0.16, 1)
                mf['#menu'].Visible = true
                mf.AutomaticSize = Enum.AutomaticSize.Y
            end
            self.minimized = newState
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

            local insts = {}
            insts.sectionFrame = self.instances.sectionFrame:Clone()
            insts.title = insts.sectionFrame['#title-bar']['#title']
            insts.minimizeButton = insts.sectionFrame['#title-bar']['#min']
            insts.controlMenu = insts.sectionFrame['#menu']

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
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.new(1, -24, 1, 0),
                Text = 'toggle',
                TextColor3 = offTextColor,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
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
            end)
            swatchBtn.MouseLeave:Connect(function()
                p.focused = false
                tween(swatchBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
            end)
            swatchBtn.MouseButton1Click:Connect(function()
                p:click()
            end)

            if (typeof(callback) == 'function') then
                p:bindToEvent('onNewColor', callback)
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
            end)
            badgeBtn.MouseLeave:Connect(function()
                hk.focused = false
                if (not hk.inputCon) then
                    tween(hkLbl, {TextColor3 = theme.TextDim}, 0.14, 1)
                    tween(badgeBtn['#stroke'], {Color = theme.Stroke}, 0.14, 1)
                end
            end)
            badgeBtn.MouseButton1Click:Connect(function()
                hk:click()
            end)

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
                BackgroundTransparency = 1,
                Name = '#control',
                Size = UDim2.new(1, 0, 0, 19),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local lbl = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                RichText = true,
                Size = UDim2.fromScale(1, 1),
                Text = 'label',
                TextColor3 = theme.TextPrimary,
                TextSize = 12,
                TextStrokeColor3 = theme.TextStroke,
                TextStrokeTransparency = 0.85,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 35
            }, controlFrame)
            create('UIPadding', {Name = '#padding', PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, lbl)
        end
        label.instances = instances

        label.new = function(self)
            local new = setmetatable({}, self)
            new.binds = {}
            local insts = {}
            insts.controlFrame = self.instances.controlFrame:Clone()
            insts.label = insts.controlFrame['#label']
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
                li['#padding'].PaddingLeft = UDim.new(0, 0)
                li['#padding'].PaddingRight = UDim.new(0, 0)
            end
            l.instances.controlFrame.Parent = self.instances.controlMenu
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
                Size = UDim2.new(1, 0, 0, 88),
                ZIndex = 34
            })
            instances.controlFrame = controlFrame

            local label = create('TextLabel', {
                BackgroundTransparency = 1,
                Font = currentFont,
                Name = '#label',
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 15),
                Text = 'font',
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
                Size = UDim2.new(1, -10, 0, 68),
                ZIndex = 35
            }, controlFrame)
            makeCorner(group, cornerPx)
            makeStroke(group, theme.Stroke, 1)

            for idx, fk in ipairs(fontOrder) do
                local col = (idx - 1) % 2
                local row = math.floor((idx - 1) / 2)
                local btn = create('TextButton', {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Button1,
                    BorderSizePixel = 0,
                    Font = fontMap[fk],
                    Name = '#fopt-' .. fk,
                    Position = UDim2.new(col * 0.5, col == 0 and 2 or 1, 0, 2 + row * 22),
                    Size = UDim2.new(0.5, -3, 0, 20),
                    Text = '.' .. fk,
                    TextColor3 = theme.TextDim,
                    TextSize = 11,
                    TextStrokeColor3 = theme.TextStroke,
                    TextStrokeTransparency = 0.85,
                    ZIndex = 36
                }, group)
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
            end
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
            insts.group = insts.controlFrame['#group']

            local function sync(fKey)
                for _, fk in ipairs(fontOrder) do
                    local btn = insts.group['#fopt-' .. fk]
                    local active = (fk == fKey)
                    tween(btn, {
                        BackgroundColor3 = active and theme.Button3 or theme.Button1,
                        TextColor3 = active and theme.TextPrimary or theme.TextDim
                    }, 0.16, 1)
                    tween(btn['#ind'], {BackgroundTransparency = active and 0 or 1}, 0.16, 1)
                end
            end

            for _, fk in ipairs(fontOrder) do
                local btn = insts.group['#fopt-' .. fk]
                btn.MouseButton1Click:Connect(function()
                    ui.setFont(fk)
                    new:fireEvent('onFontChange', fk, fontMap[fk])
                end)
                btn.MouseEnter:Connect(function()
                    new:showTooltip()
                    if (currentFontKey ~= fk) then
                        tween(btn, {BackgroundColor3 = theme.Button2, TextColor3 = theme.TextPrimary}, 0.14, 1)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    new:hideTooltip()
                    if (currentFontKey ~= fk) then
                        tween(btn, {BackgroundColor3 = theme.Button1, TextColor3 = theme.TextDim}, 0.14, 1)
                    end
                end)
            end

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

            new.instances.label.Text = s_title
            new.instances.controlFrame.Parent = self.instances.controlMenu

            if (typeof(callback) == 'function') then
                new:bindToEvent('onFontChange', callback)
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
                    if (io.UserInputType == Enum.UserInputType.MouseButton1) then
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
                            if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                                applyAtX(mio.Position.X)
                            end
                        end)
                        econ = inputService.InputEnded:Connect(function(eio)
                            if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                suffix = settings.suffix or 'x'
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
            if (self.inputCon) then return self end
            local display = self.instances.hotkey
            local badge = self.instances.badge

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
                if (io.UserInputType == Enum.UserInputType.MouseButton1) then
                    local clickVal = xToValue(io.Position.X)
                    activeHandle = (math.abs(clickVal - new.low) <= math.abs(clickVal - new.high)) and 'low' or 'high'
                    new.dragging = true
                    tween(insts.track['#stroke'], {Color = theme.Primary}, 0.14, 1)
                    tween(insts.fill, {BackgroundTransparency = 0.1}, 0.14, 1)
                    applyDrag(io.Position.X)

                    if (dcon) then dcon:Disconnect() end
                    if (econ) then econ:Disconnect() end
                    dcon = inputService.InputChanged:Connect(function(mio)
                        if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                            applyDrag(mio.Position.X)
                        end
                    end)
                    econ = inputService.InputEnded:Connect(function(eio)
                        if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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
                SortOrder = Enum.SortOrder.LayoutOrder
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

            insts.search:GetPropertyChangedSignal('Text'):Connect(function()
                local q = insts.search.Text:lower()
                for item, btn in pairs(new.itemButtons) do
                    btn.Visible = (q == '' or tostring(item):lower():find(q, 1, true) ~= nil)
                end
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
            return p
        end

        elemClasses.paragraph = paragraph
    end
end

local function applyFontToTree(root, fontEnum)
    if (not root) then return end
    local function maybeApply(inst)
        if (inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox')) then
            if (inst.Name:sub(1, 6) == '#fopt-') then
                return
            end
            inst.Font = fontEnum
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

    ui.fonts = {
        roboto = Enum.Font.Roboto,
        robotomono = Enum.Font.RobotoMono,
        ubuntu = Enum.Font.Ubuntu,
        arimo = Enum.Font.Arimo,
        code = Enum.Font.Code,
        gotham = Enum.Font.Gotham
    }
    ui.Fonts = ui.fonts
    ui.autoDisableToggles = true

    local windows = ui.windows
    local notifs = ui.notifs

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
                local tm = elemClasses.window.instances.mainFrame['#sidebar']['#menu']
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

    ui.newWindow = function(settings)
        if (typeof(settings) ~= 'table') then
            return error('expected type table for settings', 2)
        end

        local s_title = settings.text or 'LARPWare'
        local s_resize = settings.resize or false
        local s_showSettings = settings.showSettings
        local s_position = settings.position
        if (not s_position) then
            s_position = defaultWinPos
            defaultWinPos += UDim2.fromScale(0.02, 0.02)
        end

        local win = elemClasses.window:new(s_resize, s_showSettings)

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

    ui.destroy = function(noWindows)
        ui:fireEvent('onPreDestroy')

        task.delay(0.4, function()
            if (uiScreen) then
                uiScreen:Destroy()
                uiScreen = nil
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

        if (ui.hkCon) then
            ui.hkCon:Disconnect()
        end
        for _, hk in ipairs(ui.hotkeys) do
            if (hk.inputCon) then
                hk.inputCon:Disconnect()
            end
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

        ui:fireEvent('onDestroy')
        for _, v in pairs(ui.scriptCns) do
            v:Disconnect()
        end
    end

    ui.setTheme = function(newTheme)
        if (typeof(newTheme) ~= 'table') then
            return error('expected type table for theme', 2)
        end
        theme = newTheme
    end

    ui.notify = function(settings)
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
                if (io.UserInputType == Enum.UserInputType.MouseButton1) then
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
                        if (mio.UserInputType == Enum.UserInputType.MouseMovement) then
                            local dest = rootPos + (Vector2.new(mio.Position.X, mio.Position.Y) - startPos)
                            targetPos = UDim2.fromOffset(dest.X, dest.Y)
                        end
                    end)
                    eCon = inputService.InputEnded:Connect(function(eio)
                        if (eio.UserInputType == Enum.UserInputType.MouseButton1) then
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

        local wmFrame = create('Frame', {
            Active = true,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = theme.Window1,
            BorderSizePixel = 0,
            Name = '#watermark',
            Position = UDim2.fromOffset(16, 16),
            Size = UDim2.fromOffset(0, 24),
            Visible = false,
            ZIndex = 2600
        }, uiScreen)
        create('UIScale', {Name = '#scale', Scale = 1}, wmFrame)
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
            wmText.Text = tostring(text or 'LARPWare')
            if (visible ~= nil) then
                wmFrame.Visible = visible and true or false
            else
                wmFrame.Visible = true
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
            Position = UDim2.fromOffset(16, 52),
            Size = UDim2.fromOffset(176, 22),
            Visible = false,
            ZIndex = 2500
        }, uiScreen)
        create('UIScale', {Name = '#scale', Scale = 1}, kbFrame)
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

        ui.refreshKeybindList = function()
            if (not kbFrame or not kbFrame.Parent) then return end
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
    end

    do
        local hotkeys = ui.hotkeys
        ui.hkCon = inputService.InputBegan:Connect(function(io, gpe)
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
