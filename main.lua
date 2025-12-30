LARGURA_TELA = 320
ALTURA_TELA = 480
MAX_OBSTACULOS = 12
FIM_JOGO = false
PONTUACAO = 0
ESTADO_JOGO = "menu" -- "menu", "jogando", "gameover", "ranking", "inserir_nome"
NOME_JOGADOR = ""
RANKING = {}
MAX_RANKING = 10
ARQUIVO_RANKING = "ranking.dat"

baleia = {
    src = "img/baleia.png",
    largura = 60,
    altura = 40,
    x = LARGURA_TELA / 2 - 60 / 2,
    y = ALTURA_TELA - 100,
    tiros = {},
    velocidade = 2
}

obstaculos = {}
tiros = {}

-- Sistema de ranking
function carregarRanking()
    local arquivo = love.filesystem.getInfo(ARQUIVO_RANKING)
    if arquivo then
        local dados = love.filesystem.read(ARQUIVO_RANKING)
        if dados then
            RANKING = {}
            for linha in dados:gmatch("[^\r\n]+") do
                local nome, pontos = linha:match("([^,]+),(%d+)")
                if nome and pontos then
                    table.insert(RANKING, {nome = nome, pontos = tonumber(pontos)})
                end
            end
            table.sort(RANKING, function(a, b) return a.pontos > b.pontos end)
            if #RANKING > MAX_RANKING then
                for i = MAX_RANKING + 1, #RANKING do
                    RANKING[i] = nil
                end
            end
        end
    end
    if #RANKING == 0 then
        -- Ranking de exemplo
        RANKING = {
            {nome = "BALEIA-MESTRE", pontos = 1500},
            {nome = "OCEANO", pontos = 1200},
            {nome = "AZUL", pontos = 900},
            {nome = "ORCA", pontos = 750},
            {nome = "GOLFINHO", pontos = 600},
            {nome = "TUBARAO", pontos = 450},
            {nome = "POLVO", pontos = 300},
            {nome = "CAVALOMAR", pontos = 200},
            {nome = "SIRI", pontos = 150},
            {nome = "CONCHA", pontos = 100}
        }
    end
end

