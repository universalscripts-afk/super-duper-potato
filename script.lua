-- Universal Framework (Elite Ultra-Modern UI v3.4)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration & Default Keybinds
local Config = {
    AimbotEnabledState = false,
    AimbotFOV = 150,
    ShowFOVCircle = false,
    AimbotKey = Enum.KeyCode.E,
    SmoothAimbot = false,
    Smoothness = 5,
    WallCheck = false,
    TargetPartName = "Head",
    
    -- Auto Shoot (Trigger Bot) Settings
    AutoShootEnabled = false,
    AutoShootKey = Enum.KeyCode.Q,
    
    -- Visuals & Camera
    BoxESP = false,
    Tracers = false,
    NameESP = false,
    DistanceESP = false,
    HealthBar = false,
    FreecamEnabled = false,
    FreecamSpeed = 50,
    FreecamSensitivity = 0.3,
    FullbrightEnabled = false,
    
    -- Custom Crosshair Settings
    CustomCrosshairEnabled = false,
    CrosshairStyle = "Cross", 
    CrosshairSize = 10,
    CrosshairGap = 4,
    
    -- Movement & Utility Target Options
    SpeedHack = false,
    WalkSpeed = 32,
    JumpHack = false,
    JumpPower = 100,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    Spinbot = false,
    SpinSpeed = 20,
    ShiftLockEnabled = false,
    
    -- Target Utility / Orbit Settings
    TargetActionMode = "Orbit", -- Options: "Orbit", "Spectate", "View"
    OrbitRadius = 15,
    OrbitSpeed = 10,
    ActiveOrbitTarget = nil,
    ActiveSpectateTarget = nil,
    
    -- Menu Keybind
    MenuKey = Enum.KeyCode.RightControl
}

---------------------------------------------------------
-- CONFIG SAVE & LOAD SYSTEM
---------------------------------------------------------
local ConfigFolder = "UniversalFramework"
local ConfigFileName = "UniversalFramework/config_v3_4.json"

local function saveConfig()
    local saveTable = {}
    for k, v in pairs(Config) do
        if typeof(v) == "EnumItem" then
            saveTable[k] = v.Name
        elseif typeof(v) ~= "Instance" then
            saveTable[k] = v
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(saveTable)
    end)
    
    if success then
        if makefolder and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        if writefile then
            writefile(ConfigFileName, encoded)
        end
    end
end

local function loadConfig()
    if isfile and isfile(ConfigFileName) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then
                    if typeof(Config[k]) == "EnumItem" and type(v) == "string" then
                        local foundEnum = Enum.KeyCode[v]
                        if foundEnum then
                            Config[k] = foundEnum
                        end
                    else
                        Config[k] = v
                    end
                end
            end
        end
    end
end

local function resetConfig()
    if delfile and isfile(ConfigFileName) then
        pcall(function() delfile(ConfigFileName) end)
    end
    for k, v in pairs(Config) do
        if k == "AimbotKey" then Config[k] = Enum.KeyCode.E
        elseif k == "AutoShootKey" then Config[k] = Enum.KeyCode.Q
        elseif k == "MenuKey" then Config[k] = Enum.KeyCode.RightControl
        elseif type(v) == "boolean" then Config[k] = false
        elseif type(v) == "string" then 
            if k == "TargetActionMode" then Config[k] = "Orbit"
            elseif k == "CrosshairStyle" then Config[k] = "Cross" end
        elseif type(v) == "number" then 
            if k == "AimbotFOV" then Config[k] = 150
            elseif k == "WalkSpeed" then Config[k] = 32
            elseif k == "JumpPower" then Config[k] = 100
            elseif k == "OrbitRadius" then Config[k] = 15
            elseif k == "OrbitSpeed" then Config[k] = 10
            else Config[k] = 10 end
        end
    end
end

loadConfig()

-- Cleanup old instances
if CoreGui:FindFirstChild("UniversalMenuElite") then CoreGui.UniversalMenuElite:Destroy() end
if CoreGui:FindFirstChild("UniversalFOVGui") then CoreGui.UniversalFOVGui:Destroy() end
if CoreGui:FindFirstChild("UniversalCrosshairGui") then CoreGui.UniversalCrosshairGui:Destroy() end

---------------------------------------------------------
-- FOV CIRCLE DRAWING
---------------------------------------------------------
local FOVGui = Instance.new("ScreenGui", CoreGui)
FOVGui.Name = "UniversalFOVGui"

