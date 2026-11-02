-- =============================================
--  VINHUB: Phantom X
--  Logo ID: 72121325627003
--  All-in-One • Ready to Paste ✅
-- =============================================

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Settings
local Settings = {
    Enabled = false,
    Speed = 16,
    JumpPower = 50,
    SizeScale = 1,
    Invisible = false,
    InfiniteJump = false,
    FakeLag = false,
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(0, 255, 100),
    LastJump = 0
}

-- Create UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VinHubPhantomX"
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ===== DRAGGABLE LOGO TOGGLE (YOUR IMAGE!) =====
local LogoButton = Instance.new("ImageButton")
LogoButton.Name = "LogoButton"
LogoButton.Size = UDim2.new(0, 55, 0, 55)
LogoButton.Position = UDim2.new(0.02, 0, 0.5, 0)
LogoButton.BackgroundTransparency = 0
LogoButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
LogoButton.BorderSizePixel = 2
LogoButton.BorderColor3 = Color3.fromRGB(0, 100, 255)
LogoButton.CornerRadius = UDim.new(0.15, 0)
LogoButton.Image = "rbxassetid://72121325627003"  -- ✅ YOUR LOGO HERE
LogoButton.Parent = ScreenGui

-- ===== MAIN MENU =====
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.08, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 85, 210)
MainFrame.CornerRadius = UDim.new(0.04, 0)
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 35, 90)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "⚡ VINHUB: Phantom X"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 5, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local StatusIndicator = Instance.new("TextLabel")
StatusIndicator.Text = "● OFF"
StatusIndicator.Font = Enum.Font.Gotham
StatusIndicator.TextSize = 12
StatusIndicator.TextColor3 = Color3.fromRGB(255, 80, 80)
StatusIndicator.BackgroundTransparency = 1
StatusIndicator.Size = UDim2.new(0, 70, 1, 0)
StatusIndicator.Position = UDim2.new(1, -75, 0, 0)
StatusIndicator.Parent = TitleBar

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -35)
ScrollFrame.Position = UDim2.new(0, 0, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarColor3 = Color3.fromRGB(0, 100, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 720)
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = ScrollFrame

-- ===== HELPER: CREATE TOGGLE =====
local function MakeToggle(name, callback)
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(0.92, 0, 0, 32)
	Container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	Container.CornerRadius = UDim.new(0.08, 0)

	local Label = Instance.new("TextLabel")
	Label.Text = name
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 13
	Label.TextColor3 = Color3.fromRGB(230, 230, 230)
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.Size = UDim2.new(0.7, 0, 1, 0)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Container

	local Switch = Instance.new("TextButton")
	Switch.Size = UDim2.new(0, 40, 0, 22)
	Switch.Position = UDim2.new(1, -50, 0.5, -11)
	Switch.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	Switch.CornerRadius = UDim.new(0.5, 0)
	Switch.Text = ""
	Switch.Parent = Container

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.new(0, 16, 0, 16)
	Knob.Position = UDim2.new(0, 3, 0.5, -8)
	Knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	Knob.CornerRadius = UDim.new(1, 0)
	Knob.Parent = Switch

	local isOn = false
	Switch.MouseButton1Click:Connect(function()
		isOn = not isOn
		TweenService:Create(Knob, TweenInfo.new(0.12), {Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
		TweenService:Create(Switch, TweenInfo.new(0.15), {BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(80, 80, 100)}):Play()
		callback(isOn)
	end)

	Container.Parent = ScrollFrame
	return Container
end

-- ===== HELPER: CREATE SLIDER =====
local function MakeSlider(name, min, max, default, callback)
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(0.92, 0, 0, 55)
	Container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	Container.CornerRadius = UDim.new(0.06, 0)

	local Label = Instance.new("TextLabel")
	Label.Text = name .. ": " .. default
	Label.Name = "Label"
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 12
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.new(0, 10, 0, 4)
	Label.Size = UDim2.new(1, -10, 0, 20)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Container

	local BarBg = Instance.new("Frame")
	BarBg.Size = UDim2.new(1, -20, 0, 8)
	BarBg.Position = UDim2.new(0, 10, 0, 35)
	BarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	BarBg.CornerRadius = UDim.new(1, 0)
	BarBg.Parent = Container

	local BarFill = Instance.new("Frame")
	BarFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	BarFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
	BarFill.CornerRadius = UDim.new(1, 0)
	BarFill.Parent = BarBg

	local value = default
	local dragging = false

	local function UpdateFromMouse(x)
		local rel = (x - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X
		rel = math.clamp(rel, 0, 1)
		value = math.floor(min + (max - min) * rel + 0.5)
		BarFill.Size = UDim2.new(rel, 0, 1, 0)
		Label.Text = name .. ": " .. value
		callback(value)
	end

	BarBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			UpdateFromMouse(i.Position.X)
		end
	end)

	Container.Parent = ScrollFrame
	return Container
end

-- ===== HELPER: CREATE BUTTON =====
local function MakeButton(name, callback)
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(0.92, 0, 0, 34)
	Btn.BackgroundColor3 = Color3.fromRGB(35, 70, 120)
	Btn.Text = name
	Btn.Font = Enum.Font.GothamBold
	Btn.TextSize = 13
	Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Btn.CornerRadius = UDim.new(0.08, 0)
	Btn.AutoButtonColor = false
	Btn.MouseButton1Click:Connect(callback)
	Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 100, 170)}):Play() end)
	Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 70, 120)}):Play() end)
	Btn.Parent = ScrollFrame
	return Btn
