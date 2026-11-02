-- language: Lua (Luau), file: lootvision.lua
-- Standalone loot ESP. No loadstring dependencies.

if getgenv and getgenv().LV2 then
    pcall(function()
        for _, g in ipairs(game.CoreGui:GetChildren()) do
            if g.Name:find("LV2") then g:Destroy() end
        end
    end)
end
if getgenv then getgenv().LV2 = true end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer

local C = {
    bg = Color3.fromRGB(12, 14, 22),
    panel = Color3.fromRGB(20, 24, 36),
    panel2 = Color3.fromRGB(30, 36, 52),
    purple = Color3.fromRGB(150, 100, 255),
    cyan = Color3.fromRGB(0, 220, 255),
    green = Color3.fromRGB(80, 230, 130),
    gold = Color3.fromRGB(255, 200, 60),
    red = Color3.fromRGB(240, 70, 90),
    orange = Color3.fromRGB(255, 140, 40),
    text = Color3.fromRGB(230, 235, 245),
    muted = Color3.fromRGB(110, 120, 140),
    off = Color3.fromRGB(80, 88, 105),
}

local S = {
    enabled = false,
    players = false,
    maxDist = 1000,
    toggleKey = Enum.KeyCode.F1,
    uiKey = Enum.KeyCode.F2,
    uiVisible = true,
}

local CAT = {
    weapon = C.red,
    currency = C.gold,
    chest = C.orange,
    crate = C.purple,
    player = C.cyan,
    other = C.green,
}

local KEYWORDS = {
    crate = {"crate", "supply"},
    chest = {"chest", "box", "coffer"},
    currency = {"cash", "coin", "money", "gem"},
    weapon = {"gun", "rifle", "pistol", "shotgun", "smg", "sniper", "knife"},
    other = {"loot", "drop", "pickup", "item", "medkit", "ammo", "armor", "key", "card", "weapon", "tool"},
}

local function classify(name)
    local n = name:lower()
    for cat, words in pairs(KEYWORDS) do
        for _, k in ipairs(words) do
            if n:find(k) then return cat end
        end
    end
    return nil
end

local tracked = {}

local function remove(obj)
    local d = tracked[obj]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    tracked[obj] = nil
end

local function anchorOf(v)
    if v:IsA("BasePart") then return v end
    return v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
end

local function addESP(v, cat, isPlayer)
    if tracked[v] then return end
    local anchor = anchorOf(v)
    if not anchor then return end
    local col = isPlayer and CAT.player or (CAT[cat] or CAT.other)

    local hl = Instance.new("Highlight")
    hl.Adornee = v
    hl.FillColor = col
    hl.FillTransparency = 0.55
    hl.OutlineColor = col
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = v

    local bb = Instance.new("BillboardGui")
    bb.Adornee = anchor
    bb.Size = UDim2.new(0, 140, 0, 28)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = S.maxDist
    bb.Parent = anchor

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.6, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.Text = v.Name
    nameLbl.TextColor3 = col
    nameLbl.TextSize = 11
    nameLbl.TextStrokeTransparency = 0.4

    local distLbl = Instance.new("TextLabel", bb)
    distLbl.BackgroundTransparency = 1
    distLbl.Position = UDim2.new(0, 0, 0.6, 0)
    distLbl.Size = UDim2.new(1, 0, 0.4, 0)
    distLbl.Font = Enum.Font.Code
    distLbl.Text = "?"
    distLbl.TextColor3 = C.muted
    distLbl.TextSize = 9
    distLbl.TextStrokeTransparency = 0.5

    tracked[v] = { hl = hl, bb = bb, distLbl = distLbl, isPlayer = isPlayer }
end

-- Scan (GetChildren at 2 levels only, not GetDescendants - way faster)
local lastScan = 0
local scanCount = 0