local FOVCircle = Instance.new("Frame", FOVGui)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Size = UDim2.new(0, Config.AimbotFOV * 2, 0, Config.AimbotFOV * 2)
FOVCircle.Visible = false

local FOVCorner = Instance.new("UICorner", FOVCircle)
FOVCorner.CornerRadius = UDim.new(1, 0)

local FOVStroke = Instance.new("UIStroke", FOVCircle)
FOVStroke.Color = Color3.fromRGB(129, 140, 248)
FOVStroke.Thickness = 1.5

---------------------------------------------------------
-- CUSTOM CROSSHAIR DRAWING SYSTEM
---------------------------------------------------------
local CrosshairGui = Instance.new("ScreenGui", CoreGui)
CrosshairGui.Name = "UniversalCrosshairGui"

local CrosshairContainer = Instance.new("Frame", CrosshairGui)
CrosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairContainer.Size = UDim2.new(0, 50, 0, 50)
CrosshairContainer.BackgroundTransparency = 1
CrosshairContainer.Visible = false

local CH_Top = Instance.new("Frame", CrosshairContainer)
CH_Top.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
CH_Top.BorderSizePixel = 0

local CH_Bottom = Instance.new("Frame", CrosshairContainer)
CH_Bottom.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
CH_Bottom.BorderSizePixel = 0

local CH_Left = Instance.new("Frame", CrosshairContainer)
CH_Left.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
CH_Left.BorderSizePixel = 0

local CH_Right = Instance.new("Frame", CrosshairContainer)
CH_Right.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
CH_Right.BorderSizePixel = 0

local CH_Dot = Instance.new("Frame", CrosshairContainer)
CH_Dot.AnchorPoint = Vector2.new(0.5, 0.5)
CH_Dot.Position = UDim2.new(0.5, 0, 0.5, 0)
CH_Dot.Size = UDim2.new(0, 2, 0, 2)
CH_Dot.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
CH_Dot.BorderSizePixel = 0
Instance.new("UICorner", CH_Dot).CornerRadius = UDim.new(1, 0)

local CH_CircleRing = Instance.new("Frame", CrosshairContainer)
CH_CircleRing.AnchorPoint = Vector2.new(0.5, 0.5)
CH_CircleRing.Position = UDim2.new(0.5, 0, 0.5, 0)
CH_CircleRing.BackgroundTransparency = 1
CH_CircleRing.BorderSizePixel = 0
Instance.new("UICorner", CH_CircleRing).CornerRadius = UDim.new(1, 0)
local CH_RingStroke = Instance.new("UIStroke", CH_CircleRing)
CH_RingStroke.Color = Color3.fromRGB(129, 140, 248)
CH_RingStroke.Thickness = 1.5

local function updateCrosshairLayout()
    CrosshairContainer.Visible = Config.CustomCrosshairEnabled
    if not Config.CustomCrosshairEnabled then return end

    CH_Top.Visible = false
    CH_Bottom.Visible = false
    CH_Left.Visible = false
    CH_Right.Visible = false
    CH_Dot.Visible = false
    CH_CircleRing.Visible = false

    local size = Config.CrosshairSize
    local gap = Config.CrosshairGap
    local style = Config.CrosshairStyle

    if style == "Cross" then
        CH_Top.Visible = true; CH_Bottom.Visible = true; CH_Left.Visible = true; CH_Right.Visible = true
        CH_Top.Size = UDim2.new(0, 2, 0, size); CH_Top.Position = UDim2.new(0.5, -1, 0.5, -gap - size)
        CH_Bottom.Size = UDim2.new(0, 2, 0, size); CH_Bottom.Position = UDim2.new(0.5, -1, 0.5, gap)
        CH_Left.Size = UDim2.new(0, size, 0, 2); CH_Left.Position = UDim2.new(0.5, -gap - size, 0.5, -1)
        CH_Right.Size = UDim2.new(0, size, 0, 2); CH_Right.Position = UDim2.new(0.5, gap, 0.5, -1)
    elseif style == "Dot" then
        CH_Dot.Visible = true
        CH_Dot.Size = UDim2.new(0, size / 2, 0, size / 2)
    elseif style == "Circle" then
        CH_CircleRing.Visible = true
        CH_CircleRing.Size = UDim2.new(0, size * 2, 0, size * 2)
    elseif style == "T-Shape" then
        CH_Bottom.Visible = true; CH_Left.Visible = true; CH_Right.Visible = true
        CH_Bottom.Size = UDim2.new(0, 2, 0, size); CH_Bottom.Position = UDim2.new(0.5, -1, 0.5, gap)
        CH_Left.Size = UDim2.new(0, size, 0, 2); CH_Left.Position = UDim2.new(0.5, -gap - size, 0.5, -1)
        CH_Right.Size = UDim2.new(0, size, 0, 2); CH_Right.Position = UDim2.new(0.5, gap, 0.5, -1)
    end
