-- language: Lua (Luau), file: 1cheli.lua
-- RedJ03N · ESP Pro + Loot + Aimbot + View

if getgenv and getgenv().RJ_ESPPro then
    pcall(function()
        for _, g in ipairs(game.CoreGui:GetChildren()) do
            if g.Name:find("RJ_ESP") then g:Destroy() end
        end
    end)
end
if getgenv then getgenv().RJ_ESPPro = true end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TW = game:GetService("TweenService")
local LT = game:GetService("Lighting")
local WS = game:GetService("Workspace")
local CAM = WS.CurrentCamera
local LP = Players.LocalPlayer

local C = {
    bg=Color3.fromRGB(14,18,32), panel=Color3.fromRGB(23,28,46), panel2=Color3.fromRGB(34,40,64),
    panel3=Color3.fromRGB(46,54,82), purple=Color3.fromRGB(139,92,246), cyan=Color3.fromRGB(6,182,212),
    gold=Color3.fromRGB(245,158,11), green=Color3.fromRGB(16,185,129), red=Color3.fromRGB(239,68,68),
    pink=Color3.fromRGB(236,72,153), white=Color3.fromRGB(248,250,252),
    text=Color3.fromRGB(226,232,240), muted=Color3.fromRGB(100,116,139), off=Color3.fromRGB(71,85,105),
    orange=Color3.fromRGB(255,140,40),
}
local FB, FM, FS, FC = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamSemibold, Enum.Font.Code

local S = {
    enabled=false, box=true, name=true, health=true, distance=true, tracer=false,
    teamCheck=false, color=C.red, fillTrans=0.55, outlineTrans=0.1, textSize=12,
    maxDist=2000, antiAfk=true, fullBright=false, keybind=Enum.KeyCode.RightShift, uiVisible=true,
    lootEnabled=false, lootPlayers=false, lootMaxDist=1500, lootFill=0.55,
    -- Aimbot
    aimEnabled=false, aimAlways=true, aimSmooth=0.3, aimFOV=300, aimRange=1500,
    aimPart="Head", aimPlayers=true, aimNPCs=true, aimVisCheck=false, aimAutoFire=false,
    aimKeybind=Enum.KeyCode.E, showFOV=true,
    -- View
    fovEnabled=false, fovValue=70, zoomEnabled=false, zoomDist=30, minZoom=0.5,
}

local PD = {}
local LootCache = {}
local NpcCache = {}
local cachedAimTarget = nil
local aimHighlight = nil
local FOVCircle = nil

local function getHum(p)
    if not p.Character then return nil end
    return p.Character:FindFirstChildOfClass("Humanoid")
end
local function getRoot(p)
    if not p.Character then return nil end
    return p.Character:FindFirstChild("HumanoidRootPart")
end
local function getHead(p)
    if not p.Character then return nil end
    return p.Character:FindFirstChild("Head")
end
local function dist3(a, b) return (a - b).Magnitude end
local function isTeammate(p)
    if not S.teamCheck then return false end
    if not p.Team or not LP.Team then return false end
    return p.Team == LP.Team
end

-- NPC scan (own throttled loop, single pass)
local lastNpcScan = 0
local function scanNPCs()
    local now = tick()
    if now - lastNpcScan < 0.5 then return end
    lastNpcScan = now
    local list = {}
    local seen = {}
    local function check(v)
        if not v or seen[v] then return end
        seen[v] = true
        if not v:IsA("Model") then return end
        if v == LP.Character then return end
        if Players:GetPlayerFromCharacter(v) then return end
        local hum = v:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(list, v)
        end
    end
    for _, name in ipairs({"Enemies", "NPCs", "Mobs", "Monsters", "Targets", "Dummies", "Bots", "Hostile"}) do
        local f = WS:FindFirstChild(name)
        if f then
            for _, v in ipairs(f:GetChildren()) do check(v) end
        end
    end
    for _, v in ipairs(WS:GetChildren()) do check(v) end
    NpcCache = list
end

task.spawn(function()
    while true do
        pcall(scanNPCs)
        task.wait(0.3)
    end
end)

-- Loot
local LOOT_KEYWORDS = {
    crate={"crate","supply"}, chest={"chest","box","coffer"}, currency={"cash","coin","money","gem"},
    weapon={"gun","rifle","pistol","shotgun","smg","sniper","knife"},
    other={"loot","drop","pickup","item","medkit","ammo","armor","key","card","weapon","tool"},
}
local LOOT_COLORS = {crate=C.purple, chest=C.orange, currency=C.gold, weapon=C.red, other=C.green}
local function classifyLoot(name)
    local n = name:lower()
    for cat, words in pairs(LOOT_KEYWORDS) do
        for _, k in ipairs(words) do
            if n:find(k) then return cat end
        end
    end
    return nil
end
local function lootAnchor(v)
    if v:IsA("BasePart") then return v end
    return v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
end

