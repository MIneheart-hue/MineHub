--[[ MINEHUB :: V2 (UI Fix) ]]
print("[MINEHUB V2] Loaded. Type ;menu to open.")

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UserInput  = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer
local Cam        = Workspace.CurrentCamera

local CONFIG = {
    -- Aim
    Aimbot       = false,
    SilentAim    = true,
    AimPart      = "Head",
    FOV          = 250,
    Smoothness   = 0.5,
    TeamCheck    = true,
    -- Visuals
    SkeletonESP  = true,
    GlowESP      = true,
    -- Misc
    NoRecoil     = true,
    LongRange    = true,
    MagicBullet  = true,
    BringAll     = false,
    HugeHitbox   = false,
    -- Colors
    EnemyColor   = Color3.fromRGB(255, 40, 40),
    TeamColor    = Color3.fromRGB(0, 150, 255),
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
    if hum and hum.Health > 0 then
        fov.Position = Cam.ViewportSize / 2
        fov.Radius = CONFIG.FOV
        fov.Visible = CONFIG.Aimbot or CONFIG.SilentAim
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
-- AIMBOT (Smooth Lock)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if CONFIG.Aimbot and UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget()
        if t then
            local targetCF = CFrame.new(Cam.CFrame.Position, t.Position)
            Cam.CFrame = Cam.CFrame:Lerp(targetCF, CONFIG.Smoothness)
        end
    end
end)

-- ============================================================
-- SILENT AIM + MAGIC BULLET + HUGE HITBOX + WALLBANG
-- ============================================================
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if checkcaller() then return oldNamecall(self, ...) end

        if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            if CONFIG.MagicBullet or CONFIG.SilentAim then
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

        if (CONFIG.SilentAim or CONFIG.MagicBullet) and (method == "FireServer" or method == "InvokeServer") then
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
-- LONG RANGE + ONE HIT SNIPER
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
-- NO RECOIL
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not CONFIG.NoRecoil then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    
    local rot = Cam.CFrame - Cam.CFrame.Position
    local _, ry, _ = rot:ToEulerAnglesXYZ()
    local target = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, ry, 0)
    Cam.CFrame = Cam.CFrame:Lerp(target, 0.15)
end)

-- ============================================================
-- BRING ALL / ORBIT
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not CONFIG.BringAll then return end
    local myChar = LP.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local offset = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (not CONFIG.TeamCheck or p.Team ~= LP.Team) then
            local char = p.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    root.CFrame = myRoot.CFrame * CFrame.new(math.cos(offset) * 5, 0, math.sin(offset) * 5)
                    offset = offset + (math.pi * 2 / #Players:GetPlayers())
                end
            end
        end
    end
end)

-- ============================================================
-- HUGE HITBOX
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        if not CONFIG.HugeHitbox then
            task.wait(1)
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and (not CONFIG.TeamCheck or p.Team ~= LP.Team) then
                    local char = p.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                pcall(function() part.Size = Vector3.new(10, 10, 10) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- SKELETON & GLOW ESP
-- ============================================================
local skels = {}
local highlights = {}

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
    if highlights[p] then
        highlights[p]:Destroy()
        highlights[p] = nil
    end
end

local function buildESP(p)
    local char = p.Character
    if not char then return end
    clearPlayer(p)

    local isTeam = (p.Team == LP.Team)
    local col = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor

    local hl = Instance.new("Highlight")
    hl.Name = "MINEHUB_HL"
    hl.Adornee = char
    hl.FillColor = col
    hl.OutlineColor = col
    hl.FillTransparency = 0.5
    hl.Parent = char
    highlights[p] = hl

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

local function updateESP(p)
    local entry = skels[p]
    if not entry then return end
    local lines, bones = entry.lines, entry.bones
    local char = p.Character
    if not char then
        for _, l in ipairs(lines) do l.Visible = false end
        if highlights[p] then highlights[p].FillTransparency = 1; highlights[p].OutlineTransparency = 1 end
        return
    end
    
    local isTeam = (p.Team == LP.Team)
    local col = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor
    if entry.color ~= col then
        entry.color = col
        for _, l in ipairs(lines) do l.Color = col end
        if highlights[p] then highlights[p].FillColor = col; highlights[p].OutlineColor = col end
    end

    if highlights[p] then
        highlights[p].FillTransparency = CONFIG.GlowESP and 0.5 or 1
        highlights[p].OutlineTransparency = CONFIG.GlowESP and 0 or 1
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
    p.CharacterAdded:Connect(function() task.wait(0.6) buildESP(p) end)
end)
Players.PlayerRemoving:Connect(clearPlayer)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then buildESP(p) end
        p.CharacterAdded:Connect(function() task.wait(0.6) buildESP(p) end)
    end
