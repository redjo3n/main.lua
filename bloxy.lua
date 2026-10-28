-- language: Lua (Luau), file: redj03n_fruit_v2.lua
-- RedJ03N · Fruit Scanner v2 — premium GUI

if getgenv and getgenv().RJFS2 then
    pcall(function()
        local g = game.CoreGui:FindFirstChild("RJFS2")
        if g then g:Destroy() end
    end)
end
if getgenv then getgenv().RJFS2 = true end

pcall(function()
    local q = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if q then
        q('loadstring(game:HttpGet("https://raw.githubusercontent.com/redjo3n/main.lua/main/bloxfruit.lua"))()')
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local HS = game:GetService("HttpService")
local TS = game:GetService("TeleportService")
local TW = game:GetService("TweenService")
local SG = game:GetService("StarterGui")

local LP = Players.LocalPlayer

local C = {
    bg       = Color3.fromRGB(10, 14, 26),
    panel    = Color3.fromRGB(19, 24, 36),
    panel2   = Color3.fromRGB(28, 34, 51),
    panel3   = Color3.fromRGB(38, 46, 68),
    purple   = Color3.fromRGB(123, 94, 255),
    cyan     = Color3.fromRGB(0, 229, 204),
    gold     = Color3.fromRGB(255, 209, 102),
    text     = Color3.fromRGB(232, 237, 245),
    muted    = Color3.fromRGB(107, 114, 128),
    green    = Color3.fromRGB(16, 185, 129),
    red      = Color3.fromRGB(239, 68, 68),
    off      = Color3.fromRGB(100, 110, 130),
}
local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local FS = Enum.Font.GothamSemibold
local FC = Enum.Font.Code

local TIERS = {
    [5] = {"Dragon","Leopard","Kitsune","Venom","Dough","Mammoth","T-Rex","Spirit","Control","Gas"},
    [4] = {"Shadow","Gravity","Buddha","Blizzard","Portal","Phoenix","Rumble","Paw","Yeti"},
    [3] = {"Magma","Quake","Light","Ice","Sand","Dark","Diamond","Barrier","Love","Spider","Sound","Pain","Revive","Creation"},
    [2] = {"Rocket","Spin","Chop","Spring","Bomb","Smoke","Spike","Flame","Falcon","Rubber"},
}

local function getTier(name)
    for tier = 5, 2, -1 do
        for _, f in ipairs(TIERS[tier]) do
            if name:find(f) then return tier end
        end
    end
    return nil
end

local F = { travel = false, highOnly = false, hop = false, bulk = false, antiAfk = true }
local CFG = { speed = 300, minDist = 5, scanInterval = 1, bulkMinHigh = 1, bulkWait = 8 }
local Cache = { fruits = {}, last = 0 }
local Bulk = { records = {} }
local moveTo = nil

local function char()
    local c = LP.Character
    if not c then return nil, nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function scan()
    local now = tick()
    if now - Cache.last < CFG.scanInterval then return end
    Cache.last = now
    local list = {}
    local function check(v)
        if not v or not v:IsA("Model") then return end
        local tier = getTier(v.Name)
        if not tier then return end
        local h = v:FindFirstChild("Handle")
        if h and h:IsA("BasePart") then
            table.insert(list, { name = v.Name, pos = h.Position, tier = tier, high = tier >= 4 })
        end
    end
    for _, v in ipairs(WS:GetChildren()) do check(v) end
    local ff = WS:FindFirstChild("Fruits")
    if ff then for _, v in ipairs(ff:GetChildren()) do check(v) end end
    table.sort(list, function(a, b) return a.tier > b.tier end)
    Cache.fruits = list
end

local function hop()
    local cursor = ""
    local servers = {}
    local ok = pcall(function()
        repeat
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
            if cursor ~= "" then url = url .. "&cursor=" .. HS:UrlEncode(cursor) end
            local res = HS:JSONDecode(game:HttpGet(url))
            if not res or not res.data then break end
            for _, s in ipairs(res.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    table.insert(servers, s.id)
                end
            end
            cursor = res.nextPageCursor or ""
        until cursor == "" or #servers >= 30
    end)
    if ok and #servers > 0 then
        local chosen = servers[math.random(#servers)]
        task.wait(0.3)
        pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, chosen, LP) end)
        return true
    end
    return false
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RJFS2"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 600, 0, 480)
Main.Position = UDim2.new(0.5, -300, 0.5, -240)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local ms = Instance.new("UIStroke", Main)
ms.Color = C.purple
ms.Thickness = 1.5
ms.Transparency = 0.2

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 68)
Header.BackgroundColor3 = C.panel
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeadGradient = Instance.new("Frame", Header)
HeadGradient.Size = UDim2.new(1, 0, 1, 0)
HeadGradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeadGradient.BackgroundTransparency = 0.93
HeadGradient.BorderSizePixel = 0
Instance.new("UICorner", HeadGradient).CornerRadius = UDim.new(0, 14)
local hg = Instance.new("UIGradient", HeadGradient)
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.purple),
    ColorSequenceKeypoint.new(0.5, C.cyan),
    ColorSequenceKeypoint.new(1, C.gold),
}
hg.Rotation = 20