-- ============================================================
-- AIMBOT CORE — cached, fast, prioritised above PlayerModule
-- ============================================================
local function getAimbotTarget()
    local center = Vector2.new(CAM.ViewportSize.X / 2, CAM.ViewportSize.Y / 2)
    local best = nil
    local bestScreenDist = S.aimFOV
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position

    -- pre-filter by 3D distance, then screen distance
    local candidates = {}

    if S.aimPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and not isTeammate(p) then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local d3 = (myPos - root.Position).Magnitude
                    if d3 <= S.aimRange then
                        table.insert(candidates, p.Character)
                    end
                end
            end
        end
    end

    if S.aimNPCs then
        for _, npc in ipairs(NpcCache) do
            local root = npc:FindFirstChild("HumanoidRootPart")
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local d3 = (myPos - root.Position).Magnitude
                if d3 <= S.aimRange then
                    table.insert(candidates, npc)
                end
            end
        end
    end

    for _, char in ipairs(candidates) do
        local part = char:FindFirstChild(S.aimPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if part then
            local screen, onScreen = CAM:WorldToViewportPoint(part.Position)
            if onScreen and screen.Z > 0 then
                local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if d < bestScreenDist then
                    if S.aimVisCheck then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {LP.Character, char}
                        local ray = (part.Position - CAM.CFrame.Position).Unit * (part.Position - CAM.CFrame.Position).Magnitude
                        local result = WS:Raycast(CAM.CFrame.Position, ray, params)
                        if not result then
                            bestScreenDist = d
                            best = part
                        end
                    else
                        bestScreenDist = d
                        best = part
                    end
                end
            end
        end
    end

    return best
end

-- target refresh (12 Hz, not 60)
task.spawn(function()
    while true do
        task.wait(0.08)
        if S.aimEnabled then
            pcall(function()
                cachedAimTarget = getAimbotTarget()
            end)
        else
            cachedAimTarget = nil
        end
    end
end)

-- aim highlight (persistent, change adornee)
aimHighlight = Instance.new("Highlight")
aimHighlight.Name = "RJ_AimHL"
aimHighlight.FillColor = C.green
aimHighlight.FillTransparency = 0.5
aimHighlight.OutlineColor = C.green
aimHighlight.OutlineTransparency = 0
aimHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
aimHighlight.Enabled = false
aimHighlight.Parent = game.CoreGui

-- camera write at high priority to beat PlayerModule
RunService:BindToRenderStep("RJ_AimWrite", Enum.RenderPriority.Camera.Value + 1, function()
    if not S.aimEnabled then
        if aimHighlight then aimHighlight.Enabled = false end
        return
    end
    if not cachedAimTarget or not cachedAimTarget.Parent then
        if aimHighlight then aimHighlight.Enabled = false end
        return
    end

    -- update highlight
    local char = cachedAimTarget.Parent
    if aimHighlight.Adornee ~= char then
        aimHighlight.Adornee = char
    end
    aimHighlight.Enabled = true

    local shouldAim = S.aimAlways
        or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or UIS:IsKeyDown(S.aimKeybind)
    if not shouldAim then return end

    local targetCF = CFrame.new(CAM.CFrame.Position, cachedAimTarget.Position)
    CAM.CFrame = CAM.CFrame:Lerp(targetCF, S.aimSmooth)

    if S.aimAutoFire then
        local c = LP.Character
        if c then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

-- ============================================================
-- VIEW / POV — FOV override + zoom
-- ============================================================
RunService.RenderStepped:Connect(function()
    if S.fovEnabled then
        CAM.FieldOfView = S.fovValue
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local function removeESP(p)
    local d = PD[p]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    if d.tracer then d.tracer:Destroy() end
    if d.row then d.row:Destroy() end
    PD[p] = nil
end

local function createESP(p)
    if p == LP or not p.Character or isTeammate(p) then return end
    removeESP(p)
    local char = p.Character
    local head = getHead(p)
    local root = getRoot(p)
    if not head or not root then return end
    local data = { char = char }
    if S.box then
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillColor = S.color
        hl.FillTransparency = S.fillTrans
        hl.OutlineColor = S.color
        hl.OutlineTransparency = S.outlineTrans
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        data.hl = hl
    end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 130, 0, 46)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    data.bb = bb
    if S.name then
        local nm = Instance.new("TextLabel", bb)
        nm.Position = UDim2.new(0, 0, 0, 0)
        nm.Size = UDim2.new(1, 0, 0, 16)
        nm.BackgroundTransparency = 1
        nm.Font = FB
        nm.Text = p.Name
        nm.TextColor3 = S.color
        nm.TextSize = S.textSize
        nm.TextStrokeTransparency = 0.3
        data.nameLbl = nm
    end
    if S.health then
        local hpBg = Instance.new("Frame", bb)
        hpBg.Position = UDim2.new(0.15, 0, 0, 18)
        hpBg.Size = UDim2.new(0.7, 0, 0, 4)
        hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        hpBg.BorderSizePixel = 0
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)
        local hpFill = Instance.new("Frame", hpBg)
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = C.green
        hpFill.BorderSizePixel = 0
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
        data.hpBg = hpBg
        data.hpFill = hpFill
    end
    if S.distance then
        local ds = Instance.new("TextLabel", bb)
        ds.Position = UDim2.new(0, 0, 0, 24)
        ds.Size = UDim2.new(1, 0, 0, 14)
        ds.BackgroundTransparency = 1
        ds.Font = FC
        ds.Text = "..."
        ds.TextColor3 = C.muted
        ds.TextSize = 10
        ds.TextStrokeTransparency = 0.4
        data.distLbl = ds
    end
    if S.tracer then
        local tr = Instance.new("Frame", tracerFrame)
        tr.BackgroundColor3 = S.color
        tr.BorderSizePixel = 0
        tr.AnchorPoint = Vector2.new(0, 0.5)
        tr.Size = UDim2.new(0, 0, 0, 1)
        tr.ZIndex = 998
        data.tracer = tr
    end
    PD[p] = data
end

local function applyStyleToAll()
    for _, d in pairs(PD) do
        if d.hl then
            d.hl.FillColor = S.color
            d.hl.OutlineColor = S.color
            d.hl.FillTransparency = S.fillTrans
            d.hl.OutlineTransparency = S.outlineTrans
        end
        if d.nameLbl then
            d.nameLbl.TextColor3 = S.color
            d.nameLbl.TextSize = S.textSize
        end
        if d.tracer then d.tracer.BackgroundColor3 = S.color end
    end
end

local function removeLoot(obj)
    local d = LootCache[obj]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    LootCache[obj] = nil
end

local function createLoot(obj, cat)
    if LootCache[obj] then return end
    local anchor = lootAnchor(obj)
    if not anchor then return end
    local col = LOOT_COLORS[cat] or C.green
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = col
    hl.FillTransparency = S.lootFill
    hl.OutlineColor = col
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    local bb = Instance.new("BillboardGui")
    bb.Adornee = anchor
    bb.Size = UDim2.new(0, 140, 0, 26)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = S.lootMaxDist
    bb.Parent = anchor
    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0.6, 0)
    nameLbl.Font = FB
    nameLbl.Text = obj.Name
    nameLbl.TextColor3 = col
    nameLbl.TextSize = 11
    nameLbl.TextStrokeTransparency = 0.4
    local distLbl = Instance.new("TextLabel", bb)
    distLbl.BackgroundTransparency = 1
    distLbl.Position = UDim2.new(0, 0, 0.6, 0)
    distLbl.Size = UDim2.new(1, 0, 0.4, 0)
    distLbl.Font = FC
    distLbl.Text = "?"
    distLbl.TextColor3 = C.muted
    distLbl.TextSize = 9
    distLbl.TextStrokeTransparency = 0.5
    LootCache[obj] = { hl = hl, bb = bb, distLbl = distLbl }
