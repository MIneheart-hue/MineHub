--[[ MINEHUB :: VOXEL WARS (Stable Reset) ]]
print("[MINEHUB] Loaded. Type ;menu to open.")

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UserInput  = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer
local Cam        = Workspace.CurrentCamera

local CONFIG = {
    SkeletonESP  = true,
    NoRecoil     = true,
    LongRange    = true,
    SilentAim    = true,
    TeamCheck    = true,
    AimPart      = "Head",
    FOV          = 250,
    EnemyColor   = Color3.fromRGB(255, 40, 40),   -- Red
    TeamColor    = Color3.fromRGB(0, 150, 255),   -- Blue
    Accent       = Color3.fromRGB(255, 0, 150),
}

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local fov = Drawing.new("Circle")
fov.Thickness = 1
fov.Color = CONFIG.Accent
fov.Filled = false

RunService.RenderStepped:Connect(function()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    -- Only show FOV if alive
    if hum and hum.Health > 0 then
        fov.Position = Cam.ViewportSize / 2
        fov.Radius = CONFIG.FOV
        fov.Visible = CONFIG.SilentAim
    else
        fov.Visible = false
    end
end)

-- ============================================================
-- TARGETING
-- ============================================================
local function getTarget()
    local best, bestDist = nil, CONFIG.FOV
    local center = Cam.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local okTeam = (not CONFIG.TeamCheck) or (p.Team ~= LP.Team)
            if okTeam then
                local char = p.Character
                if char then
                    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if part and hum and hum.Health > 0 then
                        local sp, onScreen = Cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bestDist then best, bestDist = part, d end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
-- SILENT AIM + MAGIC BULLET (Safe Hook)
-- ============================================================
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if checkcaller() then return oldNamecall(self, ...) end

        if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            if CONFIG.SilentAim then
                local t = getTarget()
                if t then
                    if method == "Raycast" then
                        local origin = args[1]
                        local dir = args[2]
                        args[2] = (t.Position - origin).Unit * dir.Magnitude
                        args[3] = args[3] or RaycastParams.new()
                        args[3].FilterType = Enum.RaycastFilterType.Exclude
                        args[3].FilterDescendantsInstances = {LP.Character, Cam}
                    else
                        local ray = args[1]
                        args[1] = Ray.new(ray.Origin, (t.Position - ray.Origin).Unit * ray.Direction.Magnitude)
                        args[2] = {LP.Character, Cam}
                    end
                end
            end
            return oldNamecall(self, table.unpack(args))
        end

        if CONFIG.SilentAim and (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            local t = getTarget()
            if t then
                for i, v in ipairs(args) do
                    if typeof(v) == "CFrame" then
                        args[i] = CFrame.new(v.Position, t.Position)
                    elseif typeof(v) == "Vector3" then
                        local origin = Cam.CFrame.Position
                        args[i] = (t.Position - origin).Unit
                    end
                end
            end
            return oldNamecall(self, table.unpack(args))
        end
        return oldNamecall(self, ...)
    end)
end)

-- ============================================================
-- LONG RANGE + ONE HIT
-- ============================================================
local function patchGuns()
    if not CONFIG.LongRange then return end
    local char = LP.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("ValueBase") then
                    local n = v.Name:lower()
                    if n:find("range") or n:find("distance") then
                        pcall(function() v.Value = 99999 end)
                    end
                    if n:find("damage") then
                        pcall(function() v.Value = 9999 end)
                    end
                    if n:find("firerate") or n:find("cooldown") then
                        pcall(function() v.Value = 0.01 end)
                    end
                end
            end
            for attr, val in pairs(tool:GetAttributes()) do
                local an = tostring(attr):lower()
                if type(val) == "number" then
                    if an:find("range") or an:find("distance") then
                        pcall(function() tool:SetAttribute(attr, 99999) end)
                    end
                    if an:find("damage") then
                        pcall(function() tool:SetAttribute(attr, 9999) end)
                    end
                    if an:find("firerate") or an:find("cooldown") then
                        pcall(function() tool:SetAttribute(attr, 0.01) end)
                    end
                end
            end
        end
    end
end
task.spawn(function() while task.wait(1) do patchGuns() end end)
LP.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(function(ch)
        if ch:IsA("Tool") then task.wait(0.15) patchGuns() end
    end)
end)

-- ============================================================
-- NO RECOIL (Safely gated to only apply when alive)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not CONFIG.NoRecoil then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    -- Don't fight the respawn camera
    if not hum or hum.Health <= 0 then return end
    
    local rot = Cam.CFrame - Cam.CFrame.Position
    local _, ry, _ = rot:ToEulerAnglesXYZ()
    local target = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, ry, 0)
    Cam.CFrame = Cam.CFrame:Lerp(target, 0.15)
end)

-- ============================================================
-- SKELETON ESP
-- ============================================================
local skels = {}

