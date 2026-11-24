-- ============================================================
-- MINEHUB  |  Ultimate Edition (Fixed ESP Boxes)
-- ============================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local UserInput     = game:GetService("UserInputService")
local CoreGui       = game:GetService("CoreGui")
local LocalPlayer   = Players.LocalPlayer
local Camera        = Workspace.CurrentCamera

local CONFIG = {
    SilentAim  = true,
    Aimbot     = true,
    ESP        = true,
    NoRecoil   = true,
    AimKey     = Enum.KeyCode.K,
    FOV        = 150,
    Smoothness = 0.25, 
    MaxDist    = 500, 
    TeamCheck  = true,
    AimPart    = "Head",
    Accent     = Color3.fromRGB(255, 0, 150), 
}

-- ============================================================
-- DRAWING API ESP (Fixed Box Math)
-- ============================================================
local espTable = {}

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if CONFIG.TeamCheck and player.Team == LocalPlayer.Team then return false end
    return true
end

local function createESP(player)
    if not isEnemy(player) or espTable[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = CONFIG.Accent
    box.Filled = false
    box.Visible = false

    espTable[player] = {Box = box}
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() createESP(p) end)
    createESP(p)
end)
Players.PlayerRemoving:Connect(function(p)
    if espTable[p] then
        espTable[p].Box:Remove()
        espTable[p] = nil
    end
end)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = CONFIG.Accent
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    -- ESP Update
    for player, esp in pairs(espTable) do
        if not CONFIG.ESP or not player.Character then
            esp.Box.Visible = false
            continue
        end

        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if hrp and head and hum and hum.Health > 0 then
            -- Calculate 3D bounding box corners to screen space
            local hrpPos = hrp.Position
            local topPos = head.Position + Vector3.new(0, 0.5, 0)
            local bottomPos = hrpPos - Vector3.new(0, 2.5, 0)

            local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
            local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

            if topOnScreen and bottomOnScreen then
                local height = math.abs(bottomScreen.Y - topScreen.Y)
                local width = height / 1.8 -- Ratio of humanoid height to width

                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Position = Vector2.new(topScreen.X - width/2, topScreen.Y)
                esp.Box.Visible = true
            else
                esp.Box.Visible = false
            end
        else
            esp.Box.Visible = false
        end
    end

    -- FOV Circle Update
    fovCircle.Position = Camera.ViewportSize / 2
    fovCircle.Radius = CONFIG.FOV
    fovCircle.Visible = CONFIG.Aimbot or CONFIG.SilentAim
end)

-- ============================================================
-- UI MENU
-- ============================================================
local function createMenu()
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

    local tabList = Instance.new("UIListLayout", tabBar)
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.Padding = UDim.new(0, 5)

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
        page.ScrollBarImageColor3 = CONFIG.Accent
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content
        local list = Instance.new("UIListLayout", page)
        list.Padding = UDim.new(0, 6)
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
            pill.Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        end)
    end

    local function makeSlider(parent, label, configKey, min, max, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local labelObj = Instance.new("TextLabel")
        labelObj.Size = UDim2.new(1, -20, 0, 16)
        labelObj.Position = UDim2.new(0, 10, 0, 4)
        labelObj.BackgroundTransparency = 1
        labelObj.Text = label .. ": " .. tostring(CONFIG[configKey])
        labelObj.Font = Enum.Font.Gotham
        labelObj.TextSize = 11
        labelObj.TextColor3 = Color3.fromRGB(200, 200, 200)
        labelObj.TextXAlignment = Enum.TextXAlignment.Left
        labelObj.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 3)
        bar.Position = UDim2.new(0, 10, 0, 26)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", bar)
        fill.BackgroundColor3 = CONFIG.Accent
        fill.Size = UDim2.new((CONFIG[configKey] - min) / (max - min), 0, 1, 0)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 4, 0)
        hit.Position = UDim2.new(0, 0, 0.5, -2)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Parent = bar

        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * rel
            val = math.floor(val / step + 0.5) * step
            CONFIG[configKey] = val
            labelObj.Text = label .. ": " .. tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
        end

        hit.MouseButton1Down:Connect(function() dragging = true; setFromX(UserInput:GetMouseLocation().X) end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
        end)
        UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    local aimPage = makeTab("Aim")
    makeToggle(aimPage, "Silent Aim", "SilentAim")
    makeToggle(aimPage, "Camera Aimbot", "Aimbot")
    makeSlider(aimPage, "FOV", "FOV", 50, 500, 10)
    makeSlider(aimPage, "Smoothness", "Smoothness", 0.05, 0.8, 0.05)

    local visPage = makeTab("Visual")
    makeToggle(visPage, "ESP", "ESP")

    local miscPage = makeTab("Misc")
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
end
createMenu()

-- ============================================================
-- TARGET & SILENT AIM HOOK
-- ============================================================
local function getClosestTarget()
    local best, bestDist = nil, CONFIG.FOV
    local center = Camera.ViewportSize / 2

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if CONFIG.TeamCheck and p.Team == LocalPlayer.Team then continue end
        
        local char = p.Character
        if not char then continue end
        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if dist < bestDist then 
                best, bestDist = part, dist 
            end
        end
    end
    return best
end

local mouse = LocalPlayer:GetMouse()
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if CONFIG.SilentAim and self == mouse and (key == "Hit" or key == "Target") then
        local t = getClosestTarget()
        if t then return t.Position end
    end
    return oldIndex(self, key)
end)

-- ============================================================
-- RENDER STEP (Aimbot & No Recoil)
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    -- 1. Camera Aimbot Locking (Hold K)
    if CONFIG.Aimbot and UserInput:IsKeyDown(CONFIG.AimKey) then
        local target = getClosestTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local desired = CFrame.new(camPos, target.Position)
            local alpha = math.clamp(1 - math.exp(-CONFIG.Smoothness * 60 * dt), 0, 1)
            Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
        end
    end

    -- 2. No Recoil (Strips pitch kick)
    if CONFIG.NoRecoil then
        local rot = Camera.CFrame - Camera.CFrame.Position
        local rx, ry, rz = rot:ToEulerAnglesXYZ()
        if not UserInput:IsKeyDown(CONFIG.AimKey) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, ry, 0)
        end
    end
end)

print("[MINEHUB] Fixed Boxes loaded. Hold [K] to aim, [RightShift] to toggle menu.")