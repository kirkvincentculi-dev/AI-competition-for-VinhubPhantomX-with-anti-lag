--[[
	VINHUB : PHANTOM X
	Single-file hub for your own Roblox game.
	Put this in a LocalScript (StarterPlayerScripts or StarterGui).

	Toggle: click the draggable logo icon, or press RightShift.
	Tags:   [FE]     = physics/character based, replicates through your own character
	        [VISUAL] = client-side only
]]

------------------------------------------------------------------
-- SERVICES / CONSTANTS
------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local LOGO = "rbxassetid://72121325627003" -- VINHUB logo (swap the ID if needed)
local GUI_NAME = "VinHubPhantomX"

local THEME = {
	bg      = Color3.fromRGB(16, 14, 24),
	panel   = Color3.fromRGB(26, 23, 40),
	row     = Color3.fromRGB(36, 32, 56),
	accent  = Color3.fromRGB(138, 92, 255),
	accent2 = Color3.fromRGB(88, 196, 255),
	text    = Color3.fromRGB(240, 238, 250),
	sub     = Color3.fromRGB(150, 146, 175),
	off     = Color3.fromRGB(70, 66, 96),
	good    = Color3.fromRGB(90, 220, 140),
	bad     = Color3.fromRGB(255, 90, 110),
}

------------------------------------------------------------------
-- STATE
------------------------------------------------------------------
local S = {
	target = nil, -- selected Player

	esp = false,
	espTeamColors = true,

	size = false, sizeValue = 2,
	speed = false, speedValue = 100,
	jump = false, jumpValue = 100,
	lag = false,
	invisible = false,

	aimbot = false, aimSmooth = 0.35, aimFov = 300, teamCheck = false,
	silent = false,

	infJump = false,
}

local connections = {}
local function track(c) table.insert(connections, c) return c end

-- remove old copy
local pg = LP:WaitForChild("PlayerGui")
local old = pg:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------
local function new(class, props, children)
	local inst = Instance.new(class)
	local parent = props and props.Parent
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then inst[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end

local function round(inst, r)
	new("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = inst})
end

local function getChar() return LP.Character end
local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function isAlive(plr)
	local c = plr.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart") ~= nil
end
local function sameTeam(plr)
	return LP.Team ~= nil and plr.Team == LP.Team
end

------------------------------------------------------------------
-- GUI ROOT
------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	Parent = pg,
})

-- notifications
local function notify(msg, color)
	local toast = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -40),
		Size = UDim2.new(0, 280, 0, 34),
		BackgroundColor3 = THEME.panel,
		Text = msg,
		TextColor3 = THEME.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		ZIndex = 50,
		Parent = gui,
	})
	round(toast, 10)
	new("UIStroke", {Color = color or THEME.accent, Thickness = 1.5, Parent = toast})
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 0, 20)}):Play()
	task.delay(2.2, function()
		local t = TweenService:Create(toast, TweenInfo.new(0.25), {Position = UDim2.new(0.5, 0, 0, -50), TextTransparency = 1, BackgroundTransparency = 1})
		t:Play()
		t.Completed:Wait()
		toast:Destroy()
	end)
end

-- draggable helper (click without moving = onClick)
local function makeDraggable(handle, target, onClick)
	local dragging, moved, dragStart, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onClick then onClick() end
				end
			end)
		end
	end)
	track(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end))
end

------------------------------------------------------------------
-- MAIN WINDOW
------------------------------------------------------------------
local window = new("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 350, 0, 470),
	BackgroundColor3 = THEME.bg,
	Visible = false,
	Parent = gui,
})
round(window, 14)
new("UIStroke", {Color = THEME.accent, Thickness = 1.5, Transparency = 0.3, Parent = window})
local windowScale = new("UIScale", {Scale = 1, Parent = window})

