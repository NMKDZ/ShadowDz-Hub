-- language: Lua, executor: Xeno / Wave / Solara / any UNC L7+
-- target: Break and Steal an Egg (Roblox)
-- ShadowDz Hub — by MK 💜

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
--  THỬ LOAD HUB NGOÀI
-- ════════════════════════════════════════
local hubLoaded = false

local hubs = {
    {
        name = "Miranda Hub",
        url  = "https://raw.githubusercontent.com/miirandahub/loader/refs/heads/main/stealaegg",
    },
    {
        name = "Solix Hub",
        url  = "https://raw.githubusercontent.com/porqueijjmzm1/cool/main/StealAEgg",
    },
}

task.spawn(function()
    for _, hub in ipairs(hubs) do
        local ok = pcall(function()
            loadstring(game:HttpGet(hub.url))()
        end)
        if ok then
            hubLoaded = true
            Notify(hub.name .. " loaded ✓")
            break
        end
        task.wait(0.5)
    end
    if not hubLoaded then
        Notify("Hub ngoài offline — ShadowDz standalone ✓")
    end
end)

task.wait(2)

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════
local cfg = {
    AntiRagdoll  = false,
    Godmode      = false,
    Noclip       = false,
    AntiAFK      = true,
    ESP          = false,
    SpeedHack    = false,
    WalkSpeed    = 40,
    AutoSteal    = false,
    EggAura      = false,
    AuraRadius   = 30,
    StealDelay   = 5,
    AutoHatch    = false,
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
--  ANTI-AFK
-- ════════════════════════════════════════
lp.Idled:Connect(function()
    if cfg.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ════════════════════════════════════════
--  EGG DETECTION
-- ════════════════════════════════════════
local function findEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find("egg") or n:find("trung")) and obj:IsA("BasePart") then
            table.insert(eggs, obj)
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
    lastESP = now
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hrpE = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrpE then
                local bb = Instance.new("BillboardGui", hrpE)
                bb.Size        = UDim2.new(0, 130, 0, 44)
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.AlwaysOnTop = true
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size                   = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3             = Color3.fromRGB(255, 80, 80)
                lbl.TextStrokeTransparency = 0
                lbl.Font                   = Enum.Font.GothamBold
                lbl.TextScaled             = true
                lbl.Text                   = "👤 " .. plr.Name
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
        if obj:IsA("StringValue") and obj.Name == "Ragdoll" then
            obj:Destroy()
        end
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
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
end

local function RemoveGodmode(c)
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = 100
    hum.Health    = 100
end

-- ════════════════════════════════════════
--  RENDER LOOP
-- ════════════════════════════════════════
local lastAura = 0

RunService:BindToRenderStep("ShadowDzMain", Enum.RenderPriority.Character.Value + 1, function()
    local c = lp.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")

    if cfg.SpeedHack and hum then
        hum.WalkSpeed = math.min(cfg.WalkSpeed, 60)
    end

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
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
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
SG.Name = "ShadowDzHub"
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.ResetOnSpawn = false
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = lp.PlayerGui end

-- ── MAIN PANEL ───────────────────────────
local Panel = Instance.new("Frame", SG)
Panel.Name             = "Panel"
Panel.Size             = UDim2.new(0, 234, 0, 490)
Panel.Position         = UDim2.new(0, 10, 0, 10)
Panel.BackgroundColor3 = Color3.fromRGB(10, 9, 16)
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)
local PS = Instance.new("UIStroke", Panel)
PS.Color = Color3.fromRGB(70, 40, 130); PS.Thickness = 1.5

-- shadow glow
local Glow = Instance.new("ImageLabel", Panel)
Glow.Size               = UDim2.new(1, 30, 1, 30)
Glow.Position           = UDim2.new(0, -15, 0, -15)
Glow.BackgroundTransparency = 1
Glow.Image              = "rbxassetid://6014261993"
Glow.ImageColor3        = Color3.fromRGB(80, 0, 160)
Glow.ImageTransparency  = 0.7
Glow.ZIndex             = -1
Glow.ScaleType          = Enum.ScaleType.Slice
Glow.SliceCenter        = Rect.new(49, 49, 450, 450)

-- ── TITLE BAR ────────────────────────────
local TBar = Instance.new("Frame", Panel)
TBar.Size             = UDim2.new(1, 0, 0, 44)
TBar.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
TBar.BorderSizePixel  = 0
local TFix = Instance.new("Frame", TBar)
TFix.Size = UDim2.new(1,0,0.5,0); TFix.Position = UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3 = Color3.fromRGB(16,12,28); TFix.BorderSizePixel = 0

-- accent line bên trái title
local Accent = Instance.new("Frame", TBar)
Accent.Size             = UDim2.new(0, 3, 0, 26)
Accent.Position         = UDim2.new(0, 8, 0.5, -13)
Accent.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
Accent.BorderSizePixel  = 0
Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

local TLbl = Instance.new("TextLabel", TBar)
TLbl.Size                   = UDim2.new(1, -76, 1, 0)
TLbl.Position               = UDim2.new(0, 18, 0, 0)
TLbl.BackgroundTransparency = 1
TLbl.Text                   = "🖤 ShadowDz"
TLbl.TextColor3             = Color3.fromRGB(210, 170, 255)
TLbl.Font                   = Enum.Font.GothamBold
TLbl.TextSize               = 14
TLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- close
local CB = Instance.new("TextButton", TBar)
CB.Size = UDim2.new(0,28,0,28); CB.Position = UDim2.new(1,-34,0.5,-14)
CB.BackgroundColor3 = Color3.fromRGB(180,35,55)
CB.Text = "✕"; CB.TextColor3 = Color3.fromRGB(255,255,255)
CB.Font = Enum.Font.GothamBold; CB.TextSize = 13; CB.BorderSizePixel = 0
Instance.new("UICorner", CB).CornerRadius = UDim.new(0,6)
CB.MouseButton1Click:Connect(function()
    RunService:UnbindFromRenderStep("ShadowDzMain")
    disableNoclip(); clearESP(); SG:Destroy()
end)

-- minimize
local MB = Instance.new("TextButton", TBar)
MB.Size = UDim2.new(0,28,0,28); MB.Position = UDim2.new(1,-66,0.5,-14)
MB.BackgroundColor3 = Color3.fromRGB(40,30,70)
MB.Text = "─"; MB.TextColor3 = Color3.fromRGB(180,150,240)
MB.Font = Enum.Font.GothamBold; MB.TextSize = 13; MB.BorderSizePixel = 0
Instance.new("UICorner", MB).CornerRadius = UDim.new(0,6)

local Content = Instance.new("Frame", Panel)
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -44)
Content.Position = UDim2.new(0, 0, 0, 44)
Content.BackgroundTransparency = 1

