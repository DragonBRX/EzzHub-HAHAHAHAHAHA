--[[
    AUTO-LOBBY SCRIPT (DELTA EXECUTOR)
    PlaceId: 18199615050
    Versão: 1.0-OPTIMIZED
    
    Ordem de Execução:
    1. ChangeStatus ("Ready")
    2. ChangeJobSite (Mapa)
    3. ChangeDifficulty (Cíclico)
    4. AttemptStart (Retry Inteligente)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10) -- Ajuste o caminho se necessário

-- Configurações
local CONFIG = {
    MAP_NAME = "NomeDoMapa", -- Substitua pelo nome real do mapa
    DIFFICULTY_CLICKS = 1,   -- Quantas vezes clicar para mudar a dificuldade
    RETRY_DELAY = 1.5,       -- Tempo entre tentativas de Start
    MAX_RETRIES = 5          -- Máximo de tentativas de Start
}

-- Função para localizar remotes de forma segura
local function getRemote(name)
    local remote = Remotes:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
    if not remote then
        -- Busca recursiva simples caso as remotes estejam em outro lugar
        remote = ReplicatedStorage:findFirstChild(name, true)
    end
    return remote
end

local function startAutoLobby()
    print("[Auto-Lobby] Iniciando sequência...")

    -- 1. Localizar Remotes
    local changeStatus = getRemote("ChangeStatus")
    local changeJobSite = getRemote("ChangeJobSite")
    local changeDifficulty = getRemote("ChangeDifficulty")
    local attemptStart = getRemote("AttemptStart")

    if not (changeStatus and changeJobSite and changeDifficulty and attemptStart) then
        warn("[Auto-Lobby] Erro: Uma ou mais remotes não foram encontradas!")
        return
    end

    -- 2. Executar Ordem Obrigatória
    
    -- Passo 1: Marcar como Pronto
    print("[Auto-Lobby] Definindo status: Ready")
    changeStatus:FireServer("Ready")
    task.wait(0.5)

    -- Passo 2: Selecionar Mapa
    print("[Auto-Lobby] Selecionando mapa: " .. CONFIG.MAP_NAME)
    changeJobSite:FireServer(CONFIG.MAP_NAME)
    task.wait(0.5)

    -- Passo 3: Mudar Dificuldade
    print("[Auto-Lobby] Ajustando dificuldade...")
    for i = 1, CONFIG.DIFFICULTY_CLICKS do
        changeDifficulty:FireServer()
        task.wait(0.2)
    end
    task.wait(0.5)

    -- Passo 4: Iniciar Partida (com Retry Inteligente)
    print("[Auto-Lobby] Tentando iniciar partida...")
    for i = 1, CONFIG.MAX_RETRIES do
        print("[Auto-Lobby] Tentativa de Start #" .. i)
        attemptStart:FireServer()
        task.wait(CONFIG.RETRY_DELAY)
        
        -- Opcional: Adicionar verificação se o jogo já iniciou para parar o loop
    end

    print("[Auto-Lobby] Sequência finalizada.")
end

-- Execução
task.spawn(startAutoLobby)