local Logo = Instance.new("Frame", Header)
Logo.Position = UDim2.new(0, 18, 0, 18)
Logo.Size = UDim2.new(0, 32, 0, 32)
Logo.BackgroundColor3 = C.purple
Logo.BorderSizePixel = 0
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)
local LogoText = Instance.new("TextLabel", Logo)
LogoText.BackgroundTransparency = 1
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.Font = FB
LogoText.Text = "R"
LogoText.TextColor3 = C.bg
LogoText.TextSize = 20

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 60, 0, 14)
Title.Size = UDim2.new(1, -140, 0, 22)
Title.Font = FB
Title.Text = "REDJ03N"
Title.TextColor3 = C.text
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel", Header)
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 60, 0, 36)
Subtitle.Size = UDim2.new(1, -140, 0, 16)
Subtitle.Font = FM
Subtitle.Text = "F R U I T   S C A N N E R"
Subtitle.TextColor3 = C.cyan
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Position = UDim2.new(1, -34, 0, 20)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = C.panel2
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = FB
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.red
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Position = UDim2.new(0, 0, 0, 68)
Sidebar.Size = UDim2.new(0, 160, 1, -108)
Sidebar.BackgroundColor3 = C.bg
Sidebar.BorderSizePixel = 0

local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0, 160, 0, 68)
Content.Size = UDim2.new(1, -160, 1, -108)
Content.BackgroundColor3 = C.panel
Content.BorderSizePixel = 0

local StatusBar = Instance.new("Frame", Main)
StatusBar.Position = UDim2.new(0, 0, 1, -40)
StatusBar.Size = UDim2.new(1, 0, 0, 40)
StatusBar.BackgroundColor3 = C.panel
StatusBar.BorderSizePixel = 0
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 14)

local StatusDot = Instance.new("Frame", StatusBar)
StatusDot.Position = UDim2.new(0, 18, 0.5, -4)
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.BackgroundColor3 = C.green
StatusDot.BorderSizePixel = 0
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusText = Instance.new("TextLabel", StatusBar)
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 34, 0, 0)
StatusText.Size = UDim2.new(1, -50, 1, 0)
StatusText.Font = FC
StatusText.Text = "ready"
StatusText.TextColor3 = C.muted
StatusText.TextSize = 11
StatusText.TextXAlignment = Enum.TextXAlignment.Left

local Tabs = {}

local function newTab(name, icon, order)
    local page = Instance.new("Frame", Content)
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.BorderSizePixel = 0

    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -16, 0, 38)
    btn.Position = UDim2.new(0, 8, 0, order * 44 + 10)
    btn.BackgroundColor3 = C.bg
    btn.BorderSizePixel = 0
    btn.Font = FS
    btn.Text = "  " .. icon .. "   " .. name
    btn.TextColor3 = C.muted
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = C.bg
            t.Btn.TextColor3 = C.muted
        end
        page.Visible = true
        btn.BackgroundColor3 = C.panel2
        btn.TextColor3 = C.purple
    end)
    Tabs[name] = { Page = page, Btn = btn }
    return page
end