end

local lastLootScan = 0
local function scanLoot()
    local now = tick()
    if now - lastLootScan < 0.7 then return end
    lastLootScan = now
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local live = {}
    local function check(v)
        if not v or not v.Parent then return end
        if v == LP.Character or v.Parent == LP.Character then return end
        if Players:GetPlayerFromCharacter(v) then return end
        if v.Parent and v.Parent.Name == "Backpack" then return end
        if v:IsA("Model") or v:IsA("Tool") then
            local cat = classifyLoot(v.Name)
            if cat then
                local anchor = lootAnchor(v)
                if anchor then
                    local d = (hrp.Position - anchor.Position).Magnitude
                    if d <= S.lootMaxDist then
                        live[v] = true
                        if not LootCache[v] then createLoot(v, cat) end
                    end
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetChildren()) do check(v) end
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, v in ipairs(folder:GetChildren()) do check(v) end
        end
    end
    for obj, _ in pairs(LootCache) do
        if not live[obj] or not obj.Parent then removeLoot(obj) end
    end
end

-- ============================================================
-- Tracer/Watermark/Notif/Minimap GUIs
-- ============================================================
local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "RJ_ESP_Tracers"
tracerGui.Parent = game.CoreGui
tracerGui.ResetOnSpawn = false
tracerGui.DisplayOrder = 996
local tracerFrame = Instance.new("Frame", tracerGui)
tracerFrame.Size = UDim2.new(1, 0, 1, 0)
tracerFrame.BackgroundTransparency = 1
tracerFrame.Name = "Frame"

local wmGui = Instance.new("ScreenGui")
wmGui.Name = "RJ_ESP_WM"
wmGui.Parent = game.CoreGui
wmGui.ResetOnSpawn = false
wmGui.DisplayOrder = 1001
local WM = Instance.new("Frame", wmGui)
WM.Position = UDim2.new(0, 20, 0, 20)
WM.Size = UDim2.new(0, 300, 0, 28)
WM.BackgroundColor3 = C.bg
WM.BackgroundTransparency = 0.15
WM.BorderSizePixel = 0
Instance.new("UICorner", WM).CornerRadius = UDim.new(0, 6)
local wms = Instance.new("UIStroke", WM)
wms.Color = C.purple
wms.Thickness = 1
wms.Transparency = 0.4
local wmBar = Instance.new("Frame", WM)
wmBar.Size = UDim2.new(0, 3, 1, 0)
wmBar.BackgroundColor3 = C.purple
wmBar.BorderSizePixel = 0
Instance.new("UICorner", wmBar).CornerRadius = UDim.new(0, 6)
local wmText = Instance.new("TextLabel", WM)
wmText.BackgroundTransparency = 1
wmText.Position = UDim2.new(0, 10, 0, 0)
wmText.Size = UDim2.new(1, -14, 1, 0)
wmText.Font = FC
wmText.Text = "RedJ03N"
wmText.TextColor3 = C.text
wmText.TextSize = 10
wmText.TextXAlignment = Enum.TextXAlignment.Left

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "RJ_ESP_Notif"
notifGui.Parent = game.CoreGui
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 1002
local notifCon = Instance.new("Frame", notifGui)
notifCon.Position = UDim2.new(1, -290, 1, -400)
notifCon.Size = UDim2.new(0, 270, 0, 380)
notifCon.BackgroundTransparency = 1
local ncl = Instance.new("UIListLayout", notifCon)
ncl.Padding = UDim.new(0, 6)
ncl.VerticalAlignment = Enum.VerticalAlignment.Bottom
ncl.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function notify(title, body)
    local card = Instance.new("Frame", notifCon)
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = C.panel
    card.BorderSizePixel = 0
    card.Position = UDim2.new(1, 30, 0, 0)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", card)
    s.Color = C.purple
    s.Thickness = 1
    s.Transparency = 0.5
    local bar = Instance.new("Frame", card)
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = C.purple
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local t = Instance.new("TextLabel", card)
    t.BackgroundTransparency = 1
    t.Position = UDim2.new(0, 12, 0, 6)
    t.Size = UDim2.new(1, -20, 0, 16)
    t.Font = FB
    t.Text = title
    t.TextColor3 = C.text
    t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("TextLabel", card)
    b.BackgroundTransparency = 1
    b.Position = UDim2.new(0, 12, 0, 22)
    b.Size = UDim2.new(1, -20, 0, 22)
    b.Font = FM
    b.Text = body
    b.TextColor3 = C.muted
    b.TextSize = 9
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextWrapped = true
    TW:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(3.5, function()
        TW:Create(card, TweenInfo.new(0.25), {Position = UDim2.new(1, 30, 0, 0)}):Play()
        task.wait(0.3)
        card:Destroy()
    end)
end

local blur = Instance.new("BlurEffect", LT)
blur.Size = 0
blur.Enabled = false

