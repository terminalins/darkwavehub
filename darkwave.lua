--[[
    DARKWAVE HUB: STEAL A BRAINROT - OMEGA V79 "RAGDOLL FIX"
    Status: Combat & Speed 100% V72 + Fixed Anti-Ragdoll + Renamed ESP
    Features: God Interact, Safe Carry (14.8), Main player ESP (Red), Ultra Anti-Ragdoll
]]--

-- VERHINDERT DOPPELTE AUSFÜHRUNG & CLEANUP
if getgenv().DarkWaveLoaded then
    pcall(function() getgenv().DarkWaveCleanup() end)
end
getgenv().DarkWaveLoaded = true

-- EINSTELLUNGEN
getgenv().DarkWaveSettings = {
    WalkSpeed = 55,
    SpeedEnabled = false,
    AntiRagdoll = true,
    AutoBat = false,
    AutoBatRange = 25, 
    PlayerESP = false,
    PlayerNames = false,
    ReachEnabled = false,
    ReachSize = 15,
    FlyEnabled = false,
    FlySpeed = 22,
    JumpBoost = false,
    JumpHeight = 25,
    FastInteract = true,
    MainPlayerESP = true -- Umbenannt von BaseESP
}

local Settings = getgenv().DarkWaveSettings
local isHovering = false 
local lastHit = 0
local espData = {}
local currentTab = "Combat"

-- DIENSTE
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Benachrichtigungs-Helfer
local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

-- MAIN PLAYER ESP & TRACER LOGIK
local baseHighlight = Instance.new("Highlight")
baseHighlight.FillColor = Color3.fromRGB(255, 0, 0)
baseHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
baseHighlight.FillTransparency = 0.6
baseHighlight.Enabled = false

local baseTracer = Drawing.new("Line")
baseTracer.Visible = false
baseTracer.Color = Color3.fromRGB(255, 0, 0)
baseTracer.Thickness = 2
baseTracer.Transparency = 1

local function GetMyBase()
    local searchLocations = {workspace:FindFirstChild("Bases"), workspace}
    for _, loc in pairs(searchLocations) do
        if loc then
            local direct = loc:FindFirstChild(LocalPlayer.Name)
            if direct and direct:IsA("Model") then return direct end
            for _, b in pairs(loc:GetChildren()) do
                if b:IsA("Model") then
                    local owner = b:FindFirstChild("Owner") or b:FindFirstChild("OwnerName")
                    if (owner and owner:IsA("StringValue") and owner.Value == LocalPlayer.Name) or b:GetAttribute("Owner") == LocalPlayer.Name then
                        return b
                    end
                end
            end
        end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    if Settings.MainPlayerESP then
        local myBase = GetMyBase()
        if myBase then
            baseHighlight.Parent = myBase
            baseHighlight.Enabled = true
            local targetPart = myBase:FindFirstChild("Essentials") and myBase.Essentials:FindFirstChild("Deposit") 
                               or myBase:FindFirstChild("Deposit") 
                               or myBase:FindFirstChild("Hitbox") 
                               or myBase.PrimaryPart
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    baseTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    baseTracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    baseTracer.Visible = true
                else baseTracer.Visible = false end
            end
        else baseHighlight.Enabled = false baseTracer.Visible = false end
    else baseHighlight.Enabled = false baseTracer.Visible = false end
end)

-- GOD-MODE E-BOOSTER LOGIK (V72)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if Settings.FastInteract and player == LocalPlayer then fireproximityprompt(prompt) end
end)
ProximityPromptService.PromptShown:Connect(function(prompt)
    if Settings.FastInteract then prompt.HoldDuration = 0 end
end)

