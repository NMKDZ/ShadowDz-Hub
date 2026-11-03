-- language: Lua, executor: Xeno / Wave / Solara / any UNC L7+
-- target: Break and Steal an Egg (Roblox)
-- ShadowDz Hub v3 — by MK 💜
-- GUI to giống Chilli Hub, chọn khu vực / độ hiếm / pet

-- ════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local lp               = Players.LocalPlayer
local char             = lp.Character or lp.CharacterAdded:Wait()
local hrp              = char:WaitForChild("HumanoidRootPart")

-- ════════════════════════════════════════
--  NOTIFY
-- ════════════════════════════════════════
local function Notify(msg)
    task.spawn(function()
        for i = 1, 10 do
            local ok = pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title    = "ShadowDz",
                    Text     = msg,
                    Icon     = "rbxassetid://122052941282436",
                    Duration = 5,
                })
            end)
            if ok then return end
            task.wait(1)
        end
    end)
end

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local cfg = {
    -- toggles
    AutoSteal    = false,
    EggAura      = false,
    AutoHatch    = false,
    AntiRagdoll  = false,
    Godmode      = false,
    Noclip       = false,
    AntiAFK      = true,
    ESP          = false,
    SpeedHack    = false,
    -- values
    WalkSpeed    = 40,
    AuraRadius   = 30,
    StealDelay   = 5,
    -- filters
    TargetZone   = "Tất cả",   -- khu vực
    TargetRarity = "Tất cả",   -- độ hiếm
    TargetPet    = "Tất cả",   -- pet
}

-- zone / rarity / pet lists — dj cập nhật theo game thật
local ZONES = {
    "Tất cả", "Zone 1", "Zone 2", "Zone 3",
    "Zone 4", "Zone 5", "Boss Zone",
}
local RARITIES = {
    "Tất cả", "Common", "Uncommon", "Rare",
    "Epic", "Legendary", "Mythic", "Secret",
}
local PETS = {
    "Tất cả", "Cat", "Dog", "Dragon",
    "Phoenix", "Unicorn", "Shadow", "Golden",
}

-- ════════════════════════════════════════
--  UTILITY
-- ════════════════════════════════════════
local function getRoot()
    char = lp.Character
    if char then hrp = char:FindFirstChild("HumanoidRootPart") end
    return hrp
end

local function smoothTP(root, targetPos, steps)
    steps = steps or 8
    local origin = root.CFrame.Position
    for i = 1, steps do
        if not root or not root.Parent then return end
        root.CFrame = CFrame.new(origin:Lerp(targetPos, i / steps))
        task.wait(0.03)
    end
end

-- ════════════════════════════════════════
--  EGG FILTER — zone / rarity / pet
-- ════════════════════════════════════════
local function eggPassFilter(egg)
    local n = egg.Name:lower()

    -- rarity filter
    if cfg.TargetRarity ~= "Tất cả" then
        local r = cfg.TargetRarity:lower()
        if not n:find(r) then
            -- check attribute
            local attr = egg:GetAttribute("Rarity") or egg:GetAttribute("rarity")
            if not attr or tostring(attr):lower() ~= r then
                return false
            end
        end
    end

    -- pet filter
    if cfg.TargetPet ~= "Tất cả" then
        local p = cfg.TargetPet:lower()
        if not n:find(p) then
            local attr = egg:GetAttribute("Pet") or egg:GetAttribute("pet")
            if not attr or tostring(attr):lower():find(p) == nil then
                return false
            end
        end
    end

    return true
end

local function findEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("egg") or n:find("trung")) and obj:IsA("BasePart") then
            -- zone filter: check parent folder name
            if cfg.TargetZone ~= "Tất cả" then
                local zoneName = cfg.TargetZone:lower()
                local parent   = obj.Parent
                local inZone   = false
                while parent and parent ~= workspace do
                    if parent.Name:lower():find(zoneName) then
                        inZone = true; break
                    end
                    parent = parent.Parent
                end
                if not inZone then
                    -- fallback: check attribute
                    local attr = obj:GetAttribute("Zone") or obj:GetAttribute("zone")
                    if attr and tostring(attr):lower():find(zoneName) then
                        inZone = true
                    end
                end
                if not inZone then continue end
            end
            if eggPassFilter(obj) then
                table.insert(eggs, obj)
            end
        end
    end
    return eggs