local minimized = false
MB.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    TweenService:Create(Panel, TweenInfo.new(0.18), {
        Size = minimized
            and UDim2.new(0, 234, 0, 44)
            or  UDim2.new(0, 234, 0, 490),
    }):Play()
end)

-- drag
local drag, ds, sp
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag=true; ds=i.Position; sp=Panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        Panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)

-- ── SECTION LABEL ────────────────────────
local function mkSec(yPos, txt)
    local L = Instance.new("TextLabel", Content)
    L.Size = UDim2.new(1,-16,0,16); L.Position = UDim2.new(0,8,0,yPos)
    L.BackgroundTransparency = 1; L.Text = txt
    L.TextColor3 = Color3.fromRGB(110,80,180)
    L.Font = Enum.Font.GothamBold; L.TextSize = 10
    L.TextXAlignment = Enum.TextXAlignment.Left
end

-- ── TOGGLE ───────────────────────────────
local function mkT(yPos, label, key, onEn, onDis)
    local Row = Instance.new("Frame", Content)
    Row.Size = UDim2.new(1,-16,0,36); Row.Position = UDim2.new(0,8,0,yPos)
    Row.BackgroundColor3 = Color3.fromRGB(18,14,30); Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local RS = Instance.new("UIStroke", Row)
    RS.Color = Color3.fromRGB(50,35,85); RS.Thickness = 1

    local L = Instance.new("TextLabel", Row)
    L.Size = UDim2.new(1,-54,1,0); L.Position = UDim2.new(0,10,0,0)
    L.BackgroundTransparency = 1; L.Text = label
    L.TextColor3 = Color3.fromRGB(200,185,220)
    L.Font = Enum.Font.Gotham; L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left

    local Pill = Instance.new("Frame", Row)
    Pill.Size = UDim2.new(0,42,0,22); Pill.Position = UDim2.new(1,-50,0.5,-11)
    Pill.BackgroundColor3 = Color3.fromRGB(38,28,60); Pill.BorderSizePixel = 0
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size = UDim2.new(0,16,0,16); Knob.Position = UDim2.new(0,3,0.5,-8)
    Knob.BackgroundColor3 = Color3.fromRGB(140,120,180); Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local state = cfg[key]
    local function ref()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position         = state and UDim2.new(0,23,0.5,-8) or UDim2.new(0,3,0.5,-8),
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
        Notify(label .. ": " .. (state and "ON ✓" or "OFF ✗"))
    end)
