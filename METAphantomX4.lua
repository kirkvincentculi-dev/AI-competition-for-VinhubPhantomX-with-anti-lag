--[[ 
    VINHUB: Phantom X | FINAL COMPETITION EDITION
    One File - For Your Game Only
    Logo: 72121325627003 | Theme: Red / Purple / Blue Gradient
    All Abilities Included
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Colors
local C = {
    Red = Color3.fromRGB(255, 30, 70),
    Purple = Color3.fromRGB(138, 50, 255),
    Blue = Color3.fromRGB(0, 150, 255),
    Dark = Color3.fromRGB(18, 15, 30),
    Dark2 = Color3.fromRGB(28, 25, 45)
}

local function GetGui()
    local s, h = pcall(function() return gethui() end)
    if s and h then return h end
    return game:GetService("CoreGui")
end

local Parent = GetGui()
if Parent:FindFirstChild("VINHUB_PhantomX") then Parent:FindFirstChild("VINHUB_PhantomX"):Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "VINHUB_PhantomX"
Gui.ResetOnSpawn = false
Gui.Parent = Parent
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Helpers
local function GetChar() return LP.Character or LP.CharacterAdded:Wait() end
local function GetHRP() return GetChar():WaitForChild("HumanoidRootPart") end
local function GetHum() return GetChar():FindFirstChildOfClass("Humanoid") end
local function Corner(o, r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 10) c.Parent=o return c end

-- ================= LOGO TOGGLE BUTTON (DRAGGABLE ICON) =================
local LogoBtn = Instance.new("ImageButton")
LogoBtn.Name = "PhantomX_ToggleIcon"
LogoBtn.Size = UDim2.fromOffset(70, 70)
LogoBtn.Position = UDim2.fromOffset(25, 80)
LogoBtn.BackgroundColor3 = C.Dark
LogoBtn.Image = "rbxassetid://72121325627003"
LogoBtn.ScaleType = Enum.ScaleType.Fit
LogoBtn.Parent = Gui
Corner(LogoBtn, 18)

local LogoStroke = Instance.new("UIStroke", LogoBtn)
LogoStroke.Thickness = 3
LogoStroke.Color = C.Purple

local LogoGrad = Instance.new("UIGradient", LogoStroke)
LogoGrad.Color = ColorSequence.new(C.Red, C.Blue)
LogoGrad.Rotation = 0

-- Animate logo border
task.spawn(function() while LogoBtn.Parent do LogoGrad.Rotation=(LogoGrad.Rotation+1)%360 task.wait(0.02) end end)

-- Draggable Logo
local dragToggle, dragInput, dragStart, startPos
LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragToggle=true dragStart=input.Position startPos=LogoBtn.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragToggle=false end end)
    end
end)
LogoBtn.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end end)
UIS.InputChanged:Connect(function(input)
    if input==dragInput and dragToggle then
        local delta=input.Position-dragStart
        LogoBtn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-- ================= MAIN HUB WITH GRADIENT =================
local Main = Instance.new("Frame")
Main.Name = "MainHub"
Main.Size = UDim2.fromOffset(580, 420)
Main.Position = UDim2.new(0.5, -290, 0.5, -210)
Main.BackgroundColor3 = C.Dark
Main.BorderSizePixel=0
Main.Parent=Gui
Corner(Main, 14)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness=2
MainStroke.Color=C.Purple

local MainGrad = Instance.new("UIGradient", Main)
MainGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.Red),
    ColorSequenceKeypoint.new(0.5, C.Purple),
    ColorSequenceKeypoint.new(1, C.Blue)
})
MainGrad.Rotation=90
MainGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.12),NumberSequenceKeypoint.new(1,0.12)})

task.spawn(function() while Main.Parent do MainGrad.Rotation=(MainGrad.Rotation+0.15)%360 task.wait(0.03) end end)

-- Title Bar (draggable)
local TopBar = Instance.new("Frame", Main)
TopBar.Size=UDim2.new(1,0,0,45)
TopBar.BackgroundTransparency=1
Corner(TopBar,14)

local Title = Instance.new("TextLabel", TopBar)
Title.Size=UDim2.new(1,-20,1,0) Title.Position=UDim2.new(0,10,0,0)
Title.BackgroundTransparency=1 Title.Text="VINHUB: Phantom X" Title.Font=Enum.Font.GothamBold Title.TextSize=18 Title.TextXAlignment=Enum.TextXAlignment.Left
Title.TextColor3=Color3.new(1,1,1)

