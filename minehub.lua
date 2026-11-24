-- ============================================================
-- MINEHUB  |  Bulletproof Edition (Fixed UI + Button)
-- ============================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local CoreGui       = game:GetService("CoreGui")
local LocalPlayer   = Players.LocalPlayer
local Camera        = Workspace.CurrentCamera

local CONFIG = {
    SilentAim  = true,
    ESP        = true,
    NoRecoil   = true,
    SmoothPOV  = true,
    FOV        = 150,
    Smoothness = 0.18,
    MaxSmooth  = 400,
    TeamCheck  = true,
    AimPart    = "Head",
    ESPColor   = Color3.fromRGB(255, 0, 150),
    Accent     = Color3.fromRGB(255, 0, 150), 
}

local function createMenu()
    local existing = CoreGui:FindFirstChild("MINEHUB")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MINEHUB"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    -- Main Container
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 260, 0, 210)
    main.Position = UDim2.new(0.5, -130, 0.5, -105)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Solid Dark Gray
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 8)
    
    -- Simple Pink Accent Line (No UIStroke)
    local accentLine = Instance.new("Frame", main)
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = CONFIG.Accent
    accentLine.BorderSizePixel = 0

    -- Title & Close Button
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
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = main
    local cCorner = Instance.new("UICorner", closeBtn)
    cCorner.CornerRadius = UDim.new(0, 4)
    
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    -- Tab Strip
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
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -70)
    content.Position = UDim2.new(0, 10, 0, 65)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = main

    local pages = {}
    local activeTab = nil

    local function newPage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = CONFIG.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content

        local list = Instance.new("UIListLayout", page)
        list.Padding = UDim.new(0, 6)
        list.SortOrder = Enum.SortOrder.LayoutOrder

        pages[name] = page
        return page
    end

    local function makeTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, -4, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        btn.AutoButtonColor = false
        btn.Parent = tabBar

        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 4)

        local page = newPage(name)

        btn.MouseButton1Click:Connect(function()
            if activeTab == name then return end
            activeTab = name
            for n, p in pairs(pages) do p.Visible = (n == name) end
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") then
                    local isActive = (child.Text == name)
                    TweenService:Create(child, TweenInfo.new(0.2), {
                        BackgroundColor3 = isActive and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(25, 25, 25),
                        TextColor3 = isActive and CONFIG.Accent or Color3.fromRGB(150, 150, 150),
                    }):Play()
                end
            end
        end)

        return page
    end

    local function makeToggle(parent, label, configKey)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.BorderSizePixel = 0
        row.Parent = parent
        local rCorner = Instance.new("UICorner", row)
        rCorner.CornerRadius = UDim.new(0, 6)

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
        knob.BorderSizePixel = 0
        knob.Parent = row
        local kCorner = Instance.new("UICorner", knob)
        kCorner.CornerRadius = UDim.new(1, 0)

        local pill = Instance.new("Frame", knob)
        pill.Size = UDim2.new(0, 10, 0, 10)
        pill.Position = CONFIG[configKey] and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        pill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pill.BorderSizePixel = 0
        local pCorner = Instance.new("UICorner", pill)
        pCorner.CornerRadius = UDim.new(1, 0)

        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.Parent = row

        click.MouseButton1Click:Connect(function()
            CONFIG[configKey] = not CONFIG[configKey]
            local on = CONFIG[configKey]
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                BackgroundColor3 = on and CONFIG.Accent or Color3.fromRGB(50, 50, 50),
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5),
            }):Play()
        end)
    end

    local function makeSlider(parent, label, configKey, min, max, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        row.BorderSizePixel = 0
        row.Parent = parent
        local rCorner = Instance.new("UICorner", row)
        rCorner.CornerRadius = UDim.new(0, 6)

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
        bar.BorderSizePixel = 0
        bar.Parent = row
        local bCorner = Instance.new("UICorner", bar)
        bCorner.CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", bar)
        fill.BackgroundColor3 = CONFIG.Accent
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((CONFIG[configKey] - min) / (max - min), 0, 1, 0)
        local fCorner = Instance.new("UICorner", fill)
        fCorner.CornerRadius = UDim.new(1, 0)

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
    makeToggle(aimPage, "Smooth POV", "SmoothPOV")
    makeSlider(aimPage, "FOV", "FOV", 20, 400, 5)
    makeSlider(aimPage, "Smoothness", "Smoothness", 0.01, 0.6, 0.01)

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

    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, 210),
    }):Play()

    -- INSERT KEYBIND
    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            gui.Enabled = not gui.Enabled
        end
    end)

    return gui
end

createMenu()

local espFolder = Instance.new("Folder")
espFolder.Name = "MINEHUB_ESP"
espFolder.Parent = CoreGui

local boxes = {}
local function makeBox(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if boxes[player] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(4, 5.5, 2)
    box.Color3 = CONFIG.ESPColor
    box.Transparency = 0.55
    box.Parent = espFolder
    boxes[player] = box
end

local function removeBox(p)
    if boxes[p] then boxes[p]:Destroy(); boxes[p] = nil end
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if CONFIG.ESP then
                if not boxes[p] then
                    p.CharacterAdded:Connect(function() task.wait(0.5); if CONFIG.ESP then makeBox(p) end end)
                    makeBox(p)
                end
            else removeBox(p) end
        end
    end
end
refreshESP()
task.spawn(function() while task.wait(1) do refreshESP() end end)
Players.PlayerRemoving:Connect(removeBox)

local function getTarget()
    local best, bestDist = nil, CONFIG.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if CONFIG.TeamCheck and p.Team == LocalPlayer.Team then continue end
        local char = p.Character
        if not char then continue end
        local part = char:FindFirstChild(CONFIG.AimPart)
        if not part then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local center = Camera.ViewportSize / 2
        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist then best, bestDist = part, dist end
    end
    return best
end

local mouse = LocalPlayer:GetMouse()
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if CONFIG.SilentAim and self == mouse and (key == "Hit" or key == "Target") then
        local t = getTarget()
        if t then return t.Position end
    end
    return oldIndex(self, key)
end)

RunService:BindToRenderStep("MINEHUB_SmoothPOV", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not CONFIG.SmoothPOV then return end
    local t = getTarget()
    if not t then return end
    local sp = Camera:WorldToViewportPoint(t.Position)
    local center = Camera.ViewportSize / 2
    if (Vector2.new(sp.X, sp.Y) - center).Magnitude > CONFIG.MaxSmooth then return end
    local desired = CFrame.new(Camera.CFrame.Position, t.Position)
    local alpha = math.clamp(1 - math.exp(-CONFIG.Smoothness * 60 * dt), 0, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
end)

RunService:BindToRenderStep("MINEHUB_NoRecoil", Enum.RenderPriority.Camera.Value + 2, function()
    if not CONFIG.NoRecoil then return end
    local rot = Camera.CFrame - Camera.CFrame.Position
    Camera.CFrame = CFrame.new(Camera.CFrame.Position) * rot
end)

print("[MINEHUB] Bulletproof UI loaded. Press INSERT to toggle.")