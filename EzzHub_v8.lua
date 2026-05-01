--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                     EZZ HUB v8.0 - ULTIMATE EDITION                          ║
    ║                     "Captura Tudo. Encontra Tudo."                           ║
    ║                                                                              ║
    ║  Sistema modular de captura e inteligência de jogos Roblox                   ║
    ║  - Detecção automática de Game ID e ambiente                                 ║
    ║  Menu de captura ao vivo por categoria (uma por vez)                         ║
    ║  - Pesquisa inteligente global (Remotes, Objetos, Scripts, Valores)          ║
    ║  - Catalogação completa: NPCs, Objetos, Coordenadas, Servidor                ║
    ║                                                                              ║
    ║  Criador: DragonSCPOFICIAL                                                   ║
    ║  Versão: 8.0 ULTIMATE                                                        ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMPATIBILIDADE DE EXECUTOR
-- ═══════════════════════════════════════════════════════════════════════════════
local function hasFunc(name)
    local ok, val = pcall(function() return _G[name] end)
    if ok and val ~= nil then return true end
    if getfenv then
        local ok2, val2 = pcall(function() return getfenv()[name] end)
        if ok2 and val2 ~= nil then return true end
    end
    return false
end

local CAPS = {
    hook = hasFunc("hookmetamethod") and hasFunc("getnamecallmethod"),
    newcclosure = hasFunc("newcclosure"),
    checkcaller = hasFunc("checkcaller"),
    setclipboard = hasFunc("setclipboard"),
    writefile = hasFunc("writefile"),
    readfile = hasFunc("readfile"),
    isfile = hasFunc("isfile"),
    tasklib = (task ~= nil),
    gethui = hasFunc("gethui"),
}

local function xWait(n) if CAPS.tasklib then task.wait(n or 0) else wait(n or 0) end end
local function xSpawn(fn) if CAPS.tasklib then task.spawn(fn) else spawn(fn) end end
local function xDelay(n, fn) if CAPS.tasklib then task.delay(n, fn) else delay(n, fn) end end

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOGGER
-- ═══════════════════════════════════════════════════════════════════════════════
local Logger = {}
function Logger:Log(level, msg)
    print(string.format("[EZZv8][%s][%s] %s", os.date("%H:%M:%S"), level, msg))
