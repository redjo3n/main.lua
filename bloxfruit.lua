-- language: Lua (Luau), file: redj03n_scanner_min.lua
-- Minimal · ~180 lines · no highlights, no tweens, no extra loops.

if getgenv and getgenv().RJ_FS then
    pcall(function()
        local g = game.CoreGui:FindFirstChild("RJ_FS")
        if g then g:Destroy() end
    end)
end
if getgenv then getgenv().RJ_FS = true end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera

local C = {
    bg = Color3.fromRGB(14, 10, 20),
    panel = Color3.fromRGB(24, 18, 34),
    panel2 = Color3.fromRGB(36, 28, 48),
    accent = Color3.fromRGB(220, 30, 60),
    accent2 = Color3.fromRGB(0, 220, 255),
    text = Color3.fromRGB(240, 235, 245),
    muted = Color3.fromRGB(140, 130, 155),
    on = Color3.fromRGB(0, 240, 160),
    off = Color3.fromRGB(160, 150, 180),
    gold = Color3.fromRGB(255, 200, 60),
}

local FRUITS = {
    "Dragon", "Leopard", "Kitsune", "Venom", "Dough", "Mammoth", "T-Rex",
    "Spirit", "Control", "Shadow", "Gravity", "Buddha", "Blizzard", "Portal",
    "Phoenix", "Rumble", "Paw", "Magma", "Quake", "Light", "Ice", "Sand",
    "Dark", "Diamond", "Barrier", "Rocket", "Spin", "Chop", "Spring", "Bomb",
    "Smoke", "Spike", "Flame", "Falcon", "Rubber", "Love", "Spider", "Sound",
    "Creation", "Revive", "Gas", "Yeti", "Pain",
}

local F = { travel = false, hop = false, highOnly = false }
local Cache = { fruits = {}, last = 0 }
local moveTo = nil
local travelTween = nil

local function char()
    local c = LP.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function fruitMatch(name)
    for _, f in ipairs(FRUITS) do
        if name:find(f) then return f end
    end
    return nil
end

local function isHigh(name)
    local high = {"Dragon","Leopard","Kitsune","Venom","Dough","Mammoth","T-Rex","Spirit","Control","Shadow","Gravity","Buddha","Blizzard","Portal","Phoenix","Rumble","Paw"}
    for _, h in ipairs(high) do
        if name:find(h) then return true end
    end
    return false
end

local function scan()
    local now = tick()
    if now - Cache.last < 1 then return end
    Cache.last = now
    local list = {}
    local function check(v)
        if not v or not v:IsA("Model") then return end
        if not fruitMatch(v.Name) then return end
        local h = v:FindFirstChild("Handle")
        if h and h:IsA("BasePart") then
            table.insert(list, {
                name = v.Name,
                pos = h.Position,
                high = isHigh(v.Name),
                model = v,
            })
        end
    end
    for _, v in ipairs(WS:GetChildren()) do check(v) end
    local ff = WS:FindFirstChild("Fruits")
    if ff then
        for _, v in ipairs(ff:GetChildren()) do check(v) end
    end
    Cache.fruits = list
end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "RJ_FS"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 420, 0, 380)
Main.Position = UDim2.new(0.5, -210, 0.5, -190)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = C.accent
Main:FindFirstChildOfClass("UIStroke").Thickness = 2

local Head = Instance.new("Frame", Main)
Head.Size = UDim2.new(1, 0, 0, 40)
Head.BackgroundColor3 = C.panel
Head.BorderSizePixel = 0
Instance.new("UICorner", Head).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Head)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 14, 0, 4)
Title.Size = UDim2.new(1, -60, 0, 16)
Title.Font = Enum.Font.GothamBold
Title.Text = "REDJ03N · FRUIT SCANNER"
Title.TextColor3 = C.accent
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", Head)
Sub.BackgroundTransparency = 1
Sub.Position = UDim2.new(0, 14, 0, 20)
Sub.Size = UDim2.new(1, -60, 0, 14)
Sub.Font = Enum.Font.GothamMedium
Sub.Text = "minimal · safe"
Sub.TextColor3 = C.muted
Sub.TextSize = 9
Sub.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Head)
CloseBtn.Position = UDim2.new(1, -32, 0, 8)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.BackgroundColor3 = C.panel2
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.accent
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local Stat = Instance.new("TextLabel", Main)
Stat.BackgroundColor3 = C.panel
Stat.Position = UDim2.new(0, 0, 0, 40)
Stat.Size = UDim2.new(1, 0, 0, 22)
Stat.Font = Enum.Font.Code
Stat.Text = "  scanning..."
Stat.TextColor3 = C.muted
Stat.TextSize = 10
Stat.TextXAlignment = Enum.TextXAlignment.Left
Stat.BorderSizePixel = 0

-- Fruit list panel
local ListFrame = Instance.new("ScrollingFrame", Main)
ListFrame.Position = UDim2.new(0, 10, 0, 70)
ListFrame.Size = UDim2.new(1, -20, 0, 180)
ListFrame.BackgroundColor3 = C.panel
ListFrame.BorderSizePixel = 0
ListFrame.ScrollBarThickness = 4
ListFrame.ScrollBarImageColor3 = C.accent
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)
local ll = Instance.new("UIListLayout", ListFrame)
ll.Padding = UDim.new(0, 2)
ll.SortOrder = Enum.SortOrder.LayoutOrder

