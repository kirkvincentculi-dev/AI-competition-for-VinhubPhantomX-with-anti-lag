-- VinHub:Anti Lag
-- Put this in a LocalScript inside StarterPlayer > StarterPlayerScripts
-- (you can name the LocalScript "VinHub:Anti Lag").
--
-- 1) Distance culling: only parts within RENDER_DISTANCE studs of you are drawn.
-- 2) Graphics switch (High / Low): Low turns down the quality level, shadows,
--    post effects, particles and water. Press G or tap the on-screen button.
-- 3) 60 FPS cap: caps frames at FPS_CAP using setfpscap, when your environment
--    provides it. Roblox does not give normal scripts a way to set an FPS cap.
-- Everything is local (only your screen). Switching back to High restores
-- what the game had before.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local terrain = workspace.Terrain

-- SETTINGS
local RENDER_DISTANCE = 100   -- studs (100 studs is about 28 m)
local CHECK_INTERVAL = 0.5    -- seconds between culling passes
local PARTS_PER_STEP = 500    -- parts processed per frame
local START_LOW = true        -- start in Low graphics
local TOGGLE_KEY = Enum.KeyCode.G
local FPS_CAP = 60            -- frames per second cap (0 = leave it alone)

-- Safe property helpers (some properties can be locked on some setups)
local function getProp(inst, prop)
	local ok, value = pcall(function()
		return inst[prop]
	end)
	if ok then
		return value
	end
	return nil
end

local function setProp(inst, prop, value)
	pcall(function()
		inst[prop] = value
	end)
end

-- Returns true if the FPS cap was applied
local function capFps(fps)
	if typeof(setfpscap) ~= "function" then
		return false
	end
	return (pcall(setfpscap, fps))
end

-- STATE
local lowGraphics = false
local applying = false

local parts = {}   -- [BasePart] = true
local effects = {} -- [ParticleEmitter / Trail / Beam / ...] = true
local hidden = setmetatable({}, { __mode = "k" })       -- [BasePart] = true while culled
local origShadow = setmetatable({}, { __mode = "k" })   -- original CastShadow
local origEnabled = setmetatable({}, { __mode = "k" })  -- original effect Enabled
local origPost = setmetatable({}, { __mode = "k" })     -- original post effect Enabled

local origQuality = getProp(settings().Rendering, "QualityLevel")
local origGlobalShadows = Lighting.GlobalShadows

local terrainLow = { WaterWaveSize = 0, WaterReflectance = 0, Decoration = false }
local terrainOrig = {}
for prop in pairs(terrainLow) do
	terrainOrig[prop] = getProp(terrain, prop)
end

-- TRACKING
local function refreshShadow(part)
	part.CastShadow = (not lowGraphics) and (hidden[part] ~= true) and (origShadow[part] == true)
end

local function isEffect(inst)
	return inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
		or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles")
end

local function track(inst)
	if inst:IsA("BasePart") then
		if inst:IsA("Terrain") then
			return
		end
		parts[inst] = true
		if origShadow[inst] == nil then
			origShadow[inst] = inst.CastShadow
		end
		if lowGraphics then
			inst.CastShadow = false
		end
	elseif isEffect(inst) then
		effects[inst] = true
		if origEnabled[inst] == nil then
			origEnabled[inst] = inst.Enabled
		end
		if lowGraphics then
			inst.Enabled = false
		end
	end
end

local function trackPost(inst)
	if inst:IsA("PostEffect") then
		if origPost[inst] == nil then
			origPost[inst] = inst.Enabled
		end
		if lowGraphics then
			inst.Enabled = false
		end
	end
end

for _, inst in ipairs(workspace:GetDescendants()) do
	track(inst)
end
for _, inst in ipairs(Lighting:GetDescendants()) do
	trackPost(inst)
end

workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(inst)
	parts[inst] = nil
	effects[inst] = nil
end)
Lighting.DescendantAdded:Connect(trackPost)

-- DISTANCE CULLING
local function setHidden(part, state)
	if (hidden[part] == true) == state then
		return
	end
	hidden[part] = state or nil
	part.LocalTransparencyModifier = state and 1 or 0
	refreshShadow(part)
end

local list, index, elapsed = {}, 1, 0
local maxDistSq = RENDER_DISTANCE * RENDER_DISTANCE

RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- Start a new pass when the interval is up and the last pass is done
	if index > #list then
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		list = {}
		for part in pairs(parts) do
			table.insert(list, part)
		end
		index = 1
	end

	local origin = root.Position
	local last = math.min(index + PARTS_PER_STEP - 1, #list)
	for i = index, last do
		local part = list[i]
		if part.Parent then
			local d = part.Position - origin
			setHidden(part, d:Dot(d) > maxDistSq)
		end
	end
	index = last + 1
end)

-- ON-SCREEN PANEL
local gui = Instance.new("ScreenGui")
gui.Name = "VinHub:Anti Lag"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 86)
frame.Position = UDim2.new(1, -160, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "VinHub:Anti Lag"
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -16, 0, 32)
button.Position = UDim2.new(0, 8, 0, 26)
button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
button.BorderSizePixel = 0
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "Graphics: High"
button.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 22)
status.Position = UDim2.new(0, 0, 0, 62)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Text = ""
status.Parent = frame

-- FPS CAP
if FPS_CAP > 0 then
	if capFps(FPS_CAP) then
		status.Text = "FPS cap: " .. FPS_CAP
	else
		status.Text = "FPS cap: not supported"
	end
else
	status.Text = "FPS cap: off"
end

-- APPLY HIGH / LOW
local function applyGraphics(low)
	if applying then
		return
	end
	applying = true
	lowGraphics = low
	button.Text = low and "Graphics: Low" or "Graphics: High"

	-- Roblox quality level (1 = lowest). May be ignored on some devices.
	setProp(settings().Rendering, "QualityLevel", low and Enum.QualityLevel.Level01 or origQuality)

	-- Global shadows
	if low then
		Lighting.GlobalShadows = false
	else
		Lighting.GlobalShadows = origGlobalShadows
	end

	-- Water and terrain decoration
	for prop, lowValue in pairs(terrainLow) do
		if low then
			setProp(terrain, prop, lowValue)
		else
			setProp(terrain, prop, terrainOrig[prop])
		end
	end

	-- Bloom, blur, sun rays, color correction, depth of field
	for _, inst in ipairs(Lighting:GetDescendants()) do
		if origPost[inst] ~= nil then
			inst.Enabled = (not low) and origPost[inst]
		end
	end

	-- Particles, trails, beams
	for effect in pairs(effects) do
		effect.Enabled = (not low) and (origEnabled[effect] == true)
	end

	-- Part shadows (in chunks so the game does not freeze)
	local snapshot = {}
	for part in pairs(parts) do
		table.insert(snapshot, part)
	end
	for i, part in ipairs(snapshot) do
		if part.Parent then
			refreshShadow(part)
		end
		if i % 1000 == 0 then
			task.wait()
		end
	end

	applying = false
end

button.Activated:Connect(function()
	applyGraphics(not lowGraphics)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == TOGGLE_KEY then
		applyGraphics(not lowGraphics)
	end
end)

applyGraphics(START_LOW)