-- title bar
local titleBar = new("Frame", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = THEME.panel,
	Parent = window,
})
round(titleBar, 14)
new("Frame", { -- square off bottom corners
	Position = UDim2.new(0, 0, 1, -14),
	Size = UDim2.new(1, 0, 0, 14),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	Parent = titleBar,
})
new("UIGradient", {
	Color = ColorSequence.new(THEME.panel, Color3.fromRGB(44, 30, 78)),
	Rotation = 0,
	Parent = titleBar,
})
new("ImageLabel", {
	Position = UDim2.new(0, 10, 0.5, -15),
	Size = UDim2.new(0, 30, 0, 30),
	BackgroundTransparency = 1,
	Image = LOGO,
	Parent = titleBar,
})
new("TextLabel", {
	Position = UDim2.new(0, 48, 0, 4),
	Size = UDim2.new(1, -100, 0, 24),
	BackgroundTransparency = 1,
	Text = "VINHUB : Phantom X",
	TextColor3 = THEME.text,
	Font = Enum.Font.GothamBold,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})
new("TextLabel", {
	Position = UDim2.new(0, 48, 0, 26),
	Size = UDim2.new(1, -100, 0, 14),
	BackgroundTransparency = 1,
	Text = "RightShift or logo to toggle",
	TextColor3 = THEME.sub,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})
local closeBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.new(0, 28, 0, 28),
	BackgroundColor3 = THEME.row,
	Text = "X",
	TextColor3 = THEME.text,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	AutoButtonColor = true,
	Parent = titleBar,
})
round(closeBtn, 8)
makeDraggable(titleBar, window)

-- target selector
local targetBar = new("Frame", {
	Position = UDim2.new(0, 10, 0, 54),
	Size = UDim2.new(1, -20, 0, 34),
	BackgroundColor3 = THEME.panel,
	Parent = window,
})
round(targetBar, 8)
local targetBtn = new("TextButton", {
	Size = UDim2.new(1, -70, 1, 0),
	BackgroundTransparency = 1,
	Text = "  Target: none  v",
	TextColor3 = THEME.text,
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = targetBar,
})
local clearBtn = new("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -6, 0.5, 0),
	Size = UDim2.new(0, 58, 0, 24),
	BackgroundColor3 = THEME.row,
	Text = "Clear",
	TextColor3 = THEME.sub,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	Parent = targetBar,
})
round(clearBtn, 6)

-- tabs
local tabRow = new("Frame", {
	Position = UDim2.new(0, 10, 0, 96),
	Size = UDim2.new(1, -20, 0, 30),
	BackgroundTransparency = 1,
	Parent = window,
})
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	Parent = tabRow,
})

local pageHolder = new("Frame", {
	Position = UDim2.new(0, 10, 0, 134),
	Size = UDim2.new(1, -20, 1, -144),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = window,
})

local pages, tabButtons = {}, {}
local function selectTab(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, b in pairs(tabButtons) do
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = (n == name) and THEME.accent or THEME.panel,
			TextColor3 = (n == name) and Color3.new(1, 1, 1) or THEME.sub,
		}):Play()
	end
end

local function addTab(name)
	local b = new("TextButton", {
		Size = UDim2.new(0.25, -5, 1, 0),
		BackgroundColor3 = THEME.panel,
		Text = name,
		TextColor3 = THEME.sub,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Parent = tabRow,
	})
	round(b, 8)
	tabButtons[name] = b
	local page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = pageHolder,
	})
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
	new("UIPadding", {PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 4), Parent = page})
	pages[name] = page
	b.MouseButton1Click:Connect(function() selectTab(name) end)
	return page
end

------------------------------------------------------------------
-- CONTROL BUILDERS
------------------------------------------------------------------
local function tagBadge(parent, tag)
	if not tag then return end
	local col = (tag == "FE") and THEME.good or THEME.accent2
	local l = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -62, 0.5, 0),
		Size = UDim2.new(0, #tag * 8 + 14, 0, 16),
		BackgroundColor3 = col,
		BackgroundTransparency = 0.8,
		Text = tag,
		TextColor3 = col,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		Parent = parent,
	})
	round(l, 5)
end

local function section(page, text)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = text:upper(),
		TextColor3 = THEME.accent2,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = page,
	})
end

