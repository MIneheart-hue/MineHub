print("[MINEHUB] Hard-Lock Aimbot Loaded.")

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local UserInput     = game:GetService("UserInputService")
local CoreGui       = game:GetService("CoreGui")
local LocalPlayer   = Players.LocalPlayer
local Camera        = Workspace.CurrentCamera

local CONFIG = {
    MagicBullet = true,
    Aimbot      = true,
    BoxESP      = true,
    NoRecoil    = true,
    GodGuns     = true,
    AimKey      = Enum.UserInputType.MouseButton2, -- RMB
    FOV         = 250,
    TeamCheck   = true,
    AimPart     = "Head",
    Accent      = Color3.fromRGB(255, 0, 150), 
    EnemyColor  = Color3.fromRGB(255, 0, 0),
    TeamColor   = Color3.fromRGB(0, 150, 255),
}

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = CONFIG.Accent
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Camera.ViewportSize / 2
    fovCircle.Radius = CONFIG.FOV
    fovCircle.Visible = CONFIG.Aimbot
end)

-- ============================================================
-- BOX ESP
-- ============================================================
pcall(function()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "MINEHUB_ESP"
    espFolder.Parent = CoreGui
    local espTable = {}

    local function createESP(player)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or espTable[player] then return end

        local isTeam = (player.Team == LocalPlayer.Team)
        local color = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor

        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_Box"
        box.Adornee = hrp
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = Vector3.new(4, 6, 2)
        box.Color3 = color
        box.Transparency = 0.5
        box.Parent = espFolder

        espTable[player] = box
    end

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() 
            task.wait(1) 
            if CONFIG.BoxESP then createESP(p) end 
        end)
    end)
    Players.PlayerRemoving:Connect(function(p)
        if espTable[p] then
            espTable[p]:Destroy()
            espTable[p] = nil
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and CONFIG.BoxESP then
                    if not espTable[p] then createESP(p) end
                elseif not CONFIG.BoxESP then
                    if espTable[p] then
                        espTable[p]:Destroy()
                        espTable[p] = nil
                    end
                end
            end
        end
    end)
end)

-- ============================================================
-- GOD GUNS
-- ============================================================
local function patchGuns()
    if not CONFIG.GodGuns or not LocalPlayer.Character then return end
    for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("ValueBase") then
                    local n = v.Name:lower()
                    if n:find("damage") then v.Value = 9999 end
                    if n:find("firerate") or n:find("fire rate") or n:find("cooldown") then v.Value = 0.01 end
                    if n:find("range") or n:find("distance") then v.Value = 5000 end
                end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            patchGuns()
        end
    end)
end)
task.spawn(function() while task.wait(1) do patchGuns() end end)

-- ============================================================
-- MENU
-- ============================================================
pcall(function()
    local existing = CoreGui:FindFirstChild("MINEHUB")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MINEHUB"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 260, 0, 210)
    main.Position = UDim2.new(0.5, -130, 0.5, -105)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main.BorderSizePixel = 0
    main.Parent = gui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    
    local accentLine = Instance.new("Frame", main)
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.BackgroundColor3 = CONFIG.Accent
    accentLine.BorderSizePixel = 0

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

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.new(1, -20, 0, 25)
    tabs.Position = UDim2.new(0, 10, 0, 35)
    tabs.BackgroundTransparency = 1
    tabs.Parent = main

    local tabBar = Instance.new("Frame", tabs)
    tabBar.Size = UDim2.new(1, 0, 1, 0)
    tabBar.BackgroundTransparency = 1
    Instance.new("UIListLayout", tabBar).FillDirection = Enum.FillDirection.Horizontal
    Instance.new("UIListLayout", tabBar).Padding = UDim.new(0, 5)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -70)
    content.Position = UDim2.new(0, 10, 0, 65)
    content.BackgroundTransparency = 1
    content.Parent = main

    local pages, activeTab = {}, nil

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
        btn.Size = UDim2.new(0.33, -4, 1, 0)
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

        local labelObj = Instance.new("TextLabel")
        labelObj.Size = UDim2.new(1, -50, 1, 0)
        labelObj.Position = UDim2.new(0, 10, 0, 0)
        labelObj.BackgroundTransparency = 1
        labelObj.Text = label
        labelObj.Font = Enum.Font.Gotham
        labelObj.TextSize = 12
        labelObj.TextColor3 = Color3.fromRGB(220, 220, 220)
        labelObj.TextXAlignment = Enum.TextXAlignment.Left
        labelObj.Parent = row

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 30, 0, 14)
        knob.Position = UDim2.new(1, -40, 0.5, -7)
        knob.BackgroundColor3 = CONFIG[configKey] and CONFIG.Accent or Color3.fromRGB(50, 50, 50)
        knob.Parent = row
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local pill = Instance.new("Frame", knob)
        pill.Size = UDim2.new(0, 10, 0, 10)
        pill.Position = CONFIG[configKey] and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
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

    local aimPage = makeTab("Aim")
    makeToggle(aimPage, "Magic Bullet (RMB)", "MagicBullet")
    makeToggle(aimPage, "Camera Aimbot (RMB)", "Aimbot")

    local visPage = makeTab("Visual")
    makeToggle(visPage, "Box ESP", "BoxESP")

    local miscPage = makeTab("Misc")
    makeToggle(miscPage, "God Guns (1-Hit)", "GodGuns")
    makeToggle(miscPage, "No Recoil", "NoRecoil")
    makeToggle(miscPage, "Team Check", "TeamCheck")

    tabBar:GetChildren()[1].MouseButton1Click:Fire()

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
end)

-- ============================================================
-- MAGIC BULLET & AIMBOT
-- ============================================================
local function isAiming()
    return UserInput:IsMouseButtonPressed(CONFIG.AimKey)
end

local function getClosestTarget()
    local best, bestDist = nil, CONFIG.FOV
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        local isEnemy = p ~= LocalPlayer and (not CONFIG.TeamCheck or p.Team ~= LocalPlayer.Team)
        if isEnemy then
            local char = p.Character
            if char then
                local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist < bestDist then 
                            best, bestDist = part, dist 
                        end
                    end
                end
            end
        end
    end
    return best
end

pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList") then
            local args = {...}
            if CONFIG.MagicBullet and isAiming() then
                local target = getClosestTarget()
                if target then
                    if method == "Raycast" then
                        local origin = args[1]
                        local direction = args[2]
                        args[2] = (target.Position - origin).Unit * direction.Magnitude
                        args[3] = RaycastParams.new()
                        args[3].FilterType = Enum.RaycastFilterType.Exclude
                        args[3].FilterDescendantsInstances = {LocalPlayer.Character, Workspace.CurrentCamera}
                    elseif method:find("FindPartOnRay") then
                        local ray = args[1]
                        args[1] = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * ray.Direction.Magnitude)
                        args[2] = {LocalPlayer.Character, Workspace.CurrentCamera}
                    end
                end
            end
            return oldNamecall(self, table.unpack(args))
        end
        return oldNamecall(self, ...)
    end)
end)

RunService.RenderStepped:Connect(function(dt)
    if CONFIG.Aimbot and isAiming() then
        local target = getClosestTarget()
        if target then
            -- HARD LOCK (Instant Snap)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    if CONFIG.NoRecoil then
        local rot = Camera.CFrame - Camera.CFrame.Position
        local rx, ry, rz = rot:ToEulerAnglesXYZ()
        if not isAiming() then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, ry, 0)
        end
    end
end)

print("[MINEHUB] Hard-Lock Aimbot & Box ESP loaded. Hold [RMB] to aim.")