end

-- ===== BUILD MENU OPTIONS =====
MakeToggle("👁 Player ESP", function(state)
	Settings.ESPEnabled = state
	StatusIndicator.Text = state and "● ON" or "● OFF"
	StatusIndicator.TextColor3 = state and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)
end)

MakeSlider("📐 Size", 50, 300, 100, function(val)
	Settings.SizeScale = val / 100
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.BodyHeightScale = Settings.SizeScale
		char.Humanoid.BodyWidthScale = Settings.SizeScale
		char.Humanoid.BodyDepthScale = Settings.SizeScale
	end
end)

MakeSlider("🏃 WalkSpeed", 16, 100, 16, function(val)
	Settings.Speed = val
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = val
	end
end)

MakeSlider("⬆ JumpPower", 50, 120, 50, function(val)
	Settings.JumpPower = val
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.JumpPower = val
	end
end)

MakeToggle("👻 Invisible", function(state)
	Settings.Invisible = state
	local char = LocalPlayer.Character
	if char then
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = state and 0.75 or 0
			end
		end
	end
end)

MakeToggle("🔄 Infinite Jump", function(state)
	Settings.InfiniteJump = state
end)

MakeToggle("📡 Fake Lag (Cosmetic)", function(state)
	Settings.FakeLag = state
end)

MakeButton("🏠 Teleport to Spawn", function()
	local SpawnLocation = workspace:FindFirstChild("SpawnLocation")
	local char = LocalPlayer.Character
	if SpawnLocation and char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(SpawnLocation.Position + Vector3.new(0, 4, 0))
	end
end)

-- ===== DRAG LOGO BUTTON =====
local dragStart, startPos
LogoButton.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragStart = UserInputService:GetMouseLocation()
		startPos = LogoButton.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragStart and i.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = UserInputService:GetMouseLocation()
		LogoButton.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X - dragStart.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y - dragStart.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragStart = nil end
end)

-- ===== TOGGLE MENU VISIBILITY =====
local menuOpen = false
LogoButton.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	MainFrame.Visible = menuOpen
end)

-- ===== INFINITE JUMP LOGIC =====
UserInputService.JumpRequest:Connect(function()
	if Settings.InfiniteJump and os.clock() - Settings.LastJump > 0.1 then
		Settings.LastJump = os.clock()
		local char = LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.Jump = true
		end
	end
end)

-- ===== ESP SYSTEM =====
local ESPObjects = {}
local function AddESP(player)
	local function SetupChar(char)
		local hrp = char:WaitForChild("HumanoidRootPart")

		local Billboard = Instance.new("BillboardGui")
		Billboard.AlwaysOnTop = true
		Billboard.Size = UDim2.new(0, 140, 0, 30)
		Billboard.Adornee = hrp
		Billboard.Parent = char

		local NameTag = Instance.new("TextLabel")
		NameTag.Text = "🔹 " .. player.Name
		NameTag.Font = Enum.Font.GothamBold
		NameTag.TextSize = 11
		NameTag.TextColor3 = Settings.ESPColor
		NameTag.BackgroundTransparency = 1
		NameTag.Size = UDim2.new(1, 0, 1, 0)
		NameTag.Parent = Billboard

		local Health = Instance.new("TextLabel")
		Health.Text = ""
		Health.Font = Enum.Font.Gotham
		Health.TextSize = 9
		Health.TextColor3 = Color3.fromRGB(180, 180, 180)
		Health.BackgroundTransparency = 1
		Health.Size = UDim2.new(1, 0, 0, 12)
		Health.Position = UDim2.new(0, 0, 1, -12)
		Health.Parent = Billboard

		ESPObjects[player] = {Billboard, Health}

		char.AncestryChanged:Connect(function()
			if not char:IsDescendantOf(workspace) then
				Billboard:Destroy()
				ESPObjects[player] = nil
			end
		end)
	end

	if player ~= LocalPlayer then
		if player.Character then task.spawn(SetupChar, player.Character) end
		player.CharacterAdded:Connect(SetupChar)
	end
end

-- Initialize ESP
for _, p in ipairs(Players:GetPlayers()) do task.spawn(AddESP, p) end
Players.PlayerAdded:Connect(AddESP)

-- Update loop
RunService.RenderStepped:Connect(function()
	for pl, objs in pairs(ESPObjects) do
		local bb, hp = objs[1], objs[2]
		bb.Enabled = Settings.ESPEnabled
		if pl.Character and pl.Character:FindFirstChild("Humanoid") then
			hp.Text = math.floor(pl.Character.Humanoid.Health) .. " HP"
		end
	end

	if Settings.Invisible then
		local char = LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0.75
				end
			end
		end
	end
end)

-- Character reload recovery
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid")
	task.wait(0.15)
	char.Humanoid.WalkSpeed = Settings.Speed
	char.Humanoid.JumpPower = Settings.JumpPower
	char.Humanoid.BodyHeightScale = Settings.SizeScale
	char.Humanoid.BodyWidthScale = Settings.SizeScale
	char.Humanoid.BodyDepthScale = Settings.SizeScale
end)

print("✅ VINHUB: Phantom X Loaded! Logo attached & ready.")