local function toggle(page, name, desc, tag, default, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, desc and 48 or 38),
		BackgroundColor3 = THEME.row,
		Parent = page,
	})
	round(row, 8)
	new("TextLabel", {
		Position = UDim2.new(0, 12, 0, desc and 6 or 0),
		Size = UDim2.new(1, -130, 0, desc and 18 or 38),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = THEME.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	if desc then
		new("TextLabel", {
			Position = UDim2.new(0, 12, 0, 25),
			Size = UDim2.new(1, -130, 0, 16),
			BackgroundTransparency = 1,
			Text = desc,
			TextColor3 = THEME.sub,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end
	tagBadge(row, tag)

	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 22),
		BackgroundColor3 = THEME.off,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	round(sw, 11)
	local knob = new("Frame", {
		Position = UDim2.new(0, 3, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = sw,
	})
	round(knob, 8)

	local state = default or false
	local function render()
		TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and THEME.accent or THEME.off}):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
	end
	render()
	sw.MouseButton1Click:Connect(function()
		state = not state
		render()
		callback(state)
	end)
	return function(v) state = v render() end
end

local function numberInput(page, name, default, min, max, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.row,
		Parent = page,
	})
	round(row, 8)
	new("TextLabel", {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Text = name .. "  (" .. min .. " - " .. max .. ")",
		TextColor3 = THEME.sub,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 90, 0, 24),
		BackgroundColor3 = THEME.panel,
		Text = tostring(default),
		TextColor3 = THEME.text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		ClearTextOnFocus = false,
		Parent = row,
	})
	round(box, 6)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if not n then n = default end
		n = math.clamp(n, min, max)
		box.Text = tostring(n)
		callback(n)
	end)
end

local function button(page, text, color, callback)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = color or THEME.accent,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Parent = page,
	})
	round(b, 8)
	b.MouseButton1Click:Connect(callback)
	return b
end

------------------------------------------------------------------
-- CORE FEATURES
------------------------------------------------------------------

------ Spawn point -----------------------------------------------
local spawnCF = nil
local function recordSpawn(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if root then
		task.wait(0.15)
		spawnCF = root.CFrame
	end
end

------ Size (R15 scale values) -----------------------------------
local scaleNames = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale"}
local function applySize(on)
	local hum = getHum()
	if not hum then return end
	for _, n in ipairs(scaleNames) do
		local v = hum:FindFirstChild(n)
		if v then v.Value = on and S.sizeValue or 1 end
	end
end

------ Invisible -------------------------------------------------
local origTransparency = setmetatable({}, {__mode = "k"})
local function applyInvisible(on)
	local char = getChar()
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			if on then
				if origTransparency[d] == nil then origTransparency[d] = d.Transparency end
				d.Transparency = 1
			elseif origTransparency[d] ~= nil then
				d.Transparency = origTransparency[d]
				origTransparency[d] = nil
			end
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if on then
				if origTransparency[d] == nil then origTransparency[d] = d.Transparency end
				d.Transparency = 1
			elseif origTransparency[d] ~= nil then
				d.Transparency = origTransparency[d]
				origTransparency[d] = nil
			end
		end
	end
end

------ Fake lag --------------------------------------------------
local lagToken = 0
local function setLag(on)
	lagToken += 1
	local my = lagToken
	if not on then
		local r = getRoot()
		if r then r.Anchored = false end
		return
	end
	task.spawn(function()
		while S.lag and lagToken == my do
			local r = getRoot()
			if r then
				r.Anchored = true
				task.wait(0.35)
				r.Anchored = false
			end
			task.wait(0.22)
		end
		local r = getRoot()
		if r then r.Anchored = false end
	end)
end

------ ESP --------------------------------------------------------
local espObjects = {}
local function clearEsp(plr)
	local o = espObjects[plr]
	if o then
		if o.hl then o.hl:Destroy() end
		if o.bb then o.bb:Destroy() end
		espObjects[plr] = nil
	end
end
local function buildEsp(plr)
	clearEsp(plr)
	if plr == LP or not S.esp then return end
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not head then return end

	local hl = new("Highlight", {
		Adornee = char,
		FillTransparency = 0.6,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Parent = gui,
	})
	local bb = new("BillboardGui", {
		Adornee = head,
		Size = UDim2.new(0, 160, 0, 36),
		StudsOffset = Vector3.new(0, 2.4, 0),
		AlwaysOnTop = true,
		Parent = gui,
	})
	local lbl = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = plr.DisplayName,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Parent = bb,
	})
	espObjects[plr] = {hl = hl, bb = bb, lbl = lbl}
end
local function refreshEsp()
	for _, p in ipairs(Players:GetPlayers()) do
		if S.esp then buildEsp(p) else clearEsp(p) end
	end
end