-- Ghostface draw
local function drawGhostface(container, size)
    local face = Instance.new("Frame", container)
    face.Size = UDim2.new(0, size, 0, math.floor(size * 1.15))
    face.Position = UDim2.new(0.5, -size/2, 0.5, -math.floor(size * 1.15)/2)
    face.BackgroundColor3 = C.white
    face.BorderSizePixel = 0
    Instance.new("UICorner", face).CornerRadius = UDim.new(0.5, 0)
    local stroke = Instance.new("UIStroke", face)
    stroke.Color = Color3.fromRGB(15, 15, 20)
    stroke.Thickness = 1.5
    local eyeW = math.max(2, math.floor(size * 0.16))
    local eyeH = math.max(3, math.floor(size * 0.32))
    local eyeY = 0.26
    local eyeL = Instance.new("Frame", face)
    eyeL.Size = UDim2.new(0, eyeW, 0, eyeH)
    eyeL.Position = UDim2.new(0.5, -math.floor(size * 0.26), eyeY, 0)
    eyeL.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    eyeL.BorderSizePixel = 0
    eyeL.Rotation = -18
    Instance.new("UICorner", eyeL).CornerRadius = UDim.new(1, 0)
    local eyeR = Instance.new("Frame", face)
    eyeR.Size = UDim2.new(0, eyeW, 0, eyeH)
    eyeR.Position = UDim2.new(0.5, math.floor(size * 0.10), eyeY, 0)
    eyeR.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    eyeR.BorderSizePixel = 0
    eyeR.Rotation = 18
    Instance.new("UICorner", eyeR).CornerRadius = UDim.new(1, 0)
    local mouthW = math.max(3, math.floor(size * 0.14))
    local mouthH = math.max(5, math.floor(size * 0.35))
    local mouth = Instance.new("Frame", face)
    mouth.Size = UDim2.new(0, mouthW, 0, mouthH)
    mouth.Position = UDim2.new(0.5, -math.floor(mouthW/2), 0.58, 0)
    mouth.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mouth.BorderSizePixel = 0
    Instance.new("UICorner", mouth).CornerRadius = UDim.new(1, 0)
    return face
end

-- Mini ghost
local miniGui = Instance.new("ScreenGui")
miniGui.Name = "RJ_ESP_Mini"
miniGui.Parent = game.CoreGui
miniGui.ResetOnSpawn = false
miniGui.DisplayOrder = 1003
local MiniGhost = Instance.new("TextButton", miniGui)
MiniGhost.Size = UDim2.new(0, 52, 0, 52)
MiniGhost.Position = UDim2.new(0, 20, 0, 60)
MiniGhost.BackgroundColor3 = C.bg
MiniGhost.BackgroundTransparency = 0.1
MiniGhost.BorderSizePixel = 0
MiniGhost.Text = ""
MiniGhost.AutoButtonColor = false
MiniGhost.Visible = false
Instance.new("UICorner", MiniGhost).CornerRadius = UDim.new(1, 0)
local mgStroke = Instance.new("UIStroke", MiniGhost)
mgStroke.Color = C.purple
mgStroke.Thickness = 1.5
mgStroke.Transparency = 0.3
drawGhostface(MiniGhost, 32)

local miniDrag = false
local miniStart, miniStartPos
MiniGhost.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDrag = true
        miniStart = input.Position
        miniStartPos = MiniGhost.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                miniDrag = false
                conn:Disconnect()
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if miniDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniStart
        MiniGhost.Position = UDim2.new(
            miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X,
            miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y
        )
    end
end)
task.spawn(function()
    while MiniGhost.Parent do
        if MiniGhost.Visible then
            TW:Create(mgStroke, TweenInfo.new(1.2), {Transparency = 0.7}):Play()
            task.wait(1.2)
            TW:Create(mgStroke, TweenInfo.new(1.2), {Transparency = 0.1}):Play()
            task.wait(1.2)
        else
            task.wait(0.5)
        end
    end
end)

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RJ_ESP_Pro"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 580, 0, 500)
Main.Position = UDim2.new(0.5, -290, 0.5, -250)
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
Header.Size = UDim2.new(1, 0, 0, 66)
Header.BackgroundColor3 = C.panel
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)
local hg = Instance.new("Frame", Header)
hg.Size = UDim2.new(1, 0, 1, 0)
hg.BackgroundTransparency = 0.94
hg.BorderSizePixel = 0
Instance.new("UICorner", hg).CornerRadius = UDim.new(0, 14)
local hgg = Instance.new("UIGradient", hg)
hgg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.purple),
    ColorSequenceKeypoint.new(0.5, C.cyan),
    ColorSequenceKeypoint.new(1, C.purple),
}
hgg.Rotation = 30

local Logo = Instance.new("Frame", Header)
Logo.Position = UDim2.new(0, 18, 0, 17)
Logo.Size = UDim2.new(0, 32, 0, 32)
Logo.BackgroundColor3 = C.purple
Logo.BorderSizePixel = 0
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)
local lg = Instance.new("UIGradient", Logo)
lg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.purple),
    ColorSequenceKeypoint.new(1, C.cyan),
}
local lt = Instance.new("TextLabel", Logo)
lt.BackgroundTransparency = 1
lt.Size = UDim2.new(1, 0, 1, 0)
lt.Font = FB
lt.Text = "R"
lt.TextColor3 = C.bg
lt.TextSize = 20

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 60, 0, 13)
Title.Size = UDim2.new(1, -170, 0, 22)
Title.Font = FB
Title.Text = "REDJ03N"
Title.TextColor3 = C.text
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", Header)
Sub.BackgroundTransparency = 1
Sub.Position = UDim2.new(0, 60, 0, 36)
Sub.Size = UDim2.new(1, -170, 0, 14)
Sub.Font = FM
Sub.Text = "E S P   P R O"
Sub.TextColor3 = C.cyan
Sub.TextSize = 9
Sub.TextXAlignment = Enum.TextXAlignment.Left

local GhostBtn = Instance.new("TextButton", Header)
GhostBtn.Position = UDim2.new(1, -68, 0, 18)
GhostBtn.Size = UDim2.new(0, 30, 0, 30)
GhostBtn.BackgroundColor3 = C.panel2
GhostBtn.BorderSizePixel = 0
GhostBtn.Text = ""
GhostBtn.AutoButtonColor = false
Instance.new("UICorner", GhostBtn).CornerRadius = UDim.new(0, 8)
local gbStroke = Instance.new("UIStroke", GhostBtn)
gbStroke.Color = C.purple
gbStroke.Thickness = 1
gbStroke.Transparency = 0.5
drawGhostface(GhostBtn, 18)

GhostBtn.MouseEnter:Connect(function()
    TW:Create(gbStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
    TW:Create(GhostBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.panel3}):Play()
end)
GhostBtn.MouseLeave:Connect(function()
    TW:Create(gbStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    TW:Create(GhostBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.panel2}):Play()
end)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Position = UDim2.new(1, -34, 0, 18)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.BackgroundColor3 = C.panel2
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = FB
CloseBtn.Text = "×"
CloseBtn.TextColor3 = C.red
CloseBtn.TextSize = 16
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    gui:Destroy() wmGui:Destroy() notifGui:Destroy() tracerGui:Destroy() miniGui:Destroy() blur:Destroy()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if aimHighlight then aimHighlight:Destroy() end
    pcall(function() RunService:UnbindFromRenderStep("RJ_AimWrite") end)