end

---------------------------------------------------------
-- FULLBRIGHT & FREECAM LOGIC
---------------------------------------------------------
local originalBrightness = Lighting.Brightness
local originalShadows = Lighting.GlobalShadows
local originalAmbient = Lighting.OutdoorAmbient

local function toggleFullbright(state)
    if state then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = originalBrightness; Lighting.GlobalShadows = originalShadows; Lighting.OutdoorAmbient = originalAmbient
    end
end
if Config.FullbrightEnabled then toggleFullbright(true) end

local freecamPosition = Vector3.new()
local freecamRotation = Vector2.new()
local freecamConn = nil

local function getFreecamKeysVector()
    local moveDir = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
    return moveDir
end

local function toggleFreecam(state)
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if state then
        freecamPosition = Camera.CFrame.Position
        local lookVector = Camera.CFrame.LookVector
        freecamRotation = Vector2.new(math.asin(lookVector.Y), math.atan2(-lookVector.X, -lookVector.Z))
        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        if rootPart then rootPart.Anchored = true end
        if humanoid then humanoid.PlatformStand = true end
        
        freecamConn = RunService.RenderStepped:Connect(function(dt)
            if not Config.FreecamEnabled then return end
            local moveVector = getFreecamKeysVector()
            local mouseDelta = UserInputService:GetMouseDelta()
            freecamRotation = freecamRotation - Vector2.new(mouseDelta.Y * Config.FreecamSensitivity * 0.01, mouseDelta.X * Config.FreecamSensitivity * 0.01)
            freecamRotation = Vector2.new(math.clamp(freecamRotation.X, -math.rad(89), math.rad(89)), freecamRotation.Y)
            local rotationCFrame = CFrame.Angles(0, freecamRotation.Y, 0) * CFrame.Angles(freecamRotation.X, 0, 0)
            local combined = (rotationCFrame.LookVector * -moveVector.Z + rotationCFrame.RightVector * moveVector.X + Vector3.new(0, moveVector.Y, 0))
            if combined.Magnitude > 0 then
                freecamPosition = freecamPosition + (combined.Unit * (Config.FreecamSpeed * dt))
            end
            Camera.CFrame = CFrame.new(freecamPosition) * rotationCFrame
        end)
    else
        if freecamConn then freecamConn:Disconnect() end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Camera.CameraType = Enum.CameraType.Custom
        if rootPart then rootPart.Anchored = false end
        if humanoid then humanoid.PlatformStand = false; Camera.CameraSubject = humanoid end
    end
end

---------------------------------------------------------
-- TARGETING & AIMBOT LOGIC
---------------------------------------------------------
local currentLockedTarget = nil
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function isVisible(targetPart, ignoreChar)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, ignoreChar}
    return Workspace:Raycast(origin, direction, raycastParams) == nil
end

local function getClosestPartToCenter(maxDistance, partName)
    local closestPart = nil
    local shortestDistance = maxDistance
    local screenCenter = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local targetPart = char:FindFirstChild(partName) or char:FindFirstChild("Head")
                if humanoid and humanoid.Health > 0 and targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and isVisible(targetPart, char) then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if distance < shortestDistance then
                            closestPart = targetPart
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