end

-- ════════════════════════════════════════
--  AUTO STEAL
-- ════════════════════════════════════════
local function startAutoSteal()
    task.spawn(function()
        while cfg.AutoSteal do
            local root = getRoot()
            if root then
                local eggs = findEggs()
                table.sort(eggs, function(a, b)
                    return (a.Position - root.Position).Magnitude
                         > (b.Position - root.Position).Magnitude
                end)
                for _, egg in ipairs(eggs) do
                    if not cfg.AutoSteal then break end
                    smoothTP(root, egg.Position + Vector3.new(0, 3, 0))
                    task.wait(cfg.StealDelay * 0.1)
                    pcall(function()
                        firetouchinterest(root, egg, 0)
                        task.wait(0.05)
                        firetouchinterest(root, egg, 1)
                    end)
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ════════════════════════════════════════
--  AUTO HATCH
-- ════════════════════════════════════════
local function startAutoHatch()
    task.spawn(function()
        while cfg.AutoHatch do
            for _, obj in ipairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if n:find("hatch") or n:find("incub") or n:find("ap") then
                    local root = getRoot()
                    if root and obj:IsA("BasePart") then
                        smoothTP(root, obj.Position + Vector3.new(0, 3, 0))
                        task.wait(0.3)
                        pcall(function()
                            firetouchinterest(root, obj, 0)
                            task.wait(0.05)
                            firetouchinterest(root, obj, 1)
                        end)
                    end
                end
            end
            task.wait(2)
        end
    end)
end

-- ════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════
local noclipConn
local function enableNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        local c = lp.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local c = lp.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local espObjects = {}
local lastESP    = 0
local function clearESP()
    for _, o in pairs(espObjects) do pcall(function() o:Destroy() end) end
    espObjects = {}
end
local function updateESP()
    local now = tick()
    if now - lastESP < 1 then return end
    lastESP = now; clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hrpE = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrpE then
                local bb = Instance.new("BillboardGui", hrpE)
                bb.Size = UDim2.new(0,140,0,46)
                bb.StudsOffset = Vector3.new(0,3.5,0)
                bb.AlwaysOnTop = true
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.fromRGB(255,80,80)
                lbl.TextStrokeTransparency = 0
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                lbl.Text = "👤 "..plr.Name
                table.insert(espObjects, bb)
            end
        end
    end
end

-- ════════════════════════════════════════
--  ANTI-RAGDOLL
-- ════════════════════════════════════════
local function ApplyAntiRagdoll(c)
    for _, obj in ipairs(c:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
            obj.Enabled = false
        end
        if obj:IsA("StringValue") and obj.Name == "Ragdoll" then obj:Destroy() end
    end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   false)
        hum.BreakJointsOnDeath = false
    end
end
local function RemoveAntiRagdoll(c)
    for _, obj in ipairs(c:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
            obj.Enabled = true
        end
    end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,   true)
        hum.BreakJointsOnDeath = true
    end
end

-- ════════════════════════════════════════
--  GODMODE
-- ════════════════════════════════════════
local function ApplyGodmode(c)
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = math.huge; hum.Health = math.huge
end
local function RemoveGodmode(c)
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = 100; hum.Health = 100
end

-- ════════════════════════════════════════
--  RENDER LOOP
-- ════════════════════════════════════════
local lastAura = 0
RunService:BindToRenderStep("ShadowDzMain", Enum.RenderPriority.Character.Value + 1, function()
    local c = lp.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")

    if cfg.SpeedHack and hum then hum.WalkSpeed = math.min(cfg.WalkSpeed, 60) end

    if cfg.EggAura then
        local now = tick()
        if now - lastAura >= 0.4 then
            lastAura = now
            local root = getRoot()
            if root then
                for _, egg in ipairs(findEggs()) do
                    if (egg.Position - root.Position).Magnitude <= cfg.AuraRadius then
                        pcall(function()
                            firetouchinterest(root, egg, 0)
                            task.wait(0.02)
                            firetouchinterest(root, egg, 1)
                        end)
                    end
                end
            end
        end
    end

    if cfg.ESP then updateESP() end

    if hum then
        if cfg.AntiRagdoll then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        if cfg.Godmode then
            if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
            if hum:GetState() == Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

lp.CharacterAdded:Connect(function(c)
    c:WaitForChild("HumanoidRootPart", 5)
    if cfg.AntiRagdoll then ApplyAntiRagdoll(c) end
    if cfg.Godmode     then ApplyGodmode(c)     end
    if cfg.Noclip      then task.wait(0.5) enableNoclip() end
    Notify("Respawn OK ✓")
end)
if lp.Character then
    if cfg.AntiRagdoll then ApplyAntiRagdoll(lp.Character) end
    if cfg.Godmode     then ApplyGodmode(lp.Character)     end
end

-- ════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════
local old = game:GetService("CoreGui"):FindFirstChild("ShadowDzHub")
    or lp.PlayerGui:FindFirstChild("ShadowDzHub")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "ShadowDzHub"; SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.ResetOnSpawn = false
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = lp.PlayerGui end

-- ── MAIN FRAME — rộng như Chilli Hub ─────
local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 460, 0, 560)
Main.Position = UDim2.new(0.5, -230, 0.5, -280)
Main.BackgroundColor3 = Color3.fromRGB(10, 9, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MS = Instance.new("UIStroke", Main)
MS.Color = Color3.fromRGB(70,40,130); MS.Thickness = 1.5

local Glow = Instance.new("ImageLabel", Main)
Glow.Size = UDim2.new(1,40,1,40); Glow.Position = UDim2.new(0,-20,0,-20)
Glow.BackgroundTransparency = 1; Glow.Image = "rbxassetid://6014261993"
Glow.ImageColor3 = Color3.fromRGB(80,0,160); Glow.ImageTransparency = 0.7
Glow.ZIndex = -1; Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(49,49,450,450)

-- ── TITLE BAR ────────────────────────────
local TBar = Instance.new("Frame", Main)
TBar.Size = UDim2.new(1,0,0,48); TBar.BackgroundColor3 = Color3.fromRGB(16,12,28)
TBar.BorderSizePixel = 0
local TFix = Instance.new("Frame", TBar)
TFix.Size = UDim2.new(1,0,0.5,0); TFix.Position = UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3 = Color3.fromRGB(16,12,28); TFix.BorderSizePixel = 0

local AccentLine = Instance.new("Frame", TBar)
AccentLine.Size = UDim2.new(0,3,0,28)
AccentLine.Position = UDim2.new(0,10,0.5,-14)
AccentLine.BackgroundColor3 = Color3.fromRGB(140,60,255)
AccentLine.BorderSizePixel = 0
Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1,0)

local TLbl = Instance.new("TextLabel", TBar)
TLbl.Size = UDim2.new(1,-100,1,0); TLbl.Position = UDim2.new(0,22,0,0)
TLbl.BackgroundTransparency = 1
TLbl.Text = "🖤 ShadowDz Hub  /  Steal an Egg"
TLbl.TextColor3 = Color3.fromRGB(210,170,255)
TLbl.Font = Enum.Font.GothamBold; TLbl.TextSize = 14
TLbl.TextXAlignment = Enum.TextXAlignment.Left

local CB = Instance.new("TextButton", TBar)
CB.Size = UDim2.new(0,30,0,30); CB.Position = UDim2.new(1,-38,0.5,-15)
CB.BackgroundColor3 = Color3.fromRGB(180,35,55); CB.Text = "✕"
CB.TextColor3 = Color3.fromRGB(255,255,255); CB.Font = Enum.Font.GothamBold
CB.TextSize = 13; CB.BorderSizePixel = 0
Instance.new("UICorner", CB).CornerRadius = UDim.new(0,6)
CB.MouseButton1Click:Connect(function()
    RunService:UnbindFromRenderStep("ShadowDzMain")
    disableNoclip(); clearESP(); SG:Destroy()
end)

local MB = Instance.new("TextButton", TBar)
MB.Size = UDim2.new(0,30,0,30); MB.Position = UDim2.new(1,-72,0.5,-15)
MB.BackgroundColor3 = Color3.fromRGB(40,30,70); MB.Text = "─"
MB.TextColor3 = Color3.fromRGB(180,150,240); MB.Font = Enum.Font.GothamBold
MB.TextSize = 13; MB.BorderSizePixel = 0
Instance.new("UICorner", MB).CornerRadius = UDim.new(0,6)

-- drag
local drag, ds, sp
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag=true; ds=i.Position; sp=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position-ds
        Main.Position = UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)

