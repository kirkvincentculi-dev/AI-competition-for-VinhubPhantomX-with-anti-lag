-- VINHUB: Phantom X
-- One file. Put this in a LocalScript under StarterPlayer > StarterPlayerScripts.
-- The logo is the button: drag it anywhere, click it to open or close the hub.
-- Right Shift also toggles the hub.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

if RunService:IsServer() and not RunService:IsClient() then
	warn("[Phantom X] Client only. Use a LocalScript in StarterPlayerScripts.")
	return
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local LOGO_IMAGE = "rbxassetid://72121325627003"
local TOGGLE_KEY = Enum.KeyCode.RightShift

local C = {
	void = Color3.fromRGB(7, 6, 10),
	panel = Color3.fromRGB(16, 12, 22),
	card = Color3.fromRGB(26, 20, 36),
	cardHi = Color3.fromRGB(36, 28, 50),
	text = Color3.fromRGB(244, 240, 255),
	muted = Color3.fromRGB(155, 147, 174),
	red = Color3.fromRGB(255, 46, 72),
	blue = Color3.fromRGB(76, 141, 255),
	violet = Color3.fromRGB(180, 76, 255),
	magenta = Color3.fromRGB(255, 61, 154),
	line = Color3.fromRGB(58, 46, 78),
	good = Color3.fromRGB(72, 220, 140),
}

local T_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local T_MED = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local State = {
	esp = false,
	espNames = true,
	espHealth = true,
	espDistance = true,
	teamCheck = true,
	sizeOn = false,
	size = 1,
	speedOn = false,
	speed = 16,
	jumpOn = false,
	jump = 50,
	infJump = false,
	fakeLag = false,
	lag = 40,
	invisible = false,
	aimbot = false,
	silent = false,
	silentMode = "Team",
	aimPart = "Head",
	smooth = 0.25,
	fov = 140,
	showFov = true,
	targetUserId = nil,
}

local dead = false
local bin = {}
local screenGui
local espMap = {}
local defaults = {}
local seenAt = {}
local savedTrans = {}
local savedEnabled = {}
local spawnCF
local flinging = false
local silentHooks = false
local opened = false
local popup

local restoreAll
local notify
local refreshTarget
local setOpen

local function listen(conn)
	table.insert(bin, conn)
	return conn
end

local function shutdown()
	if dead then
		return
	end
	dead = true
	flinging = false
	pcall(function()
		settings().Network.IncomingReplicationLag = 0
	end)
	if restoreAll then
		pcall(restoreAll)
	end
	for _, conn in ipairs(bin) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	if popup then
		pcall(function()
			popup:Destroy()
		end)
		popup = nil
	end
	if screenGui then
		pcall(function()
			screenGui:Destroy()
		end)
		screenGui = nil
	end
	if _G.__PhantomXCleanup == shutdown then
		_G.__PhantomXCleanup = nil
	end
end

if type(_G.__PhantomXCleanup) == "function" then
	pcall(_G.__PhantomXCleanup)
end
_G.__PhantomXCleanup = shutdown

local function corner(inst, radius)
	local c = Instance.new("UICorner")
	if typeof(radius) == "number" then
		c.CornerRadius = UDim.new(0, radius)
	else
		c.CornerRadius = radius
	end
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function getChar(plr)
	plr = plr or LocalPlayer
	local char = plr and plr.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return nil
	end
	return char, hum, hrp
end

local function playerById(userId)
	if not userId or userId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function sameTeam(plr)
	if not plr or plr == LocalPlayer then
		return false
	end
	if LocalPlayer.Neutral or plr.Neutral then
		return false
	end
	return plr.Team ~= nil and plr.Team == LocalPlayer.Team
end

local function isEnemy(plr)
	if not plr or plr == LocalPlayer then
		return false
	end
	if not State.teamCheck then
		return true
	end
	return not sameTeam(plr)
end

local function aimPartOf(plr)
	local char = plr and plr.Character
	if not char then
		return nil
	end
	local name = State.aimPart == "Torso" and "UpperTorso" or "Head"
	return char:FindFirstChild(name)
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("Head")
		or char:FindFirstChild("HumanoidRootPart")
end

local function closestInFov(enemiesOnly)
	local cam = Workspace.CurrentCamera
	if not cam then
		return nil
	end
	local center = cam.ViewportSize * 0.5
	local best, bestDist
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and (not enemiesOnly or isEnemy(plr)) then
			local part = aimPartOf(plr)
			if part then
				local v, onScreen = cam:WorldToViewportPoint(part.Position)
				if onScreen and v.Z > 0 then
					local dist = (Vector2.new(v.X, v.Y) - center).Magnitude
					if dist <= State.fov and (not bestDist or dist < bestDist) then
						best = plr
						bestDist = dist
					end
				end
			end
		end
	end
	return best