local function makeSection(parent, txt, yPos)
    local lbl = Instance.new("TextLabel", parent)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 0, 0, yPos)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Font = FB
    lbl.Text = txt:upper()
    lbl.TextColor3 = C.purple
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeToggle(parent, txt, key, yPos, cb)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundColor3 = C.panel2
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Font = FS
    lbl.Text = txt
    lbl.TextColor3 = C.text
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Position = UDim2.new(1, -50, 0.5, -10)
    track.Size = UDim2.new(0, 38, 0, 20)
    track.BackgroundColor3 = C.off
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = C.text
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        if F[key] then
            TW:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = C.purple}):Play()
            TW:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TW:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = C.off}):Play()
            TW:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end
    refresh()

    row.MouseButton1Click:Connect(function()
        F[key] = not F[key]
        refresh()
        if cb then pcall(cb, F[key]) end
    end)
    return row
end

local function makeButton(parent, txt, yPos, callback, accent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, 0, 0, 36)
    b.Position = UDim2.new(0, 0, 0, yPos)
    b.BackgroundColor3 = accent and C.purple or C.panel2
    b.BorderSizePixel = 0
    b.Font = FS
    b.Text = txt
    b.TextColor3 = C.text
    b.TextSize = 12
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    b.MouseEnter:Connect(function()
        TW:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = accent and C.cyan or C.panel3}):Play()
    end)
    b.MouseLeave:Connect(function()
        TW:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = accent and C.purple or C.panel2}):Play()
    end)
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return b
end