-- ── TAB BAR ──────────────────────────────
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1,0,0,38); TabBar.Position = UDim2.new(0,0,0,48)
TabBar.BackgroundColor3 = Color3.fromRGB(14,10,24); TabBar.BorderSizePixel = 0
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0,4)
Instance.new("UIPadding", TabBar).PaddingLeft = UDim.new(0,8)

-- ── CONTENT ──────────────────────────────
local ContentArea = Instance.new("Frame", Main)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1,0,1,-86)
ContentArea.Position = UDim2.new(0,0,0,86)
ContentArea.BackgroundTransparency = 1

local minimized = false
MB.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentArea.Visible = not minimized
    TabBar.Visible = not minimized
    TweenService:Create(Main, TweenInfo.new(0.18), {
        Size = minimized and UDim2.new(0,460,0,48) or UDim2.new(0,460,0,560)
    }):Play()
end)

-- ── SCROLL TAB ───────────────────────────
local function makeTab(visible)
    local f = Instance.new("ScrollingFrame", ContentArea)
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundTransparency = 1
    f.ScrollBarThickness = 3
    f.ScrollBarImageColor3 = Color3.fromRGB(110,80,180)
    f.CanvasSize = UDim2.new(0,0,0,800)
    f.Visible = visible or false
    f.BorderSizePixel = 0
    return f