end)

local Side = Instance.new("Frame", Main)
Side.Position = UDim2.new(0, 0, 0, 66)
Side.Size = UDim2.new(0, 150, 1, -106)
Side.BackgroundColor3 = C.bg
Side.BorderSizePixel = 0

local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0, 150, 0, 66)
Content.Size = UDim2.new(1, -150, 1, -106)
Content.BackgroundColor3 = C.panel
Content.BorderSizePixel = 0

local StatusBar = Instance.new("Frame", Main)
StatusBar.Position = UDim2.new(0, 0, 1, -40)
StatusBar.Size = UDim2.new(1, 0, 0, 40)
StatusBar.BackgroundColor3 = C.panel
StatusBar.BorderSizePixel = 0
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 14)
local sDot = Instance.new("Frame", StatusBar)
sDot.Position = UDim2.new(0, 18, 0.5, -4)
sDot.Size = UDim2.new(0, 8, 0, 8)
sDot.BackgroundColor3 = C.green
sDot.BorderSizePixel = 0
Instance.new("UICorner", sDot).CornerRadius = UDim.new(1, 0)
local sText = Instance.new("TextLabel", StatusBar)
sText.BackgroundTransparency = 1
sText.Position = UDim2.new(0, 34, 0, 0)
sText.Size = UDim2.new(1, -50, 1, 0)
sText.Font = FC
sText.Text = "ready"
sText.TextColor3 = C.muted
sText.TextSize = 10
sText.TextXAlignment = Enum.TextXAlignment.Left

local function minimizeToGhost()
    S.uiVisible = false
    Main.Visible = false
    WM.Visible = false
    MiniGhost.Visible = true
end
local function restoreFromGhost()
    S.uiVisible = true
    Main.Visible = true
    WM.Visible = true
    MiniGhost.Visible = false
end
GhostBtn.MouseButton1Click:Connect(minimizeToGhost)
MiniGhost.MouseButton1Click:Connect(function()
    if not miniDrag then restoreFromGhost() end
end)

-- UI Builders
local Tabs = {}
local function newTab(name, icon, order)
    local page = Instance.new("ScrollingFrame", Content)
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = C.purple
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.ClipsDescendants = true
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 8)
    local btn = Instance.new("TextButton", Side)
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.Position = UDim2.new(0, 8, 0, order * 42 + 8)
    btn.BackgroundColor3 = C.bg
    btn.BorderSizePixel = 0
    btn.Font = FS
    btn.Text = "  " .. icon .. "   " .. name
    btn.TextColor3 = C.muted
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        if not page.Visible then TW:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.panel}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not page.Visible then TW:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.bg}):Play() end
    end)
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

local function section(p, txt, y)
    local l = Instance.new("TextLabel", p)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 0, 0, y)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.Font = FB
    l.Text = "▸ " .. txt:upper()
    l.TextColor3 = C.purple
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function toggle(p, txt, key, y, cb)
    local row = Instance.new("TextButton", p)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.Position = UDim2.new(0, 0, 0, y)
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
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local function refresh()
        if S[key] then
            TW:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = C.purple}):Play()
            TW:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TW:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = C.off}):Play()
            TW:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end
    refresh()
    row.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        refresh()
        if cb then pcall(cb, S[key]) end
    end)
end

local function button(p, txt, y, cb, primary)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1, 0, 0, 34)
    b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = primary and C.purple or C.panel2
    b.BorderSizePixel = 0
    b.Font = FS
    b.Text = txt
    b.TextColor3 = C.text
    b.TextSize = 12
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
end