local function makeSlider(parent, label, mn, mx, dflt, yPos, cb)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1, 0, 0, 56)
    holder.Position = UDim2.new(0, 0, 0, yPos)
    holder.BackgroundColor3 = C.panel2
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", holder)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.Size = UDim2.new(1, -70, 0, 16)
    lbl.Font = FS
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local val = Instance.new("TextLabel", holder)
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(1, -60, 0, 6)
    val.Size = UDim2.new(0, 46, 0, 16)
    val.Font = FC
    val.Text = tostring(dflt)
    val.TextColor3 = C.cyan
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Instance.new("Frame", holder)
    bar.BackgroundColor3 = C.panel3
    bar.Position = UDim2.new(0, 14, 0, 34)
    bar.Size = UDim2.new(1, -28, 0, 6)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = C.purple
    fill.Size = UDim2.new((dflt - mn) / (mx - mn), 0, 1, 0)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local gradient = Instance.new("UIGradient", fill)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.purple),
        ColorSequenceKeypoint.new(1, C.cyan),
    }

    local drag = false
    local function update(i)
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx - mn) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        val.Text = tostring(v)
        cb(v)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            update(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag then update(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

local ScannerT = newTab("Scanner", "◉", 0)
local TravelT = newTab("Travel", "➤", 1)
local ServerT = newTab("Server", "◈", 2)
local SettingsT = newTab("Settings", "◍", 3)

-- Scanner tab
local scanTitle = Instance.new("TextLabel", ScannerT)
scanTitle.BackgroundTransparency = 1
scanTitle.Position = UDim2.new(0, 0, 0, 0)
scanTitle.Size = UDim2.new(1, 0, 0, 18)
scanTitle.Font = FB
scanTitle.Text = "LIVE FRUITS"
scanTitle.TextColor3 = C.purple
scanTitle.TextSize = 10
scanTitle.TextXAlignment = Enum.TextXAlignment.Left

local scanCount = Instance.new("TextLabel", ScannerT)
scanCount.BackgroundTransparency = 1
scanCount.Position = UDim2.new(0, 0, 0, 20)
scanCount.Size = UDim2.new(1, 0, 0, 16)
scanCount.Font = FC
scanCount.Text = "scanning..."
scanCount.TextColor3 = C.muted
scanCount.TextSize = 10
scanCount.TextXAlignment = Enum.TextXAlignment.Left

local FruitList = Instance.new("ScrollingFrame", ScannerT)
FruitList.Position = UDim2.new(0, 0, 0, 42)
FruitList.Size = UDim2.new(1, 0, 1, -92)
FruitList.BackgroundColor3 = C.bg
FruitList.BorderSizePixel = 0
FruitList.ScrollBarThickness = 3
FruitList.ScrollBarImageColor3 = C.purple
FruitList.CanvasSize = UDim2.new(0, 0, 0, 0)
FruitList.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", FruitList).CornerRadius = UDim.new(0, 8)
local fl = Instance.new("UIListLayout", FruitList)
fl.Padding = UDim.new(0, 4)
fl.SortOrder = Enum.SortOrder.LayoutOrder
local flPad = Instance.new("UIPadding", FruitList)
flPad.PaddingTop = UDim.new(0, 6)
flPad.PaddingBottom = UDim.new(0, 6)
flPad.PaddingLeft = UDim.new(0, 6)
flPad.PaddingRight = UDim.new(0, 6)

local function refreshList()
    for _, c in ipairs(FruitList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    scanCount.Text = #Cache.fruits .. " fruits detected"
    if #Cache.fruits == 0 then
        local empty = Instance.new("Frame", FruitList)
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundColor3 = C.panel2
        empty.BorderSizePixel = 0
        Instance.new("UICorner", empty).CornerRadius = UDim.new(0, 6)
        local el = Instance.new("TextLabel", empty)
        el.BackgroundTransparency = 1
        el.Size = UDim2.new(1, 0, 1, 0)
        el.Font = FM
        el.Text = "No fruits in this server"
        el.TextColor3 = C.muted
        el.TextSize = 11
        return
    end
    for i, f in ipairs(Cache.fruits) do
        local row = Instance.new("TextButton", FruitList)
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = C.panel2
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.LayoutOrder = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local tierColor = f.tier == 5 and C.gold or f.tier == 4 and C.purple or f.tier == 3 and C.cyan or C.muted

        local stripe = Instance.new("Frame", row)
        stripe.Size = UDim2.new(0, 3, 1, 0)
        stripe.BackgroundColor3 = tierColor
        stripe.BorderSizePixel = 0
        Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 3)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position = UDim2.new(0, 14, 0, 4)
        nameLbl.Size = UDim2.new(1, -80, 0, 18)
        nameLbl.Font = FS
        nameLbl.Text = f.name
        nameLbl.TextColor3 = C.text
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local distLbl = Instance.new("TextLabel", row)
        distLbl.BackgroundTransparency = 1
        distLbl.Position = UDim2.new(0, 14, 0, 22)
        distLbl.Size = UDim2.new(1, -80, 0, 14)
        distLbl.Font = FC
        distLbl.Text = math.floor(f.dist or 0) .. " studs"
        distLbl.TextColor3 = C.muted
        distLbl.TextSize = 9
        distLbl.TextXAlignment = Enum.TextXAlignment.Left

        local badge = Instance.new("TextLabel", row)
        badge.Position = UDim2.new(1, -54, 0.5, -10)
        badge.Size = UDim2.new(0, 42, 0, 20)
        badge.BackgroundColor3 = tierColor
        badge.BackgroundTransparency = 0.75
        badge.BorderSizePixel = 0
        badge.Font = FB
        badge.Text = "T" .. f.tier
        badge.TextColor3 = tierColor
        badge.TextSize = 10
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

        row.MouseButton1Click:Connect(function()
            moveTo = f.pos
            StatusText.Text = "traveling → " .. f.name
        end)
    end
end

local refreshBtn = Instance.new("TextButton", ScannerT)
refreshBtn.Position = UDim2.new(0, 0, 1, -36)
refreshBtn.Size = UDim2.new(1, 0, 0, 32)
refreshBtn.BackgroundColor3 = C.purple
refreshBtn.BorderSizePixel = 0
refreshBtn.Font = FS
refreshBtn.Text = "REFRESH SCAN"
refreshBtn.TextColor3 = C.text
refreshBtn.TextSize = 11
refreshBtn.AutoButtonColor = false
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)
refreshBtn.MouseButton1Click:Connect(function()
    Cache.last = 0
    pcall(scan)
    pcall(refreshList)
    StatusText.Text = "refreshed · " .. #Cache.fruits .. " fruits"
end)

-- Travel tab
makeSection(TravelT, "Auto Travel", 0)
makeToggle(TravelT, "Auto Travel to Nearest", "travel", 24)
makeToggle(TravelT, "Only High Value (T4+)", "highOnly", 70)
makeSection(TravelT, "Tuning", 122)
makeSlider(TravelT, "Travel Speed", 100, 800, CFG.speed, 146, function(v) CFG.speed = v end)

local tip = Instance.new("Frame", TravelT)
tip.Position = UDim2.new(0, 0, 0, 212)
tip.Size = UDim2.new(1, 0, 0, 48)
tip.BackgroundColor3 = C.panel2
tip.BorderSizePixel = 0
Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 6)
local tipText = Instance.new("TextLabel", tip)
tipText.BackgroundTransparency = 1
tipText.Position = UDim2.new(0, 10, 0, 0)
tipText.Size = UDim2.new(1, -20, 1, 0)
tipText.Font = FM
tipText.Text = "Click any fruit in Scanner tab to travel manually"
tipText.TextColor3 = C.muted
tipText.TextSize = 10
tipText.TextWrapped = true