local function scan()
    local now = tick()
    if now - lastScan < 1 then return end
    lastScan = now

    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local live = {}
    scanCount = 0

    local function check(v)
        if not v or not v.Parent then return end
        if v == LP.Character then return end
        if v.Parent == LP.Character then return end
        if Players:GetPlayerFromCharacter(v) then return end
        if v.Parent and v.Parent.Name == "Backpack" then return end

        if v:IsA("Model") or v:IsA("Tool") then
            local cat = classify(v.Name)
            if cat then
                local anchor = anchorOf(v)
                if anchor then
                    local d = (hrp.Position - anchor.Position).Magnitude
                    if d <= S.maxDist then
                        live[v] = true
                        scanCount = scanCount + 1
                        if not tracked[v] then addESP(v, cat, false) end
                    end
                end
            end
        end
    end

    -- Level 1
    for _, v in ipairs(WS:GetChildren()) do check(v) end
    -- Level 2
    for _, folder in ipairs(WS:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, v in ipairs(folder:GetChildren()) do check(v) end
        end
    end

    -- Players
    if S.players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d <= S.maxDist then
                        live[p.Character] = true
                        if not tracked[p.Character] then
                            addESP(p.Character, "player", true)
                        end
                    end
                end
            end
        end
    end

    -- Cleanup
    for obj, _ in pairs(tracked) do
        if not live[obj] or not obj.Parent then remove(obj) end
    end
end

-- Distance update
local lastFast = 0
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastFast < 0.15 then return end
    lastFast = now
    if not S.enabled then return end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for obj, d in pairs(tracked) do
        if obj.Parent and d.distLbl then
            local a = anchorOf(obj)
            if a then d.distLbl.Text = math.floor((hrp.Position - a.Position).Magnitude) .. "m" end
        end
    end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "LV2"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 300, 0, 320)
Main.Position = UDim2.new(0, 20, 0.5, -160)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", Main)
ms.Color = C.purple
ms.Thickness = 1.5

local Head = Instance.new("Frame", Main)
Head.Size = UDim2.new(1, 0, 0, 46)
Head.BackgroundColor3 = C.panel
Head.BorderSizePixel = 0
Instance.new("UICorner", Head).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Head)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 14, 0, 6)
Title.Size = UDim2.new(1, -60, 0, 18)
Title.Font = Enum.Font.GothamBold
Title.Text = "LOOT VISION"
Title.TextColor3 = C.purple
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", Head)
Sub.BackgroundTransparency = 1
Sub.Position = UDim2.new(0, 14, 0, 24)
Sub.Size = UDim2.new(1, -60, 0, 12)
Sub.Font = Enum.Font.GothamMedium
Sub.Text = "F1 enable  ·  F2 hide"
Sub.TextColor3 = C.muted
Sub.TextSize = 9
Sub.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Head)
CloseBtn.Position = UDim2.new(1, -32, 0, 10)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.BackgroundColor3 = C.panel2
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.red
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local Stat = Instance.new("TextLabel", Main)
Stat.BackgroundColor3 = C.panel
Stat.Position = UDim2.new(0, 0, 0, 46)
Stat.Size = UDim2.new(1, 0, 0, 22)
Stat.Font = Enum.Font.Code
Stat.Text = "  F1 to start"
Stat.TextColor3 = C.muted
Stat.TextSize = 10
Stat.TextXAlignment = Enum.TextXAlignment.Left
Stat.BorderSizePixel = 0

local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0, 0, 0, 68)
Content.Size = UDim2.new(1, 0, 1, -68)
Content.BackgroundTransparency = 1

local function toggleBtn(txt, key, y, cb)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(1, -24, 0, 32)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = C.panel2
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamSemibold
    b.Text = "  " .. txt
    b.TextColor3 = C.off
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    local function refresh()
        if S[key] then
            b.TextColor3 = C.green
        else
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

local function actionBtn(txt, y, cb, primary)
    local b = Instance.new("TextButton", Content)
    b.Size = UDim2.new(1, -24, 0, 32)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = primary and C.purple or C.panel2
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamSemibold
    b.Text = txt
    b.TextColor3 = C.text
    b.TextSize = 11
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
end