end

local function aimSubject()
	local picked = playerById(State.targetUserId)
	if picked and picked.Character and aimPartOf(picked) then
		return picked
	end
	return closestInFov(State.teamCheck)
end

local function silentSubject()
	if State.silentMode == "Player" then
		local picked = playerById(State.targetUserId)
		if picked and aimPartOf(picked) then
			return picked
		end
		return nil
	end
	return closestInFov(State.teamCheck)
end

local function silentPart()
	if not State.silent then
		return nil
	end
	local plr = silentSubject()
	return plr and aimPartOf(plr) or nil
end

local function callerSafe()
	local ok, result = pcall(function()
		return typeof(checkcaller) == "function" and checkcaller()
	end)
	return ok and result == true
end

local function redirectDir(origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return direction
	end
	if direction.Magnitude < 8 then
		return direction
	end
	local cam = Workspace.CurrentCamera
	local near = false
	if cam and (origin - cam.CFrame.Position).Magnitude < 14 then
		near = true
	end
	local _, _, hrp = getChar()
	if hrp and (origin - hrp.Position).Magnitude < 12 then
		near = true
	end
	if not near then
		return direction
	end
	local part = silentPart()
	if not part then
		return direction
	end
	local aim = part.Position - origin
	if aim.Magnitude < 0.05 then
		return direction
	end
	return aim.Unit * direction.Magnitude
end

local function installSilentHooks()
	if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
		return
	end
	local function wrap(fn)
		if typeof(newcclosure) == "function" then
			return newcclosure(fn)
		end
		return fn
	end
	local mouse = LocalPlayer:GetMouse()
	local nameOk = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
			if State.silent and not dead and not callerSafe() then
				local ok, method = pcall(getnamecallmethod)
				if ok and self == Workspace and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
					local args = { ... }
					local redirected = false
					pcall(function()
						if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
							local dir = redirectDir(args[1], args[2])
							if dir ~= args[2] then
								args[2] = dir
								redirected = true
							end
						elseif typeof(args[1]) == "Ray" then
							local dir = redirectDir(args[1].Origin, args[1].Direction)
							if dir ~= args[1].Direction then
								args[1] = Ray.new(args[1].Origin, dir)
								redirected = true
							end
						end
					end)
					if redirected then
						return old(self, unpack(args))
					end
				end
			end
			return old(self, ...)
		end))
	end)
	local indexOk = pcall(function()
		local old
		old = hookmetamethod(game, "__index", wrap(function(self, key)
			if key == "Hit" or key == "Target" then
				local override
				pcall(function()
					if State.silent and not dead and self == mouse and not callerSafe() then
						local part = silentPart()
						if part then
							override = key == "Hit" and CFrame.new(part.Position) or part
						end
					end
				end)
				if override ~= nil then
					return override
				end
			end
			return old(self, key)
		end))
	end)
	silentHooks = nameOk or indexOk
end

local function clearEsp(plr)
	local entry = espMap[plr]
	if not entry then
		return
	end
	if entry.hl then
		entry.hl:Destroy()
	end
	if entry.bb then
		entry.bb:Destroy()
	end
	espMap[plr] = nil
end

local function clearAllEsp()
	for plr in pairs(espMap) do
		clearEsp(plr)
	end
end

local function ensureEsp(plr)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not head or not hum then
		clearEsp(plr)
		return nil
	end
	local entry = espMap[plr]
	if entry and entry.hl and entry.hl.Parent == char and entry.bb and entry.bb.Parent then
		return entry
	end
	clearEsp(plr)

	local hl = Instance.new("Highlight")
	hl.Name = "PhantomESP"
	hl.Adornee = char
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillTransparency = 0.62
	hl.OutlineTransparency = 0
	hl.Parent = char

	local bb = Instance.new("BillboardGui")
	bb.Name = "PhantomTag"
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(168, 44)
	bb.StudsOffset = Vector3.new(0, 2.7, 0)
	bb.ResetOnSpawn = false
	bb.Parent = head

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 13
	name.TextColor3 = C.text
	name.TextStrokeTransparency = 0.45
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Size = UDim2.new(0.68, 0, 0, 16)
	name.Position = UDim2.fromOffset(2, 0)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = bb

	local dist = Instance.new("TextLabel")
	dist.BackgroundTransparency = 1
	dist.Font = Enum.Font.Gotham
	dist.TextSize = 12
	dist.TextColor3 = C.text
	dist.TextStrokeTransparency = 0.45
	dist.TextXAlignment = Enum.TextXAlignment.Right
	dist.Size = UDim2.new(0.32, -2, 0, 16)
	dist.Position = UDim2.new(0.68, 0, 0, 0)
	dist.Parent = bb

	local back = Instance.new("Frame")
	back.Name = "HealthBack"
	back.BorderSizePixel = 0
	back.BackgroundColor3 = Color3.fromRGB(12, 10, 16)
	back.Size = UDim2.new(1, -4, 0, 5)
	back.Position = UDim2.fromOffset(2, 22)
	back.Parent = bb
	corner(back, 4)

	local fill = Instance.new("Frame")
	fill.Name = "HealthFill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	corner(fill, 4)

	entry = { hl = hl, bb = bb, name = name, dist = dist, back = back, fill = fill }
	espMap[plr] = entry
	return entry