local function slider(p, label, mn, mx, dflt, y, cb)
    local h = Instance.new("Frame", p)
    h.Size = UDim2.new(1, 0, 0, 54)
    h.Position = UDim2.new(0, 0, 0, y)
    h.BackgroundColor3 = C.panel2
    h.BorderSizePixel = 0
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", h)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.Size = UDim2.new(1, -70, 0, 16)
    lbl.Font = FS
    lbl.Text = label
    lbl.TextColor3 = C.text
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", h)
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(1, -60, 0, 6)
    val.Size = UDim2.new(0, 46, 0, 16)
    val.Font = FC
    val.Text = tostring(dflt)
    val.TextColor3 = C.cyan
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    local bar = Instance.new("Frame", h)
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
    local drag = false
    local function update(i)
        local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor((mn + (mx - mn) * rel) * 100 + 0.5) / 100
        fill.Size = UDim2.new(rel, 0, 1, 0)
        val.Text = tostring(v)
        cb(v)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true update(i)
        end
    end)
    UIS.InputChanged:Connect(function(i) if drag then update(i) end end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- Tabs
local ESPT = newTab("ESP", "◉", 0)
local PlayersT = newTab("Players", "◈", 1)
local LootT = newTab("Loot", "◆", 2)
local AimT = newTab("Aimbot", "◎", 3)
local ViewT = newTab("View", "▣", 4)
local StyleT = newTab("Style", "✦", 5)
local SettingsT = newTab("Settings", "◍", 6)

-- ESP
section(ESPT, "Master", 0)
toggle(ESPT, "Enable ESP", "enabled", 24, function(v)
    if v then
        notify("ESP ON", "Scanning players...")
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then pcall(createESP, p) end end
    else
        for p, _ in pairs(PD) do removeESP(p) end
    end
end)
section(ESPT, "Elements", 74)
toggle(ESPT, "Box", "box", 98, function() for p, _ in pairs(PD) do pcall(createESP, p) end end)
toggle(ESPT, "Name Tag", "name", 144, function() for p, _ in pairs(PD) do pcall(createESP, p) end end)
toggle(ESPT, "Health Bar", "health", 190, function() for p, _ in pairs(PD) do pcall(createESP, p) end end)
toggle(ESPT, "Distance", "distance", 236, function() for p, _ in pairs(PD) do pcall(createESP, p) end end)
toggle(ESPT, "Tracer Lines", "tracer", 282, function() for p, _ in pairs(PD) do pcall(createESP, p) end end)
section(ESPT, "Filters", 332)
toggle(ESPT, "Team Check", "teamCheck", 356, function()
    for p, _ in pairs(PD) do removeESP(p) end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and S.enabled then pcall(createESP, p) end end
end)

-- Players
local listCount = Instance.new("TextLabel", PlayersT)
listCount.BackgroundTransparency = 1
listCount.Position = UDim2.new(0, 0, 0, 0)
listCount.Size = UDim2.new(1, 0, 0, 16)
listCount.Font = FC
listCount.Text = "0 players"
listCount.TextColor3 = C.muted
listCount.TextSize = 10
listCount.TextXAlignment = Enum.TextXAlignment.Left

local PlayerList = Instance.new("ScrollingFrame", PlayersT)
PlayerList.Position = UDim2.new(0, 0, 0, 24)
PlayerList.Size = UDim2.new(1, 0, 0, 340)
PlayerList.BackgroundColor3 = C.bg
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 3
PlayerList.ScrollBarImageColor3 = C.purple
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", PlayerList).CornerRadius = UDim.new(0, 8)
local pll = Instance.new("UIListLayout", PlayerList)
pll.Padding = UDim.new(0, 4)
pll.SortOrder = Enum.SortOrder.LayoutOrder
local plp = Instance.new("UIPadding", PlayerList)
plp.PaddingTop = UDim.new(0, 6)
plp.PaddingBottom = UDim.new(0, 6)
plp.PaddingLeft = UDim.new(0, 6)
plp.PaddingRight = UDim.new(0, 6)

local function buildRow(p)
    if p == LP then return end
    local d = PD[p]
    if not d then return end
    if d.row then d.row:Destroy() end
    local row = Instance.new("TextButton", PlayerList)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = C.panel2
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local stripe = Instance.new("Frame", row)
    stripe.Size = UDim2.new(0, 3, 1, 0)
    stripe.BackgroundColor3 = (p.Team and p.Team.TeamColor.Color) or C.cyan
    stripe.BorderSizePixel = 0
    Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 3)
    local nm = Instance.new("TextLabel", row)
    nm.BackgroundTransparency = 1
    nm.Position = UDim2.new(0, 14, 0, 4)
    nm.Size = UDim2.new(1, -80, 0, 16)
    nm.Font = FS
    nm.Text = p.Name
    nm.TextColor3 = C.text
    nm.TextSize = 12
    nm.TextXAlignment = Enum.TextXAlignment.Left
    local ds = Instance.new("TextLabel", row)
    ds.BackgroundTransparency = 1
    ds.Position = UDim2.new(1, -70, 0, 4)
    ds.Size = UDim2.new(0, 60, 0, 16)
    ds.Font = FC
    ds.Text = "-"
    ds.TextColor3 = C.muted
    ds.TextSize = 10
    ds.TextXAlignment = Enum.TextXAlignment.Right
    local hpBg = Instance.new("Frame", row)
    hpBg.Position = UDim2.new(0, 14, 0, 26)
    hpBg.Size = UDim2.new(1, -28, 0, 6)
    hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hpBg.BorderSizePixel = 0
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)
    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = C.green
    hpFill.BorderSizePixel = 0
    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)
    row.MouseButton1Click:Connect(function()
        local root = getRoot(p)
        if root then CAM.CFrame = CFrame.new(CAM.CFrame.Position, root.Position) end
    end)
    d.row = row
    d.rowDist = ds
    d.rowFill = hpFill
end