------ Aimbot / Silent aim target selection -----------------------
local function screenDist(part)
	local v, onScreen = Camera:WorldToViewportPoint(part.Position)
	if not onScreen then return math.huge end
	local m = UIS:GetMouseLocation()
	return (Vector2.new(v.X, v.Y) - m).Magnitude
end

local function closestPlayerPart()
	local best, bestD = nil, S.aimFov
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and isAlive(p) and not (S.teamCheck and sameTeam(p)) then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local d = screenDist(head)
				if d < bestD then best, bestD = head, d end
			end
		end
	end
	return best
end

local function getTargetPart()
	if S.target and isAlive(S.target) then
		return S.target.Character:FindFirstChild("Head")
	end
	return closestPlayerPart()
end

-- Public API so your own weapon scripts can ask for the silent-aim part:
--   local part = _G.PhantomX.GetSilentAimPart()
_G.PhantomX = {
	GetSilentAimPart = function()
		if not S.silent then return nil end
		return getTargetPart()
	end,
}

-- Optional automatic hook (only works where hookmetamethod exists)
pcall(function()
	if not (hookmetamethod and newcclosure and getnamecallmethod) then return end
	local oldNC
	oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if S.silent and self == Workspace and method == "Raycast" and not (checkcaller and checkcaller()) then
			local args = {...}
			local origin, dir = args[1], args[2]
			local part = getTargetPart()
			if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" and part then
				args[2] = (part.Position - origin).Unit * dir.Magnitude
				return oldNC(self, table.unpack(args))
			end
		end
		return oldNC(self, ...)
	end))

	local mouse = LP:GetMouse()
	local oldIdx
	oldIdx = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if S.silent and self == mouse and not (checkcaller and checkcaller()) then
			local part = getTargetPart()
			if part then
				if key == "Hit" then return part.CFrame end
				if key == "Target" then return part end
			end
		end
		return oldIdx(self, key)
	end))
end)

------ Fling ------------------------------------------------------
local flinging = false
local function stopFling() flinging = false end

local function startFling()
	if flinging then return notify("Fling already running", THEME.bad) end
	local target = S.target
	if not target or not target.Parent then return notify("Select a target first", THEME.bad) end
	if not isAlive(target) then return notify("Target is not alive", THEME.bad) end
	local root = getRoot()
	if not root then return end

	local origin = root.CFrame -- go back here when done
	local startPos = target.Character.HumanoidRootPart.Position
	flinging = true
	notify("Flinging " .. target.DisplayName, THEME.accent)

	local conn = RunService.Heartbeat:Connect(function()
		local myRoot = getRoot()
		local tc = target.Character
		local tRoot = tc and tc:FindFirstChild("HumanoidRootPart")
		if not flinging or not myRoot or not tRoot then return end
		for _, p in ipairs(getChar():GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
		-- stick to the target and spin hard
		myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 0.5)
		myRoot.AssemblyAngularVelocity = Vector3.new(0, 1e5, 0)
		myRoot.AssemblyLinearVelocity = Vector3.new(
			math.random(-1, 1) * 5000, 2500, math.random(-1, 1) * 5000)
	end)

	task.spawn(function()
		local t0 = os.clock()
		local flung = false
		while flinging and os.clock() - t0 < 10 do
			local tc = target.Character
			local tRoot = tc and tc:FindFirstChild("HumanoidRootPart")
			local hum = tc and tc:FindFirstChildOfClass("Humanoid")
			if not tRoot or not hum or hum.Health <= 0 then break end
			if tRoot.AssemblyLinearVelocity.Magnitude > 300 or (tRoot.Position - startPos).Magnitude > 80 then
				flung = true
				task.wait(0.25)
				break
			end
			RunService.Heartbeat:Wait()
		end
		flinging = false
		conn:Disconnect()

		-- return to where the fling started
		for _ = 1, 6 do
			local r = getRoot()
			if r then
				r.AssemblyAngularVelocity = Vector3.zero
				r.AssemblyLinearVelocity = Vector3.zero
				r.CFrame = origin
			end
			RunService.Heartbeat:Wait()
		end
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
		notify(flung and "Target flinged - returned" or "Fling ended - returned", flung and THEME.good or THEME.sub)
	end)
end

