print("Library Loading Started")
local LoadingTick = os.clock()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/zanerBRUH/UwU-Ware/refs/heads/main/Libraries/Kiwisense.lua"))()

-- Services
local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

-- Configs
local MAIN_POS = Vector3.new(2823, 950, 1514)
local ALT_POS  = Vector3.new(1330.58, 876.74, -817.15)

local HOLD_E_TIME = 5
local WAIT_MAIN   = 25
local WAIT_ALT    = 25

local isMain = true
local pvpRunning = false
local infiniteJumpEnabled = false
local infiniteJumpConn = nil

-- Funções
local function Teleport(target)
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cf
    if typeof(target) == "Vector3" then
        cf = CFrame.new(target + Vector3.new(0, 5, 0))
    elseif typeof(target) == "CFrame" then
        cf = target
    elseif target:IsA("BasePart") then
        cf = target.CFrame
    elseif target:IsA("Model") and target.PrimaryPart then
        cf = target.PrimaryPart.CFrame
    else
        return
    end

    root.CFrame = cf
end

local function setupInfiniteJump(state)
    if infiniteJumpConn then infiniteJumpConn:Disconnect() infiniteJumpConn = nil end
    if state then
        infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
end

local function holdE(sec)
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(sec or 5)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function doCycle()
    if not pvpRunning then return end

    -- Pega valores reais dos FLAGS (mais confiável que :Get() em algumas versões)
    HOLD_E_TIME = tonumber(Library.Flags["holdESlider"]) or 5
    WAIT_MAIN   = tonumber(Library.Flags["waitMainSlider"]) or 25
    WAIT_ALT    = tonumber(Library.Flags["waitAltSlider"]) or 25

    -- Debug: evita NaN
    if HOLD_E_TIME ~= HOLD_E_TIME then HOLD_E_TIME = 5 end  -- se for NaN
    if WAIT_MAIN   ~= WAIT_MAIN   then WAIT_MAIN   = 25 end
    if WAIT_ALT    ~= WAIT_ALT    then WAIT_ALT    = 25 end

    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local targetPos = isMain and MAIN_POS or ALT_POS
    char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))

    task.wait(2.2)
    holdE(HOLD_E_TIME)

    if isMain then
        task.wait(WAIT_MAIN)
        task.spawn(doCycle)
    else
        task.wait(WAIT_ALT)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end

local function togglePVP(state)
    pvpRunning = state
    if state then task.spawn(doCycle) end
end

-- UI
local Window = Library:Window({
    Name = "REVO Hub by Sixh1 | Bizarre Lineage",
    Logo = "135215559087473",
    FadeSpeed = 0.25,
})

local MainPage = Window:Page({
    Name = "Main",
    Icon = "111178525804834",
    SubPages = true,
    Columns = 1,
})

local FarmsSub = MainPage:SubPage({ 
    Name = "Farms", 
    Icon = "111386589037485", 
    Columns = 2 
})

local FarmsSection = FarmsSub:Section({ Name = "PVP FARM", Side = 1 })
local SettingsSection = FarmsSub:Section({ Name = "PVP Settings", Side = 2 })

FarmsSection:Toggle({
    Name = "Ativar Auto PVP Farm",
    Flag = "pvpToggle",
    Default = false,
    Callback = togglePVP
})

FarmsSection:Toggle({
    Name = "Role: MAIN (clique para ALT)",
    Default = true,
    Callback = function(v) isMain = v end
})

-- Debug: Mostra valores atuais (atualiza manualmente ou via loop se quiser)
local HoldLabel = SettingsSection:Label("Hold E: 5s")
local MainLabel = SettingsSection:Label("Wait MAIN: 25s")
local AltLabel  = SettingsSection:Label("Wait ALT: 25s")

-- Sliders SEM callback (usa flags)
SettingsSection:Slider({
    Name = "Tempo Hold E (s)",
    Flag = "holdESlider",
    Min = 1, Max = 10, Default = 5, Decimals = 0, Suffix = "s"
})

SettingsSection:Slider({
    Name = "Espera MAIN (s)",
    Flag = "waitMainSlider",
    Min = 10, Max = 60, Default = 25, Decimals = 0, Suffix = "s"
})

SettingsSection:Slider({
    Name = "Espera ALT (s)",
    Flag = "waitAltSlider",
    Min = 10, Max = 60, Default = 25, Decimals = 0, Suffix = "s"
})

-- Botão pra atualizar labels (debug)
SettingsSection:Button({
    Name = "Atualizar Valores (Debug)",
    Callback = function()
        local h = Library.Flags["holdESlider"] or 5
        local m = Library.Flags["waitMainSlider"] or 25
        local a = Library.Flags["waitAltSlider"] or 25
        
        HoldLabel:Set("Hold E: " .. tostring(h) .. "s")
        MainLabel:Set("Wait MAIN: " .. tostring(m) .. "s")
        AltLabel:Set("Wait ALT: " .. tostring(a) .. "s")
        
        if h ~= h then Library:Notification({Name = "Erro", Description = "Hold E está NaN!"}) end
    end
})

-- Seus botões de TP (já corrigidos antes)
SettingsSection:Button({
    Name = "FORÇAR NOVO CICLO AGORA",
    Callback = function()
        if pvpRunning then doCycle() else Library:Notification({Name = "Aviso", Description = "Ative o PVP primeiro!"}) end
    end
})

SettingsSection:Button({
    Name = "TP PARA QUEST BRICK",
    Callback = function()
        local folder = workspace:FindFirstChild("Effects")
        if folder then
            local q = folder:FindFirstChild("questbrick")
            if q and q:FindFirstChild("questbrick") then
                Teleport(q.questbrick)
            end
        end
    end
})

SettingsSection:Button({ Name = "TP PRESTIGE", Callback = function() Teleport(Vector3.new(-186.44, 912.53, -459.47)) end })
SettingsSection:Button({ Name = "VENDER ITENS", Callback = function() Teleport(Vector3.new(50.66, 903.43, -411.07)) end })

SettingsSection:Toggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = setupInfiniteJump
})

-- Final
Window:SetOpen(true)

Library:Notification({
    Name = "REVO Loaded",
    Description = "Carregado em " .. string.format("%.2f", os.clock() - LoadingTick) .. "s",
    Duration = 5,
})

Library:Init()

-- Auto-update labels a cada 1s (opcional, pra ver se muda)
task.spawn(function()
    while true do
        task.wait(1)
        local h = Library.Flags["holdESlider"] or 5
        HoldLabel:Set("Hold E: " .. tostring(h) .. "s")
    end
end)