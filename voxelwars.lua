--[[ MINEHUB :: VOXEL WARS (Tabbed UI) ]]
print("[MINEHUB] Loaded. Type ;menu to open.")

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UserInput  = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer
local Cam        = Workspace.CurrentCamera

local CONFIG = {
    -- Aim
    Aimbot       = true,
    AimPart      = "Head",
    FOV          = 250,
    TeamCheck    = true,
    -- Visual
    BoxESP       = true,
    SkeletonESP  = true,
    ESPColor     = Color3.fromRGB(255, 40, 40),
    -- Misc
    NoRecoil     = true,
    LongRange    = true,
    BringAll     = false,
    -- Config
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
    fov.Position = Cam.ViewportSize / 2
    fov.Radius = CONFIG.FOV
    fov.Visible = CONFIG.Aimbot
end)

-- ============================================================
-- TARGETING
-- ============================================================
local function isAiming()
    return UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

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
-- AIMBOT (Hold RMB)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if CONFIG.Aimbot and isAiming() then
        local t = getTarget()
        if t then
            Cam.CFrame = CFrame.new(Cam.CFrame.Position, t.Position)
        end
    end
end)

-- ============================================================
-- BRING ALL
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
-- LONG RANGE
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
    if isAiming() then return end
    local rot = Cam.CFrame - Cam.CFrame.Position
    local _, ry, _ = rot:ToEulerAnglesXYZ()
    local target = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, ry, 0)
    Cam.CFrame = Cam.CFrame:Lerp(target, 0.15)
end)

-- ============================================================
-- ESP
-- ============================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "MINEHUB_ESP"
pcall(function() espFolder.Parent = CoreGui end)
if not espFolder.Parent then espFolder.Parent = LP:WaitForChild("PlayerGui") end

local boxes = {}
local skels = {}

local function clearPlayer(p)
    if boxes[p] then boxes[p]:Destroy(); boxes[p] = nil end
    if skels[p] then
        for _, line in pairs(skels[p].lines) do line:Destroy() end
        skels[p] = nil
    end
end

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

local function buildSkeleton(char)
    local lines = {}
    local rig = char:FindFirstChild("Humanoid") and char.Humanoid.RigType
    local bones = (rig == Enum.HumanoidRigType.R15) and SKEL_BONES_R15 or SKEL_BONES_R6
    for i = 1, #bones do
        local l = Drawing.new("Line")
        l.Thickness = 1
        l.Color = CONFIG.ESPColor
        l.Visible = false
        lines[i] = l
    end
    return lines, bones
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

local function buildESP(p)
    local char = p.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    clearPlayer(p)

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "MINEHUB_BOX"
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = CONFIG.ESPColor
    box.Transparency = 0.4
    box.Parent = espFolder
    boxes[p] = box

    local lines, bones = buildSkeleton(char)
    skels[p] = {lines = lines, bones = bones}
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
    for p, box in pairs(boxes) do
        if CONFIG.BoxESP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = true
            box.Adornee = p.Character.HumanoidRootPart
            box.Color3 = CONFIG.ESPColor
        else
            box.Visible = false
        end
    end
    for p, _ in pairs(skels) do updateSkeleton(p) end
end)

-- ============================================================
-- TABBED MENU
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
    main.Size = UDim2.new(0, 320, 0, 280)
    main.Position = UDim2.new(0.5, -160, 0.5, -140)
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
    title.Text = "MINEHUB VOXEL"
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
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content
        Instance.new("UIListLayout", page).Padding = UDim.new(0, 6)
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

    local aimPage = makeTab("Aim")
    makeToggle(aimPage, "Aimbot (Hold RMB)", "Aimbot")
    makeToggle(aimPage, "Team Check", "TeamCheck")
    makeSlider(aimPage, "FOV", "FOV", 50, 800)

    local visPage = makeTab("Visual")
    makeToggle(visPage, "Box ESP", "BoxESP")
    makeToggle(visPage, "Skeleton ESP", "SkeletonESP")

    local miscPage = makeTab("Misc")
    makeToggle(miscPage, "Long Range", "LongRange")
    makeToggle(miscPage, "No Recoil", "NoRecoil")
    makeToggle(miscPage, "Bring All", "BringAll")

    local cfgPage = makeTab("Config")
    -- Add anything else here later if needed

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

print("[MINEHUB] Tabbed Menu Loaded.")