-- ESP LOGIK (SPIELER)
local function CreateESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(160, 32, 240)
    box.Thickness = 1.5
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Size = 14
    name.Center = true
    name.Outline = true
    espData[player] = {Box = box, Name = name}

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not (Settings.PlayerESP or Settings.PlayerNames) or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            name.Visible = false
            if not Players:FindFirstChild(player.Name) then box:Remove() name:Remove() connection:Disconnect() end
            return
        end
        local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
        if onScreen then
            local sizeX, sizeY = 2000 / pos.Z, 3000 / pos.Z
            if Settings.PlayerESP then
                box.Size = Vector2.new(sizeX, sizeY)
                box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                box.Visible = true
            else box.Visible = false end
            if Settings.PlayerNames then
                name.Text = player.Name
                name.Position = Vector2.new(pos.X, pos.Y - sizeY / 2 - 15)
                name.Visible = true
            else name.Visible = false end
        else box.Visible = false name.Visible = false end
    end)
end

-- STOP COMBAT
local function ForceStopCombat()
    Settings.AutoBat = false
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-- CLEANUP
getgenv().DarkWaveCleanup = function()
    ForceStopCombat()
    Settings.SpeedEnabled = false
    Settings.FlyEnabled = false
    Settings.JumpBoost = false
    baseHighlight:Destroy()
    baseTracer:Remove()
    for _, data in pairs(espData) do data.Box:Remove() data.Name:Remove() end
end

-- ULTIMATE ANTI-RAGDOLL (FIXED)
RunService.Stepped:Connect(function()
    if Settings.AntiRagdoll and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and root then
            -- Blockiert Status-Wechsel die zum Umfallen führen
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            
            -- Sofortiges Aufstehen falls das Spiel es erzwingt
            if hum.PlatformStand or hum.Sit or hum:GetState() == Enum.HumanoidStateType.Physics then
                hum.PlatformStand = false
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

-- GUI SETUP (V72 ORIGINAL STYLE)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DarkWave_V79" 
ScreenGui.Parent = (gethui and gethui()) or CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -170)
MainFrame.Size = UDim2.new(0, 420, 0, 340) 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true -- Wichtig für die Animation

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(50, 50, 50)
MainStroke.Parent = MainFrame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

MainFrame.MouseEnter:Connect(function() isHovering = true end)
MainFrame.MouseLeave:Connect(function() isHovering = false end)

-- MINIMIZE BUTTON (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "Minimize"
MinimizeBtn.Parent = MainFrame
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Position = UDim2.new(1, -35, 0, 5)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 24

-- OPEN BUTTON (+)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "Open"
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
OpenBtn.Position = UDim2.new(0.5, -20, 0.1, 0)
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Text = "+"
OpenBtn.TextColor3 = Color3.fromRGB(160, 32, 240)
OpenBtn.TextSize = 25
OpenBtn.Visible = false
local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 8)
OpenCorner.Parent = OpenBtn
local OpenStroke = Instance.new("UIStroke")
OpenStroke.Thickness = 1.5
OpenStroke.Color = Color3.fromRGB(160, 32, 240)
OpenStroke.Parent = OpenBtn

-- ANIMATION LOGIK
local originalSize = UDim2.new(0, 420, 0, 340)
local isMinimized = false

local function ToggleGUI()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 0)}):Play()
        task.wait(0.3)
        MainFrame.Visible = false
        OpenBtn.Visible = true
    else
        MainFrame.Visible = true
        OpenBtn.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = originalSize}):Play()
    end
end

MinimizeBtn.MouseButton1Click:Connect(ToggleGUI)
OpenBtn.MouseButton1Click:Connect(ToggleGUI)

local Header = Instance.new("TextLabel")
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Position = UDim2.new(0, 15, 0, 0)
Header.Size = UDim2.new(0, 200, 0, 40)
Header.Font = Enum.Font.GothamBold
Header.Text = "DARKWAVE HUB"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.TextSize = 13
Header.TextXAlignment = Enum.TextXAlignment.Left

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Parent = MainFrame
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TabBar.Position = UDim2.new(0, 10, 0, 45)
TabBar.Size = UDim2.new(1, -20, 0, 35)

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 6)
TabCorner.Parent = TabBar

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabBar
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.VerticalAlignment = Enum.VerticalAlignment.Center
TabList.Padding = UDim.new(0, 5)

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "Content"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 90)
ContentFrame.Size = UDim2.new(1, -20, 1, -100)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 450)
ContentFrame.ScrollBarThickness = 2
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(160, 32, 240)