local TGrad = Instance.new("UIGradient", Title)
TGrad.Color=ColorSequence.new(C.Red, C.Blue)

local Sub = Instance.new("TextLabel", TopBar)
Sub.Size=UDim2.new(0,150,0,15) Sub.Position=UDim2.new(1,-160,0,25)
Sub.BackgroundTransparency=1 Sub.Text="RED // PURPLE // BLUE" Sub.Font=Enum.Font.Gotham Sub.TextSize=10 Sub.TextColor3=C.Purple

-- Content
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size=UDim2.new(1,-12,1,-55) Scroll.Position=UDim2.new(0,6,0,48)
Scroll.BackgroundTransparency=1 Scroll.ScrollBarThickness=3 Scroll.CanvasSize=UDim2.new(0,0,0,1100)
Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y

local List = Instance.new("UIListLayout", Scroll)
List.Padding=UDim.new(0,6)

-- UI Builders
local function CreateLabel(txt)
    local l=Instance.new("TextLabel") l.Size=UDim2.new(1,-10,0,25) l.BackgroundTransparency=1 l.Text=txt l.TextColor3=C.Purple l.Font=Enum.Font.GothamBold l.TextSize=12 l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=Scroll return l
end

local function CreateToggle(name, def, cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,38) f.BackgroundColor3=C.Dark2 f.Parent=Scroll Corner(f,8)
    local t=Instance.new("TextLabel",f) t.Size=UDim2.new(0.7,0,1,0) t.Position=UDim2.new(0,10,0,0) t.BackgroundTransparency=1 t.Text=name t.TextColor3=Color3.new(1,1,1) t.Font=Enum.Font.Gotham t.TextSize=12 t.TextXAlignment=Enum.TextXAlignment.Left
    local b=Instance.new("TextButton",f) b.Size=UDim2.new(0,70,0,26) b.Position=UDim2.new(1,-80,0.5,-13) b.BackgroundColor3=def and C.Purple or Color3.fromRGB(50,50,50) b.Text=def and "ON" or "OFF" b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold b.TextSize=11 Corner(b,6)
    local state=def b.MouseButton1Click:Connect(function() state=not state b.Text=state and "ON" or "OFF" b.BackgroundColor3=state and C.Purple or Color3.fromRGB(50,50,50) cb(state) end)
end

local function CreateButton(name, cb)
    local b=Instance.new("TextButton") b.Size=UDim2.new(1,-10,0,38) b.BackgroundColor3=C.Dark2 b.Text=name b.TextColor3=Color3.new(1,1,1) b.Font=Enum.Font.GothamBold b.TextSize=12 b.Parent=Scroll Corner(b,8)
    local s=Instance.new("UIStroke",b) s.Thickness=1 s.Color=C.Purple s.Transparency=0.6
    b.MouseButton1Click:Connect(cb)
end

local function CreateSlider(name, min, max, def, cb)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,-10,0,38) f.BackgroundColor3=C.Dark2 f.Parent=Scroll Corner(f,8)
    local t=Instance.new("TextLabel",f) t.Size=UDim2.new(0.45,0,1,0) t.Position=UDim2.new(0,10,0,0) t.BackgroundTransparency=1 t.Text=name..": "..def t.TextColor3=Color3.new(1,1,1) t.Font=Enum.Font.Gotham t.TextSize=11 t.TextXAlignment=Enum.TextXAlignment.Left
    local box=Instance.new("TextBox",f) box.Size=UDim2.new(0,80,0,26) box.Position=UDim2.new(1,-90,0.5,-13) box.BackgroundColor3=Color3.fromRGB(40,38,60) box.Text=tostring(def) box.TextColor3=Color3.new(1,1,1) box.Font=Enum.Font.GothamBold box.TextSize=11 Corner(box,6)
    box.FocusLost:Connect(function(enter) if enter then local n=tonumber(box.Text) if n then n=math.clamp(n,min,max) cb(n) t.Text=name..": "..n end end end)
end

-- STATE
local SpawnCF = GetChar():GetPivot()
LP.CharacterAdded:Connect(function(c) task.wait(1) SpawnCF=c:GetPivot() end)

local SelectedPlayer = nil
local ESP_Table = {}

-- ================= ABILITIES =================
CreateLabel("VISUAL - ESP")