end

RunService.RenderStepped:Connect(function()
    for p, _ in pairs(skels) do updateESP(p) end
end)

-- ============================================================
-- MENU (UI FIX - NO SCROLLING FRAME)
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
    main.Size = UDim2.new(0, 320, 0, 380) -- Taller frame
    main.Position = UDim2.new(0.5, -160, 0.5, -190)
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
    title.Position = UDim2.new(0, 10, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = "MINEHUB V2"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.TextColor3 = CONFIG.Accent
    closeBtn.Parent = main
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    -- Tabs Container
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 25)
    tabBar.Position = UDim2.new(0, 10, 0, 35)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main
    Instance.new("UIListLayout", tabBar).FillDirection = Enum.FillDirection.Horizontal
    Instance.new("UIListLayout", tabBar).Padding = UDim.new(0, 5)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -70)
    content.Position = UDim2.new(0, 10, 0, 65)
    content.BackgroundTransparency = 1
    content.Parent = main

    local pages = {}
    local activeTab = nil

    local function newPage(name)
        local page = Instance.new("Frame") -- Changed to Frame
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = content
        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        pages[name] = page
        return page
    end

    local function makeTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, -4, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        btn.Text = name
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        btn.Parent = tabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        local page = newPage(name)

        btn.MouseButton1Click:Connect(function()
            if activeTab == name then return end
            activeTab = name
            for n, p in pairs(pages) do p.Visible = (n == name) end
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") then
                    local isActive = (child.Text == name)
                    child.BackgroundColor3 = isActive and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(25, 25, 25)
                    child.TextColor3 = isActive and CONFIG.Accent or Color3.fromRGB(150, 150, 150)
                end
            end
        end)
        return page
    end

    local function makeToggle(parent, label, configKey)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.Parent = parent
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

    local function makeSlider(parent, label, configKey, min, max)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 15)
        lbl.Position = UDim2.new(0, 10, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": " .. tostring(CONFIG[configKey])
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 8)
        bar.Position = UDim2.new(0, 10, 0, 25)
        bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((CONFIG[configKey]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = CONFIG.Accent
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bar

        btn.MouseButton1Click:Connect(function()
            local mouse = UserInput:GetMouseLocation()
            local relX = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            CONFIG[configKey] = math.floor(min + (max - min) * relX)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            lbl.Text = label .. ": " .. tostring(CONFIG[configKey])
        end)
    end

    -- Build Pages
    local aimPage = makeTab("Aim")
    makeToggle(aimPage, "Aimbot (Hold RMB)", "Aimbot")
    makeToggle(aimPage, "Silent Aim", "SilentAim")
    makeToggle(aimPage, "Team Check", "TeamCheck")
    makeSlider(aimPage, "FOV", "FOV", 50, 800)
    makeSlider(aimPage, "Smoothness", "Smoothness", 0.1, 1)

    local visPage = makeTab("Visuals")
    makeToggle(visPage, "Skeleton ESP (Red/Blue)", "SkeletonESP")
    makeToggle(visPage, "Glow ESP (Highlight)", "GlowESP")

    local miscPage = makeTab("Misc")
    makeToggle(miscPage, "No Recoil", "NoRecoil")
    makeToggle(miscPage, "Magic Bullet", "MagicBullet")
    makeToggle(miscPage, "Long Range / One Hit", "LongRange")
    makeToggle(miscPage, "Bring All Enemy (Orbit)", "BringAll")
    makeToggle(miscPage, "Huge Hitbox", "HugeHitbox")

    local cfgPage = makeTab("Config")
    -- Config stuff here

    -- Activate first tab
    tabBar:GetChildren()[1].MouseButton1Click:Fire()

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

    -- Open/Close
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

print("[MINEHUB V2] UI Fixed.")