---------------------------------------------------------
-- ESP MANAGEMENT
---------------------------------------------------------
local ESPData = {}
local function setupPlayerESP(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        if ESPData[player] then
            if ESPData[player].Highlight then ESPData[player].Highlight:Destroy() end
            if ESPData[player].Beam then ESPData[player].Beam:Destroy() end
            if ESPData[player].Attachment0 then ESPData[player].Attachment0:Destroy() end
            if ESPData[player].Attachment1 then ESPData[player].Attachment1:Destroy() end
            if ESPData[player].Billboard then ESPData[player].Billboard:Destroy() end
        end
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not rootPart then return end

        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.5
        highlight.FillColor = Color3.fromRGB(244, 63, 94)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Adornee = character
        highlight.Enabled = Config.BoxESP
        highlight.Parent = character

        local att0 = Instance.new("Attachment", Workspace.Terrain)
        local att1 = Instance.new("Attachment", rootPart)
        local beam = Instance.new("Beam")
        beam.Attachment0 = att0; beam.Attachment1 = att1
        beam.Color = ColorSequence.new(Color3.fromRGB(129, 140, 248))
        beam.Width0 = 0.1; beam.Width1 = 0.1; beam.FaceCamera = true
        beam.Enabled = Config.Tracers; beam.Parent = rootPart

        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = character:WaitForChild("Head", 5)
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = Config.NameESP or Config.DistanceESP or Config.HealthBar
        billboard.Parent = character

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 0, 25); label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255); label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold; label.TextSize = 13

        local healthBarBg = Instance.new("Frame", billboard)
        healthBarBg.Size = UDim2.new(0, 80, 0, 6); healthBarBg.Position = UDim2.new(0.5, -40, 0, 28)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(20, 22, 30); healthBarBg.BorderSizePixel = 0
        Instance.new("UICorner", healthBarBg).CornerRadius = UDim.new(1, 0)

        local healthBarFill = Instance.new("Frame", healthBarBg)
        healthBarFill.Size = UDim2.new(1, 0, 1, 0); healthBarFill.BackgroundColor3 = Color3.fromRGB(74, 222, 128); healthBarFill.BorderSizePixel = 0
        Instance.new("UICorner", healthBarFill).CornerRadius = UDim.new(1, 0)

        local healthText = Instance.new("TextLabel", billboard)
        healthText.Size = UDim2.new(1, 0, 0, 20); healthText.Position = UDim2.new(0, 0, 0, 36)
        healthText.BackgroundTransparency = 1; healthText.TextColor3 = Color3.fromRGB(74, 222, 128)
        healthText.TextStrokeTransparency = 0; healthText.Font = Enum.Font.GothamBold; healthText.TextSize = 11

        ESPData[player] = {
            Character = character, Highlight = highlight, Beam = beam, Attachment0 = att0, Attachment1 = att1,
            Billboard = billboard, Label = label, HealthBarBg = healthBarBg, HealthBarFill = healthBarFill, HealthText = healthText
        }
    end
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function removePlayerESP(player)
    if ESPData[player] then
        if ESPData[player].Highlight then ESPData[player].Highlight:Destroy() end
        if ESPData[player].Beam then ESPData[player].Beam:Destroy() end
        if ESPData[player].Attachment0 then ESPData[player].Attachment0:Destroy() end
        if ESPData[player].Attachment1 then ESPData[player].Attachment1:Destroy() end
        if ESPData[player].Billboard then ESPData[player].Billboard:Destroy() end
        ESPData[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do setupPlayerESP(p) end
Players.PlayerAdded:Connect(setupPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

---------------------------------------------------------
-- MAIN CORE RENDER LOOP & ORBIT / SPECTATE HANDLER
---------------------------------------------------------
local frameCounter = 0
RunService.RenderStepped:Connect(function(dt)
    FOVCircle.Size = UDim2.new(0, Config.AimbotFOV * 2, 0, Config.AimbotFOV * 2)
    FOVCircle.Visible = Config.ShowFOVCircle
    currentLockedTarget = nil

    -- Active Spectate Handler
    if Config.TargetActionMode == "Spectate" and Config.ActiveSpectateTarget then
        if Config.ActiveSpectateTarget.Character and Config.ActiveSpectateTarget.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = Config.ActiveSpectateTarget.Character.Humanoid
        end
    end

    -- Active Orbit Handler
    if Config.TargetActionMode == "Orbit" and Config.ActiveOrbitTarget then
        local targetChar = Config.ActiveOrbitTarget.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if targetRoot and myRoot then
            local timeValue = tick() * Config.OrbitSpeed
            local offsetX = math.cos(timeValue) * Config.OrbitRadius
            local offsetZ = math.sin(timeValue) * Config.OrbitRadius
            myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(offsetX, 3, offsetZ), targetRoot.Position)
        end
    end

    if Config.AimbotEnabledState and not Config.FreecamEnabled then
        local targetPart = getClosestPartToCenter(Config.AimbotFOV, Config.TargetPartName)
        if targetPart then
            currentLockedTarget = targetPart.Parent
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / math.max(Config.Smoothness, 1))
            
            if Config.AutoShootEnabled then
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function()
                            tool:Activate()
                            local screenCenter = Camera.ViewportSize * 0.5
                            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
                            task.defer(function()
                                VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)
                            end)
                        end)
                    end
                end
            end
        end
    end

    local char = LocalPlayer.Character
    if char and not Config.FreecamEnabled then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")

        if humanoid then
            if Config.SpeedHack then 
                humanoid.WalkSpeed = Config.WalkSpeed 
                if rootPart and humanoid.MoveDirection.Magnitude > 0 then
                    rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (Config.WalkSpeed / 16) * 0.12)
                end
            end
            if Config.JumpHack then humanoid.UseJumpPower = true; humanoid.JumpPower = Config.JumpPower end
        end

        if Config.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end

        if Config.Spinbot and rootPart then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0)
        end

        if Config.Fly and rootPart then
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            rootPart.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * Config.FlySpeed) or Vector3.new(0, 0.1, 0)
        end

        if Config.ShiftLockEnabled and rootPart and humanoid then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            humanoid.AutoRotate = false
            local camLook = Camera.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Unit.Z)
            if flatLook.Magnitude > 0 then rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + flatLook) end
        elseif not Config.ShiftLockEnabled and humanoid then
            humanoid.AutoRotate = true
        end
    end

    frameCounter = frameCounter + 1
    if frameCounter % 2 == 0 then
        local localRoot = char and char:FindFirstChild("HumanoidRootPart")
        for player, esp in pairs(ESPData) do
            local pChar = player.Character
            local pHumanoid = pChar and pChar:FindFirstChildOfClass("Humanoid")
            local pRootPart = pChar and pChar:FindFirstChild("HumanoidRootPart")

            if pChar and pHumanoid and pRootPart and pHumanoid.Health > 0 then
                if pChar == currentLockedTarget then
                    esp.Highlight.FillColor = Color3.fromRGB(74, 222, 128)
                    esp.Highlight.Enabled = true
                else
                    esp.Highlight.FillColor = Color3.fromRGB(244, 63, 94)
                    esp.Highlight.Enabled = Config.BoxESP
                end

                if Config.Tracers and localRoot then
                    esp.Attachment0.WorldPosition = localRoot.Position - Vector3.new(0, 2, 0)
                    esp.Beam.Enabled = true
                else
                    esp.Beam.Enabled = false
                end

                if Config.NameESP or Config.DistanceESP then
                    esp.Billboard.Enabled = true
                    local text = Config.NameESP and player.Name or ""
                    if Config.DistanceESP then
                        local dist = math.floor((pRootPart.Position - Camera.CFrame.Position).Magnitude)
                        text = text .. (text ~= "" and " [" or "[") .. dist .. "m]"
                    end
                    esp.Label.Text = text
                    esp.Label.Visible = true
                else
                    esp.Label.Visible = false
                end

                esp.HealthBarBg.Visible = Config.HealthBar
                esp.HealthText.Visible = Config.HealthBar
                if Config.HealthBar then
                    local healthPercent = math.clamp(pHumanoid.Health / pHumanoid.MaxHealth, 0, 1)
                    esp.HealthBarFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    esp.HealthText.Text = "HP: " .. math.floor(pHumanoid.Health)
                end
            else
                esp.Highlight.Enabled = false
                esp.Beam.Enabled = false
                esp.Billboard.Enabled = false
            end
        end
    end