CreateToggle("ESP: Detects players [VISUAL]", false, function(v)
    if v then
        for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character and not p.Character:FindFirstChild("PhantomESP") then
            local h=Instance.new("Highlight") h.Name="PhantomESP" h.FillColor=C.Purple h.OutlineColor=C.Blue h.FillTransparency=0.5 h.Parent=p.Character ESP_Table[p]=h
        end end
    else for _,h in pairs(ESP_Table) do h:Destroy() end table.clear(ESP_Table) end
end)

CreateToggle("Invisible: Hides character [FE]", false, function(v)
    for _,d in pairs(GetChar():GetDescendants()) do if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then d.Transparency=v and 1 or 0 end end
end)

CreateToggle("Fake lag: Pretend lag [FE]", false, function(v) settings().Network.IncomingReplicationLag = v and 2.5 or 0 end)

CreateLabel("COMBAT - Aim")

CreateButton("Select Player: Tap to set target", function()
    local list={} for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(list,p) end end
    if #list>0 then SelectedPlayer=list[1] Title.Text="VINHUB: Phantom X | Target: "..SelectedPlayer.Name end
end)

CreateToggle("Aimbot: Aims at specific player", false, function(v)
    getgenv().PhantomAim=v
    if v then RunService:BindToRenderStep("PhantomAimbot",1,function() if getgenv().PhantomAim and SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("Head") then Camera.CFrame=CFrame.new(Camera.CFrame.Position, SelectedPlayer.Character.Head.Position) end end)
    else RunService:UnbindFromRenderStep("PhantomAimbot") end
end)

CreateToggle("Silent aim: Shoots opposing team while staying", false, function(v) getgenv().SilentAim=v end)
-- For your own gun, hook it: if getgenv().SilentAim then FireServer(SelectedPlayer.Character.Head.Position)

CreateToggle("Infinite Jump: No cooldown", false, function(v) getgenv().InfJump=v end)
UIS.JumpRequest:Connect(function() if getgenv().InfJump then GetHum():ChangeState(Enum.HumanoidStateType.Jumping) end end)

CreateLabel("MOVEMENT - Enforcers")

CreateSlider("Speed enforcer 0-10000", 0, 10000, 16, function(v) GetHum().WalkSpeed=v end)
CreateSlider("Jump enforcer 0-10000", 0, 10000, 50, function(v) GetHum().JumpPower=v GetHum().UseJumpPower=true end)
CreateSlider("SIZE: Changes size [FE]", 0.1, 10, 1, function(v) local h=GetHum() if h:FindFirstChild("BodyHeightScale") then h.BodyHeightScale.Value=v h.BodyWidthScale.Value=v h.BodyDepthScale.Value=v h.HeadScale.Value=v end end)

CreateLabel("TELEPORT / FLING")

CreateButton("Teleport to spawn", function() GetHRP().CFrame = SpawnCF + Vector3.new(0,3,0) end)
CreateButton("Teleport to: Selected player", function() if SelectedPlayer and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then GetHRP().CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0) end end)

CreateButton("Fling: Teleport, spin, fling, return [FE]", function()
    if not SelectedPlayer or not SelectedPlayer.Character then Title.Text="No player selected!" return end
    local myHRP=GetHRP() local oldCF=myHRP.CFrame
    local targetHRP=SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") if not targetHRP then return end
    myHRP.CFrame=targetHRP.CFrame
    local bv=Instance.new("BodyAngularVelocity") bv.Name="PhantomFling" bv.AngularVelocity=Vector3.new(0,99999,0) bv.MaxTorque=Vector3.new(0,math.huge,0) bv.P=math.huge bv.Parent=myHRP
    task.wait(1.2) -- stops when flinged
    bv:Destroy()
    myHRP.CFrame=oldCF -- GOES BACK TO PLACE WHERE PLAYER USED FLING
end)

-- Draggable Main via TopBar
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragStart=input.Position startPos=Main.Position end end)
TopBar.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
UIS.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then local delta=input.Position-dragStart Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end end)

-- Logo toggle
local Open=true
LogoBtn.MouseButton1Click:Connect(function()
    if dragToggle then dragToggle=false return end
    Open=not Open
    Main.Visible=Open
    TweenService:Create(LogoBtn, TweenInfo.new(0.2), {Size = Open and UDim2.fromOffset(70,70) or UDim2.fromOffset(60,60)}):Play()
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = Open and UDim2.fromOffset(580,420) or UDim2.fromOffset(0,0)}):Play()
end)

print("VINHUB: Phantom X Loaded - Competition Edition")