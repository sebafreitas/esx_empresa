ESX = exports["es_extended"]:getSharedObject()

-- Eliminamos la verificación de IP
-- local allowed_ips = {
--     ["192.168.1.100"] = true,
--     ["192.168.1.101"] = true,
--     -- Agrega más IPs permitidas según sea necesario
-- }

local vrp_ready = true  -- Establecemos vrp_ready como verdadero

-- Eliminamos la función CheckIP()

function SendWebhookMessage(webhook, message)
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
end

-- Eliminamos el evento playerConnecting relacionado con la verificación de IP

Citizen.CreateThread(function()
    Wait(5000)
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `vrp_empresas` (
            `local` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
            `user_id` VARCHAR(50) NOT NULL,
            `produtos` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `pesquisa` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `suprimentos` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `funcionarios` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade1` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade2` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade3` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `ganhos` INT(10) UNSIGNED NOT NULL DEFAULT '0',
            `vendas` INT(10) UNSIGNED NOT NULL DEFAULT '0',
            PRIMARY KEY (`local`, `user_id`) USING BTREE
        )
        COLLATE='utf8mb4_general_ci'
        ENGINE=InnoDB
        ;
    ]])
end)

-- También eliminamos el segundo hilo de verificación de IP

-- Citizen.CreateThread(function()
--     PerformHttpRequest("https://api.ipify.org?format=json", function(err, data, headers)
--         if data then
--             local ip = json.decode(data).ip
--             if allowed_ips[ip] then
--                 vrp_ready = true
--                 print("^2["..GetCurrentResourceName().."] Script autenticado, cualquier duda, contáctame en Discord perttex")
--             else
--                 vrp_ready = false
--                 print("^8["..GetCurrentResourceName().."] Tu IP no está autenticada, contáctame en Discord perttex")
--                 SendWebhookMessage("https://discordapp.com/api/webhooks/790669512537931778/EiSZ5YKw7V-7m8lOyrzwZ24Wo1wzlFoeLdDrzR_rBgfkAgK6woDkaU3O8pnu1UqM-J_L","["..GetCurrentResourceName().."] "..ip)
--             end
--         else
--             print("^8["..GetCurrentResourceName().."] Problemas con el servidor. ¡Intenta nuevamente! Cualquier duda, contáctame en Discord perttex")
--         end
--     end, "GET", "", {})
-- end)


--local version = 5
--Citizen.CreateThread(function()
--    PerformHttpRequest("https://github.com/sebafreitas/fivem_ip_version_lock/ips/ip_empresas.txt", function(err, database_ips, headers)
--       if database_ips then
--            print("Datos recibidos:", database_ips)
--            local arr_ips = json.decode(database_ips)
--            for k,v in pairs(arr_ips) do
--                -- Tu código aquí
--            end
--        else
--            print("Error al recuperar los datos:", err)
--        end
--    end, "GET", "", {})
--end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.tempo_processamento_suprimentos*1000*60)
        if vrp_ready then
            local sql = "SELECT local, user_id, produtos, pesquisa, suprimentos, funcionarios, upgrade2 FROM `vrp_empresas`";
            local query = MySQL.Sync.fetchAll(sql, {});
            for k,v in pairs(query) do
                if tonumber(v.suprimentos) > 1 then
                    local upgrade = 0
                    if tonumber(v.upgrade2) == 1 then
                        if math.random(0,100) < 30 then
                            upgrade = 1
                        end
                    end

                    local suprimentos = tonumber(v.suprimentos)
                    local pesquisa = tonumber(v.pesquisa)
                    local produtos = tonumber(v.produtos)
                    if tonumber(v.funcionarios) == 0 then
                        if produtos ~= Config.empresas[v['local']].max_estoque_produtos then
                            if produtos + 2 + upgrade <= Config.empresas[v['local']].max_estoque_produtos then
                                suprimentos = suprimentos - 2
                                produtos = produtos + 2 + upgrade
                            else
                                suprimentos = suprimentos - 2
                                produtos = Config.empresas[v['local']].max_estoque_produtos
                            end
                        end
                    elseif tonumber(v.funcionarios) == 1 then
                        if pesquisa ~= 400 then
                            if pesquisa + 2 + upgrade <= 400 then
                                suprimentos = suprimentos - 2
                                pesquisa = pesquisa + 2 + upgrade
                            else
                                suprimentos = suprimentos - 2
                                pesquisa = 400
                            end
                        end
                    elseif tonumber(v.funcionarios) == 2 then
                        if pesquisa ~= 400 then
                            if pesquisa + 1 + upgrade <= 400 then
                                suprimentos = suprimentos - 1
                                pesquisa = pesquisa + 1 + upgrade
                            else
                                suprimentos = suprimentos - 1
                                pesquisa = 400
                            end
                        end
                        if produtos ~= Config.empresas[v['local']].max_estoque_produtos then
                            if produtos + 1 + upgrade <= Config.empresas[v['local']].max_estoque_produtos then
                                suprimentos = suprimentos - 1
                                produtos = produtos + 1 + upgrade
                            else
                                suprimentos = suprimentos - 1
                                produtos = Config.empresas[v['local']].max_estoque_produtos
                            end
                        end
                    end
                    local sql = "UPDATE `vrp_empresas` SET suprimentos = @suprimentos, pesquisa = @pesquisa, produtos = @produtos WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = v['local'], ['@user_id'] = v.user_id, ['@suprimentos'] = suprimentos, ['@pesquisa'] = pesquisa, ['@produtos'] = produtos});

                    local xPlayer = ESX.GetPlayerFromIdentifier(v.user_id)
                    if xPlayer then
                        openEmpresa(xPlayer.source, v['local'], true)
                    end
                end
            end
        end
    end
end)

RegisterServerEvent("vrp_empresas:saquear")
AddEventHandler("vrp_empresas:saquear",function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local user_id = xPlayer.identifier
        if user_id then
            local sql = "SELECT * FROM `vrp_empresas` WHERE user_id = @user_id";
            local query = MySQL.Sync.fetchAll(sql, {['@user_id'] = user_id});
            if query and query[1] then
                if tonumber(query[1].upgrade3) == 0 and Config.probabilidade_ser_saqueado > math.random(0,100)/100 then
                    local sql = "UPDATE `vrp_empresas` SET suprimentos = @suprimentos, pesquisa = @pesquisa, produtos = @produtos WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = query[1]['local'], ['@user_id'] = user_id, ['@suprimentos'] = 0, ['@pesquisa'] = 0, ['@produtos'] = 0});
                    TriggerClientEvent("vrp_empresas:playSound",source,"Out_Of_Area","DLC_Lowrider_Relay_Race_Sounds")
                    TriggerClientEvent("Notify",source,"importante",Lang[Config.lang]['business_sacked']:format(Config.empresas[query[1]['local']].nome))
                    SendWebhookMessage(Config.webhook,Lang[Config.lang]['business_sacked']:format(Config.empresas[query[1]['local']].nome,user_id..os.date("\n["..Lang[Config.lang]['logs_date'].."]: %d/%m/%Y ["..Lang[Config.lang]['logs_hour'].."]: %H:%M:%S")))
                end
            end
        end
    end
end)

RegisterServerEvent("vrp_empresas:getEmpresa")
AddEventHandler("vrp_empresas:getEmpresa",function(key)
    if vrp_ready then
        local source = source
        local xPlayer = ESX.GetPlayerFromId(source)
        local user_id = xPlayer.identifier
        if user_id then
            local sql = "SELECT * FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
            local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
            if query and query[1] then
                openEmpresa(source,key,false)
            else
                local sql = "SELECT local FROM `vrp_empresas` WHERE user_id = @user_id";
                local query = MySQL.Sync.fetchAll(sql, {['@user_id'] = user_id});
                if query and query[1] then
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['already_has_business'])
                else
                    local sql = "SELECT local FROM `vrp_empresas` WHERE local = @local";
                    local query = MySQL.Sync.fetchAll(sql, {['@local'] = key});
                    if #query >= Config.max_owners then
                        TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['max_owners'])
                    else
                        money = xPlayer.getAccount('bank').money
                        if money >= Config.empresas[key].valor_compra then
                            xPlayer.removeAccountMoney('bank', Config.empresas[key].valor_compra)
                            local sql = "INSERT INTO `vrp_empresas` VALUES (@local, @user_id, 0, 0, 0, 0, 0, 0, 0, 0, 0)";
                            MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id});
                            TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['businnes_bougth']:format(Config.empresas[key].nome))
                            openEmpresa(source,key,false)
                            SendWebhookMessage(Config.webhook,Lang[Config.lang]['logs_bought']:format(Config.empresas[key].nome,user_id..os.date("\n["..Lang[Config.lang]['logs_date'].."]: %d/%m/%Y ["..Lang[Config.lang]['logs_hour'].."]: %H:%M:%S")))
                        else
                            TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_funds'])
                        end
                    end
                end
            end
        end
    end
end)

RegisterServerEvent("vrp_empresas:roubarSuprimentos")
AddEventHandler("vrp_empresas:roubarSuprimentos",function(key)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    if user_id then
        local sql = "SELECT suprimentos FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
        local max_estoque_suprimentos = getMaxEstoqueSuprimentos(user_id,key)
        if tonumber(query[1].suprimentos) < max_estoque_suprimentos then
            local suprimentos = tonumber(query[1].suprimentos) + Config.empresas[key].quantidade_roubo_suprimentos
            if suprimentos > max_estoque_suprimentos then
                suprimentos = max_estoque_suprimentos
            end
            TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['stolen_sucess']:format(suprimentos-tonumber(query[1].suprimentos)))
            local sql = "UPDATE `vrp_empresas` SET suprimentos = @suprimentos WHERE `local` = @local AND user_id = @user_id";
            MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@suprimentos'] = suprimentos});
            openEmpresa(source,key,true)
        else
            TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['supplies_full'])
        end
    end
end)

local waiting = {}
RegisterServerEvent("vrp_empresas:comprarSuprimentos")
AddEventHandler("vrp_empresas:comprarSuprimentos",function(key,data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    if user_id then
        local sql = "SELECT suprimentos FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
        if not waiting[user_id] then
            local max_estoque_suprimentos = getMaxEstoqueSuprimentos(user_id,key)
            if tonumber(query[1].suprimentos) < max_estoque_suprimentos then
                money = xPlayer.getAccount('bank').money
                if money >= Config.empresas[key].valor_comprar_suprimentos then
                    xPlayer.removeAccountMoney('bank', Config.empresas[key].valor_comprar_suprimentos)
                    waiting[user_id] = true
                    TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['supplies_bought']:format(Config.empresas[key].quantidade_compra_suprimentos,Config.tempo_suprimentos))
                    SetTimeout(Config.tempo_suprimentos*1000, function()
                        waiting[user_id] = false
                        TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['supplies_arrived'])
                        local sql = "SELECT suprimentos FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
                        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
                        local suprimentos = tonumber(query[1].suprimentos) + Config.empresas[key].quantidade_compra_suprimentos
                        if suprimentos > max_estoque_suprimentos then
                            suprimentos = max_estoque_suprimentos
                        end
                        local sql = "UPDATE `vrp_empresas` SET suprimentos = @suprimentos WHERE `local` = @local AND user_id = @user_id";
                        MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@suprimentos'] = suprimentos});
                        openEmpresa(source,key,true)
                    end)
                else
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_funds'])
                end
            else
                TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['supplies_full'])
            end
        else
            TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['supplies_on_course'])
        end
    end
end)

RegisterServerEvent("vrp_empresas:venderProdutos")
AddEventHandler("vrp_empresas:venderProdutos",function(key, data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    if user_id then
        local sql = "SELECT produtos FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
        if tonumber(query[1].produtos) > 10 then
            if data == 1 then
                -- Vender para Blaine Country
                if tonumber(query[1].produtos) > Config.qtd_venda_pouco then
                    local sql = "UPDATE `vrp_empresas` SET produtos = @produtos WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@produtos'] = 0});
                    if tonumber(query[1].produtos) > Config.qtd_venda_medio then
                        TriggerClientEvent("vrp_empresas:venderProdutos",source, key, 3, tonumber(query[1].produtos))
                    else
                        TriggerClientEvent("vrp_empresas:venderProdutos",source, key, 2, tonumber(query[1].produtos))
                    end
                else
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_products_blaine']:format(Config.qtd_venda_pouco,query[1].produtos))
                end
            elseif data == 2 then
                -- Vender para Los Santos
                local qtd_venda = tonumber(query[1].produtos)
                if tonumber(query[1].produtos) > Config.qtd_venda_pouco then
                    qtd_venda = Config.qtd_venda_pouco
                else
                    qtd_venda = tonumber(query[1].produtos)
                end
                local sql = "UPDATE `vrp_empresas` SET produtos = @produtos WHERE `local` = @local AND user_id = @user_id";
                MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@produtos'] = tonumber(query[1].produtos) - qtd_venda});
                TriggerClientEvent("vrp_empresas:venderProdutos",source, key, 1, qtd_venda)
            end
        else
            TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_products'])
        end
    end
end)

RegisterServerEvent("vrp_empresas:venderProdutos2")
AddEventHandler("vrp_empresas:venderProdutos2",function(key,tipo,qtd)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    if user_id then
        local valor = 0
        if tipo == 1 then
            -- Vender para Los Santos
            valor = qtd * Config.multiplicador_lossantos
        elseif tipo == 2 then
            -- Vender para Blaine Country
            valor = qtd * Config.multiplicador_blaine
        elseif tipo == 3 then
            -- Vender para Paleto
            valor = qtd * Config.multiplicador_paleto
        end
        local sql = "SELECT ganhos, vendas FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
        local sql = "UPDATE `vrp_empresas` SET ganhos = @ganhos, vendas = @vendas WHERE `local` = @local AND user_id = @user_id";
        MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@ganhos'] = tonumber(query[1].ganhos)+valor, ['@vendas'] = tonumber(query[1].vendas)+1});
        xPlayer.addMoney(valor)
        TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['products_sold']:format(qtd,valor))
        SendWebhookMessage(Config.webhook,Lang[Config.lang]['logs_products']:format(Config.empresas[key].nome,valor,user_id..os.date("\n["..Lang[Config.lang]['logs_date'].."]: %d/%m/%Y ["..Lang[Config.lang]['logs_hour'].."]: %H:%M:%S")))
    end
end)

RegisterServerEvent("vrp_empresas:alocar")
AddEventHandler("vrp_empresas:alocar",function(key,data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    local sql = "UPDATE `vrp_empresas` SET funcionarios = @funcionarios WHERE `local` = @local AND user_id = @user_id";
    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@funcionarios'] = data});
end)

RegisterServerEvent("vrp_empresas:upgrades")
AddEventHandler("vrp_empresas:upgrades",function(key,data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    if user_id then
        local sql = "SELECT pesquisa FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
        local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
        if tonumber(query[1].pesquisa) >= 400 then
            if data == 1 then
                -- Equipamentos
                money = xPlayer.getAccount('bank').money
                if money >= Config.empresas[key].valor_evoluir_equipamentos then
                    xPlayer.removeAccountMoney('bank', Config.empresas[key].valor_evoluir_equipamentos)
                    local sql = "UPDATE `vrp_empresas` SET upgrade1 = 1, pesquisa = @pesquisa WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@pesquisa'] = tonumber(query[1].pesquisa) - 400});
                    TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['upgrade1_bought'])
                    openEmpresa(source,key,true)
                else
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_funds'])
                end
            elseif data == 2 then
                -- Funcionarios
                money = xPlayer.getAccount('bank').money
                if money >= Config.empresas[key].valor_evoluir_funcionarios then
                    xPlayer.removeAccountMoney('bank', Config.empresas[key].valor_evoluir_funcionarios)
                    local sql = "UPDATE `vrp_empresas` SET upgrade2 = 1, pesquisa = @pesquisa WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@pesquisa'] = tonumber(query[1].pesquisa) - 400});
                    TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['upgrade2_bought'])
                    openEmpresa(source,key,true)
                else
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_funds'])
                end
            elseif data == 3 then
                -- Segurança
                money = xPlayer.getAccount('bank').money
                if money >= Config.empresas[key].valor_evoluir_seguranca then
                    xPlayer.removeAccountMoney('bank', Config.empresas[key].valor_evoluir_seguranca)
                    local sql = "UPDATE `vrp_empresas` SET upgrade3 = 1, pesquisa = @pesquisa WHERE `local` = @local AND user_id = @user_id";
                    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id, ['@pesquisa'] = tonumber(query[1].pesquisa) - 400});
                    TriggerClientEvent("Notify",source,"sucesso",Lang[Config.lang]['upgrade2_bought'])
                    openEmpresa(source,key,true)
                else
                    TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_funds'])
                end
            end
        else
            TriggerClientEvent("Notify",source,"negado",Lang[Config.lang]['insufficient_research']:format(tonumber(query[1].pesquisa)))
        end
    end
end)

RegisterServerEvent("vrp_empresas:fecharEmpresa")
AddEventHandler("vrp_empresas:fecharEmpresa",function(key)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    local sql = "DELETE FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
    MySQL.Sync.execute(sql, {['@local'] = key, ['@user_id'] = user_id});
    TriggerClientEvent("Notify",source,"importante",Lang[Config.lang]['business_closed'])
    SendWebhookMessage(Config.webhook,Lang[Config.lang]['logs_close']:format(Config.empresas[key].nome,user_id..os.date("\n["..Lang[Config.lang]['logs_date'].."]: %d/%m/%Y ["..Lang[Config.lang]['logs_hour'].."]: %H:%M:%S")))
end)

function openEmpresa(source, key, reset)
    local xPlayer = ESX.GetPlayerFromId(source)
    local user_id = xPlayer.identifier
    local sql = "SELECT * FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
    local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});

    -- Gera as quantidades de venda
    local qtd_ls = tonumber(query[1].produtos)
    local qtd_bc = tonumber(query[1].produtos)
    if tonumber(query[1].produtos) > Config.qtd_venda_pouco then
        qtd_ls = Config.qtd_venda_pouco
    end

    -- Gera os valores de venda
    local valor_ls = qtd_ls * Config.multiplicador_lossantos
    if qtd_bc > Config.qtd_venda_medio then
        valor_bc = qtd_bc * Config.multiplicador_paleto
    else
        valor_bc = qtd_bc * Config.multiplicador_blaine
    end

    -- Anexa as informações geradas
    query[1].lossantos = valor_ls
    query[1].qtd_lossantos = qtd_ls
    query[1].blaine = valor_bc
    query[1].qtd_blaine = qtd_bc
    query[1].config = deepcopy(Config.empresas[key])

    -- Verifica upgrade de equipamentos e altera o estoque máximo
    query[1].config.max_estoque_suprimentos = getMaxEstoqueSuprimentos(user_id,key)

    -- Envia pro front-end
    TriggerClientEvent("vrp_empresas:abrirEmpresa",source, query[1], reset)
end

function getMaxEstoqueSuprimentos(user_id,key)
    local sql = "SELECT upgrade1 FROM `vrp_empresas` WHERE local = @local AND user_id = @user_id";
    local query = MySQL.Sync.fetchAll(sql, {['@local'] = key, ['@user_id'] = user_id});
    if tonumber(query[1].upgrade1) == 1 then
        return Config.empresas[key].max_estoque_suprimentos + Config.empresas[key].estoque_evoluir_equipamentos
    end
    return Config.empresas[key].max_estoque_suprimentos
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

RegisterServerEvent("lixeiroHeist:ptfx")
AddEventHandler("lixeiroHeist:ptfx", function(xb,yb,zb)
    TriggerClientEvent("lixeiroHeist:ptfx_c", -1, xb,yb,zb)
end)

RegisterServerEvent('lixeiroCB:getC4')
AddEventHandler('lixeiroCB:getC4', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem(Config.itemC4).count >= 1 then
        xPlayer.removeInventoryItem(Config.itemC4, 1)
        TriggerClientEvent('lixeiroCB:getC4', source, true)
    else
        TriggerClientEvent('lixeiroCB:getC4', source, false)
    end
end)

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end