end)

---------------------------------------------------------
-- ULTRA-POLISHED V3.4 UI ARCHITECTURE (GLASSMORPHIC)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "UniversalMenuElite"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 580, 0, 520)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
MainFrame.BackgroundTransparency = 0.02
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(38, 43, 61)
MainStroke.Thickness = 1.5

-- Top Title Bar with Gradient Accent Line
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel = 0

local TitleAccent = Instance.new("Frame", TitleBar)
TitleAccent.Size = UDim2.new(1, -24, 0, 1)
TitleAccent.Position = UDim2.new(0, 12, 1, 0)
TitleAccent.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
TitleAccent.BackgroundTransparency = 0.5
TitleAccent.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -120, 1, 0)
TitleText.Position = UDim2.new(0, 16, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "UNIVERSAL FRAMEWORK V3.4"
TitleText.TextColor3 = Color3.fromRGB(245, 247, 250)
TitleText.TextSize = 13
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local SubtitleBadge = Instance.new("TextLabel", TitleBar)
SubtitleBadge.Size = UDim2.new(0, 80, 0, 22)
SubtitleBadge.Position = UDim2.new(1, -92, 0.5, -11)
SubtitleBadge.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
SubtitleBadge.Text = "ELITE UI"
SubtitleBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
SubtitleBadge.Font = Enum.Font.GothamBold
SubtitleBadge.TextSize = 10
Instance.new("UICorner", SubtitleBadge).CornerRadius = UDim.new(0, 6)

-- Sidebar Navigation Container
local Sidebar = Instance.new("ScrollingFrame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, -56)
Sidebar.Position = UDim2.new(0, 12, 0, 52)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 6)

-- Content Frame Container
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Size = UDim2.new(1, -172, 1, -60)
ContentContainer.Position = UDim2.new(0, 160, 0, 52)
ContentContainer.BackgroundTransparency = 1

-- Draggable functionality
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local aimbotKeyButtonRef = nil
local autoShootKeyButtonRef = nil
local shiftLockToggleRef = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Config.MenuKey then
            MainFrame.Visible = not MainFrame.Visible
        elseif input.KeyCode == Config.AimbotKey then
            Config.AimbotEnabledState = not Config.AimbotEnabledState
            if aimbotKeyButtonRef then
                local st = Config.AimbotEnabledState and "ON" or "OFF"
                aimbotKeyButtonRef.Text = "Aimbot Keybind: [" .. tostring(Config.AimbotKey.Name) .. "] (" .. st .. ")"
                aimbotKeyButtonRef.TextColor3 = Config.AimbotEnabledState and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
            end
        elseif input.KeyCode == Config.AutoShootKey then
            Config.AutoShootEnabled = not Config.AutoShootEnabled
            if autoShootKeyButtonRef then
                local st = Config.AutoShootEnabled and "ON" or "OFF"
                autoShootKeyButtonRef.Text = "Auto Shoot Keybind: [" .. tostring(Config.AutoShootKey.Name) .. "] (" .. st .. ")"
                autoShootKeyButtonRef.TextColor3 = Config.AutoShootEnabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
            end
        elseif input.KeyCode == Enum.KeyCode.RightShift then
            Config.ShiftLockEnabled = not Config.ShiftLockEnabled
            if not Config.ShiftLockEnabled then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").AutoRotate = true
                end
            end
            if shiftLockToggleRef then
                shiftLockToggleRef.Text = "Shift Lock (Right Shift)" .. (Config.ShiftLockEnabled and " [ ON ]" or " [ OFF ]")
                shiftLockToggleRef.TextColor3 = Config.ShiftLockEnabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
            end
        end
    end
end)