end

-- ── BUILD ────────────────────────────────
mkSec(8,   "── PROTECT ──")
mkT(24,  "🛡️ Chống Ragdoll", "AntiRagdoll",
    function() if lp.Character then ApplyAntiRagdoll(lp.Character) end end,
    function() if lp.Character then RemoveAntiRagdoll(lp.Character) end end)
mkT(66,  "💀 Bất Tử",        "Godmode",
    function() if lp.Character then ApplyGodmode(lp.Character) end end,
    function() if lp.Character then RemoveGodmode(lp.Character) end end)

mkSec(112, "── MOVE ──")
mkT(128, "👻 Noclip",     "Noclip",    enableNoclip, disableNoclip)
mkT(170, "⚡ Speed Hack", "SpeedHack", nil, nil)

mkSec(216, "── UTIL ──")
mkT(232, "💤 Anti AFK",   "AntiAFK",  nil, nil)
mkT(274, "👁️ Player ESP", "ESP",      nil, function() clearESP() end)

mkSec(320, "── STEAL ──")
mkT(336, "🥚 Auto Steal", "AutoSteal", startAutoSteal, nil)
mkT(378, "🌀 Egg Aura",   "EggAura",   nil, nil)
mkT(420, "🐣 Auto Hatch", "AutoHatch", startAutoHatch, nil)

-- ── CREDIT BAR ───────────────────────────
local CreditBar = Instance.new("Frame", Panel)
CreditBar.Size             = UDim2.new(1, 0, 0, 24)
CreditBar.Position         = UDim2.new(0, 0, 1, -24)
CreditBar.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
CreditBar.BorderSizePixel  = 0

local CreditLbl = Instance.new("TextLabel", CreditBar)
CreditLbl.Size                   = UDim2.new(1, 0, 1, 0)
CreditLbl.BackgroundTransparency = 1
CreditLbl.Text                   = "🖤 ShadowDz  •  by MK 💜"
CreditLbl.TextColor3             = Color3.fromRGB(130, 90, 200)
CreditLbl.Font                   = Enum.Font.GothamBold
CreditLbl.TextSize               = 11
CreditLbl.TextXAlignment         = Enum.TextXAlignment.Center

-- ════════════════════════════════════════
--  BOOT
-- ════════════════════════════════════════
Notify("🖤 ShadowDz loaded  •  by MK 💜")
task.wait(4)
Notify("MK Thich Em 💜")
task.wait(5)
Notify("MK Yeu Em 💜")
print("ShadowDz Hub — by MK 💜")