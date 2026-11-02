
--========================================================
-- VINHUB: PHANTOM X V5.0
-- Refined Edition | Roblox Studio LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
--========================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--========================================================
-- CONFIG
--========================================================

local VERSION = "V5.0"

local C = {
    Background = Color3.fromRGB(12, 10, 21),
    Panel = Color3.fromRGB(24, 20, 36),
    PanelLight = Color3.fromRGB(37, 30, 52),
    Red = Color3.fromRGB(255, 48, 82),
    Purple = Color3.fromRGB(166, 72, 255),
    Blue = Color3.fromRGB(48, 125, 255),
    White = Color3.fromRGB(245, 244, 255),
    Gray = Color3.fromRGB(155, 148, 177),
    Green = Color3.fromRGB(75, 225, 155),
    Yellow = Color3.fromRGB(255, 195, 75)
}

local DEFAULT_SPEED = 16
local DEFAULT_JUMP = 50

local speed = DEFAULT_SPEED
local jumpPower = DEFAULT_JUMP
local infiniteJump = false
local espEnabled = false
local selectedUsername = ""

local connections = {}
local highlights = {}
local destroyed = false

--========================================================
-- CLEAN OLD GUI
--========================================================

local oldGui = PlayerGui:FindFirstChild("PhantomX")
if oldGui then
    oldGui:Destroy()
end

--========================================================
-- HELPERS
--========================================================

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function create(class, props, parent)
    local object = Instance.new(class)

    for property, value in pairs(props) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10)
    }, object)
end

local function outline(object, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or C.Purple,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, object)
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function gradient(object, rotation)
    local g = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.Red),
            ColorSequenceKeypoint.new(0.5, C.Purple),
            ColorSequenceKeypoint.new(1, C.Blue)
        }),
        Rotation = rotation or 0
    }, object)

    task.spawn(function()
        while g.Parent and not destroyed do
            local animation = tween(g, 7, {
                Rotation = g.Rotation + 180
            })
            animation.Completed:Wait()
        end
    end)

    return g
end

--========================================================
-- SCREEN GUI
--========================================================

local gui = create("ScreenGui", {
    Name = "PhantomX",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(520, 550),
    Position = UDim2.new(0.5, -260, 0.5, -275),
    BackgroundColor3 = C.Background,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true
}, gui)

round(main, 16)

local mainStroke = outline(main, C.Purple, 2, 0.1)
local strokeGradient = gradient(mainStroke, 0)

-- Responsive scaling
local scale = create("UIScale", {
    Scale = 1
}, main)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local factor = math.min(
        viewport.X / 560,
        viewport.Y / 590,
        1
    )

    scale.Scale = math.clamp(factor, 0.65, 1)
end

updateScale()

if workspace.CurrentCamera then
    track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end

--========================================================
-- HEADER
--========================================================

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 85),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0
}, main)

round(header, 15)
gradient(header, 0)

local headerOverlay = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.Background,
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0
}, header)

round(headerOverlay, 15)

local brand = create("TextLabel", {
    Position = UDim2.fromOffset(19, 9),
    Size = UDim2.new(1, -100, 0, 39),
    BackgroundTransparency = 1,
    Text = "VINHUB",
    TextColor3 = C.White,
    Font = Enum.Font.GothamBlack,
    TextSize = 29,
    TextXAlignment = Enum.TextXAlignment.Left
}, headerOverlay)

local subtitle = create("TextLabel", {
    Position = UDim2.fromOffset(21, 48),
    Size = UDim2.new(1, -110, 0, 20),
    BackgroundTransparency = 1,
    Text = "PHANTOM X  /  " .. VERSION .. "  /  ADVANCED CONTROL",
    TextColor3 = C.Gray,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, headerOverlay)

local close = create("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -45, 0, 24),
    BackgroundColor3 = C.PanelLight,
    Text = "×",
    TextColor3 = C.White,
    TextSize = 23,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, headerOverlay)

round(close, 9)

--========================================================
-- NOTIFICATION SYSTEM
--========================================================

local notificationHolder = create("Frame", {
    Name = "Notifications",
    Size = UDim2.fromOffset(260, 250),
    Position = UDim2.new(1, -275, 0, 15),
    BackgroundTransparency = 1
}, gui)

local notificationLayout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder
}, notificationHolder)