local activeTab = nil
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, 0, 0, 36)
    TabBtn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    TabBtn.BackgroundTransparency = 0.4
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = Color3.fromRGB(140, 150, 180)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 12
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

    local Page = Instance.new("ScrollingFrame", ContentContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(129, 140, 248)
    Page.Visible = false

    local PageLayout = Instance.new("UIListLayout", Page)
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 16)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(ContentContainer:GetChildren()) do p.Visible = false end
        for _, b in pairs(Sidebar:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(140, 150, 180), BackgroundTransparency = 0.4}):Play()
            end
        end
        Page.Visible = true
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0}):Play()
    end)

    if not activeTab then
        activeTab = Page
        Page.Visible = true
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    local Elements = {}

    function Elements:AddAimbotKeybind(labelText, defaultKey, callback)
        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        btn.BorderSizePixel = 0
        local st = Config.AimbotEnabledState and "ON" or "OFF"
        btn.Text = "  " .. labelText .. ": [" .. tostring(defaultKey.Name) .. "] (" .. st .. ")"
        btn.TextColor3 = Config.AimbotEnabledState and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        aimbotKeyButtonRef = btn

        local listening = false
        btn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            btn.Text = "  " .. labelText .. ": [Press Any Key...]"
            btn.TextColor3 = Color3.fromRGB(129, 140, 248)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Config.AimbotKey = input.KeyCode
                    local curSt = Config.AimbotEnabledState and "ON" or "OFF"
                    btn.Text = "  " .. labelText .. ": [" .. tostring(input.KeyCode.Name) .. "] (" .. curSt .. ")"
                    btn.TextColor3 = Config.AimbotEnabledState and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
                    callback(input.KeyCode)
                    conn:Disconnect()
                    listening = false
                end
            end)
        end)
    end

    function Elements:AddAutoShootKeybind(labelText, defaultKey, callback)
        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        btn.BorderSizePixel = 0
        local st = Config.AutoShootEnabled and "ON" or "OFF"
        btn.Text = "  " .. labelText .. ": [" .. tostring(defaultKey.Name) .. "] (" .. st .. ")"
        btn.TextColor3 = Config.AutoShootEnabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        autoShootKeyButtonRef = btn

        local listening = false
        btn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            btn.Text = "  " .. labelText .. ": [Press Any Key...]"
            btn.TextColor3 = Color3.fromRGB(129, 140, 248)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Config.AutoShootKey = input.KeyCode
                    local curSt = Config.AutoShootEnabled and "ON" or "OFF"
                    btn.Text = "  " .. labelText .. ": [" .. tostring(input.KeyCode.Name) .. "] (" .. curSt .. ")"
                    btn.TextColor3 = Config.AutoShootEnabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
                    callback(input.KeyCode)
                    conn:Disconnect()
                    listening = false
                end
            end)
        end)
    end

    function Elements:AddKeybind(labelText, defaultKey, callback)
        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. labelText .. ": [" .. tostring(defaultKey.Name) .. "]"
        btn.TextColor3 = Color3.fromRGB(160, 168, 192)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local listening = false
        btn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            btn.Text = "  " .. labelText .. ": [Press Any Key...]"
            btn.TextColor3 = Color3.fromRGB(129, 140, 248)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    callback(input.KeyCode)
                    btn.Text = "  " .. labelText .. ": [" .. tostring(input.KeyCode.Name) .. "]"
                    btn.TextColor3 = Color3.fromRGB(160, 168, 192)
                    conn:Disconnect()
                    listening = false
                end
            end)
        end)
    end

    function Elements:AddToggle(labelText, defaultState, callback)
        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. labelText .. (defaultState and " [ ON ]" or " [ OFF ]")
        btn.TextColor3 = defaultState and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        if labelText:find("Shift Lock") then shiftLockToggleRef = btn end

        local state = defaultState
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = "  " .. labelText .. (state and " [ ON ]" or " [ OFF ]")
            TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = state and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(160, 168, 192)}):Play()
            callback(state)
            saveConfig()
        end)
    end

    function Elements:AddDropdown(labelText, options, defaultOption, callback)
        local currentIndex = 1
        for i, opt in ipairs(options) do if opt == defaultOption then currentIndex = i break end end

        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. labelText .. ": " .. options[currentIndex]
        btn.TextColor3 = Color3.fromRGB(160, 168, 192)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function()
            if #options == 0 then return end
            currentIndex = currentIndex + 1
            if currentIndex > #options then currentIndex = 1 end
            local selected = options[currentIndex]
            btn.Text = "  " .. labelText .. ": " .. selected
            callback(selected)
            saveConfig()
        end)
    end

    function Elements:AddSlider(labelText, min, max, default, callback)
        local container = Instance.new("Frame", Page)
        container.Size = UDim2.new(1, -8, 0, 52)
        container.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        container.BorderSizePixel = 0
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, -16, 0, 20)
        label.Position = UDim2.new(0, 8, 0, 6)
        label.BackgroundTransparency = 1
        label.Text = labelText .. ": " .. tostring(default)
        label.TextColor3 = Color3.fromRGB(160, 168, 192)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left

        local sliderBg = Instance.new("Frame", container)
        sliderBg.Size = UDim2.new(1, -16, 0, 6)
        sliderBg.Position = UDim2.new(0, 8, 0, 34)
        sliderBg.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
        sliderBg.BorderSizePixel = 0
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

        local sliderFill = Instance.new("Frame", sliderBg)
        sliderFill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
        sliderFill.BorderSizePixel = 0
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

        local draggingSlider = false
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + ((max - min) * pos))
                sliderFill.Size = UDim2.new(pos, 0, 1, 0)
                label.Text = labelText .. ": " .. tostring(val)
                callback(val)
                saveConfig()
            end
        end)
    end

    function Elements:AddButton(labelText, callback)
        local btn = Instance.new("TextButton", Page)
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. labelText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseButton1Click:Connect(function() callback() end)
    end

    return Elements