local UIListLayoutContent = Instance.new("UIListLayout")
UIListLayoutContent.Parent = ContentFrame
UIListLayoutContent.Padding = UDim.new(0, 8)

local Icons = { Combat = "rbxassetid://10734887448", Movement = "rbxassetid://10747373176", Visuals = "rbxassetid://10723345518", Misc = "rbxassetid://10723350262" }

local function CreateTab(name)
    local Tab = Instance.new("TextButton")
    Tab.Parent = TabBar
    Tab.BackgroundTransparency = 1
    Tab.Size = UDim2.new(0, 85, 1, 0)
    Tab.Font = Enum.Font.GothamBold
    Tab.Text = "  " .. name
    Tab.TextColor3 = Color3.fromRGB(140, 140, 140)
    Tab.TextSize = 10
    local Icon = Instance.new("ImageLabel")
    Icon.Parent = Tab
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0, 0, 0.5, -7)
    Icon.Size = UDim2.new(0, 14, 0, 14)
    Icon.Image = Icons[name] or ""
    Icon.ImageColor3 = Color3.fromRGB(140, 140, 140)
    Tab.MouseButton1Click:Connect(function()
        currentTab = name
        for _, v in pairs(TabBar:GetChildren()) do
            if v:IsA("TextButton") then v.TextColor3 = Color3.fromRGB(140, 140, 140) v.ImageLabel.ImageColor3 = Color3.fromRGB(140, 140, 140) end
        end
        Tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        Icon.ImageColor3 = Color3.fromRGB(160, 32, 240)
    end)
    return Tab
end

local function CreateToggle(name, settingKey, tabName)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Parent = ContentFrame
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 6)
    TCorner.Parent = ToggleFrame
    local Label = Instance.new("TextLabel")
    Label.Parent = ToggleFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    local Check = Instance.new("TextButton")
    Check.Parent = ToggleFrame
    Check.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(50, 50, 50)
    Check.Position = UDim2.new(1, -45, 0.5, -9)
    Check.Size = UDim2.new(0, 34, 0, 18)
    Check.Text = ""
    local CCorner = Instance.new("UICorner")
    CCorner.CornerRadius = UDim.new(0, 9)
    CCorner.Parent = Check
    Check.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local targetColor = Settings[settingKey] and Color3.fromRGB(160, 32, 240) or Color3.fromRGB(50, 50, 50)
        TweenService:Create(Check, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        if settingKey == "AutoBat" and not Settings.AutoBat then ForceStopCombat() end
    end)
    RunService.RenderStepped:Connect(function() ToggleFrame.Visible = (currentTab == tabName) end)
end

local function CreateButton(name, tabName, callback)
    local Btn = Instance.new("TextButton")
    Btn.Parent = ContentFrame
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    Btn.TextSize = 11
    local BCorner = Instance.new("UICorner")
    BCorner.CornerRadius = UDim.new(0, 6)
    BCorner.Parent = Btn
    Btn.MouseButton1Click:Connect(callback)
    RunService.RenderStepped:Connect(function() Btn.Visible = (currentTab == tabName) end)
end

-- KEYBIND (K) - V72 ORIGINAL
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        Settings.AutoBat = not Settings.AutoBat
        if not Settings.AutoBat then ForceStopCombat() end
        Notify("DarkWave", "Auto-Bat: " .. (Settings.AutoBat and "ON" or "OFF"))
    end
end)

-- DRAGGING (V72 ORIGINAL)
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

-- Helper: Nearest Player (V72 ORIGINAL)
local function GetNearestPlayer()
    local nearest, lastDist = nil, Settings.AutoBatRange
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local dist = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist < lastDist then lastDist = dist nearest = p.Character.HumanoidRootPart end
        end
    end
    return nearest
end