local SKEL_BONES_R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
local SKEL_BONES_R6 = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}

local function clearPlayer(p)
    if skels[p] then
        for _, line in pairs(skels[p].lines) do line:Destroy() end
        skels[p] = nil
    end
end

local function buildSkeleton(p)
    local char = p.Character
    if not char then return end
    clearPlayer(p)

    local isTeam = (p.Team == LP.Team)
    local col = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor

    local lines = {}
    local rig = char:FindFirstChild("Humanoid") and char.Humanoid.RigType
    local bones = (rig == Enum.HumanoidRigType.R15) and SKEL_BONES_R15 or SKEL_BONES_R6
    
    for i = 1, #bones do
        local l = Drawing.new("Line")
        l.Thickness = 1.5
        l.Color = col
        l.Visible = false
        lines[i] = l
    end
    skels[p] = {lines = lines, bones = bones, color = col}
end

local function updateSkeleton(p)
    local entry = skels[p]
    if not entry then return end
    local lines, bones = entry.lines, entry.bones
    local char = p.Character
    if not char then
        for _, l in ipairs(lines) do l.Visible = false end
        return
    end
    
    -- Update colors if team changes
    local isTeam = (p.Team == LP.Team)
    local col = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor
    if entry.color ~= col then
        entry.color = col
        for _, l in ipairs(lines) do l.Color = col end
    end

    for i, pair in ipairs(bones) do
        local a = char:FindFirstChild(pair[1])
        local b = char:FindFirstChild(pair[2])
        if a and b then
            local pa, onA = Cam:WorldToViewportPoint(a.Position)
            local pb, onB = Cam:WorldToViewportPoint(b.Position)
            if onA and onB then
                lines[i].From = Vector2.new(pa.X, pa.Y)
                lines[i].To   = Vector2.new(pb.X, pb.Y)
                lines[i].Visible = CONFIG.SkeletonESP
            else
                lines[i].Visible = false
            end
        else
            lines[i].Visible = false
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.6) buildSkeleton(p) end)
end)
Players.PlayerRemoving:Connect(clearPlayer)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then buildSkeleton(p) end
        p.CharacterAdded:Connect(function() task.wait(0.6) buildSkeleton(p) end)
    end
end

RunService.RenderStepped:Connect(function()
    for p, _ in pairs(skels) do updateSkeleton(p) end
end)

-- ============================================================
-- MENU
-- ============================================================
local function buildMenu()
    local existing = CoreGui:FindFirstChild("MINEHUB_MENU") or LP.PlayerGui:FindFirstChild("MINEHUB_MENU")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MINEHUB_MENU"
    gui.ResetOnSpawn = false
    local success = pcall(function() gui.Parent = CoreGui end)
    if not success or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 250, 0, 210)
    main.Position = UDim2.new(0.5, -125, 0.5, -105)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

    local accent = Instance.new("Frame", main)
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.BackgroundColor3 = CONFIG.Accent
    accent.BorderSizePixel = 0

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 30)
    title.Position = UDim2.new(0, 5, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "MINEHUB"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = CONFIG.Accent
    closeBtn.Parent = main
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -40)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1
    content.Parent = main
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 6)

    local function makeToggle(label, configKey)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.Parent = content
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 30, 0, 14)
        knob.Position = UDim2.new(1, -40, 0.5, -7)
        knob.BackgroundColor3 = CONFIG[configKey] and CONFIG.Accent or Color3.fromRGB(50, 50, 50)
        knob.Parent = row
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local pill = Instance.new("Frame", knob)
        pill.Size = UDim2.new(0, 10, 0, 10)
        pill.Position = CONFIG[configKey] and UDim2.new(1, -13, 0.5, -5) or UDim.new(0, 3, 0.5, -5)
        pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.Parent = row

        click.MouseButton1Click:Connect(function()
            CONFIG[configKey] = not CONFIG[configKey]
            local on = CONFIG[configKey]
            knob.BackgroundColor3 = on and CONFIG.Accent or Color3.fromRGB(50, 50, 50)
            pill.Position = on and UDim2.new(1, -13, 0.5, -5) or UDim.new(0, 3, 0.5, -5)
        end)
    end

    makeToggle("Skeleton ESP (Red/Blue)", "SkeletonESP")
    makeToggle("Silent Aim (Magic Bullet)", "SilentAim")
    makeToggle("Long Range / One Hit", "LongRange")
    makeToggle("No Recoil", "NoRecoil")

    -- Dragging
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end)
end

pcall(buildMenu)

LP.Chatted:Connect(function(msg)
    if msg == ";menu" then
        local m = LP.PlayerGui:FindFirstChild("MINEHUB_MENU") or CoreGui:FindFirstChild("MINEHUB_MENU")
        if m then m.Enabled = not m.Enabled end
    end
end)

print("[MINEHUB] Clean Reset Loaded.")