function salvarRanking()
    local dados = ""
    for i = 1, math.min(#RANKING, MAX_RANKING) do
        dados = dados .. RANKING[i].nome .. "," .. RANKING[i].pontos .. "\n"
    end
    love.filesystem.write(ARQUIVO_RANKING, dados)
end

function adicionarAoRanking(nome, pontos)
    table.insert(RANKING, {nome = nome, pontos = pontos})
    table.sort(RANKING, function(a, b) return a.pontos > b.pontos end)
    if #RANKING > MAX_RANKING then
        for i = MAX_RANKING + 1, #RANKING do
            RANKING[i] = nil
        end
    end
    salvarRanking()
end

function daTiro()
    disparo:play()
    local tiro = {
        x = baleia.x + baleia.largura / 2 - 8,
        y = baleia.y,
        largura = 16,
        altura = 16,
        velocidade = 5
    }
    table.insert(tiros, tiro)
end

function moveTiros()
    for i = #tiros, 1, -1 do
        local t = tiros[i]
        -- Não mover efeitos visuais de pontos aqui; eles são atualizados em love.update
        if not t.tipo or t.tipo ~= "pontos" then
            local v = t.velocidade or 0
            t.y = t.y - v
            if t.y < -20 then
                table.remove(tiros, i)
            end
        end
    end
end

function destroiBaleia()
    destruicao:play()
    baleia.src = "img/explosao_nave.png"
    baleia.imagem = love.graphics.newImage(baleia.src)
    baleia.largura = 67
    baleia.altura = 77
end

function temColisao(X1, Y1, L1, A1, X2, Y2, L2, A2)
    return X1 < X2 + L2 and X2 < X1 + L1 and Y1 < Y2 + A2 and Y2 < Y1 + A1
end

function removeObstaculos()
    for i = #obstaculos, 1, -1 do
        if obstaculos[i].y > ALTURA_TELA + 50 then
            table.remove(obstaculos, i)
        end
    end
end

function criaObstaculo()
    local tipos = {
        {largura = 40, altura = 40, velocidade = 1.5, pontos = 10},
        {largura = 50, altura = 50, velocidade = 1.2, pontos = 20},
        {largura = 60, altura = 60, velocidade = 1.0, pontos = 30},
        {largura = 30, altura = 30, velocidade = 2.0, pontos = 15}
    }
    
    local tipo = tipos[math.random(#tipos)]
    local obstaculo = {
        x = math.random(LARGURA_TELA - tipo.largura),
        y = -70,
        largura = tipo.largura,
        altura = tipo.altura,
        velocidade = tipo.velocidade,
        pontos = tipo.pontos,
        deslocamento_horizontal = math.random(-1, 1) * 0.5,
        tipo = math.random(4) -- Para diferentes sprites
    }
    table.insert(obstaculos, obstaculo)
end

function moveObstaculos()
    for k, obstaculo in pairs(obstaculos) do
        obstaculo.y = obstaculo.y + obstaculo.velocidade
        obstaculo.x = obstaculo.x + obstaculo.deslocamento_horizontal
        -- Mantém dentro da tela horizontalmente
        if obstaculo.x < 0 then obstaculo.x = 0 end
        if obstaculo.x + obstaculo.largura > LARGURA_TELA then 
            obstaculo.x = LARGURA_TELA - obstaculo.largura 
        end
    end
end

function moveBaleia()
    if love.keyboard.isDown('w', 'up') then
        baleia.y = math.max(50, baleia.y - baleia.velocidade)
    end
    if love.keyboard.isDown('s', 'down') then
        baleia.y = math.min(ALTURA_TELA - baleia.altura, baleia.y + baleia.velocidade)
    end
    if love.keyboard.isDown('a', 'left') then
        baleia.x = math.max(0, baleia.x - baleia.velocidade)
    end
    if love.keyboard.isDown('d', 'right') then
        baleia.x = math.min(LARGURA_TELA - baleia.largura, baleia.x + baleia.velocidade)
    end
end

function trocaMusicaDeFundo()
    musica_ambiente:stop()
    game_over:play()
end

function checaColisaoComBaleia()
    for k, obstaculo in pairs(obstaculos) do
        if temColisao(obstaculo.x, obstaculo.y, obstaculo.largura, obstaculo.altura, 
                     baleia.x, baleia.y, baleia.largura, baleia.altura) then
            trocaMusicaDeFundo()
            destroiBaleia()
            ESTADO_JOGO = "inserir_nome"
            return true
        end
    end
    return false
end

function checaColisaoComTiros()
    for i = #tiros, 1, -1 do
        for j = #obstaculos, 1, -1 do
            if temColisao(tiros[i].x, tiros[i].y, tiros[i].largura, tiros[i].altura,
                         obstaculos[j].x, obstaculos[j].y, obstaculos[j].largura, obstaculos[j].altura) then
                -- Capture data do obstáculo antes de removê-lo
                local ox, oy, op = obstaculos[j].x, obstaculos[j].y, obstaculos[j].pontos
                PONTUACAO = PONTUACAO + op
                table.remove(tiros, i)
                table.remove(obstaculos, j)
                -- Adiciona efeito visual de pontos (30% de chance)
                if math.random(100) < 30 then
                    table.insert(tiros, {
                        x = ox or 0,
                        y = oy or 0,
                        largura = 10,
                        altura = 10,
                        tipo = "pontos",
                        texto = "+" .. (op or 0),
                        tempo = 60
                    })
                end
                break
            end
        end
    end
end

function checaColisoes()
    if not checaColisaoComBaleia() then
        checaColisaoComTiros()
    end
end

function love.load()
    love.window.setMode(LARGURA_TELA, ALTURA_TELA, {
        resizable = false,
        vsync = true
    })
    love.window.setTitle("Baleia Azul - Salve o Oceano")

    math.randomseed(os.time())
    love.keyboard.setKeyRepeat(true)

    -- Carregamento de imagens (mantenha seus arquivos na pasta img)
    background = love.graphics.newImage("img/background.jpg")
    -- Imagem do menu (opcional)
    if love.filesystem.getInfo("img/menu.png") then
        menu_bg = love.graphics.newImage("img/menu.png")
    else
        menu_bg = nil
    end
    gameover_img = love.graphics.newImage("img/gameover.png")
    baleia.imagem = love.graphics.newImage(baleia.src)
    
    -- Carrega múltiplos sprites para obstáculos
    obstaculo_imgs = {
        love.graphics.newImage("img/meteoro.png"),
        love.graphics.newImage("img/meteoro.png"),
        love.graphics.newImage("img/meteoro.png"),
        love.graphics.newImage("img/meteoro.png")
    }
    
    tiro_img = love.graphics.newImage("img/tiro.png")
    baleia_tiro_img = love.graphics.newImage("img/tiro.png")

    -- Carregamento de áudio
    -- Música do jogo
    musica_ambiente = love.audio.newSource("audios/ambiente.wav", "stream")
    musica_ambiente:setLooping(true)
    musica_ambiente:setVolume(0.5)

    -- Música do menu
    musica_menu = love.audio.newSource("audios/menu.wav", "stream")
    musica_menu:setLooping(true)
    musica_menu:setVolume(0.5)
    musica_menu:play()

    destruicao = love.audio.newSource("audios/destruicao.wav", "static")
    game_over = love.audio.newSource("audios/game_over.wav", "static")
    disparo = love.audio.newSource("audios/disparo.wav", "static")
    ponto_som = love.audio.newSource("audios/disparo.wav", "static")
    ponto_som:setVolume(0.3)

    -- Carrega o ranking
    carregarRanking()
    
    -- Fonte para texto
    fonte_pequena = love.graphics.newFont(12)
    fonte_media = love.graphics.newFont(18)
    fonte_grande = love.graphics.newFont(24)
    love.graphics.setFont(fonte_pequena)
end

function love.update(dt)
    -- Menu UI
    if ESTADO_JOGO == "menu" then
        love.graphics.setFont(fonte_grande)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.printf("BALEIA AZUL", 0, 60, LARGURA_TELA, "center")

        love.graphics.setFont(fonte_media)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Pressione ESPAÇO para jogar", 0, 140, LARGURA_TELA, "center")

        love.graphics.setFont(fonte_pequena)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("ESC para sair", 0, ALTURA_TELA - 40, LARGURA_TELA, "center")

        love.graphics.setColor(1, 1, 1)
        return
    end

    if ESTADO_JOGO == "jogando" then
        if love.keyboard.isDown('w', 'a', 's', 'd', 'up', 'down', 'left', 'right') then
            moveBaleia()
        end

        removeObstaculos()
        if #obstaculos < MAX_OBSTACULOS then
            if math.random(100) < 3 then -- 3% de chance a cada frame
                criaObstaculo()
            end
        end
        
        moveObstaculos()
        moveTiros()
        checaColisoes()
        
        -- Atualiza efeitos de pontos
        for i = #tiros, 1, -1 do
            if tiros[i].tipo == "pontos" then
                tiros[i].tempo = tiros[i].tempo - 1
                tiros[i].y = tiros[i].y - 1
                if tiros[i].tempo <= 0 then
                    table.remove(tiros, i)
                end
            end
        end
        
        -- Aumenta dificuldade com o tempo
        if PONTUACAO > 1000 then
            MAX_OBSTACULOS = 15
        elseif PONTUACAO > 500 then
            MAX_OBSTACULOS = 14
        elseif PONTUACAO > 200 then
            MAX_OBSTACULOS = 13
        end
        
    elseif ESTADO_JOGO == "inserir_nome" then
        -- Processamento de entrada de nome já é feito no love.textinput
    end
end

function love.keypressed(tecla)
    if tecla == "escape" then
        love.event.quit()
    elseif ESTADO_JOGO == "menu" then
        if tecla == "space" or tecla == "return" or tecla == "enter" then
            reiniciarJogo()
        end
    elseif ESTADO_JOGO == "jogando" then
        if tecla == "space" then
            daTiro()
        end
    elseif ESTADO_JOGO == "inserir_nome" then
        if tecla == "return" or tecla == "enter" then
            if NOME_JOGADOR:len() > 0 then
                adicionarAoRanking(NOME_JOGADOR:upper(), PONTUACAO)
                ESTADO_JOGO = "ranking"
            end
        elseif tecla == "backspace" then
            NOME_JOGADOR = NOME_JOGADOR:sub(1, -2)
        end
    elseif ESTADO_JOGO == "ranking" then
        if tecla == "space" or tecla == "return" or tecla == "enter" then
            -- Volta ao menu principal ao invés de reiniciar diretamente
            ESTADO_JOGO = "menu"
            -- Parar música do jogo e tocar a do menu
            if musica_ambiente then pcall(function() musica_ambiente:stop() end) end
            if musica_menu then pcall(function() musica_menu:play() end) end
        end
    end
end

function love.textinput(text)
    if ESTADO_JOGO == "inserir_nome" then
        if NOME_JOGADOR:len() < 10 then
            NOME_JOGADOR = NOME_JOGADOR .. text
        end
    end
end

function reiniciarJogo()
    baleia = {
        src = "img/baleia.png",
        largura = 60,
        altura = 40,
        x = LARGURA_TELA / 2 - 60 / 2,
        y = ALTURA_TELA - 100,
        tiros = {},
        velocidade = 2,
        imagem = love.graphics.newImage("img/baleia.png")
    }
    obstaculos = {}
    tiros = {}
    PONTUACAO = 0
    MAX_OBSTACULOS = 12
    ESTADO_JOGO = "jogando"
    NOME_JOGADOR = ""
    -- Parar música do menu (se existir) e iniciar música do jogo
    if musica_menu then
        pcall(function() musica_menu:stop() end)
    end
    if musica_ambiente then
        if type(musica_ambiente.isPlaying) == "function" then
            if not musica_ambiente:isPlaying() then
                musica_ambiente:play()
            end
        else
            pcall(function() musica_ambiente:play() end)
        end
    end
end

function love.draw()
    -- Fundo
    if ESTADO_JOGO == "menu" then
        if menu_bg then
            love.graphics.draw(menu_bg, 0, 0)
        else
            love.graphics.draw(background, 0, 0)
        end
    else
        love.graphics.draw(background, 0, 0)
    end
    
    if ESTADO_JOGO == "jogando" then
        -- Desenha baleia
        love.graphics.draw(baleia.imagem, baleia.x, baleia.y, 0, 1, 1)
        
        -- Desenha obstáculos
        for k, obstaculo in pairs(obstaculos) do
            local img_idx = ((obstaculo.tipo - 1) % #obstaculo_imgs) + 1
            love.graphics.draw(obstaculo_imgs[img_idx], obstaculo.x, obstaculo.y, 0, 
                             obstaculo.largura/50, obstaculo.altura/44)
        end
        
        -- Desenha tiros
        for k, tiro in pairs(tiros) do
            if tiro.tipo == "pontos" then
                love.graphics.setFont(fonte_pequena)
                love.graphics.setColor(1, 1, 0)
                love.graphics.print(tiro.texto, tiro.x, tiro.y)
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.draw(baleia_tiro_img, tiro.x, tiro.y)
            end
        end
        
        -- Interface do jogador
        love.graphics.setFont(fonte_media)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.print("PONTOS: " .. PONTUACAO, 10, 10)
        
        love.graphics.setFont(fonte_pequena)
        love.graphics.print("Controles:", 10, ALTURA_TELA - 70)
        love.graphics.print("WASD/Setas: Mover", 10, ALTURA_TELA - 55)
        love.graphics.print("ESPAÇO: Atirar", 10, ALTURA_TELA - 40)
        love.graphics.print("ESC: Sair", 10, ALTURA_TELA - 25)
        
        -- Barra de dificuldade
        local dificuldade = math.min(MAX_OBSTACULOS / 15, 1)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", LARGURA_TELA - 120, 15, 100, 15)
        love.graphics.setColor(0, 0.5 + dificuldade/2, 1 - dificuldade/2)
        love.graphics.rectangle("fill", LARGURA_TELA - 120, 15, dificuldade * 100, 15)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fonte_pequena)
        love.graphics.print("DIFICULDADE", LARGURA_TELA - 118, 17)
        
    elseif ESTADO_JOGO == "inserir_nome" then
        love.graphics.setFont(fonte_grande)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.print("GAME OVER", LARGURA_TELA/2 - 80, 50)
        
        love.graphics.setFont(fonte_media)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Pontuação: " .. PONTUACAO, LARGURA_TELA/2 - 60, 100)
        
        love.graphics.print("Digite seu nome:", LARGURA_TELA/2 - 70, 150)
        
        -- Caixa do nome
        love.graphics.setColor(0, 0.3, 0.6)
        love.graphics.rectangle("fill", LARGURA_TELA/2 - 100, 180, 200, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", LARGURA_TELA/2 - 100, 180, 200, 30)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(NOME_JOGADOR, LARGURA_TELA/2 - 90, 185)
        
        -- Cursor piscante
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            local cursorX = LARGURA_TELA/2 - 90 + fonte_media:getWidth(NOME_JOGADOR)
            love.graphics.line(cursorX, 185, cursorX, 205)
        end
        
        love.graphics.setFont(fonte_pequena)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("ENTER para confirmar", LARGURA_TELA/2 - 60, 220)
        love.graphics.print("Máx. 10 caracteres", LARGURA_TELA/2 - 65, 240)
        
    elseif ESTADO_JOGO == "ranking" then
        love.graphics.setFont(fonte_grande)
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.print("TOP 10 - BALEIA AZUL", LARGURA_TELA/2 - 120, 20)
        
        love.graphics.setFont(fonte_media)
        love.graphics.setColor(1, 1, 1)
        
        -- Desenha ranking
        for i = 1, math.min(10, #RANKING) do
            local entry = RANKING[i]
            local y = 70 + (i-1) * 35
            
            -- Destaque para a última pontuação adicionada
            if i == 1 and entry.pontos == PONTUACAO then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            
            -- Posição
            love.graphics.print(string.format("%2d.", i), 50, y)
            
            -- Nome
            love.graphics.print(entry.nome, 90, y)
            
            -- Pontuação
            love.graphics.print(string.format("%6d", entry.pontos), LARGURA_TELA - 100, y)
            
            -- Medalhas para os 3 primeiros
            if i == 1 then
                love.graphics.setColor(1, 0.8, 0)
                love.graphics.print("🥇", 30, y-5)
            elseif i == 2 then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print("🥈", 30, y-5)
            elseif i == 3 then
                love.graphics.setColor(0.8, 0.5, 0.2)
                love.graphics.print("🥉", 30, y-5)
            end
        end
        
        love.graphics.setFont(fonte_pequena)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Sua pontuação: " .. PONTUACAO, LARGURA_TELA/2 - 60, ALTURA_TELA - 80)
        love.graphics.print("ESPACO ou ENTER para jogar novamente", LARGURA_TELA/2 - 120, ALTURA_TELA - 50)
        love.graphics.print("ESC para sair", LARGURA_TELA/2 - 50, ALTURA_TELA - 30)
    end
    
    love.graphics.setColor(1, 1, 1)
end