local function notify(message, color)
    if destroyed then return end

    local card = create("Frame", {
        Size = UDim2.fromOffset(245, 55),
        BackgroundColor3 = C.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0
    }, notificationHolder)

    round(card, 10)
    outline(card, color or C.Purple, 1, 0.2)

    local indicator = create("Frame", {
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = color or C.Purple,
        BorderSizePixel = 0
    }, card)

    round(indicator, 3)

    create("TextLabel", {
        Position = UDim2.fromOffset(20, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = C.White,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    card.Position = UDim2.fromOffset(260, 0)
    tween(card, 0.3, {
        Position = UDim2.fromOffset(0, 0)
    })

    task.delay(3, function()
        if card.Parent then
            tween(card, 0.25, {
                BackgroundTransparency = 1
            })
            task.wait(0.3)
            card:Destroy()
        end
    end)
end

--========================================================
-- DRAGGING
--========================================================

local dragging = false
local dragStart
local startPosition
local dragInput

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        dragInput = input
    end
end)

track(UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input == dragInput
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

--========================================================
-- SIDEBAR AND CONTENT
--========================================================

local sidebar = create("Frame", {
    Position = UDim2.fromOffset(12, 96),
    Size = UDim2.new(0, 125, 1, -108),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0
}, main)

round(sidebar, 12)

local navLayout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, sidebar)

create("UIPadding", {
    PaddingTop = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8)
}, sidebar)

local content = create("Frame", {
    Position = UDim2.fromOffset(149, 96),
    Size = UDim2.new(1, -161, 1, -108),
    BackgroundTransparency = 1
}, main)

local pageNames = {
    "Movement",
    "Visuals",
    "Players",
    "Settings"
}

local icons = {
    Movement = "⚡",
    Visuals = "◉",
    Players = "♙",
    Settings = "⚙"
}

local pages = {}
local navButtons = {}

for _, name in ipairs(pageNames) do
    local page = create("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Purple,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false
    }, content)

    create("UIListLayout", {
        Padding = UDim.new(0, 11),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 8)
    }, page)

    pages[name] = page

    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = C.Panel,
        Text = icons[name] .. "  " .. name,
        TextColor3 = C.Gray,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false
    }, sidebar)

    round(button, 9)
    navButtons[name] = button
end

local currentPage

local function switchPage(name)
    currentPage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for pageName, button in pairs(navButtons) do
        local active = pageName == name

        tween(button, 0.18, {
            BackgroundColor3 = active and C.Purple or C.Panel,
            TextColor3 = active and C.White or C.Gray
        })
    end
end

for name, button in pairs(navButtons) do
    button.Activated:Connect(function()
        switchPage(name)
    end)
end

--==================================================
-- UI ELEMENT HELPERS
--==================================================

local function label(page, text)
    return create("TextLabel", {
        Size = UDim2.new(1, -5, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Purple,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
end

local function button(page, text, callback)
    local b = create("TextButton", {
        Size = UDim2.new(1, -5, 0, 43),
        BackgroundColor3 = C.PanelLight,
        Text = text,
        TextColor3 = C.White,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false
    }, page)

    round(b, 9)
    outline(b, C.Purple, 1, 0.45)

    b.MouseEnter:Connect(function()
        tween(b, 0.15, {
            BackgroundColor3 = Color3.fromRGB(53, 37, 72)
        })
    end)

    b.MouseLeave:Connect(function()
        tween(b, 0.15, {
            BackgroundColor3 = C.PanelLight
        })
    end)

    b.Activated:Connect(function()
        callback(b)
    end)

    return b
end

local function input(page, placeholder, initial, callback)
    local box = create("TextBox", {
        Size = UDim2.new(1, -5, 0, 42),
        BackgroundColor3 = C.PanelLight,
        TextColor3 = C.White,
        PlaceholderColor3 = C.Gray,
        PlaceholderText = placeholder,
        Text = tostring(initial or ""),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12
    }, page)

    round(box, 9)
    outline(box, C.Purple, 1, 0.6)

    box.FocusLost:Connect(function()
        callback(box.Text)
    end)

    return box
end

local function slider(page, title, minValue, maxValue, initial, callback)
    local holder = create("Frame", {
        Size = UDim2.new(1, -5, 0, 76),
        BackgroundColor3 = C.PanelLight,
        BorderSizePixel = 0
    }, page)

    round(holder, 9)

    local titleLabel = create("TextLabel", {
        Position = UDim2.fromOffset(11, 7),
        Size = UDim2.new(1, -70, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.White,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local valueLabel = create("TextLabel", {
        Position = UDim2.new(1, -62, 0, 7),
        Size = UDim2.fromOffset(50, 20),
        BackgroundTransparency = 1,
        Text = tostring(initial),
        TextColor3 = C.Purple,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right
    }, holder)

    local bar = create("Frame", {
        Position = UDim2.fromOffset(12, 43),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = C.Background,
        BorderSizePixel = 0
    }, holder)

    round(bar, 5)

    local fill = create("Frame", {
        Size = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = C.Purple,
        BorderSizePixel = 0
    }, bar)

    round(fill, 5)
    gradient(fill, 0)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0),
        BackgroundColor3 = C.White,
        BorderSizePixel = 0
    }, bar)

    round(knob, 20)

    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0.5, -15),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5
    }, bar)

    local function setValue(value)
        value = math.clamp(
            math.floor(value + 0.5),
            minValue,
            maxValue
        )

        local alpha = (value - minValue) / (maxValue - minValue)

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        callback(value)
    end

    local sliding = false

    local function updateFromInput(inputObject)
        local alpha = math.clamp(
            (inputObject.Position.X - bar.AbsolutePosition.X)
                / bar.AbsoluteSize.X,
            0,
            1
        )

        setValue(minValue + alpha * (maxValue - minValue))
    end

    hitbox.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then

            sliding = true
            updateFromInput(inputObject)
        end
    end)

    track(UIS.InputChanged:Connect(function(inputObject)
        if sliding and (
            inputObject.UserInputType == Enum.UserInputType.MouseMovement
            or inputObject.UserInputType == Enum.UserInputType.Touch
        ) then
            updateFromInput(inputObject)
        end
    end))

    track(UIS.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))

    return setValue