end

---------------------------------------------------------
-- POPULATE TABS & CONTROLS (Grouped & Sorted)
---------------------------------------------------------
local CombatTab = CreateTab("Combat")
CombatTab:AddAimbotKeybind("Aimbot", Config.AimbotKey, function(k) Config.AimbotKey = k end)
CombatTab:AddAutoShootKeybind("Auto Shoot", Config.AutoShootKey, function(k) Config.AutoShootKey = k end)
CombatTab:AddSlider("Smoothness", 1, 20, Config.Smoothness, function(v) Config.Smoothness = v end)
CombatTab:AddSlider("FOV Radius", 50, 500, Config.AimbotFOV, function(v) Config.AimbotFOV = v end)
CombatTab:AddToggle("Show FOV Circle", Config.ShowFOVCircle, function(s) Config.ShowFOVCircle = s end)
CombatTab:AddToggle("Wall Check", Config.WallCheck, function(s) Config.WallCheck = s end)
CombatTab:AddDropdown("Target Part", {"Head", "HumanoidRootPart", "Torso"}, Config.TargetPartName, function(v) Config.TargetPartName = v end)

local VisualsTab = CreateTab("Visuals")
VisualsTab:AddToggle("Box ESP", Config.BoxESP, function(s) Config.BoxESP = s end)
VisualsTab:AddToggle("Tracers", Config.Tracers, function(s) Config.Tracers = s end)
VisualsTab:AddToggle("Name ESP", Config.NameESP, function(s) Config.NameESP = s end)
VisualsTab:AddToggle("Distance ESP", Config.DistanceESP, function(s) Config.DistanceESP = s end)
VisualsTab:AddToggle("Health Bar", Config.HealthBar, function(s) Config.HealthBar = s end)
VisualsTab:AddToggle("Fullbright", Config.FullbrightEnabled, function(s) Config.FullbrightEnabled = s; toggleFullbright(s) end)
VisualsTab:AddToggle("Freecam", Config.FreecamEnabled, function(s) Config.FreecamEnabled = s; toggleFreecam(s) end)
VisualsTab:AddSlider("Freecam Speed", 10, 200, Config.FreecamSpeed, function(v) Config.FreecamSpeed = v end)