end

local function updateEsp()
	if dead then
		return
	end
	if not State.esp then
		if next(espMap) then
			clearAllEsp()
		end
		return
	end
	local _, _, myHrp = getChar()
	local alive = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			alive[plr] = true
			local entry = ensureEsp(plr)
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if entry and hum and hrp then
				local enemy = not sameTeam(plr)
				local marked = plr.UserId == State.targetUserId
				entry.hl.FillColor = enemy and C.red or C.blue
				entry.hl.OutlineColor = marked and Color3.fromRGB(255, 214, 90) or (enemy and C.magenta or C.blue)
				entry.name.Visible = State.espNames
				entry.name.Text = plr.DisplayName
				entry.dist.Visible = State.espDistance
				if myHrp then
					entry.dist.Text = string.format("%dm", math.floor((myHrp.Position - hrp.Position).Magnitude + 0.5))
				else
					entry.dist.Text = ""
				end
				local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
				entry.back.Visible = State.espHealth
				entry.fill.Size = UDim2.new(ratio, 0, 1, 0)
				entry.fill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 0.85, 1)
			end
		end
	end
	for plr in pairs(espMap) do
		if not alive[plr] then
			clearEsp(plr)
		end
	end
end

local function captureDefaults(char, hum)
	if defaults[char] then
		return
	end
	defaults[char] = {
		speed = hum.WalkSpeed,
		jump = hum.JumpPower,
		height = hum.JumpHeight,
		use = hum.UseJumpPower,
	}
end

local scaleMethod = nil

local function applyScale(char, hum, scale)
	if scaleMethod ~= "humanoid" then
		local ok = pcall(function()
			char:ScaleTo(scale)
		end)
		if ok then
			scaleMethod = "model"
			return
		end
	end
	scaleMethod = "humanoid"
	pcall(function()
		hum.BodyHeightScale = scale
	end)
	pcall(function()
		hum.BodyWidthScale = scale
	end)
	pcall(function()
		hum.BodyDepthScale = scale
	end)
	pcall(function()
		hum.HeadScale = math.clamp(scale, 0.5, 2)
	end)
end

local function hideInstance(inst)
	if inst.Name == "PhantomESP" or inst.Name == "PhantomTag" then
		return
	end
	if inst:IsA("BasePart") then
		if savedTrans[inst] == nil then
			savedTrans[inst] = inst.Transparency
		end
		inst.LocalTransparencyModifier = 1
		if inst.Name ~= "HumanoidRootPart" then
			inst.Transparency = 1
		end
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		if savedTrans[inst] == nil then
			savedTrans[inst] = inst.Transparency
		end
		inst.Transparency = 1
	elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Smoke") then
		if savedEnabled[inst] == nil then
			savedEnabled[inst] = inst.Enabled
		end
		inst.Enabled = false
	end
end

local function applyInvis(on)
	local char, hum = getChar()
	if not char or not hum then
		return
	end
	if on then
		for _, inst in ipairs(char:GetDescendants()) do
			hideInstance(inst)
		end
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end)
		pcall(function()
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)
	else
		for inst, value in pairs(savedTrans) do
			if inst and inst.Parent then
				inst.Transparency = value
				if inst:IsA("BasePart") then
					inst.LocalTransparencyModifier = 0
				end
			end
		end
		for inst, value in pairs(savedEnabled) do
			if inst and inst.Parent then
				inst.Enabled = value
			end
		end
		savedTrans = {}
		savedEnabled = {}
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		end)
		pcall(function()
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
		end)
	end
end

local function restoreMotion()
	local char, hum = getChar()
	if not char or not hum then
		return
	end
	local saved = defaults[char]
	if State.speedOn and saved then
		hum.WalkSpeed = saved.speed
		State.speedOn = false
	end
	if State.jumpOn and saved then
		hum.UseJumpPower = saved.use
		hum.JumpPower = saved.jump
		hum.JumpHeight = saved.height
		State.jumpOn = false
	end
	if State.sizeOn then
		applyScale(char, hum, 1)
		State.sizeOn = false
	end
	if State.invisible then
		State.invisible = false
		applyInvis(false)
	end