end

--==================================================
-- CHARACTER UTILITIES
--==================================================

local function getHumanoid()
    local character = Player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function applyMovement()
    local hum = getHumanoid()

    if not hum then
        notify("Character is not ready.", C.Yellow)
        return
    end

    hum.WalkSpeed = speed
    hum.UseJumpPower = true
    hum.JumpPower = jumpPower
end

--==================================================
-- MOVEMENT PAGE
--==================================================

local movementPage = pages.Movement

label(movementPage, "MOVEMENT CONTROLS")

slider(movementPage, "WALK SPEED", 0, 100, speed, function(value)
    speed = value
    applyMovement()
end)

slider(movementPage, "JUMP POWER", 0, 200, jumpPower, function(value)
    jumpPower = value
    applyMovement()
end)

local infiniteButton

infiniteButton = button(movementPage, "INFINITE JUMP: OFF", function(b)
    infiniteJump = not infiniteJump

    b.Text = "INFINITE JUMP: " .. (infiniteJump and "ON" or "OFF")
    b.TextColor3 = infiniteJump and C.Green or C.White

    notify("Infinite jump " .. (infiniteJump and "enabled" or "disabled"))
end)

track(UIS.JumpRequest:Connect(function()
    if not infiniteJump then return end

    local hum = getHumanoid()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

button(movementPage, "RESET MOVEMENT", function()
    speed = DEFAULT_SPEED
    jumpPower = DEFAULT_JUMP

    applyMovement()
    notify("Movement settings reset.")
end)

--==================================================
-- ESP SYSTEM
--==================================================

local visualsPage = pages.Visuals

label(visualsPage, "VISUAL SETTINGS")

local function removeHighlight(target)
    local existing = highlights[target]

    if existing then
        existing:Destroy()
        highlights[target] = nil
    end
end

local function updateHighlight(target)
    removeHighlight(target)

    if not espEnabled or target == Player then
        return
    end

    local character = target.Character
    if not character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PhantomXHighlight"
    highlight.Adornee = character
    highlight.FillColor = C.Purple
    highlight.OutlineColor = C.Blue
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = gui

    highlights[target] = highlight
end

local espButton = button(visualsPage, "PLAYER ESP: OFF", function(b)
    espEnabled = not espEnabled

    b.Text = "PLAYER ESP: " .. (espEnabled and "ON" or "OFF")
    b.TextColor3 = espEnabled and C.Green or C.White

    for _, target in ipairs(Players:GetPlayers()) do
        updateHighlight(target)
    end

    notify("ESP " .. (espEnabled and "enabled" or "disabled"))
end)

label(visualsPage, "ESP uses visible character outlines.")

local function setupPlayer(target)
    target.CharacterAdded:Connect(function()
        task.wait(0.5)
        updateHighlight(target)
    end)
end

for _, target in ipair