-- Loot
section(LootT, "See Through Walls", 0)
toggle(LootT, "Enable Loot Vision", "lootEnabled", 24, function(v)
    if v then notify("Loot ON", "Scanning...") else
        for obj, _ in pairs(LootCache) do removeLoot(obj) end
    end
end)
section(LootT, "Tuning", 74)
slider(LootT, "Max Distance", 100, 3000, S.lootMaxDist, 98, function(v)
    S.lootMaxDist = v
    for _, d in pairs(LootCache) do if d.bb then d.bb.MaxDistance = v end end
end)
slider(LootT, "Fill Transparency", 0, 1, S.lootFill, 158, function(v)
    S.lootFill = v
    for _, d in pairs(LootCache) do if d.hl then d.hl.FillTransparency = v end end
end)
section(LootT, "Actions", 214)
button(LootT, "FORCE RESCAN", 238, function()
    for obj, _ in pairs(LootCache) do removeLoot(obj) end
    lastLootScan = 0
    notify("Rescan", "Rebuilding loot ESP")
end)
button(LootT, "DEBUG — PRINT NAMES", 280, function()
    print("=== LOOT DEBUG ===")
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local found = {}
    local function check(v)
        if not v or not v.Parent then return end
        if v == LP.Character or v.Parent == LP.Character then return end
        if Players:GetPlayerFromCharacter(v) then return end
        if v:IsA("Model") or v:IsA("Tool") then
            local a = lootAnchor(v)
            if a then
                local d = math.floor((hrp.Position - a.Position).Magnitude)
                if d < 250 then
                    table.insert(found, {name = v.Name, dist = d, cls = v.ClassName, match = classifyLoot(v.Name) or "NO MATCH"})
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetChildren()) do check(v) end
    for _, f in ipairs(workspace:GetChildren()) do
        if f:IsA("Folder") or f:IsA("Model") then
            for _, v in ipairs(f:GetChildren()) do check(v) end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    print("Objects within 250 studs:", #found)
    for i, f in ipairs(found) do
        if i > 40 then print("... and " .. (#found - 40) .. " more") break end
        print(i .. ". " .. f.name .. " [" .. f.cls .. "] " .. f.dist .. "m — " .. f.match)
    end
    print("=== END ===")
    notify("Debug", "Printed " .. #found .. " objects (check console)")
end, true)

-- Aimbot
section(AimT, "Master", 0)
toggle(AimT, "Enable Aimbot", "aimEnabled", 24, function(v)
    if v then notify("Aimbot ON", "Auto-locking nearest target")
    else
        notify("Aimbot OFF", "")
        if aimHighlight then aimHighlight.Enabled = false end
        if FOVCircle then FOVCircle.Visible = false end
    end
end)

section(AimT, "Targets", 74)
toggle(AimT, "Aim Players", "aimPlayers", 98)
toggle(AimT, "Aim NPCs", "aimNPCs", 134)
toggle(AimT, "Visibility Check", "aimVisCheck", 170)
toggle(AimT, "Always Aim (no key)", "aimAlways", 206)
toggle(AimT, "Auto Fire", "aimAutoFire", 242)

section(AimT, "Field of View", 294)
toggle(AimT, "Show FOV Circle", "showFOV", 318)
slider(AimT, "FOV Size", 50, 600, S.aimFOV, 362, function(v)
    S.aimFOV = v
    if FOVCircle then FOVCircle.Radius = v end
end)
slider(AimT, "Max Range (studs)", 100, 5000, S.aimRange, 422, function(v) S.aimRange = v end)

section(AimT, "Smoothness", 482)
slider(AimT, "Aim Smoothness", 0.05, 0.8, S.aimSmooth, 506, function(v) S.aimSmooth = v end)

section(AimT, "Debug", 568)
button(AimT, "TEST — COUNT NPCs", 592, function()
    scanNPCs()
    print("=== NPC SCAN ===")
    print("Total NPCs:", #NpcCache)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local inRange = 0
        for _, npc in ipairs(NpcCache) do
            local r = npc:FindFirstChild("HumanoidRootPart")
            if r and (hrp.Position - r.Position).Magnitude <= S.aimRange then
                inRange = inRange + 1
            end
        end
        print("In aim range:", inRange)
    end
    print("Current target:", cachedAimTarget and cachedAimTarget.Parent.Name or "NONE")
    for i, npc in ipairs(NpcCache) do
        if i > 10 then print("... and " .. (#NpcCache - 10) .. " more") break end
        local hum = npc:FindFirstChildOfClass("Humanoid")
        print(i .. ". " .. npc.Name .. " | HP:" .. math.floor(hum and hum.Health or 0))
    end
    print("=== END ===")
    notify("NPC Count", #NpcCache .. " NPCs cached")
end, true)

-- View / POV
section(ViewT, "Field of View (FOV)", 0)
toggle(ViewT, "Enable FOV Override", "fovEnabled", 24, function(v)
    if not v then CAM.FieldOfView = 70 end
    notify("FOV " .. (v and "ON" or "OFF"), v and ("FOV: " .. S.fovValue) or "Reset to 70")
end)
slider(ViewT, "FOV Value", 40, 120, S.fovValue, 68, function(v)
    S.fovValue = v
    if S.fovEnabled then CAM.FieldOfView = v end
end)
section(ViewT, "Camera Zoom", 128)
toggle(ViewT, "Enable Zoom Override", "zoomEnabled", 152, function(v)
    if v then
        LP.CameraMaxZoomDistance = S.zoomDist
        LP.CameraMinZoomDistance = S.minZoom
    else
        LP.CameraMaxZoomDistance = 128
        LP.CameraMinZoomDistance = 0.5
    end
end)
slider(ViewT, "Max Zoom Distance", 12, 200, S.zoomDist, 196, function(v)
    S.zoomDist = v
    if S.zoomEnabled then LP.CameraMaxZoomDistance = v end
end)
slider(ViewT, "Min Zoom (0 = first person)", 0, 12, S.minZoom, 256, function(v)
    S.minZoom = v
    if S.zoomEnabled then LP.CameraMinZoomDistance = v end
end)
section(ViewT, "Presets", 316)
button(ViewT, "WIDE (FOV 100 + Zoom 50)", 340, function()
    S.fovValue = 100
    S.fovEnabled = true
    CAM.FieldOfView = 100
    S.zoomDist = 50
    S.zoomEnabled = true
    LP.CameraMaxZoomDistance = 50
    notify("Wide View", "FOV 100 · Zoom 50")
end, true)
button(ViewT, "DEFAULT", 384, function()
    S.fovValue = 70
    S.fovEnabled = false
    CAM.FieldOfView = 70
    S.zoomDist = 12
    S.zoomEnabled = false
    LP.CameraMaxZoomDistance = 128
    notify("Reset", "Default view")
end)

-- Style
section(StyleT, "ESP Color", 0)
local swatchRow = Instance.new("Frame", StyleT)
swatchRow.Position = UDim2.new(0, 0, 0, 24)
swatchRow.Size = UDim2.new(1, 0, 0, 44)
swatchRow.BackgroundColor3 = C.panel2
swatchRow.BorderSizePixel = 0
Instance.new("UICorner", swatchRow).CornerRadius = UDim.new(0, 8)
local SWATCHES = {C.red, C.purple, C.cyan, C.green, C.gold, C.pink, C.white, C.orange}
local swatchBtns = {}
local function selectSwatch(i)
    S.color = SWATCHES[i]
    applyStyleToAll()
    for j, btn in ipairs(swatchBtns) do
        if j == i then btn.UIStroke.Transparency = 0 btn.UIStroke.Thickness = 2
        else btn.UIStroke.Transparency = 0.7 btn.UIStroke.Thickness = 1 end
    end
end
for i, col in ipairs(SWATCHES) do
    local b = Instance.new("TextButton", swatchRow)
    b.Position = UDim2.new(0, 12 + (i - 1) * 40, 0, 10)
    b.Size = UDim2.new(0, 24, 0, 24)
    b.BackgroundColor3 = col
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", b)
    s.Color = C.white
    s.Thickness = 1
    s.Transparency = 0.7
    b.MouseButton1Click:Connect(function() selectSwatch(i) end)
    swatchBtns[i] = b
end
selectSwatch(1)
section(StyleT, "Appearance", 78)
slider(StyleT, "Fill Transparency", 0, 1, S.fillTrans, 102, function(v)
    S.fillTrans = v
    for _, d in pairs(PD) do if d.hl then d.hl.FillTransparency = v end end
end)
slider(StyleT, "Outline Transparency", 0, 1, S.outlineTrans, 162, function(v)
    S.outlineTrans = v
    for _, d in pairs(PD) do if d.hl then d.hl.OutlineTransparency = v end end
end)
slider(StyleT, "Text Size", 8, 20, S.textSize, 222, function(v)
    S.textSize = v
    for _, d in pairs(PD) do if d.nameLbl then d.nameLbl.TextSize = v end end
end)
slider(StyleT, "Max Distance", 100, 5000, S.maxDist, 282, function(v) S.maxDist = v end)

-- Settings
section(SettingsT, "System", 0)
toggle(SettingsT, "Anti-AFK", "antiAfk", 24)
toggle(SettingsT, "Full Bright", "fullBright", 70, function(v)
    if v then
        LT.Ambient = Color3.fromRGB(255,255,255)
        LT.OutdoorAmbient = Color3.fromRGB(255,255,255)
        LT.Brightness = 2
        LT.ClockTime = 14
        LT.FogEnd = 1e6
    end
end)
section(SettingsT, "Actions", 122)
button(SettingsT, "RESET ALL", 146, function()
    for p, _ in pairs(PD) do removeESP(p) end
    for obj, _ in pairs(LootCache) do removeLoot(obj) end
    S.enabled = false
    S.lootEnabled = false
    S.aimEnabled = false
    if FOVCircle then FOVCircle.Visible = false end
    if aimHighlight then aimHighlight.Enabled = false end
    notify("Reset", "All cleared")
end)
button(SettingsT, "HIDE TO GHOSTFACE", 190, minimizeToGhost)
button(SettingsT, "DESTROY UI", 234, function()
    gui:Destroy() wmGui:Destroy() notifGui:Destroy() tracerGui:Destroy() miniGui:Destroy() blur:Destroy()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    if aimHighlight then aimHighlight:Destroy() end
    pcall(function() RunService:UnbindFromRenderStep("RJ_AimWrite") end)
end)

-- Loops
local frameCount, lastFps, fps = 0, 0, 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFps >= 1 then fps = frameCount frameCount = 0 lastFps = now end
end)

local lastUpdate = 0
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastUpdate < 0.05 then return end
    lastUpdate = now
    if not S.enabled then
        for p, _ in pairs(PD) do removeESP(p) end
        return
    end
    local lhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local d = PD[p]
            if d and d.char ~= p.Character then removeESP(p) d = nil end
            if not d then pcall(createESP, p) pcall(buildRow, p) d = PD[p] end
            if d then
                local root = getRoot(p)
                local hum = getHum(p)
                if root and hum then
                    local dist = lhrp and math.floor(dist3(lhrp.Position, root.Position)) or 0
                    if dist > S.maxDist then removeESP(p)
                    else
                        count = count + 1
                        if d.distLbl then d.distLbl.Text = tostring(dist) .. "s" end
                        if d.hpFill then
                            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            d.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                            d.hpFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(240*pct), 100)
                        end
                        if d.tracer then
                            local sp, on = CAM:WorldToViewportPoint(root.Position)
                            if on then
                                local origin = Vector2.new(CAM.ViewportSize.X/2, CAM.ViewportSize.Y)
                                local target = Vector2.new(sp.X, sp.Y)
                                local delta = target - origin
                                local len = delta.Magnitude
                                local angle = math.deg(math.atan2(delta.Y, delta.X))
                                d.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
                                d.tracer.Size = UDim2.fromOffset(len, 1)
                                d.tracer.Rotation = angle
                                d.tracer.Visible = true
                            else d.tracer.Visible = false end
                        end
                        if d.rowDist then d.rowDist.Text = tostring(dist) .. "m" end
                        if d.rowFill then
                            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            d.rowFill.Size = UDim2.new(pct, 0, 1, 0)
                            d.rowFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(240*pct), 100)
                        end
                    end
                end
            end
        end
    end
    listCount.Text = count .. " players tracked"
    sText.Text = "[" .. (S.enabled and "active" or "idle") .. "] · " .. count .. "p · NPCs:" .. #NpcCache .. (cachedAimTarget and " · TARGET:" .. cachedAimTarget.Parent.Name or "")
end)

RunService.Heartbeat:Connect(function()
    if not S.lootEnabled then
        for obj, _ in pairs(LootCache) do removeLoot(obj) end
        return
    end
    pcall(scanLoot)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        for obj, d in pairs(LootCache) do
            if obj.Parent and d.distLbl then
                local a = lootAnchor(obj)
                if a then d.distLbl.Text = math.floor((hrp.Position - a.Position).Magnitude) .. "m" end
            end
        end
    end
end)

-- FOV Circle
pcall(function()
    local Drawing = (getgenv and getgenv().Drawing) or Drawing
    if Drawing and Drawing.new then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 60
        FOVCircle.Radius = S.aimFOV
        FOVCircle.Filled = false
        FOVCircle.Transparency = 0.7
        FOVCircle.Color = C.purple
        FOVCircle.Visible = false
        FOVCircle.ZIndex = 999
    end
end)

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        if S.aimEnabled and S.showFOV then
            FOVCircle.Visible = true
            FOVCircle.Position = Vector2.new(CAM.ViewportSize.X / 2, CAM.ViewportSize.Y / 2)
            FOVCircle.Radius = S.aimFOV
        else
            FOVCircle.Visible = false
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local n = 0
            for _ in pairs(PD) do n = n + 1 end
            local l = 0
            for _ in pairs(LootCache) do l = l + 1 end
            wmText.Text = "RedJ03N · " .. n .. "p · " .. l .. "loot · " .. #NpcCache .. "npc · " .. fps .. "fps"
        end)
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == S.keybind then
        if S.uiVisible then minimizeToGhost() else restoreFromGhost() end
    end
end)

Main.MouseEnter:Connect(function()
    blur.Enabled = true
    TW:Create(blur, TweenInfo.new(0.25), {Size = 12}):Play()
end)
Main.MouseLeave:Connect(function()
    TW:Create(blur, TweenInfo.new(0.25), {Size = 0}):Play()
    task.delay(0.3, function() if blur.Size < 1 then blur.Enabled = false end end)
end)

LP.Idled:Connect(function()
    if S.antiAfk then
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if S.enabled then pcall(createESP, p) pcall(buildRow, p) end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    if p.Character then removeLoot(p.Character) end
end)

ESPT.Visible = true
Tabs["ESP"].Btn.BackgroundColor3 = C.panel2
Tabs["ESP"].Btn.TextColor3 = C.purple

task.wait(0.3)
notify("RedJ03N ESP Pro", "Loaded · aimbot fixed · View tab added")
