-- language: Lua (Luau), file: bound_esp.lua
-- Combined loader: ESP Pro (1cheli.lua) + Loot Vision with keybinds

-- Load the original ESP Pro first
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/redjo3n/main.lua/main/1cheli.lua"))()
end)

task.wait(1.5)

-- Now add Loot Vision on top
if getgenv and getgenv().RJ_LootBound then
    pcall(function()
        for _, g in ipairs(game.CoreGui:GetChildren()) do
            if g.Name:find("RJ_Loot") then g:Destroy() end
        end
    end)
end
if getgenv then getgenv().RJ_LootBound = true end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")

local LP = Players.LocalPlayer

local C = {
    bg      = Color3.fromRGB(12, 14, 22),
    panel   = Color3.fromRGB(20, 24, 36),
    panel2  = Color3.fromRGB(30, 36, 52),
    purple  = Color3.fromRGB(150, 100, 255),
    cyan    = Color3.fromRGB(0, 220, 255),
    green   = Color3.fromRGB(80, 230, 130),
    gold    = Color3.fromRGB(255, 200, 60),
    red     = Color3.fromRGB(240, 70, 90),
    orange  = Color3.fromRGB(255, 140, 40),
    text    = Color3.fromRGB(230, 235, 245),
    muted   = Color3.fromRGB(110, 120, 140),
    off     = Color3.fromRGB(80, 88, 105),
}
local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local FS = Enum.Font.GothamSemibold
local FC = Enum.Font.Code

local S = {
    enabled      = false,
    lootVisible  = true,
    playersVisible = false,
    showDistance = true,
    showName     = true,
    maxDist      = 1500,
    fillTrans    = 0.6,
    scanInterval = 0.7,
    toggleKey    = Enum.KeyCode.F1,
    uiKey        = Enum.KeyCode.F2,
    uiVisible    = true,
}

local CAT = {
    weapon  = C.red,
    currency= C.gold,
    chest   = C.orange,
    loot    = C.green,
    crate   = C.purple,
    player  = C.cyan,
    other   = Color3.fromRGB(180, 180, 200),
}

local PATTERNS = {
    { keywords = {"crate", "supply"},              cat = "crate" },
    { keywords = {"chest", "box", "coffer"},       cat = "chest" },
    { keywords = {"cash", "coin", "money", "gem"}, cat = "currency" },
    { keywords = {"gun", "rifle", "pistol", "ak", "m4", "shotgun", "smg", "sniper"}, cat = "weapon" },
    { keywords = {"medkit", "bandage", "health", "heal"}, cat = "loot" },
    { keywords = {"ammo", "mag", "bullet"},        cat = "loot" },
    { keywords = {"armor", "vest", "helmet"},      cat = "loot" },
    { keywords = {"loot", "drop", "pickup", "item", "tool"}, cat = "loot" },
    { keywords = {"key", "card"},                  cat = "loot" },
}

local function categorise(name)
    local n = name:lower()
    for _, p in ipairs(PATTERNS) do
        for _, k in ipairs(p.keywords) do
            if n:find(k) then return p.cat end
        end
    end
    return nil
end

local function isLootModel(v)
    if not v then return false end
    if not (v:IsA("Model") or v:IsA("BasePart") or v:IsA("Tool")) then return false end
    if v == LP.Character then return false end
    if Players:GetPlayerFromCharacter(v) then return false end
    if v.Parent == LP.Character then return false end
    if v.Parent and v.Parent.Name == "Backpack" then return false end
    return categorise(v.Name) ~= nil
end

local tracked = {}

local function remove(object)
    local d = tracked[object]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    tracked[object] = nil
end

local function getAnchor(v)
    if v:IsA("BasePart") then return v end
    return v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
end