end
function Logger:Info(msg) self:Log("INFO", msg) end
function Logger:Success(msg) self:Log("SUCCESS", msg) end
function Logger:Warning(msg) self:Log("WARNING", msg) end
function Logger:Error(msg) self:Log("ERROR", msg) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SERIALIZADOR UNIVERSAL
-- ═══════════════════════════════════════════════════════════════════════════════
local Serializer = {}
function Serializer.Value(val, depth)
    depth = depth or 0
    if depth > 5 then return '"[Deep]"' end
    local t = type(val)
    if t == "nil" then return "nil"
    elseif t == "boolean" then return val and "true" or "false"
    elseif t == "number" then
        if val == math.huge then return "math.huge"
        elseif val == -math.huge then return "-math.huge"
        elseif val ~= val then return "0/0"
        else return string.format("%.6g", val) end
    elseif t == "string" then return string.format("%q", val:sub(1, 500))
    elseif t == "table" then
        local items = {}
        local count = 0
        local isArray = #val > 0
        if isArray then
            for i, v in ipairs(val) do
                count = count + 1
                if count > 25 then table.insert(items, '"..."'); break end
                table.insert(items, Serializer.Value(v, depth + 1))
            end
            return "{" .. table.concat(items, ", ") .. "}"
        else
            for k, v in pairs(val) do
                count = count + 1
                if count > 20 then table.insert(items, '... = "..."'); break end
                table.insert(items, string.format("[%s] = %s",
                    Serializer.Value(k, depth + 1),
                    Serializer.Value(v, depth + 1)))
            end
            return "{" .. table.concat(items, ", ") .. "}"
        end
    elseif typeof then
        local typ = typeof(val)
        if typ == "Instance" then
            local ok, name = pcall(function() return val:GetFullName() end)
            return ok and string.format('game:FindFirstChild("%s", true)', name) or '"[Instance]"'
        elseif typ == "Vector3" then
            return string.format("Vector3.new(%.4f, %.4f, %.4f)", val.X, val.Y, val.Z)
        elseif typ == "CFrame" then
            return string.format("CFrame.new(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)",
                val:components())
        elseif typ == "Color3" then
            return string.format("Color3.fromRGB(%d, %d, %d)",
                math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255))
        elseif typ == "UDim2" then
            return string.format("UDim2.new(%.4f, %d, %.4f, %d)",
                val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
        elseif typ == "UDim" then
            return string.format("UDim.new(%.4f, %d)", val.Scale, val.Offset)
        elseif typ == "EnumItem" then return tostring(val)
        elseif typ == "Ray" then
            return string.format("Ray.new(%s, %s)",
                Serializer.Value(val.Origin, depth + 1), Serializer.Value(val.Direction, depth + 1))
        elseif typ == "BrickColor" then return string.format('BrickColor.new("%s")', val.Name)
        else return string.format('"[%s]"', typ) end
    end
    return '"[Unknown]"'
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETECTOR DE JOGO INTELIGENTE
-- ═══════════════════════════════════════════════════════════════════════════════
local GameDetector = {}
GameDetector.Info = {
    placeId = game.PlaceId,
    gameId = game.GameId,
    jobId = game.JobId,
    name = "Desconhecido",
    creator = "Desconhecido",
    description = "",
    genre = "",
    maxPlayers = 0,
    universeId = 0,
}

function GameDetector.Detect()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        if info then
            GameDetector.Info.name = info.Name or "Desconhecido"
            GameDetector.Info.description = info.Description or ""
            GameDetector.Info.creator = info.Creator and info.Creator.Name or "Desconhecido"
            GameDetector.Info.genre = tostring(info.Genre or "")
        end
    end)
    pcall(function()
        local universe = game:GetService("HttpService"):JSONDecode(
            game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. game.PlaceId .. "/universe"))
        if universe and universe.universeId then
            GameDetector.Info.universeId = universe.universeId
            local gameInfo = game:GetService("HttpService"):JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. universe.universeId))
            if gameInfo and gameInfo.data and gameInfo.data[1] then
                GameDetector.Info.maxPlayers = gameInfo.data[1].maxPlayers or 0
            end
        end
    end)
    Logger:Info(string.format("Jogo detectado: %s (PlaceId: %d)", GameDetector.Info.name, GameDetector.Info.placeId))
    return GameDetector.Info
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CATALOGO CENTRAL v8 - DATABASE UNIVERSAL
-- ═══════════════════════════════════════════════════════════════════════════════
local Catalog = {}
do
    local Database = {
        Remotes = { FireServer = {}, InvokeServer = {}, OnClientEvent = {} },
        Instances = { Parts = {}, Models = {}, Humanoids = {}, Tools = {}, Scripts = {}, LocalScripts = {}, ModuleScripts = {}, GUIs = {}, Effects = {}, Sounds = {}, Animations = {}, ValueObjects = {}, MeshParts = {} },
        Locations = { SpawnPoints = {}, Shops = {}, Checkpoints = {}, Teleporters = {}, SecretAreas = {}, NPCSpawns = {} },
        NPCs = { Enemies = {}, Friendly = {}, Merchants = {}, QuestGivers = {}, Bosses = {} },
        Players = {},
        Server = { Attributes = {}, Scripts = {}, Services = {} },
        GameData = { MoneySystems = {}, InventorySystems = {}, LevelSystems = {}, QuestSystems = {}, Leaderstats = {} },
        Codes = { PromoCodes = {}, HiddenStrings = {}, Encrypted = {} },
        Workspace = { Terrain = {}, Camera = {}, Gravity = 0, FallenPartsDestroyHeight = 0 },
        UI = { ScreenGuis = {}, Buttons = {}, Labels = {}, Frames = {} },
        Patterns = { RemoteSignatures = {}, CommonArgs = {}, Frequencies = {} },
    }

    local Stats = { totalCaptured = 0, startTime = tick(), lastUpdate = 0, captureLog = {} }

    function Catalog.GetDatabase() return Database end
    function Catalog.GetStats() return Stats end

    function Catalog.LogCapture(category, item, detail)
        table.insert(Stats.captureLog, 1, {
            time = os.date("%H:%M:%S"),
            category = category,
            item = item,
            detail = detail or "",
            timestamp = tick(),
        })
        if #Stats.captureLog > 200 then table.remove(Stats.captureLog) end
        Stats.totalCaptured = Stats.totalCaptured + 1
    end

    -- Classificador inteligente de remotes
    local function ClassifyRemote(name, args, method)
        local lower = name:lower()
        local category = "General"
        local subCategory = "Other"
        local confidence = 0
        if lower:find("money") or lower:find("cash") or lower:find("coin") or lower:find("buy") or lower:find("purchase") or lower:find("shop") or lower:find("sell") or lower:find("trade") or lower:find("pay") then
            category = "Economy"; subCategory = "Transaction"; confidence = 90
        elseif lower:find("teleport") or lower:find("tp") or lower:find("warp") or lower:find("spawn") or lower:find("position") or lower:find("move") or lower:find("goto") or lower:find("travel") then
            category = "Movement"; subCategory = "Teleport"; confidence = 85
        elseif lower:find("damage") or lower:find("hit") or lower:find("attack") or lower:find("fire") or lower:find("shoot") or lower:find("kill") or lower:find("hurt") or lower:find("combat") or lower:find("weapon") then
            category = "Combat"; subCategory = "Damage"; confidence = 80
        elseif lower:find("item") or lower:find("tool") or lower:find("equip") or lower:find("inventory") or lower:find("give") or lower:find("drop") or lower:find("pickup") or lower:find("loot") then
            category = "Inventory"; subCategory = "Item"; confidence = 75
        elseif lower:find("quest") or lower:find("mission") or lower:find("task") or lower:find("objective") or lower:find("complete") then
            category = "Quest"; subCategory = "Progress"; confidence = 70
        elseif lower:find("chat") or lower:find("message") or lower:find("say") or lower:find("talk") or lower:find("whisper") then
            category = "Social"; subCategory = "Chat"; confidence = 95
        elseif lower:find("admin") or lower:find("mod") or lower:find("ban") or lower:find("kick") or lower:find("command") then
            category = "Admin"; subCategory = "Moderation"; confidence = 80
        elseif lower:find("replicate") or lower:find("sync") or lower:find("update") then
            category = "System"; subCategory = "Replication"; confidence = 60
        end
        if args and #args > 0 then
            if type(args[1]) == "number" and (category == "Combat" or category == "Economy") then
                subCategory = subCategory .. "_Amount"
            end
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                if category == "General" then category = "Movement"; subCategory = "Position"; confidence = 70 end
            end
        end
        return category, subCategory, confidence
    end

    function Catalog.AddRemote(remoteRef, method, args, timestamp)
        local name, path, className = "", "", ""
        pcall(function()
            name = remoteRef.Name
            path = remoteRef:GetFullName()
            className = remoteRef.ClassName
        end)
        if name == "" then return end
        local storage = Database.Remotes[method]
        if not storage then return end
        if not storage[name] then
            storage[name] = { entries = {}, meta = { name = name, path = path, className = className, method = method, firstSeen = timestamp, callCount = 0, categories = {} } }
        end
        local entry = storage[name]
        entry.meta.callCount = entry.meta.callCount + 1
        entry.meta.lastSeen = timestamp
        local category, subCategory, confidence = ClassifyRemote(name, args, method)
        local catKey = category .. "_" .. subCategory
        entry.meta.categories[catKey] = (entry.meta.categories[catKey] or 0) + 1
        if #entry.entries < 50 then
            local serialized = {}
            for i, arg in ipairs(args) do serialized[i] = Serializer.Value(arg) end
            table.insert(entry.entries, { timestamp = timestamp, args = args, serialized = serialized, argTypes = (function() local types = {}; for i, arg in ipairs(args) do types[i] = typeof and typeof(arg) or type(arg) end return types end)(), category = category, subCategory = subCategory, confidence = confidence })
        end
        local sig = ""
        for i, arg in ipairs(args) do if i > 3 then break end sig = sig .. (typeof and typeof(arg) or type(arg)) .. "," end
        Database.Patterns.RemoteSignatures[name] = sig
        Database.Patterns.CommonArgs[sig] = (Database.Patterns.CommonArgs[sig] or 0) + 1
        Catalog.LogCapture("Remote", name, string.format("%s | %s", method, category))
    end

    function Catalog.AddInstance(inst)
        local name = inst.Name
        local path = ""
        pcall(function() path = inst:GetFullName() end)
        if inst:IsA("BasePart") or inst:IsA("MeshPart") or inst:IsA("Part") or inst:IsA("UnionOperation") then
            local subCategory = "Generic"
            local nameL = name:lower()
            if nameL:find("spawn") or nameL:find("start") then
                subCategory = "SpawnPoints"
                table.insert(Database.Locations.SpawnPoints, { name = name, position = inst.Position, path = path })
            elseif nameL:find("shop") or nameL:find("store") or nameL:find("buy") then
                subCategory = "Shops"
                table.insert(Database.Locations.Shops, { name = name, position = inst.Position, path = path })
            elseif nameL:find("checkpoint") or nameL:find("save") then
                subCategory = "Checkpoints"
                table.insert(Database.Locations.Checkpoints, { name = name, position = inst.Position, path = path })
            elseif nameL:find("teleport") or nameL:find("portal") or nameL:find("warp") then
                subCategory = "Teleporters"
                table.insert(Database.Locations.Teleporters, { name = name, position = inst.Position, path = path })
            elseif nameL:find("secret") or nameL:find("hidden") or nameL:find("easter") then
                subCategory = "SecretAreas"
                table.insert(Database.Locations.SecretAreas, { name = name, position = inst.Position, path = path })
            end
            table.insert(Database.Instances.Parts, { name = name, className = inst.ClassName, position = inst.Position, size = inst.Size, path = path, subCategory = subCategory })
            Catalog.LogCapture("Part", name, path)
        elseif inst:IsA("Model") then
            local humanoid = inst:FindFirstChildOfClass("Humanoid")
            local subCategory = "Generic"
            if humanoid then
                if Players:GetPlayerFromCharacter(inst) then
                    subCategory = "PlayerCharacters"
                else
                    subCategory = "NPCs"
                    local isEnemy = inst.Name:lower():find("enemy") or inst.Name:lower():find("mob") or inst.Name:lower():find("zombie") or inst.Name:lower():find("boss") or inst.Name:lower():find("monster")
                    local isBoss = inst.Name:lower():find("boss") or humanoid.MaxHealth > 1000
                    local npcData = { name = inst.Name, health = humanoid.Health, maxHealth = humanoid.MaxHealth, position = inst:FindFirstChild("HumanoidRootPart") and inst.HumanoidRootPart.Position or inst:FindFirstChild("Head") and inst.Head.Position or inst:GetPivot().Position, path = path, isEnemy = isEnemy, isBoss = isBoss }
                    if isBoss then
                        table.insert(Database.NPCs.Bosses, npcData)
                        Catalog.LogCapture("Boss", inst.Name, string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth))
                    elseif isEnemy then
                        table.insert(Database.NPCs.Enemies, npcData)
                        Catalog.LogCapture("Enemy", inst.Name, string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth))
                    else
                        table.insert(Database.NPCs.Friendly, npcData)
                        Catalog.LogCapture("NPC", inst.Name, "Friendly")
                    end
                end
            end
            table.insert(Database.Instances.Models, { name = name, hasHumanoid = humanoid ~= nil, path = path, subCategory = subCategory })
        elseif inst:IsA("Tool") then
            table.insert(Database.Instances.Tools, { name = name, path = path, requiresHandle = inst:FindFirstChild("Handle") ~= nil })
            Catalog.LogCapture("Tool", name, path)
        elseif inst:IsA("ValueBase") or inst:IsA("IntValue") or inst:IsA("StringValue") or inst:IsA("BoolValue") or inst:IsA("NumberValue") or inst:IsA("ObjectValue") then
            local subCat = "Generic"
            local nameL = name:lower()
            if nameL:find("money") or nameL:find("cash") or nameL:find("coin") or nameL:find("gold") or nameL:find("gem") then
                subCat = "Currency"
                table.insert(Database.GameData.MoneySystems, { name = name, value = inst.Value, type = inst.ClassName, path = path })
                Catalog.LogCapture("Currency", name, tostring(inst.Value))
            elseif nameL:find("level") or nameL:find("xp") or nameL:find("exp") or nameL:find("rank") then
                subCat = "Progression"
                table.insert(Database.GameData.LevelSystems, { name = name, value = inst.Value, type = inst.ClassName, path = path })
                Catalog.LogCapture("Level", name, tostring(inst.Value))
            elseif nameL:find("inventory") or nameL:find("item") or nameL:find("slot") then
                subCat = "Inventory"
                table.insert(Database.GameData.InventorySystems, { name = name, value = inst.Value, type = inst.ClassName, path = path })
            end
            table.insert(Database.Instances.ValueObjects, { name = name, className = inst.ClassName, value = inst.Value, path = path, subCategory = subCat })
        elseif inst:IsA("Script") then
            table.insert(Database.Instances.Scripts, { name = name, path = path })
            Catalog.LogCapture("Script", name, path)
        elseif inst:IsA("LocalScript") then
            table.insert(Database.Instances.LocalScripts, { name = name, path = path })
        elseif inst:IsA("ModuleScript") then
            table.insert(Database.Instances.ModuleScripts, { name = name, path = path })
            Catalog.LogCapture("Module", name, path)
        elseif inst:IsA("ScreenGui") or inst:IsA("BillboardGui") then
            table.insert(Database.Instances.GUIs, { name = name, className = inst.ClassName, path = path })
            table.insert(Database.UI.ScreenGuis, { name = name, className = inst.ClassName, path = path, enabled = inst.Enabled })
            Catalog.LogCapture("GUI", name, inst.ClassName)
        elseif inst:IsA("TextButton") or inst:IsA("TextLabel") or inst:IsA("ImageButton") then
            local uiData = { name = name, className = inst.ClassName, text = "", path = path, parent = "" }
            pcall(function() uiData.text = inst.Text; uiData.parent = inst.Parent and inst.Parent.Name or "" end)
            if inst:IsA("TextButton") then table.insert(Database.UI.Buttons, uiData)
            elseif inst:IsA("TextLabel") then table.insert(Database.UI.Labels, uiData) end
            Catalog.LogCapture("UIElement", name, uiData.text)
        elseif inst:IsA("Sound") then
            table.insert(Database.Instances.Sounds, { name = name, soundId = inst.SoundId, path = path })
        elseif inst:IsA("Animation") then
            table.insert(Database.Instances.Animations, { name = name, animationId = inst.AnimationId, path = path })
        elseif inst:IsA("Humanoid") then
            table.insert(Database.Instances.Humanoids, { name = name, health = inst.Health, maxHealth = inst.MaxHealth, path = path })
        end
        Stats.totalCaptured = Stats.totalCaptured + 1
    end

    function Catalog.AddPlayerData(player)
        if player ~= LocalPlayer then
            local char = player.Character
            local pos = nil
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then pos = hrp.Position end
            end
            table.insert(Database.Players, {
                name = player.Name, userId = player.UserId, displayName = player.DisplayName,
                team = player.Team and player.Team.Name or "None", position = pos,
                health = char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health or 0,
                maxHealth = char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").MaxHealth or 0,
            })
            return
        end
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            Database.GameData.Leaderstats = {}
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat:IsA("ValueBase") then
                    table.insert(Database.GameData.Leaderstats, { name = stat.Name, type = stat.ClassName, value = stat.Value })
                end
            end
        end
    end

    function Catalog.ScanServer()
        pcall(function()
            for attr, val in pairs(game:GetAttributes()) do
                table.insert(Database.Server.Attributes, { name = attr, value = val, type = typeof(val) })
                Catalog.LogCapture("ServerAttr", attr, tostring(val))
            end
            game.Workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
                Database.Workspace.Gravity = Workspace.Gravity
            end)
            Database.Workspace.Gravity = Workspace.Gravity
            Database.Workspace.FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight
            pcall(function()
                Database.Workspace.Camera = { CFrame = tostring(Camera.CFrame), FieldOfView = Camera.FieldOfView }
            end)
            for _, svc in ipairs(game:GetChildren()) do
                if svc:IsA("ServiceProvider") or svc.ClassName:find("Service") then
                    table.insert(Database.Server.Services, { name = svc.Name, className = svc.ClassName })
                end
            end
        end)
    end

    function Catalog.ScanWorkspace()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            Catalog.AddInstance(obj)
            count = count + 1
            if count % 150 == 0 then xWait() end
        end
        Catalog.LogCapture("System", "Workspace Scan", count .. " objetos")
        return count
    end

    function Catalog.ScanUI()
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return end
            for _, obj in ipairs(playerGui:GetDescendants()) do
                Catalog.AddInstance(obj)
            end
            Catalog.LogCapture("System", "UI Scan", "completo")
        end)
    end

    function Catalog.Clear()
        for k, v in pairs(Database) do
            if type(v) == "table" then
                for k2, _ in pairs(v) do
                    if type(Database[k][k2]) == "table" then Database[k][k2] = {} end
                end
            end
        end
        Stats.totalCaptured = 0
        Stats.captureLog = {}
        Stats.startTime = tick()
    end
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA AO VIVO POR CATEGORIA
-- ═══════════════════════════════════════════════════════════════════════════════
local LiveCapture = {}
LiveCapture.State = {
    isRunning = false,
    currentCategory = nil,
    scanProgress = 0,
    scanTotal = 0,
    lastScannedItem = "",
    activeHook = false,
}

