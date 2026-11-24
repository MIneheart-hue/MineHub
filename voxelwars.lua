--[[ MINEHUB :: VOXEL WARS ]]
print("[MINEHUB] VoxelWars build loaded.")

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local UserInput  = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer
local Cam        = Workspace.CurrentCamera

local CONFIG = {
    Aimbot       = true,
    SilentAim    = true,
    MagicBullet  = true,
    BoxESP       = true,
    SkeletonESP  = true,
    Wallbang     = true,
    NoRecoil     = true,
    LongRange    = true,
    AimKey       = Enum.UserInputType.MouseButton2,
    AimPart      = "Head",
    FOV          = 250,
    TeamCheck    = true,
    Accent       = Color3.fromRGB(255, 0, 150),
    EnemyColor   = Color3.fromRGB(255, 40, 40),
    TeamColor    = Color3.fromRGB(0, 150, 255),
    SkelColor    = Color3.fromRGB(255, 255, 255),
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
    fov.Visible = CONFIG.Aimbot or CONFIG.SilentAim
end)

-- ============================================================
-- TARGETING
-- ============================================================
local function isAiming()
    return UserInput:IsMouseButtonPressed(CONFIG.AimKey)
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
-- AIMBOT (hard lock camera)
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
-- SILENT AIM + MAGIC BULLET + WALLBANG
-- ============================================================
local ok, err = pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if checkcaller() then
            return oldNamecall(self, ...)
        end

        if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            if CONFIG.MagicBullet then
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
            if CONFIG.Wallbang and method == "Raycast" and args[3] then
                args[3].IgnoreWater = true
                args[3].CollisionGroup = "Default"
                args[3].FilterDescendantsInstances = {LP.Character, Cam}
                args[3].FilterType = Enum.RaycastFilterType.Exclude
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
if not ok then warn("[MINEHUB] namecall hook failed: "..tostring(err)) end

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
-- NO RECOIL (lerp)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not CONFIG.NoRecoil then return end
    if isAiming() then return end
    local rot = Cam.CFrame - Cam.CFrame.Position
    local _, ry, _ = rot:ToEulerAnglesXYZ()
    local target = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, ry, 0)
    Cam.CFrame = Cam.CFrame:Lerp(target, 0.12)
end)

-- ============================================================
-- ESP — BOX + SKELETON
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
        l.Color = CONFIG.SkelColor
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

    local isTeam = (p.Team == LP.Team)
    local col = isTeam and CONFIG.TeamColor or CONFIG.EnemyColor

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "MINEHUB_BOX"
    box.Adornee = hrp
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = col
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
        else
            box.Visible = false
        end
    end
    for p, _ in pairs(skels) do updateSkeleton(p) end
end)

print("[MINEHUB] All systems live.")
print("[MINEHUB] Hold RMB to lock. Have fun, Kanha.")