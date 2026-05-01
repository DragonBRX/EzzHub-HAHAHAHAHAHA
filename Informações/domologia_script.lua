local LLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = LLibrary.Lib:CreateWindow("Domologia AI - Jan 2026", "DarkTheme")

-- Main Tab
local Main = Window:NewTab("Detector")
local Section = Main:NewSection("Status do Fantasma")

local GhostLabel = Section:NewLabel("Buscando Fantasma...")
local ConfidenceLabel = Section:NewLabel("Confiança: 0%")
local ReasonLabel = Section:NewLabel("Motivo: Analisando dados...")

-- Stats Tab
local Stats = Window:NewTab("Estatísticas")
local SSection = Stats:NewSection("Dados em Tempo Real")
local SpeedLabel = SSection:NewLabel("Velocidade: 0")
local StateLabel = SSection:NewLabel("Estado: Idle")
local RoomLabel = SSection:NewLabel("Sala: Desconhecida")

-- Variables
local CurrentGhost = nil
local GhostData = {
    Speed = 0,
    LastPos = Vector3.new(0,0,0),
    States = {},
    Interactions = 0,
    EnergyDrain = 0,
    StartTime = tick()
}

-- Ghost Database (Jan 2026)
local Ghosts = {
    ["Aswang"] = {Weight = 0, Traits = {"SpeedIncrease", "SaltSlow"}},
    ["Banshee"] = {Weight = 0, Traits = {"Wail", "MirrorBreak"}},
    ["Demon"] = {Weight = 0, Traits = {"FrequentHunt", "CrucifixFloat"}},
    ["Dullahan"] = {Weight = 0, Traits = {"HeadlessPhoto", "LOSSpeed"}},
    ["Dybbuk"] = {Weight = 0, Traits = {"MusicBoxStun", "ThrowCorpse"}},
    ["Entity"] = {Weight = 0, Traits = {"Teleport", "SmokeEffect"}},
    ["Ghoul"] = {Weight = 0, Traits = {"ChatHunt", "NoElectronics"}},
    ["Keres"] = {Weight = 0, Traits = {"SpeedDecrease", "TargetLowEnergy"}},
    ["Leviathan"] = {Weight = 0, Traits = {"PassiveLightsOff", "MultiThrow"}},
    ["Nightmare"] = {Weight = 0, Traits = {"Hallucinations", "LightAfraid"}},
    ["Oni"] = {Weight = 0, Traits = {"VeryFast", "EventSpam"}},
    ["Phantom"] = {Weight = 0, Traits = {"SlowBlink", "InvisibleSpeed"}},
    ["Revenant"] = {Weight = 0, Traits = {"LowCooldown", "KillStop"}},
    ["Shadow"] = {Weight = 0, Traits = {"LowTemp", "LightInactive"}},
    ["Siren"] = {Weight = 0, Traits = {"FemaleVoice", "LOSSlow"}},
    ["Skinwalker"] = {Weight = 0, Traits = {"FakeOrb", "Mimic"}},
    ["Specter"] = {Weight = 0, Traits = {"ItemSpam", "NoRoam"}},
    ["Spirit"] = {Weight = 0, Traits = {"BlueCandle"}},
    ["The Wisp"] = {Weight = 0, Traits = {"FireWalk", "FavoriteRoomHunt"}},
    ["Umbra"] = {Weight = 0, Traits = {"NoFootsteps", "LightSlow"}},
    ["Vex"] = {Weight = 0, Traits = {"NoLidar", "WallWalk"}},
    ["Wendigo"] = {Weight = 0, Traits = {"FlameAfraid", "EnergySpeed"}},
    ["Wraith"] = {Weight = 0, Traits = {"EnergyDrain", "NoSalt"}}
}

-- Core Logic
local function GetGhost()
    for _, v in pairs(workspace:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Name ~= game.Players.LocalPlayer.Name then
            return v
        end
    end
    return nil
end

game:GetService("RunService").Heartbeat:Connect(function()
    local ghost = GetGhost()
    if ghost then
        -- Update Basic Stats
        local pos = ghost.PrimaryPart.Position
        local dist = (pos - GhostData.LastPos).Magnitude
        GhostData.Speed = dist / (1/60) -- Rough speed calc
        GhostData.LastPos = pos
        
        SpeedLabel:UpdateLabel("Velocidade: " .. string.format("%.2f", GhostData.Speed))
        
        -- Attribute Check (Fastest Method)
        local ghostTypeAttr = ghost:GetAttribute("GhostType") or ghost:GetAttribute("Type")
        if ghostTypeAttr then
            GhostLabel:UpdateLabel("Fantasma: " .. tostring(ghostTypeAttr))
            ConfidenceLabel:UpdateLabel("Confiança: 100%")
            ReasonLabel:UpdateLabel("Motivo: Atributo interno detectado.")
            return
        end

        -- Behavioral Inference
        -- 1. Speed Check
        if GhostData.Speed > 25 then
            Ghosts["Oni"].Weight = Ghosts["Oni"].Weight + 5
        end
        
        -- 2. Energy Drain Check
        local myEnergy = game.Players.LocalPlayer:GetAttribute("Energy") or 100
        if myEnergy < 95 and (tick() - GhostData.StartTime) < 30 then
            Ghosts["Wraith"].Weight = Ghosts["Wraith"].Weight + 2
        end

        -- 3. Wall Walking / Vex Check
        local ray = Ray.new(pos, ghost.PrimaryPart.CFrame.LookVector * 5)
        local hit = workspace:FindPartOnRay(ray, ghost)
        if hit and hit.CanCollide then
             Ghosts["Vex"].Weight = Ghosts["Vex"].Weight + 1
        end

        -- Find Highest Weight
        local bestGhost = "Desconhecido"
        local maxWeight = 0
        for name, data in pairs(Ghosts) do
            if data.Weight > maxWeight then
                maxWeight = data.Weight
                bestGhost = name
            end
        end

        if maxWeight > 0 then
            GhostLabel:UpdateLabel("Provável: " .. bestGhost)
            ConfidenceLabel:UpdateLabel("Confiança: " .. math.min(maxWeight * 10, 99) .. "%")
            ReasonLabel:UpdateLabel("Motivo: Análise comportamental ativa.")
        end
    end
end)

Section:NewButton("Copiar Nome", "Copia o nome do fantasma identificado", function()
    setclipboard(GhostLabel.Text:gsub("Fantasma: ", ""):gsub("Provável: ", ""))
end)

Section:NewButton("Resetar Análise", "Limpa os pesos da inferência", function()
    for _, data in pairs(Ghosts) do data.Weight = 0 end
    GhostData.StartTime = tick()
end)