toggleBtn("Show Players", "players", 8)
actionBtn("DEBUG — print all object names", 48, function()
    print("=== DEBUG SCAN ===")
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("No character")
        return
    end
    local found = {}
    local function check(v)
        if not v or not v.Parent then return end
        if v == LP.Character or v.Parent == LP.Character then return end
        if Players:GetPlayerFromCharacter(v) then return end
        if v:IsA("Model") or v:IsA("Tool") then
            local anchor = anchorOf(v)
            if anchor then
                local d = math.floor((hrp.Position - anchor.Position).Magnitude)
                if d < 200 then
                    table.insert(found, {name = v.Name, dist = d, class = v.ClassName, matched = classify(v.Name) or "NO MATCH"})
                end
            end
        end
    end
    for _, v in ipairs(WS:GetChildren()) do check(v) end
    for _, f in ipairs(WS:GetChildren()) do
        if f:IsA("Folder") or f:IsA("Model") then
            for _, v in ipairs(f:GetChildren()) do check(v) end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    print("Objects within 200 studs:", #found)
    for i, f in ipairs(found) do
        if i > 40 then
            print("... and " .. (#found - 40) .. " more")
            break
        end
        print(i .. ". " .. f.name .. " [" .. f.class .. "] " .. f.dist .. "m — " .. f.matched)
    end
    print("=== END ===")
    Stat.Text = "  debug: " .. #found .. " objects (check console)"
end, true)

actionBtn("FORCE RESCAN", 88, function()
    for obj, _ in pairs(tracked) do remove(obj) end
    lastScan = 0
    Stat.Text = "  rescanning..."
end)

-- Distance slider
local lbl = Instance.new("TextLabel", Content)
lbl.BackgroundTransparency = 1
lbl.Position = UDim2.new(0, 12, 0, 130)
lbl.Size = UDim2.new(1, -24, 0, 14)
lbl.Font = Enum.Font.GothamMedium
lbl.Text = "Max Distance: " .. S.maxDist
lbl.TextColor3 = C.text
lbl.TextSize = 10
lbl.TextXAlignment = Enum.TextXAlignment.Left

local bar = Instance.new("Frame", Content)
bar.Position = UDim2.new(0, 12, 0, 148)
bar.Size = UDim2.new(1, -24, 0, 6)
bar.BackgroundColor3 = C.panel2
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame", bar)
fill.BackgroundColor3 = C.purple
fill.Size = UDim2.new((S.maxDist - 100) / (2000 - 100), 0, 1, 0)
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local drag = false
local function updateBar(i)
    local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
    local v = math.floor(100 + 1900 * rel)
    fill.Size = UDim2.new(rel, 0, 1, 0)
    lbl.Text = "Max Distance: " .. v
    S.maxDist = v
    for _, d in pairs(tracked) do
        if d.bb then d.bb.MaxDistance = v end
    end
end
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        updateBar(i)
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag then updateBar(i) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- Keybinds
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == S.toggleKey then
        S.enabled = not S.enabled
        if S.enabled then
            Stat.Text = "  scanning..."
            lastScan = 0
        else
            Stat.Text = "  disabled"
            for obj, _ in pairs(tracked) do remove(obj) end
        end
    elseif input.KeyCode == S.uiKey then
        S.uiVisible = not S.uiVisible
        Main.Visible = S.uiVisible
    end
end)

RunService.Heartbeat:Connect(function()
    if not S.enabled then return end
    pcall(scan)
end)

task.spawn(function()
    while task.wait(1) do
        if S.enabled then
            pcall(function()
                local n = 0
                for _ in pairs(tracked) do n = n + 1 end
                Stat.Text = "  tracking " .. n .. " · " .. scanCount .. " in range"
            end)
        end
    end
end)