local fruitLabels = {}

local function refreshList()
    for _, lbl in ipairs(fruitLabels) do lbl:Destroy() end
    fruitLabels = {}
    if #Cache.fruits == 0 then
        local empty = Instance.new("TextLabel", ListFrame)
        empty.BackgroundTransparency = 1
        empty.Size = UDim2.new(1, 0, 0, 24)
        empty.Font = Enum.Font.GothamMedium
        empty.Text = "  No fruits in this server"
        empty.TextColor3 = C.muted
        empty.TextSize = 11
        empty.TextXAlignment = Enum.TextXAlignment.Left
        table.insert(fruitLabels, empty)
        return
    end
    for i, f in ipairs(Cache.fruits) do
        local lbl = Instance.new("TextButton", ListFrame)
        lbl.BackgroundColor3 = C.panel2
        lbl.Size = UDim2.new(1, -4, 0, 26)
        lbl.Font = Enum.Font.GothamSemibold
        lbl.Text = "  " .. f.name .. (f.high and "  ★" or "")
        lbl.TextColor3 = f.high and C.gold or C.text
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.AutoButtonColor = false
        lbl.BorderSizePixel = 0
        lbl.LayoutOrder = i
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
        lbl.MouseButton1Click:Connect(function()
            moveTo = f.pos
        end)
        table.insert(fruitLabels, lbl)
    end
end

-- Buttons
local function mkToggle(parent, txt, key, yPos)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, yPos)
    b.BackgroundColor3 = C.panel2
    b.Font = Enum.Font.GothamMedium
    b.Text = "  " .. txt .. "  · OFF"
    b.TextColor3 = C.off
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        F[key] = not F[key]
        if F[key] then
            b.Text = "  " .. txt .. "  · ON"
            b.TextColor3 = C.on
        else
            b.Text = "  " .. txt .. "  · OFF"
            b.TextColor3 = C.off
        end
    end)
    return b
end

local function mkButton(parent, txt, yPos, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -20, 0, 28)
    b.Position = UDim2.new(0, 10, 0, yPos)
    b.BackgroundColor3 = C.panel2
    b.Font = Enum.Font.GothamMedium
    b.Text = "  " .. txt
    b.TextColor3 = C.text
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

mkToggle(Main, "Auto Travel to Fruit", "travel", 258)
mkToggle(Main, "Auto Server Hop (empty)", "hop", 290)
mkToggle(Main, "Only High Value", "highOnly", 322)

mkButton(Main, "Refresh Scan", 354, function()
    Cache.last = 0
    scan()
    refreshList()
    Stat.Text = "  refreshed · " .. #Cache.fruits .. " fruits"
end)

-- ============================================================
-- HOP
-- ============================================================
local function hop()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
    end)
    if not ok or not res or not res.data then return false end
    local servers = {}
    for _, s in ipairs(res.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            table.insert(servers, s.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], LP)
        return true
    end
    return false
end

-- ============================================================
-- LOOPS — single render loop
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- travel
    if F.travel and #Cache.fruits > 0 then
        local _, hrp = char()
        if hrp then
            local best, bd = nil, math.huge
            for _, f in ipairs(Cache.fruits) do
                if F.highOnly and not f.high then continue end
                local d = (hrp.Position - f.pos).Magnitude
                if d < bd then best, bd = f, d end
            end
            if best and bd > 6 then
                pcall(function()
                    hrp.CFrame = CFrame.new(hrp.Position + (best.pos - hrp.Position).Unit * 5)
                end)
            end
        end
    end

    -- manual click travel
    if moveTo then
        local _, hrp = char()
        if not hrp then moveTo = nil return end
        local dir = moveTo - hrp.Position
        local d = dir.Magnitude
        if d < 5 then moveTo = nil return end
        pcall(function()
            hrp.CFrame = CFrame.new(hrp.Position + dir.Unit * math.min(5, d))
        end)
    end
end)

-- scan loop — 1 second, pcall
task.spawn(function()
    while task.wait(1) do
        pcall(scan)
        pcall(refreshList)
    end
end)

-- hop loop — every 2 seconds
task.spawn(function()
    while task.wait(2) do
        if F.hop then
            local count = 0
            for _, f in ipairs(Cache.fruits) do
                if not F.highOnly or f.high then count = count + 1 end
            end
            if count == 0 then
                pcall(hop)
                task.wait(6)
            end
        end
    end
end)

-- status loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local high = 0
            for _, f in ipairs(Cache.fruits) do
                if f.high then high = high + 1 end
            end
            local act = "idle"
            if F.hop then act = "hopping"
            elseif F.travel then act = "traveling"
            end
            Stat.Text = "  [" .. act .. "]  ·  " .. #Cache.fruits .. " fruits  ·  " .. high .. " high-value"
        end)
    end
end)

-- initial scan
task.wait(0.5)
pcall(scan)
pcall(refreshList)