end

-- ── TOGGLE ───────────────────────────────
local function mkT(parent, yPos, label, key, onEn, onDis)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1,-20,0,42); Row.Position = UDim2.new(0,10,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(18,14,30); Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local RS = Instance.new("UIStroke", Row)
    RS.Color = Color3.fromRGB(50,35,85); RS.Thickness = 1

    local L = Instance.new("TextLabel", Row)
    L.Size = UDim2.new(1,-60,1,0); L.Position = UDim2.new(0,14,0,0)
    L.BackgroundTransparency = 1; L.Text = label
    L.TextColor3 = Color3.fromRGB(200,185,220)
    L.Font = Enum.Font.Gotham; L.TextSize = 13
    L.TextXAlignment = Enum.TextXAlignment.Left

    local Pill = Instance.new("Frame", Row)
    Pill.Size = UDim2.new(0,46,0,24); Pill.Position = UDim2.new(1,-56,0.5,-12)
    Pill.BackgroundColor3 = Color3.fromRGB(38,28,60); Pill.BorderSizePixel = 0
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,3,0.5,-9)
    Knob.BackgroundColor3 = Color3.fromRGB(140,120,180); Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local state = cfg[key]
    local function ref()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position         = state and UDim2.new(0,25,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3 = state and Color3.fromRGB(170,90,255) or Color3.fromRGB(140,120,180),
        }):Play()
        TweenService:Create(Pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(75,35,145) or Color3.fromRGB(38,28,60),
        }):Play()
        L.TextColor3 = state and Color3.fromRGB(195,145,255) or Color3.fromRGB(200,185,220)
    end
    ref()

    local HB = Instance.new("TextButton", Row)
    HB.Size = UDim2.new(1,0,1,0); HB.BackgroundTransparency = 1; HB.Text = ""
    HB.MouseButton1Click:Connect(function()
        state = not state; cfg[key] = state; ref()
        if state then if onEn  then onEn()  end
        else          if onDis then onDis() end end
        Notify(label..": "..(state and "ON ✓" or "OFF ✗"))
    end)
