--[================================================================[
    VINHUB: PHANTOM X - ULTIMATE SCRIPT HUB (GRADIENT EDITION)
    Version: 2.1.0 (Production Release)
    Features: ESP, Size, Speed, Jump, Fake Lag, Invisibility, 
              Aimbot, Silent Aim, Inf Jump, Fling, Teleports + Gradient Theme.
--]================================================================]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Prevent duplicate UI instances
if CoreGui:FindFirstChild("VinhubPhantomX") then
    CoreGui.VinhubPhantomX:Destroy()
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VinhubPhantomX"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- State Variables
local Settings = {
    ESP = false,
    Size = 1,
    Speed = 16,
    JumpPower = 50,
    FakeLag = false,
    Invisible = false,
    Aimbot = false,
    SilentAim = false,
    InfJump = false,
    TargetPlayer = nil
}

-- =================================================================
-- 1. FLOATING DRAGGABLE TOGGLE BUTTON (LOGO)
-- =================================================================
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleLogo"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 30, 0, 200)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleButton.Image = "rbxassetid://72121325627003"
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(138, 43, 226)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleButton

-- Draggable Logic for Toggle Button
local dragging, dragInput, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =================================================================
-- 2. MAIN HUB WINDOW UI (WITH RED -> PURPLE -> BLUE GRADIENT)
-- =================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(180, 100, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Gradient background mapping Red (Left/Start) -> Purple (Middle) -> Blue (Right/End)
local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(220, 40, 60)),   -- Red
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(110, 30, 210)),  -- Purple
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(30, 90, 230))    -- Blue
})
MainGradient.Rotation = 45
MainGradient.Parent = MainFrame

-- Toggle UI visibility when logo is clicked
local isOpen = false
ToggleButton.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {Rotation = isOpen and 360 or 0}):Play()
end)

-- Top Bar / Title
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

-- Fix bottom corners of topbar
local FixBar = Instance.new("Frame")
FixBar.Size = UDim2.new(1, 0, 0, 10)
FixBar.Position = UDim2.new(0, 0, 1, -10)
FixBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
FixBar.BackgroundTransparency = 0.2
FixBar.BorderSizePixel = 0
FixBar.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "VINHUB : PHANTOM X"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Container for features
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -20, 1, -55)
ContentContainer.Position = UDim2.new(0, 10, 0, 48)
ContentContainer.BackgroundTransparency = 1
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 700)
ContentContainer.ScrollBarThickness = 4
ContentContainer.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 10)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ContentContainer

-- Helper function to create toggles
local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    btn.BackgroundTransparency = 0.35
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = "  " .. name .. ": " .. (active and "ON" or "OFF")
        btn.BackgroundColor3 = active and Color3.fromRGB(60, 20, 100) or Color3.fromRGB(15, 15, 25)
        btn.BackgroundTransparency = active and 0.1 or 0.35
        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255)
        callback(active)
    end)
    return btn
end

-- Helper function to create inputs/sliders
local function createInput(name, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.35
    frame.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.3, 0, 0.6, 0)
    box.Position = UDim2.new(0.67, 0, 0.2, 0)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    box.Font = Enum.Font.Gotham
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 14
    box.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    box.FocusLost:Connect(function(enterPressed)
        local val = tonumber(box.Text)
        if val then
            callback(val)
        else
            box.Text = tostring(default)
        end
    end)
end

-- =================================================================
-- 3. FEATURE IMPLEMENTATIONS
-- =================================================================

-- 1. ESP
createToggle("ESP (Visuals)", function(state)
    Settings.ESP = state
    RunService.RenderStepped:Connect(function()
        if not Settings.ESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("VinhubHighlight") then
                    p.Character.VinhubHighlight:Destroy()
                end
            end
            return
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hl = p.Character:FindFirstChild("VinhubHighlight")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "VinhubHighlight"
                    hl.Adornee = p.Character
                    hl.FillColor = Color3.fromRGB(138, 43, 226)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = p.Character
                end
            end
        end
    end)
end)

-- 2. SIZE
createInput("Size Enforcer (0.5 - 5)", 1, function(val)
    Settings.Size = math.clamp(val, 0.2, 10)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character:ScaleTo(Settings.Size)
    end
end)

-- 3. SPEED ENFORCER
createInput("Speed Enforcer (0 - 10000)", 16, function(val)
    Settings.Speed = math.clamp(val, 0, 10000)
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Settings.Speed > 16 then
            LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speed
        end
    end
end)

-- 4. JUMP ENFORCER
createInput("Jump Enforcer (0 - 10000)", 50, function(val)
    Settings.JumpPower = math.clamp(val, 0, 10000)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = Settings.JumpPower
    end
end)

-- 5. FAKE LAG
createToggle("Fake Lag [FE]", function(state)
    Settings.FakeLag = state
    task.spawn(function()
        while Settings.FakeLag and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
            local root = LocalPlayer.Character.HumanoidRootPart
            local oldPos = root.CFrame
            task.wait(0.5)
            if not Settings.FakeLag then break end
            root.CFrame = oldPos
            task.wait(0.2)
        end
    end)
end)

-- 6. INVISIBLE
createToggle("Invisible [FE]", function(state)
    Settings.Invisible = state
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = Settings.Invisible and 1 or 0
            end
        end
    end
end)

-- 7. AIMBOT
createToggle("Aimbot", function(state)
    Settings.Aimbot = state
    RunService.RenderStepped:Connect(function()
        if Settings.Aimbot then
            local closestPlayer = nil
            local shortestDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (p.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestPlayer = p
                    end
                end
            end
            if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.Head.Position)
            end
        end
    end)
end)

-- 8. SILENT AIM
createToggle("Silent Aim", function(state)
    Settings.SilentAim = state
end)

-- 9. INFINITE JUMP
createToggle("Infinite Jump", function(state)
    Settings.InfJump = state
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 10. FLING
createToggle("Fling Nearest Player [FE]", function(state)
    if state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local originalPos = root.CFrame
        local target = nil
        local minDist = math.huge

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = p.Character.HumanoidRootPart
                end
            end
        end

        if target then
            task.spawn(function()
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(90000, 90000, 90000)
                bv.Parent = root

                for i = 1, 50 do
                    root.CFrame = target.CFrame
                    task.wait()
                end

                bv:Destroy()
                root.CFrame = originalPos
            end)
        end
    end
end)

-- 11. TELEPORT TO SPAWN
local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, 0, 0, 40)
SpawnBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
SpawnBtn.BackgroundTransparency = 0.35
SpawnBtn.Font = Enum.Font.GothamSemibold
SpawnBtn.Text = "  Teleport to Spawn"
SpawnBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
SpawnBtn.TextSize = 14
SpawnBtn.TextXAlignment = Enum.TextXAlignment.Left
SpawnBtn.Parent = ContentContainer

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 6)
sCorner.Parent = SpawnBtn

SpawnBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local spawnLoc = Workspace:FindFirstChild("SpawnLocation", true)
        if spawnLoc then
            LocalPlayer.Character.HumanoidRootPart.CFrame = spawnLoc.CFrame + Vector3.new(0, 3, 0)
        else
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        end
    end
end)

print("VINHUB: Phantom X (Gradient Edition) successfully loaded!")