-- SPEED & CARRY FIX (V72 ORIGINAL - UNTOUCHED)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root then
        if Settings.JumpBoost then hum.JumpHeight = Settings.JumpHeight hum.UseJumpPower = false else hum.JumpHeight = 7.2 end
        if Settings.SpeedEnabled and hum.MoveDirection.Magnitude > 0 then
            local targetSpeed = Settings.WalkSpeed
            local tool = char:FindFirstChildOfClass("Tool")
            local lerpPower = 0.12 
            if tool and (tool.Name:lower():find("brainrot") or tool.Name:lower():find("pizza") or tool.Name:lower():find("noob")) then 
                targetSpeed = 14.8 lerpPower = 0.02 
            end
            local currentVel = root.AssemblyLinearVelocity
            local targetVel = hum.MoveDirection * targetSpeed
            root.AssemblyLinearVelocity = Vector3.new(currentVel.X + (targetVel.X - currentVel.X) * lerpPower, currentVel.Y, currentVel.Z + (targetVel.Z - currentVel.Z) * lerpPower)
        end
    end
end)

-- FLY & COMBAT (V72 ORIGINAL - UNTOUCHED)
RunService.Heartbeat:Connect(function()
    if Settings.FlyEnabled and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,0.6,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,0.6,0) end
            if moveDir.Magnitude > 0 then root.Velocity = moveDir.Unit * Settings.FlySpeed else root.Velocity = Vector3.new(0, 0.1, 0) end
        end
    end
end)

RunService.PostSimulation:Connect(function()
    if not Settings.AutoBat or isHovering then 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end
        return 
    end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local tool = char:FindFirstChildOfClass("Tool")
    if tick() - lastHit > 0.012 then
        if tool then tool:Activate() end
        pcall(function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) RunService.RenderStepped:Wait() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
        lastHit = tick()
    end
    local target = GetNearestPlayer()
    local spinVel = 120 
    if target then
        local dir = (target.Position - root.Position).Unit
        local tAngle = math.atan2(dir.X, dir.Z)
        local cAngle = math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z)
        local diff = tAngle - cAngle
        if diff > math.pi then diff = diff - (math.pi * 2) end
        if diff < -math.pi then diff = diff + (math.pi * 2) end
        root.AssemblyAngularVelocity = Vector3.new(0, (diff * 350) + spinVel, 0)
    else root.AssemblyAngularVelocity = Vector3.new(0, spinVel, 0) end
end)

-- TABS
CreateTab("Combat")
CreateTab("Movement")
CreateTab("Visuals")
CreateTab("Misc")

-- Toggles
CreateToggle("Auto-Bat (God Mode) [K]", "AutoBat", "Combat")
local RangeBtn = CreateButton("Change Range: " .. Settings.AutoBatRange, "Combat", function()
    if Settings.AutoBatRange == 25 then Settings.AutoBatRange = 40
    elseif Settings.AutoBatRange == 40 then Settings.AutoBatRange = 60
    elseif Settings.AutoBatRange == 60 then Settings.AutoBatRange = 100
    else Settings.AutoBatRange = 25 end
end)
RunService.RenderStepped:Connect(function() RangeBtn.Text = "Change Range: " .. Settings.AutoBatRange end)
CreateToggle("Bat Reach (OP Handle)", "ReachEnabled", "Combat")

CreateToggle("Speed Hack", "SpeedEnabled", "Movement")
CreateToggle("Safe Fly Hack", "FlyEnabled", "Movement")
CreateToggle("Legit Jump Boost", "JumpBoost", "Movement")
CreateToggle("Ultra Anti-Ragdoll", "AntiRagdoll", "Movement") -- FIXED

CreateToggle("Player Box ESP", "PlayerESP", "Visuals")
CreateToggle("Player Name ESP", "PlayerNames", "Visuals")
CreateToggle("Main player ESP", "MainPlayerESP", "Visuals") -- Umbenannt

CreateToggle("E-Booster (God Interaction)", "FastInteract", "Misc")
CreateButton("Rejoin Game", "Misc", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)

-- INIT
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Notify("DarkWave Hub", "V79 FIXED RAGDOLL & ESP!")
