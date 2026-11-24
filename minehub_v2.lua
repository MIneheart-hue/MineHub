--[[ MINEHUB :: V2 (Menu Framework) ]]
print("[MINEHUB V2] Menu loaded. Type ;menu to open.")

local Players    = game:GetService("Players")
local UserInput  = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

local CONFIG = {
    Accent = Color3.fromRGB(255, 0, 150),
}

-- ============================================================
-- MENU FRAMEWORK
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

    -- Create Tabs
    makeTab("Aim")
    makeTab("Visuals")
    makeTab("Misc")
    makeTab("Config")

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