------ Teleports --------------------------------------------------
local function tpSpawn()
	local r = getRoot()
	if r and spawnCF then
		r.CFrame = spawnCF + Vector3.new(0, 3, 0)
		notify("Teleported to spawn", THEME.good)
	else
		notify("Spawn not recorded yet", THEME.bad)
	end
end
local function tpTarget()
	local t = S.target
	if not t or not isAlive(t) then return notify("Select a living target", THEME.bad) end
	local r = getRoot()
	if r then
		r.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		notify("Teleported to " .. t.DisplayName, THEME.good)
	end
end

------------------------------------------------------------------
-- PAGES
------------------------------------------------------------------
local combat   = addTab("Combat")
local player   = addTab("Player")
local visual   = addTab("Visual")
local teleport = addTab("Teleport")

-- Combat
section(combat, "Aim")
toggle(combat, "Aimbot", "Hold right mouse. Uses target or nearest to cursor", nil, false, function(v) S.aimbot = v end)
toggle(combat, "Team check", "Ignore teammates", nil, false, function(v) S.teamCheck = v end)
numberInput(combat, "Smoothness", S.aimSmooth, 0.05, 1, function(n) S.aimSmooth = n end)
numberInput(combat, "Aim FOV (px)", S.aimFov, 50, 1000, function(n) S.aimFov = n end)
section(combat, "Shooting")
toggle(combat, "Silent aim", "Shoots at target while you stay in place", nil, false, function(v)
	S.silent = v
	if v then notify("Silent aim on") end
end)
section(combat, "Fling")
button(combat, "Fling selected player", THEME.accent, startFling)
button(combat, "Stop fling", THEME.bad, function() stopFling() end)

-- Player
section(player, "Movement")
toggle(player, "Speed enforcer", "Keeps your WalkSpeed locked", nil, false, function(v)
	S.speed = v
	if not v then local h = getHum() if h then h.WalkSpeed = 16 end end
end)
numberInput(player, "Speed", S.speedValue, 0, 10000, function(n) S.speedValue = n end)
toggle(player, "Jump enforcer", "Keeps your JumpPower locked", nil, false, function(v)
	S.jump = v
	if not v then local h = getHum() if h then h.JumpPower = 50 end end
end)
numberInput(player, "Jump power", S.jumpValue, 0, 10000, function(n) S.jumpValue = n end)
toggle(player, "Infinite jump", "Jump with no cooldown", nil, false, function(v) S.infJump = v end)
section(player, "Character")
toggle(player, "Size", "Changes your size (R15)", "FE", false, function(v)
	S.size = v
	applySize(v)
end)
numberInput(player, "Size scale", S.sizeValue, 0.3, 10, function(n)
	S.sizeValue = n
	if S.size then applySize(true) end
end)
toggle(player, "Invisible", "Hides your character", "FE", false, function(v)
	S.invisible = v
	applyInvisible(v)
end)
toggle(player, "Fake lag", "Pretend you're lagging", "FE", false, function(v)
	S.lag = v
	setLag(v)
end)

-- Visual
section(visual, "ESP")
toggle(visual, "Player ESP", "Highlights and names players", "VISUAL", false, function(v)
	S.esp = v
	refreshEsp()
end)
toggle(visual, "Team colors", "Green for teammates, red for enemies", "VISUAL", true, function(v) S.espTeamColors = v end)

-- Teleport
section(teleport, "Teleports")
button(teleport, "Teleport to spawn", THEME.accent, tpSpawn)
button(teleport, "Teleport to selected player", THEME.accent2, tpTarget)

selectTab("Combat")

------------------------------------------------------------------
-- TARGET DROPDOWN
------------------------------------------------------------------
local dropdown = new("ScrollingFrame", {
	Position = UDim2.new(0, 10, 0, 90),
	Size = UDim2.new(1, -20, 0, 180),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Visible = false,
	ZIndex = 20,
	Parent = window,
})
round(dropdown, 8)
new("UIStroke", {Color = THEME.accent, Thickness = 1, Parent = dropdown})
new("UIListLayout", {Padding = UDim.new(0, 2), Parent = dropdown})

local function setTarget(plr)
	S.target = plr
	targetBtn.Text = "  Target: " .. (plr and plr.DisplayName or "none") .. "  v"
end