-- Categorias disponíveis para captura
LiveCapture.Categories = {
    { id = "remotes",    name = "Remotes (FireServer)",    icon = "📡", description = "Captura RemoteEvents e RemoteFunctions chamados" },
    { id = "workspace",  name = "Workspace Completo",      icon = "🌍", description = "Todas as partes, modelos e objetos do mapa" },
    { id = "npcs",       name = "NPCs & Inimigos",         icon = "👾", description = "Personagens com Humanoid no workspace" },
    { id = "players",    name = "Jogadores Online",        icon = "👥", description = "Dados de todos os jogadores do servidor" },
    { id = "server",     name = "Dados do Servidor",       icon = "⚙️", description = "Atributos do jogo, serviços e configurações" },
    { id = "gui",        name = "Interface (UI)",          icon = "🖥️", description = "Elementos de UI do jogador local" },
    { id = "scripts",    name = "Scripts & Módulos",       icon = "📜", description = "Scripts locais e módulos no jogo" },
    { id = "values",     name = "Valores & Leaderstats",   icon = "📊", description = "IntValues, StringValues e leaderstats" },
    { id = "tools",      name = "Ferramentas (Tools)",     icon = "🛠️", description = "Tools e itens equipáveis" },
    { id = "locations",  name = "Pontos de Interesse",     icon = "📍", description = "Spawns, shops, checkpoints e teleporters" },
    { id = "sounds",     name = "Sons & Animações",        icon = "🔊", description = "Sons e animações do jogo" },
    { id = "replicated", name = "ReplicatedStorage",       icon = "📦", description = "Conteúdo do ReplicatedStorage completo" },
}

function LiveCapture.StartCategory(categoryId, onProgress)
    if LiveCapture.State.isRunning then
        Logger:Warning("Já existe uma captura em andamento!")
        return false
    end
    LiveCapture.State.isRunning = true
    LiveCapture.State.currentCategory = categoryId
    LiveCapture.State.scanProgress = 0
    LiveCapture.State.lastScannedItem = "Iniciando..."
    Logger:Info("Iniciando captura ao vivo: " .. categoryId)

    xSpawn(function()
        if categoryId == "remotes" then
            LiveCapture.ScanRemotesLive(onProgress)
        elseif categoryId == "workspace" then
            LiveCapture.ScanWorkspaceLive(onProgress)
        elseif categoryId == "npcs" then
            LiveCapture.ScanNPCsLive(onProgress)
        elseif categoryId == "players" then
            LiveCapture.ScanPlayersLive(onProgress)
        elseif categoryId == "server" then
            LiveCapture.ScanServerLive(onProgress)
        elseif categoryId == "gui" then
            LiveCapture.ScanUILive(onProgress)
        elseif categoryId == "scripts" then
            LiveCapture.ScanScriptsLive(onProgress)
        elseif categoryId == "values" then
            LiveCapture.ScanValuesLive(onProgress)
        elseif categoryId == "tools" then
            LiveCapture.ScanToolsLive(onProgress)
        elseif categoryId == "locations" then
            LiveCapture.ScanLocationsLive(onProgress)
        elseif categoryId == "sounds" then
            LiveCapture.ScanSoundsLive(onProgress)
        elseif categoryId == "replicated" then
            LiveCapture.ScanReplicatedLive(onProgress)
        end
        LiveCapture.State.isRunning = false
        LiveCapture.State.currentCategory = nil
        if onProgress then pcall(onProgress, 100, "Completo!") end
        Logger:Success("Captura de " .. categoryId .. " finalizada!")
    end)
    return true
end

function LiveCapture.Stop()
    LiveCapture.State.isRunning = false
    LiveCapture.State.currentCategory = nil
    Logger:Info("Captura interrompida pelo usuário")
end

-- Scanners ao vivo (um por vez)
function LiveCapture.ScanRemotesLive(onProgress)
    -- Hook remotes em tempo real
    if CAPS.hook and not LiveCapture.State.activeHook then
        LiveCapture.State.activeHook = true
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "InvokeServer") then
                    local isRemote = false
                    pcall(function() isRemote = (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) end)
                    if isRemote then
                        xSpawn(function()
                            Catalog.AddRemote(self, method, {...}, tick())
                            LiveCapture.State.lastScannedItem = self.Name .. " [" .. method .. "]"
                        end)
                    end
                end
                return oldNamecall(self, ...)
            end))
        end)
    end
    -- Também escaneia os que já existem
    local allRemotes = {}
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(allRemotes, obj)
            end
        end
    end)
    LiveCapture.State.scanTotal = #allRemotes
    for i, remote in ipairs(allRemotes) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #allRemotes) * 100)
        LiveCapture.State.lastScannedItem = remote.Name .. " [" .. remote.ClassName .. "]"
        Catalog.AddRemote(remote, "FireServer", {}, tick())
        if i % 20 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
    -- Conecta OnClientEvent
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                obj.OnClientEvent:Connect(function(...)
                    if LiveCapture.State.isRunning and LiveCapture.State.currentCategory == "remotes" then
                        Catalog.AddRemote(obj, "OnClientEvent", {...}, tick())
                        LiveCapture.State.lastScannedItem = obj.Name .. " [OnClientEvent]"
                    end
                end)
            end
        end
    end)
end