end

-- ── SECTION LABEL ────────────────────────
local function mkSec(parent, yPos, txt)
    local L = Instance.new("TextLabel", parent)
    L.Size = UDim2.new(1,-20,0,18); L.Position = UDim2.new(0,10,0,yPos)
    L.BackgroundTransparency = 1; L.Text = txt
    L.TextColor3 = Color3.fromRGB(120,85,200)
    L.Font = Enum.Font.GothamBold; L.TextSize = 11
    L.TextXAlignment = Enum.TextXAlignment.Left
end

-- ── DROPDOWN ─────────────────────────────
local activeDropdown = nil

local function mkDropdown(parent, yPos, label, cfgKey, options, onChange)
    local Row = Instance.new("Frame", parent)
    Row.Name = "DD_"..cfgKey
    Row.Size = UDim2.new(1,-20,0,42); Row.Position = UDim2.new(0,10,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(18,14,30); Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local RS = Instance.new("UIStroke", Row)
    RS.Color = Color3.fromRGB(50,35,85); RS.Thickness = 1

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(0.45,0,1,0); Lbl.Position = UDim2.new(0,14,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(170,150,210)
    Lbl.Font = Enum.Font.Gotham; Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValBtn = Instance.new("TextButton", Row)
    ValBtn.Size = UDim2.new(0.5,0,0,30); ValBtn.Position = UDim2.new(0.48,0,0.5,-15)
    ValBtn.BackgroundColor3 = Color3.fromRGB(28,20,48); ValBtn.BorderSizePixel = 0
    ValBtn.Text = cfg[cfgKey]; ValBtn.TextColor3 = Color3.fromRGB(195,145,255)
    ValBtn.Font = Enum.Font.GothamSemibold; ValBtn.TextSize = 12
    Instance.new("UICorner", ValBtn).CornerRadius = UDim.new(0,6)
    local VS = Instance.new("UIStroke", ValBtn)
    VS.Color = Color3.fromRGB(80,50,140); VS.Thickness = 1

    -- dropdown list
    local DDList = Instance.new("Frame", SG)
    DDList.Name = "DDList_"..cfgKey
    DDList.BackgroundColor3 = Color3.fromRGB(20,16,34)
    DDList.BorderSizePixel = 0; DDList.Visible = false; DDList.ZIndex = 20
    Instance.new("UICorner", DDList).CornerRadius = UDim.new(0,8)
    local DS = Instance.new("UIStroke", DDList)
    DS.Color = Color3.fromRGB(80,50,140); DS.Thickness = 1; DS.ZIndex = 20

    local itemH = 32
    DDList.Size = UDim2.new(0, 160, 0, math.min(#options, 6) * itemH + 8)

    for idx, opt in ipairs(options) do
        local item = Instance.new("TextButton", DDList)
        item.Size = UDim2.new(1,-8,0,itemH-2)
        item.Position = UDim2.new(0,4,0,(idx-1)*itemH+4)
        item.BackgroundColor3 = Color3.fromRGB(28,20,48)
        item.Text = opt; item.TextColor3 = Color3.fromRGB(200,180,230)
        item.Font = Enum.Font.Gotham; item.TextSize = 12
        item.BorderSizePixel = 0; item.ZIndex = 21
        Instance.new("UICorner", item).CornerRadius = UDim.new(0,6)
        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(55,35,100)
        end)
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(28,20,48)
        end)
        item.MouseButton1Click:Connect(function()
            cfg[cfgKey] = opt
            ValBtn.Text = opt
            DDList.Visible = false
            activeDropdown = nil
            if onChange then onChange(opt) end
        end)
    end

    ValBtn.MouseButton1Click:Connect(function()
        if activeDropdown and activeDropdown ~= DDList then
            activeDropdown.Visible = false
        end
        DDList.Visible = not DDList.Visible
        activeDropdown = DDList.Visible and DDList or nil
        -- position dưới ValBtn
        local abs = ValBtn.AbsolutePosition
        DDList.Position = UDim2.new(0, abs.X, 0, abs.Y + 34)
    end)

    return Row
end

-- ── SLIDER ───────────────────────────────
local function mkSlider(parent, yPos, label, key, minV, maxV)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1,-20,0,56); Row.Position = UDim2.new(0,10,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(18,14,30); Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local RS = Instance.new("UIStroke", Row)
    RS.Color = Color3.fromRGB(50,35,85); RS.Thickness = 1

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1,-10,0,24); Lbl.Position = UDim2.new(0,14,0,4)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label..": "..tostring(cfg[key])
    Lbl.TextColor3 = Color3.fromRGB(200,185,220)
    Lbl.Font = Enum.Font.Gotham; Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Track = Instance.new("Frame", Row)
    Track.Size = UDim2.new(1,-28,0,6); Track.Position = UDim2.new(0,14,0,36)
    Track.BackgroundColor3 = Color3.fromRGB(38,28,60); Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1,0)

    local pct = (cfg[key]-minV)/(maxV-minV)
    local Fill = Instance.new("Frame", Track)
    Fill.Size = UDim2.new(pct,0,1,0)
    Fill.BackgroundColor3 = Color3.fromRGB(130,60,220); Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)

    local Handle = Instance.new("TextButton", Track)
    Handle.Size = UDim2.new(0,14,0,14); Handle.Position = UDim2.new(pct,-7,0.5,-7)
    Handle.BackgroundColor3 = Color3.fromRGB(190,140,255)
    Handle.Text = ""; Handle.BorderSizePixel = 0
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1,0)

    local sliding = false
    Handle.MouseButton1Down:Connect(function() sliding = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local p = math.clamp(
                (i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + p*(maxV-minV))
            cfg[key] = v
            Fill.Size = UDim2.new(p,0,1,0)
            Handle.Position = UDim2.new(p,-7,0.5,-7)
            Lbl.Text = label..": "..tostring(v)
        end
    end)
end

-- ════════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════════
local tabNames = {"Tự Cày", "Farm", "Protect", "ESP", "Info"}
local tabBtns  = {}
local allTabs  = {}

-- Tab 1: Tự Cày
local t1 = makeTab(true)

mkSec(t1, 8, "── STEAL ──")
mkT(t1, 26, "🥚 Auto Steal",  "AutoSteal", startAutoSteal, nil)
mkT(t1, 76, "🌀 Egg Aura",    "EggAura",   nil, nil)
mkT(t1, 126,"🐣 Auto Hatch",  "AutoHatch", startAutoHatch, nil)
mkSlider(t1, 176, "Delay steal", "StealDelay", 1, 30)
mkSlider(t1, 240, "Aura radius", "AuraRadius", 10, 80)

mkSec(t1, 304, "── LỌC TRỨNG ──")
mkDropdown(t1, 322, "🗺️ Khu vực",  "TargetZone",   ZONES,    nil)
mkDropdown(t1, 372, "⭐ Độ hiếm",  "TargetRarity", RARITIES, nil)
mkDropdown(t1, 422, "🐾 Pet",      "TargetPet",    PETS,     nil)

-- Tab 2: Farm
local t2 = makeTab()
mkSec(t2, 8, "── MOVE ──")
mkT(t2, 26,  "⚡ Speed Hack", "SpeedHack", nil, nil)
mkSlider(t2, 76, "Walk Speed", "WalkSpeed", 16, 60)
mkT(t2, 140, "👻 Noclip",    "Noclip", enableNoclip, disableNoclip)
mkT(t2, 190, "💤 Anti AFK",  "AntiAFK", nil, nil)

-- Tab 3: Protect
local t3 = makeTab()
mkSec(t3, 8, "── PROTECT ──")
mkT(t3, 26, "🛡️ Chống Ragdoll", "AntiRagdoll",
    function() if lp.Character then ApplyAntiRagdoll(lp.Character) end end,
    function() if lp.Character then RemoveAntiRagdoll(lp.Character) end end)
mkT(t3, 76, "💀 Bất Tử",        "Godmode",
    function() if lp.Character then ApplyGodmode(lp.Character) end end,
    function() if lp.Character then RemoveGodmode(lp.Character) end end)

-- Tab 4: ESP
local t4 = makeTab()
mkSec(t4, 8, "── ESP ──")
mkT(t4, 26, "👁️ Player ESP", "ESP", nil, function() clearESP() end)

-- Tab 5: Info
local t5 = makeTab()
local InfoBox = Instance.new("TextLabel", t5)
InfoBox.Size = UDim2.new(1,-20,0,220); InfoBox.Position = UDim2.new(0,10,0,10)
InfoBox.BackgroundColor3 = Color3.fromRGB(18,14,30)
InfoBox.TextColor3 = Color3.fromRGB(170,140,220)
InfoBox.Font = Enum.Font.Gotham; InfoBox.TextSize = 12
InfoBox.TextWrapped = true; InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top
InfoBox.BorderSizePixel = 0
InfoBox.Text =
    "🖤 ShadowDz Hub v3  •  by MK 💜\n\n"..
    "Executor: Xeno / Wave / Solara\n"..
    "Game: Break and Steal an Egg\n\n"..
    "── Tips tránh ban ──\n"..
    "Delay steal ≥ 5 (0.5s)\n"..
    "Không bật Aura + AutoSteal cùng lúc\n"..
    "Speed ≤ 40 là an toàn nhất\n"..
    "Noclip ít bị detect hơn AutoSteal\n\n"..
    "── Filter ──\n"..
    "Chọn Zone / Rarity / Pet trước\n"..
    "rồi mới bật Auto Steal\n\n"..
    "MK Thich Em 💜  •  MK Yeu Em 💜"
Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0,8)
local IS = Instance.new("UIStroke", InfoBox)
IS.Color = Color3.fromRGB(50,35,85); IS.Thickness = 1