local function createESP(v, cat, isPlayer)
    if tracked[v] then return end
    local anchor = getAnchor(v)
    if not anchor then return end

    local colour = isPlayer and CAT.player or (CAT[cat] or CAT.other)

    local hl = Instance.new("Highlight")
    hl.Adornee = v
    hl.FillColor = colour
    hl.FillTransparency = S.fillTrans
    hl.OutlineColor = colour
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = v

    local bb = Instance.new("BillboardGui")
    bb.Adornee = anchor
    bb.Size = UDim2.new(0, 160, 0, 32)
    bb.StudsOffset = Vector3.new(0, 2.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = S.maxDist
    bb.Parent = anchor

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
    nameLbl.Font = FB
    nameLbl.Text = v.Name
    nameLbl.TextColor3 = colour
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.Visible = S.showName

    local distLbl = Instance.new("TextLabel", bb)
    distLbl.BackgroundTransparency = 1
    distLbl.Position = UDim2.new(0, 0, 0.55, 0)
    distLbl.Size = UDim2.new(1, 0, 0.45, 0)
    distLbl.Font = FC
    distLbl.Text = "?"
    distLbl.TextColor3 = C.muted
    distLbl.TextSize = 10
    distLbl.TextStrokeTransparency = 0.4
    distLbl.Visible = S.showDistance

    tracked[v] = {
        hl = hl,
        bb = bb,
        distLbl = distLbl,
        nameLbl = nameLbl,
        cat = cat,
        isPlayer = isPlayer,
    }
end

local lastScan = 0
local function scan()
    local now = tick()
    if now - lastScan < S.scanInterval then return end
    lastScan = now

    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local live = {}

    if S.lootVisible then
        for _, v in ipairs(WS:GetDescendants()) do
            if isLootModel(v) then
                local cat = categorise(v.Name)
                if cat then
                    local anchor = getAnchor(v)
                    if anchor then
                        local d = (hrp.Position - anchor.Position).Magnitude
                        if d <= S.maxDist then
                            live[v] = true
                            if not tracked[v] then
                                createESP(v, cat, false)
                            end
                        end
                    end
                end
            end
        end
    end

    if S.playersVisible then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d <= S.maxDist then
                        live[p.Character] = true
                        if not tracked[p.Character] then
                            createESP(p.Character, "player", true)
                        end
                    end
                end
            end
        end
    end

    for object, _ in pairs(tracked) do
        if not live[object] or not object.Parent then
            remove(object)
        end
    end
end

local lastFast = 0
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastFast < 0.1 then return end
    lastFast = now
    if not S.enabled then return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for object, d in pairs(tracked) do
        if object.Parent and d.distLbl then
            local anchor = getAnchor(object)
            if anchor then
                d.distLbl.Text = math.floor((hrp.Position - anchor.Position).Magnitude) .. "m"
            end
        end
    end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RJ_LootBound"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 320, 0, 380)
Main.Position = UDim2.new(0, 20, 0.5, -190)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", Main)
ms.Color = C.purple
ms.Thickness = 1.5
ms.Transparency = 0.2

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = C.panel
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 14, 0, 8)
Title.Size = UDim2.new(1, -60, 0, 18)
Title.Font = FB
Title.Text = "LOOT VISION"
Title.TextColor3 = C.purple
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", Header)
Sub.BackgroundTransparency = 1
Sub.Position = UDim2.new(0, 14, 0, 26)
Sub.Size = UDim2.new(1, -60, 0, 12)
Sub.Font = FM
Sub.Text = "F1 toggle · F2 hide"
Sub.TextColor3 = C.muted
Sub.TextSize = 9
Sub.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Position = UDim2.new(1, -32, 0, 12)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.BackgroundColor3 = C.panel2
CloseBtn.Font = FB
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.red
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local Stat = Instance.new("TextLabel", Main)
Stat.BackgroundColor3 = C.panel
Stat.Position = UDim2.new(0, 0, 0, 50)
Stat.Size = UDim2.new(1, 0, 0, 22)
Stat.Font = FC
Stat.Text = "  F1 to enable"
Stat.TextColor3 = C.muted
Stat.TextSize = 10
Stat.TextXAlignment = Enum.TextXAlignment.Left
Stat.BorderSizePixel = 0

local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0, 0, 0, 72)
Content.Size = UDim2.new(1, 0, 1, -72)
Content.BackgroundTransparency = 1