function LiveCapture.ScanWorkspaceLive(onProgress)
    local all = Workspace:GetDescendants()
    LiveCapture.State.scanTotal = #all
    local count = 0
    for _, obj in ipairs(all) do
        if not LiveCapture.State.isRunning then break end
        count = count + 1
        LiveCapture.State.scanProgress = math.floor((count / #all) * 100)
        LiveCapture.State.lastScannedItem = obj.Name .. " [" .. obj.ClassName .. "]"
        Catalog.AddInstance(obj)
        if count % 150 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait()
        end
    end
end

function LiveCapture.ScanNPCsLive(onProgress)
    local npcs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and not Players:GetPlayerFromCharacter(obj) then
                table.insert(npcs, obj)
            end
        end
    end
    LiveCapture.State.scanTotal = #npcs
    for i, npc in ipairs(npcs) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #npcs) * 100)
        LiveCapture.State.lastScannedItem = npc.Name .. " [HP: " .. math.floor(npc:FindFirstChildOfClass("Humanoid").Health) .. "]"
        Catalog.AddInstance(npc)
        if i % 10 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanPlayersLive(onProgress)
    local allPlayers = Players:GetPlayers()
    LiveCapture.State.scanTotal = #allPlayers
    for i, player in ipairs(allPlayers) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #allPlayers) * 100)
        LiveCapture.State.lastScannedItem = player.Name .. " [" .. (player.Team and player.Team.Name or "Sem Time") .. "]"
        Catalog.AddPlayerData(player)
        xWait(0.1)
        if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
    end
end

function LiveCapture.ScanServerLive(onProgress)
    LiveCapture.State.scanTotal = 1
    LiveCapture.State.scanProgress = 50
    LiveCapture.State.lastScannedItem = "Atributos do Servidor..."
    if onProgress then pcall(onProgress, 30, "Atributos do servidor") end
    Catalog.ScanServer()
    xWait(0.2)
    LiveCapture.State.scanProgress = 70
    LiveCapture.State.lastScannedItem = "Servicos do jogo..."
    if onProgress then pcall(onProgress, 70, "Servicos detectados") end
    xWait(0.2)
    LiveCapture.State.scanProgress = 100
    LiveCapture.State.lastScannedItem = "Configuracoes do Workspace..."
    if onProgress then pcall(onProgress, 100, "Completo") end
end

function LiveCapture.ScanUILive(onProgress)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        local all = playerGui:GetDescendants()
        LiveCapture.State.scanTotal = #all
        for i, obj in ipairs(all) do
            if not LiveCapture.State.isRunning then break end
            LiveCapture.State.scanProgress = math.floor((i / #all) * 100)
            LiveCapture.State.lastScannedItem = obj.Name .. " [" .. obj.ClassName .. "]"
            Catalog.AddInstance(obj)
            if i % 50 == 0 then
                if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
                xWait()
            end
        end
    end)
end

function LiveCapture.ScanScriptsLive(onProgress)
    local scripts = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            table.insert(scripts, obj)
        end
    end
    LiveCapture.State.scanTotal = #scripts
    for i, s in ipairs(scripts) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #scripts) * 100)
        LiveCapture.State.lastScannedItem = s.Name .. " [" .. s.ClassName .. "]"
        Catalog.AddInstance(s)
        if i % 30 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanValuesLive(onProgress)
    local values = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ValueBase") or obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
            table.insert(values, obj)
        end
    end
    LiveCapture.State.scanTotal = #values
    for i, v in ipairs(values) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #values) * 100)
        local valStr = ""
        pcall(function() valStr = tostring(v.Value) end)
        LiveCapture.State.lastScannedItem = v.Name .. " = " .. valStr
        Catalog.AddInstance(v)
        if i % 30 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanToolsLive(onProgress)
    local tools = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Tool") then table.insert(tools, obj) end
    end
    LiveCapture.State.scanTotal = #tools
    for i, tool in ipairs(tools) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #tools) * 100)
        LiveCapture.State.lastScannedItem = tool.Name
        Catalog.AddInstance(tool)
        if i % 10 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanLocationsLive(onProgress)
    local locs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local nameL = obj.Name:lower()
            if nameL:find("spawn") or nameL:find("shop") or nameL:find("checkpoint") or nameL:find("teleport") or nameL:find("portal") then
                table.insert(locs, obj)
            end
        end
    end
    LiveCapture.State.scanTotal = #locs
    for i, loc in ipairs(locs) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #locs) * 100)
        LiveCapture.State.lastScannedItem = loc.Name .. " @ " .. Serializer.Value(loc.Position)
        Catalog.AddInstance(loc)
        if i % 10 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanSoundsLive(onProgress)
    local sounds = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Sound") or obj:IsA("Animation") then table.insert(sounds, obj) end
    end
    LiveCapture.State.scanTotal = #sounds
    for i, s in ipairs(sounds) do
        if not LiveCapture.State.isRunning then break end
        LiveCapture.State.scanProgress = math.floor((i / #sounds) * 100)
        LiveCapture.State.lastScannedItem = s.Name .. " [" .. s.ClassName .. "]"
        Catalog.AddInstance(s)
        if i % 20 == 0 then
            if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
            xWait(0.05)
        end
    end
end

function LiveCapture.ScanReplicatedLive(onProgress)
    pcall(function()
        local all = ReplicatedStorage:GetDescendants()
        LiveCapture.State.scanTotal = #all
        for i, obj in ipairs(all) do
            if not LiveCapture.State.isRunning then break end
            LiveCapture.State.scanProgress = math.floor((i / #all) * 100)
            LiveCapture.State.lastScannedItem = obj.Name .. " [" .. obj.ClassName .. "]"
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                Catalog.AddRemote(obj, "FireServer", {}, tick())
            else
                Catalog.AddInstance(obj)
            end
            if i % 50 == 0 then
                if onProgress then pcall(onProgress, LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem) end
                xWait()
            end
        end
    end)
end

-- Captura passiva contínua (hook de remotes)
function LiveCapture.StartPassiveRemoteCapture()
    if CAPS.hook and not LiveCapture.State.activeHook then
        LiveCapture.State.activeHook = true
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "InvokeServer") then
                    local isRemote = false
                    pcall(function() isRemote = (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) end)
                    if isRemote then
                        xSpawn(function()
                            Catalog.AddRemote(self, method, {...}, tick())
                            if LiveCapture.State.currentCategory == "remotes" then
                                LiveCapture.State.lastScannedItem = self.Name .. " [" .. method .. "]"
                            end
                        end)
                    end
                end
                return oldNamecall(self, ...)
            end))
            Logger:Success("Hook passivo de remotes ativo - jogo NAO sera interrompido")
        end)
    end
    -- OnClientEvent listeners
    pcall(function()
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                obj.OnClientEvent:Connect(function(...)
                    Catalog.AddRemote(obj, "OnClientEvent", {...}, tick())
                end)
            end
        end
    end)
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PESQUISA INTELIGENTE GLOBAL
-- ═══════════════════════════════════════════════════════════════════════════════
local SearchSystem = {}
SearchSystem.LastResults = {}

function SearchSystem.Search(query, scope)
    if not query or #query < 1 then return {} end
    scope = scope or "all"
    local q = query:lower()
    local results = {}
    local db = Catalog.GetDatabase()

    local function addResult(title, category, data, path, value)
        table.insert(results, {
            title = title, category = category, data = data,
            path = path or "", value = value or "",
            timestamp = os.date("%H:%M:%S"),
        })
    end

    -- Pesquisa em Remotes
    if scope == "all" or scope == "remotes" then
        for method, remotes in pairs(db.Remotes) do
            for name, data in pairs(remotes) do
                if name:lower():find(q, 1, true) then
                    for _, entry in ipairs(data.entries) do
                        addResult(name, "Remote [" .. method .. "]", entry, data.meta.path, table.concat(entry.serialized, ", "))
                        if #results >= 100 then break end
                    end
                end
            end
        end
    end

    -- Pesquisa em Instances (Parts, Models, etc)
    if scope == "all" or scope == "objects" then
        for cat, items in pairs(db.Instances) do
            for _, item in ipairs(items) do
                if item.name and item.name:lower():find(q, 1, true) then
                    local val = ""
                    if item.position then val = Serializer.Value(item.position) end
                    if item.value ~= nil then val = tostring(item.value) end
                    addResult(item.name, "Instance [" .. cat .. "]", item, item.path, val)
                    if #results >= 100 then break end
                end
            end
        end
    end

    -- Pesquisa em NPCs
    if scope == "all" or scope == "npcs" then
        for cat, items in pairs(db.NPCs) do
            for _, item in ipairs(items) do
                if item.name and item.name:lower():find(q, 1, true) then
                    addResult(item.name, "NPC [" .. cat .. "]", item, item.path, string.format("HP: %d/%d", item.health or 0, item.maxHealth or 0))
                    if #results >= 100 then break end
                end
            end
        end
    end

    -- Pesquisa em Players
    if scope == "all" or scope == "players" then
        for _, item in ipairs(db.Players) do
            if item.name and item.name:lower():find(q, 1, true) then
                addResult(item.name, "Player", item, "", (item.team or ""))
                if #results >= 100 then break end
            end
        end
    end

    -- Pesquisa em GameData (Valores, Moedas, Levels)
    if scope == "all" or scope == "values" then
        for cat, items in pairs(db.GameData) do
            for _, item in ipairs(items) do
                if (item.name and item.name:lower():find(q, 1, true)) or (tostring(item.value):lower():find(q, 1, true)) then
                    addResult(item.name, "GameData [" .. cat .. "]", item, item.path, tostring(item.value))
                    if #results >= 100 then break end
                end
            end
        end
    end

    -- Pesquisa em Locations
    if scope == "all" or scope == "locations" then
        for cat, items in pairs(db.Locations) do
            for _, item in ipairs(items) do
                if item.name and item.name:lower():find(q, 1, true) then
                    addResult(item.name, "Location [" .. cat .. "]", item, item.path, Serializer.Value(item.position))
                    if #results >= 100 then break end
                end
            end
        end
    end

    -- Pesquisa em UI
    if scope == "all" or scope == "ui" then
        for cat, items in pairs(db.UI) do
            for _, item in ipairs(items) do
                if (item.name and item.name:lower():find(q, 1, true)) or (item.text and item.text:lower():find(q, 1, true)) then
                    addResult(item.name, "UI [" .. cat .. "]", item, item.path, item.text or "")
                    if #results >= 100 then break end
                end
            end
        end
    end

    SearchSystem.LastResults = results
    return results
end

function SearchSystem.PullObject(name)
    local found = Workspace:FindFirstChild(name, true)
    if found then return found end
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then found = pg:FindFirstChild(name, true) end
    end)
    if found then return found end
    for _, obj in pairs(game:GetDescendants()) do
        if obj.Name == name then return obj end
    end
    return nil
end

function SearchSystem.GetObjectDetails(obj)
    if not obj then return nil end
    local details = {
        Name = obj.Name,
        ClassName = obj.ClassName,
        FullName = "",
        Children = {},
        Attributes = {},
        Properties = {},
        IsA = {},
    }
    pcall(function() details.FullName = obj:GetFullName() end)
    pcall(function()
        for _, child in ipairs(obj:GetChildren()) do
            table.insert(details.Children, { Name = child.Name, ClassName = child.ClassName })
        end
    end)
    pcall(function()
        for _, attr in ipairs(obj:GetAttributes()) do
            details.Attributes[attr] = obj:GetAttribute(attr)
        end
    end)
    -- Propriedades comuns
    pcall(function() if obj:IsA("BasePart") then details.Properties.Position = Serializer.Value(obj.Position); details.Properties.Size = Serializer.Value(obj.Size); details.Properties.Color = Serializer.Value(obj.Color); details.Properties.Transparency = obj.Transparency; details.Properties.CanCollide = obj.CanCollide end end)
    pcall(function() if obj:IsA("ValueBase") then details.Properties.Value = tostring(obj.Value) end end)
    pcall(function() if obj:IsA("Humanoid") then details.Properties.Health = obj.Health; details.Properties.MaxHealth = obj.MaxHealth; details.Properties.WalkSpeed = obj.WalkSpeed; details.Properties.JumpPower = obj.JumpPower end end)
    pcall(function() if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then details.Properties.ClassName = obj.ClassName end end)
    return details
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXPORTADOR DE RELATORIOS
-- ═══════════════════════════════════════════════════════════════════════════════
local Exporter = {}

function Exporter.GenerateTextReport()
    local db = Catalog.GetDatabase()
    local stats = Catalog.GetStats()
    local lines = {}
    table.insert(lines, "========================================")
    table.insert(lines, "EZZ HUB v8.0 - RELATORIO COMPLETO")
    table.insert(lines, "Jogo: " .. GameDetector.Info.name)
    table.insert(lines, "PlaceId: " .. game.PlaceId)
    table.insert(lines, "Gerado: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "Tempo de captura: " .. string.format("%.2f", tick() - stats.startTime) .. "s")
    table.insert(lines, "Total capturado: " .. stats.totalCaptured)
    table.insert(lines, "========================================")

    -- REMOTES
    table.insert(lines, "")
    table.insert(lines, "[REMOTES CAPTURADOS]")
    table.insert(lines, "----------------------------------------")
    for method, remotes in pairs(db.Remotes) do
        table.insert(lines, "")
        table.insert(lines, "  > " .. method .. ":")
        for name, data in pairs(remotes) do
            local meta = data.meta
            table.insert(lines, string.format("    - %s [%s] | Chamadas: %d", name, meta.className, meta.callCount))
            table.insert(lines, "      Path: " .. meta.path)
            if #data.entries > 0 then
                table.insert(lines, "      Exemplos:")
                for i = 1, math.min(3, #data.entries) do
                    local args = table.concat(data.entries[i].serialized, ", ")
                    if #args > 80 then args = args:sub(1, 80) .. "..." end
                    table.insert(lines, string.format("        [%d] %s", i, args))
                end
            end
        end
    end

    -- INSTANCES
    table.insert(lines, "")
    table.insert(lines, "[INSTANCIAS]")
    for cat, items in pairs(db.Instances) do
        if #items > 0 then table.insert(lines, string.format("  %s: %d items", cat, #items)) end
    end

    -- NPCs
    table.insert(lines, "")
    table.insert(lines, "[NPCs]")
    for cat, items in pairs(db.NPCs) do
        if #items > 0 then
            table.insert(lines, string.format("  %s: %d encontrados", cat, #items))
            for i, npc in ipairs(items) do
                if i <= 3 then
                    table.insert(lines, string.format("    - %s (HP: %d/%d) @ (%.1f, %.1f, %.1f)",
                        npc.name, npc.health or 0, npc.maxHealth or 0,
                        npc.position and npc.position.X or 0, npc.position and npc.position.Y or 0, npc.position and npc.position.Z or 0))
                elseif i == 4 then table.insert(lines, "    ... e " .. (#items - 3) .. " mais"); break
                end
            end
        end
    end

    -- PLAYERS
    if #db.Players > 0 then
        table.insert(lines, "")
        table.insert(lines, "[JOGADORES ONLINE: " .. #db.Players .. "]")
        for _, p in ipairs(db.Players) do
            table.insert(lines, string.format("  - %s (@%s) | Time: %s", p.name, p.displayName or p.name, p.team or "N/A"))
        end
    end

    -- LOCAIS
    table.insert(lines, "")
    table.insert(lines, "[LOCAIS IMPORTANTES]")
    for locType, locs in pairs(db.Locations) do
        if #locs > 0 then
            table.insert(lines, "  > " .. locType .. ":")
            for _, loc in ipairs(locs) do
                table.insert(lines, string.format("    - %s: (%.2f, %.2f, %.2f)", loc.name, loc.position.X, loc.position.Y, loc.position.Z))
            end
        end
    end

    -- GAME DATA
    if #db.GameData.MoneySystems > 0 then
        table.insert(lines, "")
        table.insert(lines, "[SISTEMAS DE ECONOMIA]")
        for _, sys in ipairs(db.GameData.MoneySystems) do
            table.insert(lines, string.format("  - %s (%s) = %s", sys.name, sys.type, tostring(sys.value)))
        end
    end
    if #db.GameData.LevelSystems > 0 then
        table.insert(lines, "")
        table.insert(lines, "[SISTEMAS DE PROGRESSAO]")
        for _, sys in ipairs(db.GameData.LevelSystems) do
            table.insert(lines, string.format("  - %s = %s", sys.name, tostring(sys.value)))
        end
    end

    -- SERVER
    if #db.Server.Attributes > 0 then
        table.insert(lines, "")
        table.insert(lines, "[ATRIBUTOS DO SERVIDOR]")
        for _, attr in ipairs(db.Server.Attributes) do
            table.insert(lines, string.format("  - %s = %s (%s)", attr.name, tostring(attr.value), attr.type))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "========================================")
    table.insert(lines, "FIM DO RELATORIO - EZZ HUB v8.0")
    table.insert(lines, "========================================")
    return table.concat(lines, "\n")
end

function Exporter.GenerateLuaDatabase()
    local db = Catalog.GetDatabase()
    local lines = {}
    table.insert(lines, "-- EZZ HUB v8.0 - DATABASE EXPORT")
    table.insert(lines, "-- Jogo: " .. GameDetector.Info.name .. " (" .. game.PlaceId .. ")")
    table.insert(lines, "-- Gerado: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "")
    table.insert(lines, "local GameDatabase = {}")

    -- Remotes organizados
    table.insert(lines, "")
    table.insert(lines, "GameDatabase.Remotes = {")
    local categories = {}
    for method, remotes in pairs(db.Remotes) do
        for name, data in pairs(remotes) do
            for cat, _ in pairs(data.meta.categories) do
                if not categories[cat] then categories[cat] = {} end
                table.insert(categories[cat], { name = name, method = method, data = data })
            end
        end
    end
    for cat, remotes in pairs(categories) do
        table.insert(lines, string.format('    ["%s"] = {', cat))
        for _, remote in ipairs(remotes) do
            table.insert(lines, string.format('        { Name = %q, Method = %q, Path = %q, CallCount = %d,', remote.name, remote.method, remote.data.meta.path, remote.data.meta.callCount))
            table.insert(lines, '            Execute = function(...)')
            table.insert(lines, string.format('                local remote = game:FindFirstChild(%q, true)', remote.name))
            table.insert(lines, '                if remote then')
            if remote.method == "FireServer" then table.insert(lines, '                    remote:FireServer(...)')
            else table.insert(lines, '                    return remote:InvokeServer(...)') end
            table.insert(lines, '                end')
            table.insert(lines, '            end,')
            if #remote.data.entries > 0 then
                table.insert(lines, '            Examples = {')
                for _, entry in ipairs(remote.data.entries) do
                    if #entry.serialized > 0 then table.insert(lines, string.format('                {%s},', table.concat(entry.serialized, ", "))) end
                end
                table.insert(lines, '            },')
            end
            table.insert(lines, '        },')
        end
        table.insert(lines, '    },')
    end
    table.insert(lines, "}")

    -- NPCs
    if #db.NPCs.Enemies > 0 or #db.NPCs.Bosses > 0 then
        table.insert(lines, "")
        table.insert(lines, "GameDatabase.NPCs = {")
        for cat, items in pairs(db.NPCs) do
            if #items > 0 then
                table.insert(lines, string.format('    %s = {', cat))
                for _, npc in ipairs(items) do
                    table.insert(lines, string.format('        { Name = %q, Health = %d, MaxHealth = %d, Position = Vector3.new(%.4f, %.4f, %.4f), Path = %q },',
                        npc.name, npc.health or 0, npc.maxHealth or 0,
                        npc.position and npc.position.X or 0, npc.position and npc.position.Y or 0, npc.position and npc.position.Z or 0,
                        npc.path or ""))
                end
                table.insert(lines, '    },')
            end
        end
        table.insert(lines, "}")
    end

    -- Locais
    table.insert(lines, "")
    table.insert(lines, "GameDatabase.Locations = {")
    for locType, locs in pairs(db.Locations) do
        if #locs > 0 then
            table.insert(lines, string.format('    ["%s"] = {', locType))
            for _, loc in ipairs(locs) do
                table.insert(lines, string.format('        { Name = %q, Position = Vector3.new(%.4f, %.4f, %.4f), Path = %q },',
                    loc.name, loc.position.X, loc.position.Y, loc.position.Z, loc.path))
            end
            table.insert(lines, '    },')
        end
    end
    table.insert(lines, "}")

    -- Funções utilitárias
    table.insert(lines, "")
    table.insert(lines, "function GameDatabase.GetRemote(category, name)")
    table.insert(lines, "    local cat = GameDatabase.Remotes[category] or {}")
    table.insert(lines, "    for _, r in ipairs(cat) do if r.Name == name then return r end end")
    table.insert(lines, "    return nil")
    table.insert(lines, "end")
    table.insert(lines, "")
    table.insert(lines, "function GameDatabase.TeleportTo(locationType, name)")
    table.insert(lines, "    local locs = GameDatabase.Locations[locationType] or {}")
    table.insert(lines, "    for _, loc in ipairs(locs) do")
    table.insert(lines, "        if loc.Name == name then")
    table.insert(lines, "            local p = game:GetService(\"Players\").LocalPlayer")
    table.insert(lines, "            local c = p.Character")
    table.insert(lines, "            if c then local hrp = c:FindFirstChild(\"HumanoidRootPart\"); if hrp then hrp.CFrame = CFrame.new(loc.Position) end end")
    table.insert(lines, "            return true")
    table.insert(lines, "        end")
    table.insert(lines, "    end")
    table.insert(lines, "    return false")
    table.insert(lines, "end")
    table.insert(lines, "")
    table.insert(lines, "return GameDatabase")
    return table.concat(lines, "\n")
end

function Exporter.GenerateJSON()
    local db = Catalog.GetDatabase()
    local stats = Catalog.GetStats()
    local export = {
        meta = { version = "8.0", gameName = GameDetector.Info.name, placeId = game.PlaceId, generated = os.date("%Y-%m-%d %H:%M:%S"), totalCaptured = stats.totalCaptured },
        remotes = {}, instances = {}, npcs = db.NPCs, locations = db.Locations,
        gameData = db.GameData, players = db.Players, server = db.Server,
    }
    for method, remotes in pairs(db.Remotes) do
        for name, data in pairs(remotes) do
            table.insert(export.remotes, { name = name, method = method, path = data.meta.path, callCount = data.meta.callCount, categories = data.meta.categories })
        end
    end
    for cat, items in pairs(db.Instances) do
        export.instances[cat] = #items
    end
    local ok, result = pcall(function() return HttpService:JSONEncode(export) end)
    return ok and result or "Error encoding JSON"
end

function Exporter.SaveToFile(content, extension)
    if not CAPS.writefile then Logger:Error("writefile nao disponivel"); return false end
    local filename = "EZZv8_" .. game.PlaceId .. "_" .. os.time() .. "." .. (extension or "txt")
    pcall(writefile, filename, content)
    Logger:Success("Arquivo salvo: " .. filename)
    return filename
end

function Exporter.CopyToClipboard(content)
    if not CAPS.setclipboard then Logger:Error("Clipboard nao disponivel"); return false end
    pcall(setclipboard, content)
    Logger:Success("Copiado para clipboard!")
    return true
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- INTERFACE DO USUARIO v8 - UI MODERNA E PROFISSIONAL
-- ═══════════════════════════════════════════════════════════════════════════════
local UI = {}
do
    local Theme = {
        Background = Color3.fromRGB(12, 12, 18),
        BackgroundSecondary = Color3.fromRGB(22, 22, 32),
        BackgroundTertiary = Color3.fromRGB(32, 32, 48),
        Surface = Color3.fromRGB(42, 42, 62),
        Primary = Color3.fromRGB(220, 60, 60),
        PrimaryHover = Color3.fromRGB(240, 80, 80),
        Secondary = Color3.fromRGB(60, 140, 220),
        Accent = Color3.fromRGB(255, 200, 60),
        Success = Color3.fromRGB(50, 220, 100),
        Warning = Color3.fromRGB(255, 180, 50),
        Error = Color3.fromRGB(220, 50, 50),
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 210),
        TextMuted = Color3.fromRGB(120, 120, 150),
        Border = Color3.fromRGB(50, 50, 75),
    }

    local State = {
        screenGui = nil,
        mainFrame = nil,
        isVisible = true,
        currentTab = "Capture",
        isMinimized = false,
        isDragging = false,
        dragStart = nil,
        dragPos = nil,
    }

    local function Tween(obj, props, dur)
        local info = TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(obj, info, props):Play()
    end

    local function CreateCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 8)
        c.Parent = parent
        return c
    end

    local function CreateStroke(parent, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color or Theme.Border
        s.Thickness = thickness or 1
        s.Parent = parent
        return s
    end

    local function CreateLabel(config)
        local label = Instance.new("TextLabel")
        label.Name = config.Name or "Label"
        label.Size = config.Size or UDim2.new(1, 0, 0, 20)
        label.Position = config.Position or UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = config.Text or ""
        label.TextColor3 = config.TextColor or Theme.TextPrimary
        label.Font = config.Font or Enum.Font.Gotham
        label.TextSize = config.TextSize or 12
        label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
        label.TextYAlignment = config.TextYAlignment or Enum.TextYAlignment.Center
        label.TextWrapped = config.TextWrapped or false
        label.Parent = config.Parent
        return label
    end

    local function CreateButton(config)
        local button = Instance.new("TextButton")
        button.Name = config.Name or "Button"
        button.Size = config.Size or UDim2.new(0, 120, 0, 32)
        button.Position = config.Position or UDim2.new(0, 0, 0, 0)
        button.BackgroundColor3 = config.BackgroundColor or Theme.BackgroundSecondary
        button.Text = config.Text or "Button"
        button.TextColor3 = config.TextColor or Theme.TextPrimary
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 11
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Parent = config.Parent
        CreateCorner(button, config.CornerRadius or 6)
        if config.Stroke then CreateStroke(button, config.StrokeColor, config.StrokeThickness) end
        button.MouseEnter:Connect(function()
            Tween(button, {BackgroundColor3 = config.HoverColor or Theme.BackgroundTertiary}, 0.15)
        end)
        button.MouseLeave:Connect(function()
            Tween(button, {BackgroundColor3 = config.BackgroundColor or Theme.BackgroundSecondary}, 0.15)
        end)
        if config.Callback then button.MouseButton1Click:Connect(config.Callback) end
        return button
    end

    local function CreateScrollFrame(config)
        local sf = Instance.new("ScrollingFrame")
        sf.Name = config.Name or "ScrollFrame"
        sf.Size = config.Size or UDim2.new(1, 0, 1, 0)
        sf.Position = config.Position or UDim2.new(0, 0, 0, 0)
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 4
        sf.ScrollBarImageColor3 = Theme.Primary
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.Parent = config.Parent
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.Parent = sf
        if config.Padding then
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, config.Padding)
            pad.PaddingBottom = UDim.new(0, config.Padding)
            pad.PaddingLeft = UDim.new(0, config.Padding)
            pad.PaddingRight = UDim.new(0, config.Padding)
            pad.Parent = sf
        end
        return sf
    end

    local function CreateProgressBar(parent, yPos)
        local frame = Instance.new("Frame")
        frame.Name = "ProgressBar"
        frame.Size = UDim2.new(1, -20, 0, 8)
        frame.Position = UDim2.new(0, 10, 0, yPos)
        frame.BackgroundColor3 = Theme.BackgroundTertiary
        frame.BorderSizePixel = 0
        frame.Parent = parent
        CreateCorner(frame, 4)

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Success
        fill.BorderSizePixel = 0
        fill.Parent = frame
        CreateCorner(fill, 4)

        local label = Instance.new("TextLabel")
        label.Name = "ProgressText"
        label.Size = UDim2.new(1, 0, 0, 16)
        label.Position = UDim2.new(0, 0, 0, -18)
        label.BackgroundTransparency = 1
        label.Text = "0% - Aguardando..."
        label.TextColor3 = Theme.TextSecondary
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        return { Frame = frame, Fill = fill, Label = label }
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- TAB: CAPTURA AO VIVO
    -- ═════════════════════════════════════════════════════════════════════════════
    local function SetupCaptureTab(parent)
        -- Header da tab
        CreateLabel({
            Name = "TabTitle",
            Text = "Captura ao Vivo por Categoria",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Primary,
            Parent = parent,
        })

        CreateLabel({
            Name = "TabDesc",
            Text = "Selecione UMA categoria para capturar por vez.\nO sistema mostra o progresso em tempo real.",
            Size = UDim2.new(1, -20, 0, 32),
            Position = UDim2.new(0, 10, 0, 34),
            TextSize = 10,
            TextColor3 = Theme.TextMuted,
            TextWrapped = true,
            Parent = parent,
        })

        -- Progress bar
        local progressBar = CreateProgressBar(parent, 475)

        -- Status ao vivo
        local liveStatus = CreateLabel({
            Name = "LiveStatus",
            Text = "Status: Pronto",
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 10, 0, 490),
            TextSize = 10,
            TextColor3 = Theme.TextSecondary,
            Parent = parent,
        })

        -- Scroll de categorias
        local scroll = CreateScrollFrame({
            Name = "CatScroll",
            Size = UDim2.new(1, -20, 0, 400),
            Position = UDim2.new(0, 10, 0, 70),
            Padding = 8,
            Parent = parent,
        })

        -- Botões de categoria
        local catButtons = {}
        for _, cat in ipairs(LiveCapture.Categories) do
            local row = Instance.new("Frame")
            row.Name = "CatRow_" .. cat.id
            row.Size = UDim2.new(1, 0, 0, 52)
            row.BackgroundColor3 = Theme.BackgroundSecondary
            row.BorderSizePixel = 0
            row.Parent = scroll
            CreateCorner(row, 8)
            CreateStroke(row, Theme.Border)

            local icon = CreateLabel({
                Name = "Icon",
                Text = cat.icon,
                Size = UDim2.new(0, 36, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = row,
            })

            local nameLabel = CreateLabel({
                Name = "CatName",
                Text = cat.name,
                Size = UDim2.new(1, -140, 0, 20),
                Position = UDim2.new(0, 44, 0, 4),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Parent = row,
            })

            local descLabel = CreateLabel({
                Name = "CatDesc",
                Text = cat.description,
                Size = UDim2.new(1, -140, 0, 20),
                Position = UDim2.new(0, 44, 0, 26),
                TextSize = 9,
                TextColor3 = Theme.TextMuted,
                Parent = row,
            })

            local btn = Instance.new("TextButton")
            btn.Name = "ToggleBtn"
            btn.Size = UDim2.new(0, 72, 0, 30)
            btn.Position = UDim2.new(1, -80, 0.5, -15)
            btn.BackgroundColor3 = Theme.Success
            btn.Text = "CAPTURAR"
            btn.TextColor3 = Color3.new(0, 0, 0)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 9
            btn.BorderSizePixel = 0
            btn.Parent = row
            CreateCorner(btn, 6)

            catButtons[cat.id] = { row = row, btn = btn, nameLabel = nameLabel }

            btn.MouseButton1Click:Connect(function()
                if LiveCapture.State.isRunning and LiveCapture.State.currentCategory == cat.id then
                    -- Parar
                    LiveCapture.Stop()
                    btn.Text = "CAPTURAR"
                    btn.BackgroundColor3 = Theme.Success
                    liveStatus.Text = "Status: Parado"
                    Tween(progressBar.Fill, {Size = UDim2.new(0, 0, 1, 0)}, 0.3)
                else
                    -- Iniciar
                    if LiveCapture.State.isRunning then
                        Logger:Warning("Pare a captura atual primeiro!")
                        return
                    end
                    Catalog.Clear()
                    local function onProgress(pct, item)
                        liveStatus.Text = string.format("Status: %s | %s", cat.name, item)
                        progressBar.Label.Text = string.format("%d%% - %s", pct, item)
                        Tween(progressBar.Fill, {Size = UDim2.new(pct / 100, 0, 1, 0)}, 0.1)
                    end
                    if LiveCapture.StartCategory(cat.id, onProgress) then
                        btn.Text = "PARAR"
                        btn.BackgroundColor3 = Theme.Error
                    end
                end
            end)
        end

        -- Atualizador de status
        xSpawn(function()
            while xWait(0.5) do
                if not liveStatus.Parent then break end
                if LiveCapture.State.isRunning then
                    progressBar.Label.Text = string.format("%d%% - %s", LiveCapture.State.scanProgress, LiveCapture.State.lastScannedItem)
                    Tween(progressBar.Fill, {Size = UDim2.new(LiveCapture.State.scanProgress / 100, 0, 1, 0)}, 0.1)
                    liveStatus.Text = string.format("Capturando: %s | %s", LiveCapture.State.currentCategory or "", LiveCapture.State.lastScannedItem)
                    -- Atualiza todos os botões
                    for id, cb in pairs(catButtons) do
                        if LiveCapture.State.currentCategory == id then
                            cb.btn.Text = "PARAR"
                            cb.btn.BackgroundColor3 = Theme.Error
                        else
                            cb.btn.Text = "CAPTURAR"
                            cb.btn.BackgroundColor3 = Theme.Success
                        end
                    end
                end
            end
        end)
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- TAB: PESQUISA INTELIGENTE
    -- ═════════════════════════════════════════════════════════════════════════════
    local function SetupSearchTab(parent)
        CreateLabel({
            Name = "TabTitle",
            Text = "Pesquisa Global",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Secondary,
            Parent = parent,
        })

        CreateLabel({
            Name = "TabDesc",
            Text = "Pesquise por nome em Remotes, Objetos, NPCs, Valores e mais.",
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 10, 0, 34),
            TextSize = 10,
            TextColor3 = Theme.TextMuted,
            Parent = parent,
        })

        -- Barra de pesquisa
        local searchFrame = Instance.new("Frame")
        searchFrame.Name = "SearchFrame"
        searchFrame.Size = UDim2.new(1, -20, 0, 36)
        searchFrame.Position = UDim2.new(0, 10, 0, 56)
        searchFrame.BackgroundColor3 = Theme.BackgroundSecondary
        searchFrame.BorderSizePixel = 0
        searchFrame.Parent = parent
        CreateCorner(searchFrame, 8)
        CreateStroke(searchFrame, Theme.Border)

        local searchIcon = CreateLabel({
            Text = "🔍",
            Size = UDim2.new(0, 30, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = searchFrame,
        })

        local searchInput = Instance.new("TextBox")
        searchInput.Name = "SearchInput"
        searchInput.Size = UDim2.new(1, -100, 1, 0)
        searchInput.Position = UDim2.new(0, 38, 0, 0)
        searchInput.BackgroundTransparency = 1
        searchInput.Text = ""
        searchInput.PlaceholderText = "Digite para pesquisar..."
        searchInput.PlaceholderColor3 = Theme.TextMuted
        searchInput.TextColor3 = Theme.TextPrimary
        searchInput.Font = Enum.Font.Gotham
        searchInput.TextSize = 12
        searchInput.ClearTextOnFocus = false
        searchInput.Parent = searchFrame

        -- Scope selector
        local scopeFrame = Instance.new("Frame")
        scopeFrame.Name = "ScopeFrame"
        scopeFrame.Size = UDim2.new(0, 120, 1, -4)
        scopeFrame.Position = UDim2.new(1, -122, 0, 2)
        scopeFrame.BackgroundColor3 = Theme.BackgroundTertiary
        scopeFrame.BorderSizePixel = 0
        scopeFrame.Parent = searchFrame
        CreateCorner(scopeFrame, 6)

        local scopeDropdown = Instance.new("TextButton")
        scopeDropdown.Name = "ScopeBtn"
        scopeDropdown.Size = UDim2.new(1, 0, 1, 0)
        scopeDropdown.BackgroundTransparency = 1
        scopeDropdown.Text = "Tudo ▼"
        scopeDropdown.TextColor3 = Theme.TextSecondary
        scopeDropdown.Font = Enum.Font.Gotham
        scopeDropdown.TextSize = 10
        scopeDropdown.Parent = scopeFrame

        local scopes = { {id="all", label="Tudo"}, {id="remotes", label="Remotes"}, {id="objects", label="Objetos"}, {id="npcs", label="NPCs"}, {id="players", label="Jogadores"}, {id="values", label="Valores"}, {id="locations", label="Locais"}, {id="ui", label="UI"} }
        local currentScope = "all"
        local scopeMenuOpen = false

        local scopeMenu = Instance.new("Frame")
        scopeMenu.Name = "ScopeMenu"
        scopeMenu.Size = UDim2.new(0, 120, 0, #scopes * 26)
        scopeMenu.Position = UDim2.new(0, 0, 1, 4)
        scopeMenu.BackgroundColor3 = Theme.BackgroundTertiary
        scopeMenu.BorderSizePixel = 0
        scopeMenu.Visible = false
        scopeMenu.ZIndex = 10
        scopeMenu.Parent = scopeFrame
        CreateCorner(scopeMenu, 6)

        for i, scope in ipairs(scopes) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 26)
            item.Position = UDim2.new(0, 0, 0, (i-1) * 26)
            item.BackgroundTransparency = 1
            item.Text = scope.label
            item.TextColor3 = Theme.TextSecondary
            item.Font = Enum.Font.Gotham
            item.TextSize = 10
            item.ZIndex = 11
            item.Parent = scopeMenu
            item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.8; item.BackgroundColor3 = Theme.Surface end)
            item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
            item.MouseButton1Click:Connect(function()
                currentScope = scope.id
                scopeDropdown.Text = scope.label .. " ▼"
                scopeMenu.Visible = false
                scopeMenuOpen = false
            end)
        end

        scopeDropdown.MouseButton1Click:Connect(function()
            scopeMenuOpen = not scopeMenuOpen
            scopeMenu.Visible = scopeMenuOpen
        end)

        -- Resultados
        local resultsScroll = CreateScrollFrame({
            Name = "ResultsScroll",
            Size = UDim2.new(1, -20, 0, 330),
            Position = UDim2.new(0, 10, 0, 100),
            Padding = 8,
            Parent = parent,
        })

        local resultsLabel = CreateLabel({
            Text = "Digite acima para pesquisar no banco de dados capturado.",
            Size = UDim2.new(1, -10, 0, 40),
            TextColor3 = Theme.TextMuted,
            TextSize = 11,
            TextWrapped = true,
            Parent = resultsScroll,
        })

        -- Contador
        local countLabel = CreateLabel({
            Name = "CountLabel",
            Text = "0 resultados",
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 10, 0, 436),
            TextSize = 9,
            TextColor3 = Theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = parent,
        })

        -- Botão copiar
        local copyBtn = CreateButton({
            Name = "CopyResults",
            Text = "📋 Copiar Resultados",
            Size = UDim2.new(0, 140, 0, 26),
            Position = UDim2.new(0, 10, 0, 456),
            BackgroundColor = Theme.BackgroundTertiary,
            TextColor3 = Theme.TextSecondary,
            CornerRadius = 6,
            Parent = parent,
            Callback = function()
                if #SearchSystem.LastResults > 0 then
                    local lines = {}
                    for _, r in ipairs(SearchSystem.LastResults) do
                        table.insert(lines, string.format("[%s] %s | Path: %s | Value: %s", r.category, r.title, r.path, r.value))
                    end
                    Exporter.CopyToClipboard(table.concat(lines, "\n"))
                    copyBtn.Text = "✅ Copiado!"
                    xDelay(2, function() copyBtn.Text = "📋 Copiar Resultados" end)
                end
            end,
        })

        -- Botão Pull
        local pullBtn = CreateButton({
            Name = "PullBtn",
            Text = "⬇ Pull Objeto",
            Size = UDim2.new(0, 110, 0, 26),
            Position = UDim2.new(0, 156, 0, 456),
            BackgroundColor = Theme.BackgroundTertiary,
            TextColor3 = Theme.TextSecondary,
            CornerRadius = 6,
            Parent = parent,
            Callback = function()
                local name = searchInput.Text
                if #name < 1 then return end
                local obj = SearchSystem.PullObject(name)
                if not obj then
                    resultsLabel.Text = "❌ Objeto '" .. name .. "' não encontrado no jogo."
                    resultsLabel.TextColor3 = Theme.Error
                else
                    local details = SearchSystem.GetObjectDetails(obj)
                    local lines = { "✅ OBJETO ENCONTRADO:", "Nome: " .. details.Name, "Classe: " .. details.ClassName, "FullName: " .. details.FullName, "", "[Atributos]" }
                    for k, v in pairs(details.Attributes) do table.insert(lines, "  " .. k .. " = " .. tostring(v)) end
                    if #details.Attributes == 0 then table.insert(lines, "  (nenhum)") end
                    table.insert(lines, "")
                    table.insert(lines, "[Propriedades]")
                    for k, v in pairs(details.Properties) do table.insert(lines, "  " .. k .. " = " .. tostring(v)) end
                    table.insert(lines, "")
                    table.insert(lines, "[Filhos]")
                    for _, c in ipairs(details.Children) do table.insert(lines, "  - " .. c.Name .. " [" .. c.ClassName .. "]") end
                    resultsLabel.Text = table.concat(lines, "\n")
                    resultsLabel.TextColor3 = Theme.TextPrimary
                    Exporter.CopyToClipboard(HttpService:JSONEncode(details))
                end
            end,
        })

        -- Executar pesquisa
        local function doSearch()
            local query = searchInput.Text
            if #query < 1 then return end
            resultsLabel.Text = "🔍 Pesquisando..."
            resultsLabel.TextColor3 = Theme.TextSecondary
            xWait(0.1)
            local results = SearchSystem.Search(query, currentScope)
            countLabel.Text = #results .. " resultado(s)"
            if #results == 0 then
                resultsLabel.Text = "❌ Nenhum resultado para: '" .. query .. "'"
                resultsLabel.TextColor3 = Theme.Error
            else
                local lines = { "✅ " .. #results .. " resultado(s) encontrados:\n" }
                for i, r in ipairs(results) do
                    if i > 50 then table.insert(lines, "... e mais " .. (#results - 50) .. " resultados"); break end
                    local line = string.format("[%s] %s", r.category, r.title)
                    if r.path and #r.path > 0 then line = line .. "\n  Path: " .. r.path end
                    if r.value and #tostring(r.value) > 0 then
                        local val = tostring(r.value)
                        if #val > 60 then val = val:sub(1, 60) .. "..." end
                        line = line .. "\n  Value: " .. val
                    end
                    table.insert(lines, line)
                end
                resultsLabel.Text = table.concat(lines, "\n")
                resultsLabel.TextColor3 = Theme.TextPrimary
            end
        end

        searchInput.FocusLost:Connect(function() doSearch() end)
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- TAB: VISUALIZAR DADOS
    -- ═════════════════════════════════════════════════════════════════════════════
    local function SetupDataTab(parent)
        CreateLabel({
            Name = "TabTitle",
            Text = "Dados Capturados",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Accent,
            Parent = parent,
        })

        local dataScroll = CreateScrollFrame({
            Name = "DataScroll",
            Size = UDim2.new(1, -20, 0, 445),
            Position = UDim2.new(0, 10, 0, 38),
            Padding = 8,
            Parent = parent,
        })

        local dataLabel = CreateLabel({
            Text = "Nenhum dado capturado ainda.\nUse a aba 'Captura' para coletar informações.",
            Size = UDim2.new(1, -10, 0, 60),
            TextColor3 = Theme.TextMuted,
            TextSize = 11,
            TextWrapped = true,
            Parent = dataScroll,
        })

        -- Atualiza periodicamente
        xSpawn(function()
            while xWait(1) do
                if not dataLabel.Parent then break end
                local db = Catalog.GetDatabase()
                local stats = Catalog.GetStats()
                local lines = {}
                table.insert(lines, string.format("📊 Total capturado: %d itens | Tempo: %.0fs", stats.totalCaptured, tick() - stats.startTime))
                table.insert(lines, "")

                -- Remotes
                for method, remotes in pairs(db.Remotes) do
                    local count = 0
                    for _ in pairs(remotes) do count = count + 1 end
                    if count > 0 then table.insert(lines, string.format("📡 %s: %d unicos", method, count)) end
                end

                -- Instancias
                table.insert(lines, "")
                for cat, items in pairs(db.Instances) do
                    if #items > 0 then table.insert(lines, string.format("  %s: %d", cat, #items)) end
                end

                -- NPCs
                table.insert(lines, "")
                for cat, items in pairs(db.NPCs) do
                    if #items > 0 then
                        table.insert(lines, string.format("👾 %s: %d", cat, #items))
                        for i, npc in ipairs(items) do
                            if i <= 3 then
                                table.insert(lines, string.format("    - %s (HP: %d/%d)", npc.name, npc.health or 0, npc.maxHealth or 0))
                            else table.insert(lines, "    ... e mais " .. (#items - 3)); break end
                        end
                    end
                end

                -- Players
                if #db.Players > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "👥 Jogadores: " .. #db.Players)
                end

                -- GameData
                if #db.GameData.MoneySystems > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "💰 Moedas:")
                    for _, m in ipairs(db.GameData.MoneySystems) do
                        table.insert(lines, string.format("    - %s = %s", m.name, tostring(m.value)))
                    end
                end
                if #db.GameData.LevelSystems > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "⭐ Progressao:")
                    for _, l in ipairs(db.GameData.LevelSystems) do
                        table.insert(lines, string.format("    - %s = %s", l.name, tostring(l.value)))
                    end
                end

                -- Log de capturas recentes
                if #stats.captureLog > 0 then
                    table.insert(lines, "")
                    table.insert(lines, "📝 Ultimas capturas:")
                    for i = 1, math.min(10, #stats.captureLog) do
                        local log = stats.captureLog[i]
                        table.insert(lines, string.format("  [%s] %s: %s", log.time, log.category, log.item))
                    end
                end

                dataLabel.Text = table.concat(lines, "\n")
                dataLabel.TextColor3 = Theme.TextPrimary
            end
        end)
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- TAB: EXPORTAR
    -- ═════════════════════════════════════════════════════════════════════════════
    local function SetupExportTab(parent)
        CreateLabel({
            Name = "TabTitle",
            Text = "Exportar Relatorios",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Success,
            Parent = parent,
        })

        local desc = CreateLabel({
            Text = "Exporte os dados capturados em varios formatos.",
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 10, 0, 34),
            TextSize = 10,
            TextColor3 = Theme.TextMuted,
            Parent = parent,
        })

        local y = 60
        local buttons = {
            { text = "📋 COPIAR RELATORIO TEXTO", color = Theme.Secondary, desc = "Relatorio completo formatado em texto", action = function()
                local report = Exporter.GenerateTextReport()
                Exporter.CopyToClipboard(report)
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "Relatorio copiado!", Duration = 3 })
            end },
            { text = "📋 COPIAR DATABASE LUA", color = Theme.Success, desc = "Database executavel em Lua", action = function()
                local lua = Exporter.GenerateLuaDatabase()
                Exporter.CopyToClipboard(lua)
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "Database Lua copiado!", Duration = 3 })
            end },
            { text = "📋 COPIAR JSON", color = Theme.Accent, desc = "Exportacao em formato JSON", action = function()
                local json = Exporter.GenerateJSON()
                Exporter.CopyToClipboard(json)
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "JSON copiado!", Duration = 3 })
            end },
            { text = "💾 SALVAR RELATORIO (.txt)", color = Theme.BackgroundTertiary, desc = "Salvar relatorio em arquivo", action = function()
                local report = Exporter.GenerateTextReport()
                local fname = Exporter.SaveToFile(report, "txt")
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "Salvo: " .. (fname or ""), Duration = 3 })
            end },
            { text = "💾 SALVAR DATABASE (.lua)", color = Theme.BackgroundTertiary, desc = "Salvar database Lua em arquivo", action = function()
                local lua = Exporter.GenerateLuaDatabase()
                local fname = Exporter.SaveToFile(lua, "lua")
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "Salvo: " .. (fname or ""), Duration = 3 })
            end },
        }

        for _, btnData in ipairs(buttons) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -20, 0, 50)
            row.Position = UDim2.new(0, 10, 0, y)
            row.BackgroundColor3 = Theme.BackgroundSecondary
            row.BorderSizePixel = 0
            row.Parent = parent
            CreateCorner(row, 8)

            local btn = CreateButton({
                Text = btnData.text,
                Size = UDim2.new(1, -16, 0, 30),
                Position = UDim2.new(0, 8, 0, 4),
                BackgroundColor = btnData.color,
                TextColor3 = (btnData.color == Theme.Accent) and Color3.new(0, 0, 0) or Theme.TextPrimary,
                CornerRadius = 6,
                Parent = row,
                Callback = btnData.action,
            })

            CreateLabel({
                Text = btnData.desc,
                Size = UDim2.new(1, -16, 0, 14),
                Position = UDim2.new(0, 8, 0, 34),
                TextSize = 8,
                TextColor3 = Theme.TextMuted,
                Parent = row,
            })

            y = y + 58
        end

        -- Limpar
        local clearBtn = CreateButton({
            Text = "🗑️ LIMPAR TUDO",
            Size = UDim2.new(1, -20, 0, 36),
            Position = UDim2.new(0, 10, 0, y + 10),
            BackgroundColor = Theme.Error,
            CornerRadius = 8,
            Parent = parent,
            Callback = function()
                Catalog.Clear()
                StarterGui:SetCore("SendNotification", { Title = "EZZ v8", Text = "Todos os dados foram limpos!", Duration = 3 })
            end,
        })
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- TAB: INFO DO JOGO
    -- ═════════════════════════════════════════════════════════════════════════════
    local function SetupInfoTab(parent)
        CreateLabel({
            Name = "TabTitle",
            Text = "Informacoes do Jogo",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Warning,
            Parent = parent,
        })

        local infoScroll = CreateScrollFrame({
            Name = "InfoScroll",
            Size = UDim2.new(1, -20, 0, 445),
            Position = UDim2.new(0, 10, 0, 38),
            Padding = 8,
            Parent = parent,
        })

        local infoLabel = CreateLabel({
            Text = "Detectando informacoes do jogo...",
            Size = UDim2.new(1, -10, 0, 300),
            TextColor3 = Theme.TextSecondary,
            TextSize = 11,
            TextWrapped = true,
            Parent = infoScroll,
        })

        xSpawn(function()
            GameDetector.Detect()
            while xWait(2) do
                if not infoLabel.Parent then break end
                local info = GameDetector.Info
                local lines = {}
                table.insert(lines, string.format("🎮 Nome: %s", info.name))
                table.insert(lines, string.format("🆔 PlaceId: %d", info.placeId))
                table.insert(lines, string.format("🆔 GameId: %d", info.gameId))
                table.insert(lines, string.format("🆔 UniverseId: %d", info.universeId))
                table.insert(lines, string.format("👤 Criador: %s", info.creator))
                table.insert(lines, string.format("📝 Genero: %s", info.genre))
                table.insert(lines, string.format("👥 Max Players: %d", info.maxPlayers))
                table.insert(lines, "")
                table.insert(lines, string.format("🔧 JobId: %s", info.jobId:sub(1, 30) .. "..."))
                table.insert(lines, string.format("📍 Gravidade: %.1f", Workspace.Gravity))
                table.insert(lines, string.format("🌍 Descendants: %d", #game:GetDescendants()))
                table.insert(lines, string.format("👥 Jogadores Online: %d", #Players:GetPlayers()))
                table.insert(lines, "")
                if #info.description > 0 then
                    table.insert(lines, "📝 Descricao:")
                    table.insert(lines, info.description:sub(1, 300))
                end
                infoLabel.Text = table.concat(lines, "\n")
            end
        end)
    end

    -- ═════════════════════════════════════════════════════════════════════════════
    -- CONSTRUCAO DA UI PRINCIPAL
    -- ═════════════════════════════════════════════════════════════════════════════
    function UI.Create()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local old = playerGui:FindFirstChild("EZZ_HUB_V8")
        if old then old:Destroy() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "EZZ_HUB_V8"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999999
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        if CAPS.gethui then pcall(function() screenGui.Parent = gethui() end) else screenGui.Parent = playerGui end
        if not screenGui.Parent then screenGui.Parent = playerGui end
        State.screenGui = screenGui

        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 580, 0, 540)
        mainFrame.Position = UDim2.new(0, 60, 0, 60)
        mainFrame.BackgroundColor3 = Theme.Background
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Parent = screenGui
        State.mainFrame = mainFrame
        CreateCorner(mainFrame, 14)
        CreateStroke(mainFrame, Theme.Border, 2)

        -- Header
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 48)
        header.BackgroundColor3 = Theme.BackgroundSecondary
        header.BorderSizePixel = 0
        header.Parent = mainFrame
        CreateCorner(header, 14)

        local headerFix = Instance.new("Frame")
        headerFix.Size = UDim2.new(1, 0, 0, 20)
        headerFix.Position = UDim2.new(0, 0, 1, -14)
        headerFix.BackgroundColor3 = Theme.BackgroundSecondary
        headerFix.BorderSizePixel = 0
        headerFix.Parent = header

        local logoDot = Instance.new("Frame")
        logoDot.Size = UDim2.new(0, 10, 0, 10)
        logoDot.Position = UDim2.new(0, 14, 0.5, -5)
        logoDot.BackgroundColor3 = Theme.Primary
        logoDot.BorderSizePixel = 0
        logoDot.Parent = header
        CreateCorner(logoDot, 5)

        CreateLabel({
            Text = "  EZZ HUB v8.0 ULTIMATE",
            Size = UDim2.new(1, -160, 1, 0),
            Position = UDim2.new(0, 30, 0, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = Theme.Primary,
            Parent = header,
        })

        local btnMinimize = CreateButton({
            Name = "Minimize",
            Text = "-",
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(1, -84, 0, 6),
            BackgroundColor = Theme.BackgroundTertiary,
            CornerRadius = 8,
            Parent = header,
        })

        local btnClose = CreateButton({
            Name = "Close",
            Text = "X",
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(1, -42, 0, 6),
            BackgroundColor = Theme.Error,
            CornerRadius = 8,
            Parent = header,
        })

        -- Sidebar
        local sidebar = Instance.new("Frame")
        sidebar.Name = "Sidebar"
        sidebar.Size = UDim2.new(0, 140, 1, -48)
        sidebar.Position = UDim2.new(0, 0, 0, 48)
        sidebar.BackgroundColor3 = Theme.BackgroundSecondary
        sidebar.BorderSizePixel = 0
        sidebar.Parent = mainFrame

        local sidebarLine = Instance.new("Frame")
        sidebarLine.Size = UDim2.new(0, 1, 1, 0)
        sidebarLine.Position = UDim2.new(1, -1, 0, 0)
        sidebarLine.BackgroundColor3 = Theme.Border
        sidebarLine.BorderSizePixel = 0
        sidebarLine.Parent = sidebar

        -- Tabs
        local tabs = {
            { Name = "Capture",   Icon = "📡", Color = Theme.Success },
            { Name = "Pesquisa",  Icon = "🔍", Color = Theme.Secondary },
            { Name = "Dados",     Icon = "📊", Color = Theme.Accent },
            { Name = "Exportar",  Icon = "📋", Color = Theme.Success },
            { Name = "Info",      Icon = "🎮", Color = Theme.Warning },
        }

        local tabButtons = {}
        local tabContents = {}

        for i, tab in ipairs(tabs) do
            local btn = CreateButton({
                Name = tab.Name .. "Tab",
                Text = "  " .. tab.Icon .. " " .. tab.Name,
                Size = UDim2.new(1, -10, 0, 38),
                Position = UDim2.new(0, 5, 0, 12 + (i-1) * 46),
                BackgroundColor = i == 1 and tab.Color or Theme.BackgroundTertiary,
                TextColor3 = i == 1 and Theme.TextPrimary or Theme.TextSecondary,
                TextXAlignment = Enum.TextXAlignment.Left,
                CornerRadius = 8,
                Parent = sidebar,
            })
            tabButtons[tab.Name] = btn

            local content = Instance.new("Frame")
            content.Name = tab.Name .. "Content"
            content.Size = UDim2.new(1, -140, 1, -48)
            content.Position = UDim2.new(0, 140, 0, 48)
            content.BackgroundTransparency = 1
            content.Visible = (i == 1)
            content.Parent = mainFrame
            tabContents[tab.Name] = content

            btn.MouseButton1Click:Connect(function()
                for name, button in pairs(tabButtons) do
                    Tween(button, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.15)
                    button.TextColor3 = Theme.TextSecondary
                    tabContents[name].Visible = false
                end
                Tween(btn, {BackgroundColor3 = tab.Color}, 0.15)
                btn.TextColor3 = Theme.TextPrimary
                content.Visible = true
                State.currentTab = tab.Name
            end)
        end

        -- Drag
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                State.isDragging = true
                State.dragStart = input.Position
                State.dragPos = mainFrame.Position
            end
        end)
        header.InputChanged:Connect(function(input)
            if State.isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - State.dragStart
                mainFrame.Position = UDim2.new(State.dragPos.X.Scale, State.dragPos.X.Offset + delta.X,
                    State.dragPos.Y.Scale, State.dragPos.Y.Offset + delta.Y)
            end
        end)
        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then State.isDragging = false end
        end)

        -- Minimize / Close
        btnMinimize.MouseButton1Click:Connect(function()
            State.isMinimized = not State.isMinimized
            if State.isMinimized then
                Tween(mainFrame, {Size = UDim2.new(0, 580, 0, 48)}, 0.3)
                sidebar.Visible = false
                for _, c in pairs(tabContents) do c.Visible = false end
                btnMinimize.Text = "+"
            else
                Tween(mainFrame, {Size = UDim2.new(0, 580, 0, 540)}, 0.3)
                xDelay(0.3, function()
                    sidebar.Visible = true
                    tabContents[State.currentTab].Visible = true
                end)
                btnMinimize.Text = "-"
            end
        end)

        btnClose.MouseButton1Click:Connect(function()
            Tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
            xDelay(0.3, function() screenGui.Enabled = false end)
        end)

        -- Status bar
        local statusBar = Instance.new("Frame")
        statusBar.Name = "StatusBar"
        statusBar.Size = UDim2.new(1, 0, 0, 22)
        statusBar.Position = UDim2.new(0, 0, 1, -22)
        statusBar.BackgroundColor3 = Theme.BackgroundSecondary
        statusBar.BorderSizePixel = 0
        statusBar.Parent = mainFrame

        local statusLine = Instance.new("Frame")
        statusLine.Size = UDim2.new(1, 0, 0, 1)
        statusLine.BackgroundColor3 = Theme.Border
        statusLine.BorderSizePixel = 0
        statusLine.Parent = statusBar

        local statusLabel = CreateLabel({
            Name = "StatusText",
            Text = "EZZ v8.0 | Insert: Toggle UI | PlaceId: " .. game.PlaceId,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            TextSize = 9,
            TextColor3 = Theme.TextMuted,
            Parent = statusBar,
        })

        -- Atualiza status
        xSpawn(function()
            while xWait(2) do
                if not statusLabel.Parent then break end
                local stats = Catalog.GetStats()
                statusLabel.Text = string.format("EZZ v8.0 | Capturado: %d | %s | Insert: Toggle",
                    stats.totalCaptured, GameDetector.Info.name ~= "Desconhecido" and GameDetector.Info.name or ("PlaceId: " .. game.PlaceId))
            end
        end)

        -- Setup das tabs
        SetupCaptureTab(tabContents.Capture)
        SetupSearchTab(tabContents.Pesquisa)
        SetupDataTab(tabContents.Dados)
        SetupExportTab(tabContents.Exportar)
        SetupInfoTab(tabContents.Info)

        -- Animate in
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        Tween(mainFrame, {Size = UDim2.new(0, 580, 0, 540)}, 0.5, Enum.EasingStyle.Back)

        return UI
    end

    function UI.Toggle()
        State.isVisible = not State.isVisible
        if State.screenGui then State.screenGui.Enabled = State.isVisible end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INICIALIZACAO DO EZZ HUB v8
-- ═══════════════════════════════════════════════════════════════════════════════
local EZZ = {
    Version = "8.0 ULTIMATE",
    Creator = "DragonSCPOFICIAL",
    Catalog = Catalog,
    Search = SearchSystem,
    LiveCapture = LiveCapture,
    Exporter = Exporter,
    GameDetector = GameDetector,
}

function EZZ.Start()
    Logger:Info("╔══════════════════════════════════════╗")
    Logger:Info("║     EZZ HUB v8.0 ULTIMATE            ║")
    Logger:Info("║     'Captura Tudo. Encontra Tudo.'   ║")
    Logger:Info("╚══════════════════════════════════════╝")

    -- Detecta jogo
    xSpawn(function() GameDetector.Detect() end)

    -- Cria UI
    xSpawn(function() UI.Create() end)

    -- Inicia hook passivo de remotes (background)
    xDelay(1, function() LiveCapture.StartPassiveRemoteCapture() end)

    -- Monitora clicks
    xSpawn(function()
        pcall(function()
            Mouse.Button1Down:Connect(function()
                local target = Mouse.Target
                if target then
                    Catalog.LogCapture("Click", target.Name, target.ClassName)
                end
            end)
        end)
    end)

    -- Keybinds
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            UI.Toggle()
        elseif input.KeyCode == Enum.KeyCode.F5 then
            -- Quick capture toggle
            if LiveCapture.State.isRunning then
                LiveCapture.Stop()
            else
                LiveCapture.StartCategory("workspace")
            end
        end
    end)

    -- Notificacao
    xDelay(3, function()
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "EZZ HUB v8.0 ULTIMATE",
                Text = "Carregado!\nInsert = Toggle UI\nCaptura ao vivo por categoria\nPesquisa global inteligente",
                Duration = 6,
            })
        end)
    end)

    Logger:Success("EZZ HUB v8.0 iniciado com sucesso!")
    Logger:Info("Comandos: Insert = Toggle UI | F5 = Captura rapida Workspace")
end

EZZ.Start()
return EZZ