end

restoreAll = function()
	State.esp = false
	State.fakeLag = false
	State.aimbot = false
	State.silent = false
	State.infJump = false
	clearAllEsp()
	restoreMotion()
end

local function noteSpawn(char)
	task.delay(0.35, function()
		if dead or not char.Parent then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnCF = hrp.CFrame
		end
	end)
end

local function teleportTo(cf)
	if flinging or not cf then
		return false
	end
	local _, _, hrp = getChar()
	if not hrp then
		return false
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CFrame = cf
	hrp.AssemblyLinearVelocity = Vector3.zero
	return true
end

local function teleportSpawn()
	local cf = spawnCF
	if not cf then
		local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawn then
			cf = spawn.CFrame + Vector3.new(0, 5, 0)
		end
	end
	if not cf then
		notify("No spawn saved yet")
		return
	end
	if teleportTo(cf) then
		notify("Back at spawn")
	end
end

local function teleportTarget()
	local plr = playerById(State.targetUserId)
	local part = plr and (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"))
	if not part then
		notify("Select a spawned player")
		return
	end
	if teleportTo(part.CFrame * CFrame.new(0, 1, 3)) then
		notify("Teleported to " .. plr.DisplayName)
	end
end

local function flingTarget()
	if flinging then
		return
	end
	local plr = playerById(State.targetUserId)
	if not plr or plr == LocalPlayer then
		notify("Select someone to fling")
		return
	end
	local char, hum, hrp = getChar()
	local tchar = plr.Character
	local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
	local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
	if not char or not hum or not hrp or not thrp or not thum then
		notify(plr.DisplayName .. " is not spawned")
		return
	end

	flinging = true
	local origin = hrp.CFrame
	local started = os.clock()
	local startPos = thrp.Position
	notify("Flinging " .. plr.DisplayName)

	pcall(function()
		if typeof(sethiddenproperty) == "function" then
			sethiddenproperty(LocalPlayer, "SimulationRadius", 1e9)
			sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", 1e9)
		end
	end)

	local wasPlatform = hum.PlatformStand
	local wasAuto = hum.AutoRotate
	hum.PlatformStand = true
	hum.AutoRotate = false

	local spin = Instance.new("BodyAngularVelocity")
	spin.Name = "PhantomSpin"
	spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	spin.AngularVelocity = Vector3.new(0, 9e4, 0)
	spin.P = 1e6
	spin.Parent = hrp

	local hold = Instance.new("BodyVelocity")
	hold.Name = "PhantomHold"
	hold.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	hold.Velocity = Vector3.zero
	hold.Parent = hrp

	local oldCollide = hrp.CanCollide
	hrp.CanCollide = true

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if dead or not flinging then
			return
		end
		if not hrp.Parent or not thrp.Parent or thum.Health <= 0 then
			flinging = false
			return
		end
		hrp.CFrame = thrp.CFrame
		hrp.AssemblyAngularVelocity = Vector3.new(0, 9e4, 0)
		spin.AngularVelocity = Vector3.new(0, 9e4, 0)
		local moved = (thrp.Position - startPos).Magnitude > 18
		local fast = thrp.AssemblyLinearVelocity.Magnitude > 70
		if moved or fast or (os.clock() - started) > 5 then
			flinging = false
		end
	end)

	task.spawn(function()
		while flinging and not dead do
			task.wait()
		end
		pcall(function()
			conn:Disconnect()
		end)
		pcall(function()
			spin:Destroy()
		end)
		pcall(function()
			hold:Destroy()
		end)

		local function settle(root, human)
			if not root then
				return
			end
			root.AssemblyAngularVelocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = origin
			root.CanCollide = oldCollide
			if human then
				human.PlatformStand = wasPlatform
				human.AutoRotate = wasAuto
			end
			task.wait()
			if root.Parent then
				root.CFrame = origin
				root.AssemblyAngularVelocity = Vector3.zero
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end

		if hrp.Parent and hum.Health > 0 then
			settle(hrp, hum)
			notify("Fling done. Back where you started.")
		else
			local back
			back = LocalPlayer.CharacterAdded:Connect(function(newChar)
				back:Disconnect()
				task.wait(0.35)
				local root = newChar:FindFirstChild("HumanoidRootPart")
				local human = newChar:FindFirstChildOfClass("Humanoid")
				settle(root, human)
			end)
			notify("Fling done. Returning after respawn.")
		end
	end)
end

local function curveAlpha(value, minV, maxV)
	local n = math.clamp((value - minV) / (maxV - minV), 0, 1)
	return n ^ (1 / 3)
end

local function curveValue(alpha, minV, maxV)
	alpha = math.clamp(alpha, 0, 1)
	return minV + (maxV -