-- Server tab
makeSection(ServerT, "Server Hop", 0)
makeToggle(ServerT, "Auto Hop When Empty", "hop", 24)
makeToggle(ServerT, "Bulk Scan Mode", "bulk", 70)
makeSlider(ServerT, "Min High-Value to Stay", 1, 5, CFG.bulkMinHigh, 118, function(v) CFG.bulkMinHigh = v end)
makeSection(ServerT, "Actions", 190)
makeButton(ServerT, "HOP NOW", 214, function()
    StatusText.Text = "hopping..."
    pcall(hop)
end, true)
makeButton(ServerT, "VIEW SCAN HISTORY", 260, function()
    print("=== BULK SCAN HISTORY ===")
    local count = 0
    for job, rec in pairs(Bulk.records) do
        count = count + 1
        print(job:sub(1, 8) .. "... · high: " .. rec.high .. " · " .. table.concat(rec.fruits, ", "))
    end
    print("Total: " .. count .. " servers")
    StatusText.Text = count .. " servers in history (check console)"
end)
makeButton(ServerT, "CLEAR HISTORY", 306, function()
    Bulk.records = {}
    StatusText.Text = "history cleared"
end)

-- Settings tab
makeSection(SettingsT, "System", 0)
makeToggle(SettingsT, "Anti-AFK", "antiAfk", 24)
makeSection(SettingsT, "Danger Zone", 90)
makeButton(SettingsT, "STOP ALL FEATURES", 114, function()
    F.travel = false
    F.hop = false
    F.bulk = false
    moveTo = nil
    StatusText.Text = "all stopped"
end)
makeButton(SettingsT, "DESTROY UI", 160, function()
    gui:Destroy()
end)

-- Loops
RunService.RenderStepped:Connect(function()
    local ok = pcall(scan)
    local _, hrp = char()
    if hrp then
        for _, f in ipairs(Cache.fruits) do
            f.dist = (hrp.Position - f.pos).Magnitude
        end
    end

    if F.travel and hrp and #Cache.fruits > 0 then
        local best, bd = nil, math.huge
        for _, f in ipairs(Cache.fruits) do
            if F.highOnly and not f.high then continue end
            if f.dist < bd then best, bd = f, f.dist end
        end
        if best and bd > CFG.minDist then
            pcall(function()
                hrp.CFrame = CFrame.new(hrp.Position + (best.pos - hrp.Position).Unit * 5)
            end)
        end
    end

    if moveTo then
        if not hrp then moveTo = nil else
            local dir = moveTo - hrp.Position
            local d = dir.Magnitude
            if d < 5 then moveTo = nil
            else
                pcall(function()
                    hrp.CFrame = CFrame.new(hrp.Position + dir.Unit * math.min(5, d))
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        pcall(refreshList)
    end
end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            if F.hop then
                local count = 0
                for _, f in ipairs(Cache.fruits) do
                    if not F.highOnly or f.high then count = count + 1 end
                end
                if count == 0 then
                    hop()
                    task.wait(6)
                end
            elseif F.bulk then
                local hc = 0
                for _, f in ipairs(Cache.fruits) do if f.high then hc = hc + 1 end end
                Bulk.records[game.JobId] = { high = hc, fruits = {} }
                for _, f in ipairs(Cache.fruits) do table.insert(Bulk.records[game.JobId].fruits, f.name) end
                if hc < CFG.bulkMinHigh then
                    hop()
                    task.wait(CFG.bulkWait)
                end
            end
        end)
    end
end)

LP.Idled:Connect(function()
    if F.antiAfk then
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
end)

ScannerT.Visible = true
Tabs["Scanner"].Btn.BackgroundColor3 = C.panel2
Tabs["Scanner"].Btn.TextColor3 = C.purple

task.wait(0.3)
pcall(scan)
pcall(refreshList)
StatusText.Text = "ready · " .. #Cache.fruits .. " fruits"