local function rebuildDropdown()
	for _, c in ipairs(dropdown:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = THEME.row,
				Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")",
				TextColor3 = THEME.text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 21,
				Parent = dropdown,
			})
			round(b, 6)
			b.MouseButton1Click:Connect(function()
				setTarget(p)
				dropdown.Visible = false
			end)
		end
	end
end

targetBtn.MouseButton1Click:Connect(function()
	rebuildDropdown()
	dropdown.Visible = not dropdown.Visible
end)
clearBtn.MouseButton1Click:Connect(function()
	setTarget(nil)
	dropdown.Visible = false
end)

track(Players.PlayerRemoving:Connect(function(p)
	clearEsp(p)
	if S.target == p then
		setTarget(nil)
		stopFling()
	end
end))

------------------------------------------------------------------
-- DRAGGABLE LOGO TOGGLE
------------------------------------------------------------------
local function setWindow(open)
	if open then
		window.Visible = true
		windowScale.Scale = 0.92
		TweenService:Create(windowScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	else
		dropdown.Visible = false
		window.Visible = false
	end
end

local icon = new("ImageButton", {
	Name = "ToggleIcon",
	Position = UDim2.new(0, 20, 0.5, -28),
	Size = UDim2.new(0, 56, 0, 56),
	BackgroundColor3 = THEME.bg,
	Image = LOGO,
	ScaleType = Enum.ScaleType.Fit,
	AutoButtonColor = false,
	ZIndex = 30,
	Parent = gui,
})
round(icon, 28)
new("UIStroke", {Color = THEME.accent, Thickness = 2, Parent = icon})
makeDraggable(icon, icon, function() setWindow(not window.Visible) end)

closeBtn.MouseButton1Click:Connect(function() setWindow(false) end)
track(UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		setWindow(not window.Visible)
	end
end))

------------------------------------------------------------------
-- MAIN LOOPS
------------------------------------------------------------------
-- movement enforcers + ESP refresh
local espTick = 0
track(RunService.Heartbeat:Connect(function(dt)
	local hum = getHum()
	if hum then
		if S.speed then hum.WalkSpeed = S.speedValue end
		if S.jump then
			hum.UseJumpPower = true
			hum.JumpPower = S.jumpValue
		end
	end

	if S.esp then
		espTick += dt
		if espTick > 0.2 then
			espTick = 0
			local myRoot = getRoot()
			for plr, o in pairs(espObjects) do
				if isAlive(plr) then
					local col = Color3.fromRGB(255, 70, 90)
					if S.espTeamColors and sameTeam(plr) then col = Color3.fromRGB(80, 230, 130) end
					o.hl.FillColor = col
					o.hl.OutlineColor = col
					local dist = myRoot and math.floor((plr.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude) or 0
					o.lbl.Text = plr.DisplayName .. "  [" .. dist .. "m]"
					o.lbl.TextColor3 = col
				end
			end
		end
	end
end))

-- aimbot
track(RunService.RenderStepped:Connect(function()
	if not S.aimbot then return end
	local holding = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UIS.TouchEnabled
	if not holding then return end
	local part = getTargetPart()
	if part then
		local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
		Camera.CFrame = Camera.CFrame:Lerp(goal, S.aimSmooth)
	end
end))

-- infinite jump
track(UIS.JumpRequest:Connect(function()
	if S.infJump then
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end))

------------------------------------------------------------------
-- CHARACTER / PLAYER LIFECYCLE
------------------------------------------------------------------
local function onMyCharacter(char)
	task.spawn(recordSpawn, char)
	task.wait(0.6)
	if S.size then applySize(true) end
	if S.invisible then applyInvisible(true) end
	if S.lag then setLag(true) end
end
track(LP.CharacterAdded:Connect(onMyCharacter))
if LP.Character then task.spawn(onMyCharacter, LP.Character) end

local function watchPlayer(p)
	if p == LP then return end
	track(p.CharacterAdded:Connect(function()
		task.wait(0.4)
		if S.esp then buildEsp(p) end
	end))
	if p.Character and S.esp then buildEsp(p) end
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
track(Players.PlayerAdded:Connect(watchPlayer))

gui.Destroying:Connect(function()
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	setLag(false)
	for p in pairs(espObjects) do clearEsp(p) end
end)

notify("VINHUB : Phantom X loaded", THEME.good)