local function section(txt, y)
    local l = Instance.new("TextLabel", Content)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 12, 0, y)
    l.Size = UDim2.new(1, -24, 0, 16)
    l.Font = FB
    l.Text = "▸ " .. txt:upper()
    l.TextColor3 = C.cyan
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function toggle(txt, key, y, cb)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(1, -24, 0, 30)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = C.panel2
    b.BorderSizePixel = 0
    b.Font = FS
    b.Text = "  " .. txt
    b.TextColor3 = C.off
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Color = C.purple
    s.Transparency = 0.8

    local ind = Instance.new("Frame", b)
    ind.Position = UDim2.new(1, -42, 0.5, -7)
    ind.Size = UDim2.new(0, 30, 0, 14)
    ind.BackgroundColor3 = C.off
    ind.BorderSizePixel = 0
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", ind)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = C.text
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        if S[key] then
            ind.BackgroundColor3 = C.green
            knob.Position = UDim2.new(1, -12, 0.5, -5)
            b.TextColor3 = C.text
        else
            ind.BackgroundColor3 = C.off
            knob.Position = UDim2.new(0, 2, 0.5, -5)
            b.TextColor3 = C.off
        end
    end
    refresh()

    b.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        refresh()
        if cb then pcall(cb, S[key]) end
    end)
end

section("What To Show", 6)
toggle("Loot Items", "lootVisible", 24, function()
    for obj, d in pairs(tracked) do
        if not d.isPlayer then remove(obj) end
    end
    lastScan = 0
end)
toggle("Players", "playersVisible", 58, function()
    for obj, d in pairs(tracked) do
        if d.isPlayer then remove(obj) end
    end
    lastScan = 0
end)
toggle("Show Name", "showName", 92, function(v)
    for _, d in pairs(tracked) do
        if d.nameLbl then d.nameLbl.Visible = v end
    end
end)
toggle("Show Distance", "showDistance", 126, function(v)
    for _, d in pairs(tracked) do
        if d.distLbl then d.distLbl.Visible = v end
    end
end)

-- Max distance slider
local lbl = Instance.new("TextLabel", Content)
lbl.BackgroundTransparency = 1
lbl.Position = UDim2.new(0, 12, 0, 166)
lbl.Size = UDim2.new(1, -24, 0, 14)
lbl.Font = FM
lbl.Text = "Max Distance: " .. S.maxDist
lbl.TextColor3 = C.text
lbl.TextSize = 10
lbl.TextXAlignment = Enum.TextXAlignment.Left

local bar = Instance.new("Frame", Content)
bar.Position = UDim2.new(0, 12, 0, 184)
bar.Size = UDim2.new(1, -24, 0, 6)
bar.BackgroundColor3 = C.panel2
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame", bar)
fill.BackgroundColor3 = C.purple
fill.Size = UDim2.new((S.maxDist - 100) / (3000 - 100), 0, 1, 0)
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local drag = false
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(100 + 2900 * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = "Max Distance: " .. v
        S.maxDist = v
        for _, d in pairs(tracked) do
            if d.bb then d.bb.MaxDistance = v end
        end
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag then
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(100 + 2900 * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = "Max Distance: " .. v
        S.maxDist = v
        for _, d in pairs(tracked) do
            if d.bb then d.bb.MaxDistance = v end
        end
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- Keybind handlers
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == S.toggleKey then
        S.enabled = not S.enabled
        if S.enabled then
            Stat.Text = "  scanning..."
            lastScan = 0
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Loot Vision",
                    Text = "ENABLED",
                    Duration = 2,
                })
            end)
        else
            Stat.Text = "  disabled"
            for obj, _ in pairs(tracked) do remove(obj) end
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Loot Vision",
                    Text = "DISABLED",
                    Duration = 2,
                })
            end)
        end
    elseif input.KeyCode == S.uiKey then
        S.uiVisible = not S.uiVisible
        Main.Visible = S.uiVisible
    end
end)

-- Main scan loop
RunService.Heartbeat:Connect(function()
    if not S.enabled then return end
    pcall(scan)
end)

-- Status
task.spawn(function()
    while task.wait(1) do
        if S.enabled then
            pcall(function()
                local n = 0
                for _ in pairs(tracked) do n = n + 1 end
                Stat.Text = "  tracking " .. n .. " objects  ·  range " .. S.maxDist
            end)
        end
    end
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(p)
    if p.Character then remove(p.Character) end
end)