allTabs = {t1, t2, t3, t4, t5}

-- ── TAB BUTTONS ──────────────────────────
for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 82, 1, -8)
    btn.BackgroundColor3 = i == 1
        and Color3.fromRGB(65,40,125)
        or  Color3.fromRGB(26,20,44)
    btn.Text = name
    btn.TextColor3 = i == 1
        and Color3.fromRGB(220,185,255)
        or  Color3.fromRGB(150,130,185)
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 11
    btn.BorderSizePixel = 0; btn.LayoutOrder = i
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseButton1Click:Connect(function()
        for j, tab in ipairs(allTabs) do
            tab.Visible = (j == i)
            tabBtns[j].BackgroundColor3 = (j == i)
                and Color3.fromRGB(65,40,125)
                or  Color3.fromRGB(26,20,44)
            tabBtns[j].TextColor3 = (j == i)
                and Color3.fromRGB(220,185,255)
                or  Color3.fromRGB(150,130,185)
        end
        -- đóng dropdown khi đổi tab
        if activeDropdown then activeDropdown.Visible = false activeDropdown = nil end
    end)
    tabBtns[i] = btn
end

-- ── CREDIT BAR ───────────────────────────
local CreditBar = Instance.new("Frame", Main)
CreditBar.Size = UDim2.new(1,0,0,22); CreditBar.Position = UDim2.new(0,0,1,-22)
CreditBar.BackgroundColor3 = Color3.fromRGB(14,10,24); CreditBar.BorderSizePixel = 0

local CLbl = Instance.new("TextLabel", CreditBar)
CLbl.Size = UDim2.new(1,0,1,0); CLbl.BackgroundTransparency = 1
CLbl.Text = "🖤 ShadowDz  •  by MK 💜"
CLbl.TextColor3 = Color3.fromRGB(110,75,175)
CLbl.Font = Enum.Font.GothamBold; CLbl.TextSize = 11
CLbl.TextXAlignment = Enum.TextXAlignment.Center

-- ════════════════════════════════════════
--  BOOT
-- ════════════════════════════════════════
Notify("🖤 ShadowDz v3 loaded  •  by MK 💜")
task.wait(4)
Notify("MK Thich Em 💜")
task.wait(5)
Notify("MK Yeu Em 💜")
print("ShadowDz Hub v3 — by MK 💜")