local CrosshairTab = CreateTab("Crosshair")
CrosshairTab:AddToggle("Custom Crosshair", Config.CustomCrosshairEnabled, function(s) Config.CustomCrosshairEnabled = s; updateCrosshairLayout() end)
CrosshairTab:AddDropdown("Crosshair Style", {"Cross", "Dot", "Circle", "T-Shape"}, Config.CrosshairStyle, function(v) Config.CrosshairStyle = v; updateCrosshairLayout() end)
CrosshairTab:AddSlider("Crosshair Size", 2, 30, Config.CrosshairSize, function(v) Config.CrosshairSize = v; updateCrosshairLayout() end)
CrosshairTab:AddSlider("Crosshair Gap", 0, 20, Config.CrosshairGap, function(v) Config.CrosshairGap = v; updateCrosshairLayout() end)

local MovementTab = CreateTab("Movement")
-- Speed Hack & WalkSpeed
MovementTab:AddToggle("Speed Hack", Config.SpeedHack, function(s) Config.SpeedHack = s end)
MovementTab:AddSlider("WalkSpeed", 16, 200, Config.WalkSpeed, function(v) Config.WalkSpeed = v end)

-- Jump Hack & JumpPower
MovementTab:AddToggle("Jump Hack", Config.JumpHack, function(s) Config.JumpHack = s end)
MovementTab:AddSlider("JumpPower", 50, 400, Config.JumpPower, function(v) Config.JumpPower = v end)

-- Fly & Fly Speed
MovementTab:AddToggle("Fly", Config.Fly, function(s) Config.Fly = s end)
MovementTab:AddSlider("Fly Speed", 10, 200, Config.FlySpeed, function(v) Config.FlySpeed = v end)

-- Spinbot & Spin Speed
MovementTab:AddToggle("Spinbot", Config.Spinbot, function(s) Config.Spinbot = s end)
MovementTab:AddSlider("Spin Speed", 5, 100, Config.SpinSpeed, function(v) Config.SpinSpeed = v end)

-- Other Movement options
MovementTab:AddToggle("Noclip", Config.Noclip, function(s) Config.Noclip = s end)
MovementTab:AddToggle("Shift Lock (Right Shift)", Config.ShiftLockEnabled, function(s) Config.ShiftLockEnabled = s end)

local SettingsTab = CreateTab("Settings")
SettingsTab:AddKeybind("Menu Key", Config.MenuKey, function(k) Config.MenuKey = k end)
SettingsTab:AddButton("Save Config", function() saveConfig() end)
SettingsTab:AddButton("Load Config", function() loadConfig() end)
SettingsTab:AddButton("Reset Config", function() resetConfig() end)
SettingsTab:AddButton("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)

updateCrosshairLayout()
