-- LOCAL
--------
local menuactive = false
local empresaAtual = nil
Citizen.CreateThread(function()
    -- SetNuiFocus(false,false)
    local timer = 10
    while true do
        timer = 3000
        for k,mark in pairs(Config.empresas) do
            local x,y,z = table.unpack(mark.coordenada)
            local distance = #(GetEntityCoords(PlayerPedId()) - vector3(x,y,z))
            if not menuactive and distance <= 20.0 then
                timer = 10
                DrawMarker(21,x,y,z-0.6,0,0,0,0.0,0,0,0.5,0.5,0.4,255,0,0,50,0,0,0,1)
                if distance <= 1.5 then
                    DrawText3D2(x,y,z-0.6, Lang[Config.lang]['open'], 0.40)
                    if IsControlJustPressed(0,38) then
                        empresaAtual = k
                        TriggerServerEvent("vrp_empresas:getEmpresa",empresaAtual) 
                    end
                end
            end
        end
        Citizen.Wait(timer)
    end
end)

RegisterNetEvent('vrp_empresas:abrirEmpresa')
AddEventHandler('vrp_empresas:abrirEmpresa', function(dados,update)
    SendNUIMessage({ 
        showmenu = true,
        update = update,
        dados = dados
    })
    if update == false then
        menuactive = true
        SetNuiFocus(true,true)
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent("vrp_empresas:saquear") 
end)



-- CALLBACKS
------------

RegisterNUICallback("suprimentos",function(data,cb)
    if data == 1 then
        -- Robo de suministros
        TriggerEvent("vrp_empresas:roubarSuprimentos",empresaAtual)
    elseif data == 2 then
        -- Comprar suministros
        TriggerServerEvent("vrp_empresas:comprarSuprimentos",empresaAtual, data)
    end
end)

RegisterNUICallback("estoque",function(data,cb)
    TriggerServerEvent("vrp_empresas:venderProdutos",empresaAtual, data)
end)

RegisterNUICallback("alocar",function(data,cb)
    TriggerServerEvent("vrp_empresas:alocar",empresaAtual, data)
end)

RegisterNUICallback("upgrades",function(data,cb)
    TriggerServerEvent("vrp_empresas:upgrades",empresaAtual, data)
end)

RegisterNUICallback("fecharEmpresa",function(data,cb)
    TriggerServerEvent("vrp_empresas:fecharEmpresa",empresaAtual)
    closeUI()
end)

RegisterNUICallback('fechar', function(data, cb)
    closeUI()
end)

function closeUI()
    empresaAtual = nil
    menuactive = false
    SetNuiFocus(false,false)
    SendNUIMessage({ hidemenu = true })
end



-- ROBAR SUMINISTROS
--------------------

local nveh = nil
local blip = nil
local blipgaragem = nil
local bomba = nil

-- NPCs
local Group = nil
local Driver = nil
local Passenger = nil
local Enemyveh = nil
local Enemyblip = nil

local output = nil
RegisterNetEvent('lixeiroCB:getC4')
AddEventHandler('lixeiroCB:getC4', function(ret)
    output = ret
end)

RegisterNetEvent('vrp_empresas:roubarSuprimentos')
AddEventHandler('vrp_empresas:roubarSuprimentos', function(key)
    if not blip then
        TriggerEvent("Notify","importante",Lang[Config.lang]['new_cargo'])
        roubarCarga(key)
    else
        TriggerEvent("Notify","negado",Lang[Config.lang]['already_in_job'])
    end
end)

function roubarCarga(key)
    local rand = math.random(#Config.locais_roubo)
    createBlip(Config.locais_roubo[rand][1],Config.locais_roubo[rand][2],Config.locais_roubo[rand][3])
    x2,y2,z2,h = Config.locais_roubo[rand][1],Config.locais_roubo[rand][2],Config.locais_roubo[rand][3],Config.locais_roubo[rand][4]
    x,y,z = table.unpack(Config.empresas[key].coordenada_garagem)
    local timer = 10
    bomba = nil
    while blip do
        timer = 3000
        local ped = PlayerPedId()
        veh = GetVehiclePedIsIn(ped,false)

        local distance = #(GetEntityCoords(ped) - vector3(x,y,z))
        if distance <= 50.0 then
            timer = 10
            DrawMarker(39,x,y,z-0.6,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
            DrawText3D2(x,y,z-0.6, Lang[Config.lang]['garage_marker'], 0.40)
            if distance <= 4.0 then
                if veh == nveh then
                    BringVehicleToHalt(nveh, 2.5, 1, false)
                    Citizen.Wait(10)
                    DoScreenFadeOut(500)
                    Citizen.Wait(500)
                    DeleteVehicle(nveh)
                    RemoveBlip(blip)
                    RemoveBlip(blipgaragem)
                    PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
                    Citizen.Wait(1000)
                    DoScreenFadeIn(1000)
                    Citizen.CreateThreadNow(function()
                        showScaleform(Lang[Config.lang]['sucess'], Lang[Config.lang]['sucess_finished'], 3)
                    end)
                    nveh = nil
                    blip = nil
                    blipgaragem = nil
                    TriggerServerEvent("vrp_empresas:roubarSuprimentos",key)
                    return
                end
            end
        end

        local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(nveh,GetEntityBoneIndexByName(nveh,"door_dside_r")))
        local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(nveh,GetEntityBoneIndexByName(nveh,"door_dside_r")))
        if distance2 < 50.0 and not blipgaragem then
            timer = 10
            if distance2 < 2.0 and not bomba and not IsPedInAnyVehicle(ped) then
                DrawText3D2(xb,yb,zb, Lang[Config.lang]['explode_door'], 0.40)
                if IsControlJustPressed(0,38) then
                    output = nil
                    TriggerServerEvent('lixeiroCB:getC4')
                    while output == nil do 
                        Wait(10)
                    end
                    if output == true then
                        SetVehicleEngineHealth(nveh,-4000)
                        SetVehicleUndriveable(nveh,true)
                        bomba = true
                        RequestNamedPtfxAsset("scr_ornate_heist")
                        local x,y,z = GetEntityCoords(ped)
                        local distance = GetDistanceBetweenCoords(xb,yb,zb, x,y,z,true)
                        if distance <= 3 then
                            TaskGoStraightToCoord(ped, xb,yb,zb,1.0, 100000, GetEntityHeading(nveh), 2.0)
                            if distance <= 0.3 then
                                ClearPedTasks(ped)
                            end
                        end
                        local thermal_hash = GetHashKey("hei_prop_heist_thermite_flash")
                        local bagHash4 = GetHashKey('p_ld_heist_bag_s_pro_o')
                        local coords = GetEntityCoords(ped)
                        loadModel(thermal_hash)
                        Wait(10)
                        loadModel(bagHash4)
                        Wait(10)

                        thermalentity = CreateObject(thermal_hash, (xb+yb+zb)-20, true, true)
                        local bagProp4 = CreateObject(bagHash4, coords-20, true, false)
                        SetEntityAsMissionEntity(thermalentity, true, true)
                        SetEntityAsMissionEntity(bagProp4, true, true)
                        termitacolocando = true
                        local boneIndexf1 = GetPedBoneIndex(PlayerPedId(), 28422)
                        local bagIndex1 = GetPedBoneIndex(PlayerPedId(), 57005)
                        Wait(500)
                        SetEntityHeading(ped, GetEntityHeading(nveh))
                        SetPedComponentVariation(PlayerPedId(), 5, 0, 0, 0)
                        AttachEntityToEntity(thermalentity, PlayerPedId(), boneIndexf1, 0.0, 0.0, 0.0, 180.0, 180.0, 0, 1, 1, 0, 1, 1, 1)
                        AttachEntityToEntity(bagProp4, PlayerPedId(), bagIndex1, 0.3, -0.25, -0.3, 300.0, 200.0, 300.0, true, true, false, true, 1, true)

                        RequestAnimDict('anim@heists@ornate_bank@thermal_charge')
                        while not HasAnimDictLoaded('anim@heists@ornate_bank@thermal_charge') do
                            Wait(100)
                        end
                        playAnim(false,{{'anim@heists@ornate_bank@thermal_charge','thermal_charge'}},false)

                        Wait(2500)
                        DetachEntity(bagProp4, 1, 1)
                        FreezeEntityPosition(bagProp4, true)
                        Wait(2500)
                        FreezeEntityPosition(bagProp4, false)
                        AttachEntityToEntity(bagProp4, PlayerPedId(), bagIndex1, 0.3, -0.25, -0.3, 300.0, 200.0, 300.0, true, true, false, true, 1, true)
                        Wait(1000)
                        DeleteEntity(bagProp4)
                        DeleteObject(bagProp4)
                        SetPedComponentVariation(PlayerPedId(), 5, 40, 0, 0)
                        ClearPedTasks(player)
                        TriggerEvent("Notify","importante",Lang[Config.lang]['planted_bomb'])

                        TriggerServerEvent("lixeiroHeist:ptfx", xb,yb,zb)
                        SetPtfxAssetNextCall("scr_ornate_heist")
                        local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", vector3(xb,yb,zb), 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                        DeleteEntity(thermalentity)

                        Citizen.Wait(15000)
                        SetVehicleDoorOpen(nveh,2,0,0)
                        SetVehicleDoorOpen(nveh,3,0,0)
                        StopParticleFxLooped(effect, 0)

                        local crate_prop = "prop_drop_crate_01"
                        RequestModel(crate_prop)
                        while not HasModelLoaded(crate_prop) do
                            Citizen.Wait(10)
                        end
                        SetModelAsNoLongerNeeded(crate_prop)
                        local boneIndex = GetPedBoneIndex(PlayerPedId(), 57005)
                        crate_obj = CreateObjectNoOffset(crate_prop, xb,yb,zb, 1, 0, 1)
                        while crate_obj do 
                            Citizen.Wait(10)
                            x,y,z = table.unpack(GetEntityCoords(ped))
                            distance2 = GetDistanceBetweenCoords(xb,yb,zb,x,y,z,true)
                            x2,y2,z2 = table.unpack(GetEntityCoords(crate_obj))
                            if distance2 <= 2.0 then
                                DrawText3D2(x2,y2,z2,Lang[Config.lang]['pickup'],0.40)
                                if IsControlJustPressed(0,47) and not IsPedInAnyVehicle(ped) and not IsEntityDead(ped) then
                                    playAnim(false,{{'pickup_object','pickup_low'}},false)
                                    Wait(1000)
                                    SetEntityVisible(crate_obj, true)
                                    TriggerServerEvent("vrp_empresas:roubarSuprimentos",key)
                                    PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
                                    Citizen.CreateThreadNow(function()
                                        showScaleform(Lang[Config.lang]['sucess'], Lang[Config.lang]['sucess_supplies'], 2)
                                    end)
                                    AttachEntityToEntity(crate_obj, PlayerPedId(), boneIndex, 0.125, 0.0, -0.05, 360.0, 150.0, 360.0, true, true, false, true, 1, true)
                                    Wait(800)
                                    SetEntityVisible(crate_obj, false)

                                    DeleteEntity(crate_obj)
                                    RemoveBlip(blip)
                                    RemoveBlip(blipgaragem)
                                    nveh = nil
                                    blip = nil
                                    blipgaragem = nil
                                    crate_obj = nil
                                    return
                                end
                            elseif Vdist(xb,yb,zb,x,y,z) > 100.0 then
                                TriggerEvent("Notify","negado",Lang[Config.lang]['run_away'])

                                DeleteEntity(crate_obj)
                                RemoveBlip(blip)
                                RemoveBlip(blipgaragem)
                                nveh = nil
                                blip = nil
                                blipgaragem = nil
                                crate_obj = nil
                                return
                            end
                        end
                    else
                        TriggerEvent("Notify","negado",Lang[Config.lang]['need_c4'])
                    end
                end
            end
        end

        local distance3 = #(GetEntityCoords(ped) - vector3(x2,y2,z2))
        if distance3 <= 100.0 and nveh == nil then
            local rand_v = math.random(#Config.veiculos_roubo)
            spawnVehicle(Config.veiculos_roubo[rand_v],x2,y2,z2,h)
        end

        if not blipgaragem then
            if veh == nveh then
                timer = 10
                blipgaragem = AddBlipForCoord(x,y,z)
                SetBlipSprite(blipgaragem, 357)
                SetBlipColour(blipgaragem, 1)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(Lang[Config.lang]['blip_garage'])
                EndTextCommandSetBlipName(blipgaragem)
                SetBlipAsShortRange(blipgaragem, false)
                SetBlipAsMissionCreatorBlip(blipgaragem,true)
                SetBlipRoute(blipgaragem, 1)
                TriggerEvent("Notify","importante",Lang[Config.lang]['stolen_route'])

                Citizen.CreateThreadNow(function()
                    geradorNPCs()
                end)
            end
        end

        local enghealth = GetVehicleEngineHealth(nveh)
        if enghealth <= 150 then
            SetVehicleEngineHealth(nveh,-4000)
            SetVehicleUndriveable(nveh,true)
            RemoveBlip(blip)
            RemoveBlip(blipgaragem)
            nveh = nil
            blip = nil
            blipgaragem = nil
            PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
            TriggerEvent("Notify","negado",Lang[Config.lang]['vehicle_destroyed'])
            return
        end

        if IsEntityDead(ped) then
            RemoveBlip(blip)
            RemoveBlip(blipgaragem)
            nveh = nil
            blip = nil
            blipgaragem = nil
            PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
            TriggerEvent("Notify","negado",Lang[Config.lang]['you_died'])
            return
        end

        Citizen.Wait(timer)
    end
end

function geradorNPCs()
    local timer = 3000
    while nveh do
        timer = 3000
        if Config.NPC then
            timer = 1
            local player = PlayerPedId()
            local playerloc = GetEntityCoords(player)
            local driverloc = GetEntityCoords(Driver)
            local distance = GetDistanceBetweenCoords(playerloc, driverloc, false)
            Citizen.Wait(2000)
            if not DoesEntityExist(Driver) or IsEntityDead(Driver) or distance > 400 then
                despawnNPC()
                Citizen.Wait(15000)
                Currentloc = GetEntityCoords(player)
                SpawnEnemyNPC(Currentloc.x, Currentloc.y, Currentloc.x, player)
            end

            if IsEntityDead(Driver) then
                RemoveBlip(Enemyblip)
            end
        end
        Citizen.Wait(timer)
    end

    despawnNPC()
    Driver = nil
    Passenger = nil
    Enemyveh = nil
    Enemyblip = nil
    Group = nil
end

function despawnNPC()
    ClearPedTasksImmediately(Driver)            ClearPedTasksImmediately(Passenger)
    SetPedAlertness(Driver, 0)                  SetPedAlertness(Passenger, 0)
    SetPedCombatAttributes(Driver, 46, false)   SetPedCombatAttributes(Passenger, 46, false)
    RemoveBlip(Enemyblip)
    RemoveRelationshipGroup(Group)
    Citizen.Wait(1000)
    SetEntityAsNoLongerNeeded(Driver)
    SetEntityAsNoLongerNeeded(Passenger)
    SetEntityAsNoLongerNeeded(Enemyveh)
end



-- VENDER STOCK
---------------

local nveh2 = nil
local blip2 = nil
RegisterNetEvent('vrp_empresas:venderProdutos')
AddEventHandler('vrp_empresas:venderProdutos', function(key,tipo,qtd)
    local local_de_venda = {}
    if tipo == 1 then
        -- Vender poco
        local_de_venda = Config.locais_venda_pouco
    elseif tipo == 2 then
        -- Vender medio
        local_de_venda = Config.locais_venda_medio
    elseif tipo == 3 then
        -- Vender mucho
        local_de_venda = Config.locais_venda_muito
    end

    local rand = math.random(#local_de_venda)
    if not nveh2 then
        spawnVehicle2(local_de_venda[rand].car,Config.empresas[key].coordenada_garagem[1],Config.empresas[key].coordenada_garagem[2],Config.empresas[key].coordenada_garagem[3],Config.empresas[key].coordenada_garagem[4])

        blip2 = AddBlipForCoord(local_de_venda[rand][1],local_de_venda[rand][2],local_de_venda[rand][3])
        SetBlipSprite(blip2, 478)
        SetBlipColour(blip2, 1)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Lang[Config.lang]['blip_delivery'])
        EndTextCommandSetBlipName(blip2)
        SetBlipAsShortRange(blip2, false)
        SetBlipAsMissionCreatorBlip(blip2,true)
        SetBlipRoute(blip2, 1)

        TriggerEvent("Notify","importante",Lang[Config.lang]['start_delivery'])
        entregaCarga(local_de_venda[rand][1],local_de_venda[rand][2],local_de_venda[rand][3],key,tipo,qtd)
    else
        TriggerEvent("Notify","negado",Lang[Config.lang]['already_in_job'])
    end
end)

function entregaCarga(x,y,z,key,tipo,qtd)
    local timer = 10
    while nveh2 do
        timer = 3000
        local ped = PlayerPedId()
        veh = GetVehiclePedIsIn(ped,false)
        local distance = #(GetEntityCoords(ped) - vector3(x,y,z))
        if distance <= 50.0 then
            timer = 10
            DrawMarker(39,x,y,z-0.6,0,0,0,0.0,0,0,1.0,1.0,1.0,255,0,0,50,0,0,0,1)
            if distance <= 4.0 then
                if veh == nveh2 then
                    BringVehicleToHalt(nveh2, 2.5, 1, false)
                    Citizen.Wait(10)
                    DoScreenFadeOut(500)
                    Citizen.Wait(500)
                    DeleteVehicle(nveh2)
                    RemoveBlip(blip2)
                    PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
                    Citizen.Wait(1000)
                    DoScreenFadeIn(1000)
                    Citizen.CreateThreadNow(function()
                        showScaleform(Lang[Config.lang]['sucess'], Lang[Config.lang]['products_sold'], 3)
                    end)
                    nveh2 = nil
                    blip2 = nil
                    TriggerServerEvent("vrp_empresas:venderProdutos2",key,tipo,qtd)
                    return
                end
            end
        end

        if veh == nveh2 then
            local enghealth = GetVehicleEngineHealth(veh)
            if enghealth <= 150 then
                SetVehicleEngineHealth(veh,-4000)
                SetVehicleUndriveable(veh,true)
                RemoveBlip(blip2)
                nveh2 = nil
                blip2 = nil
                PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
                TriggerEvent("Notify","negado",Lang[Config.lang]['vehicle_destroyed_2'])
                return
            end
        end

        if IsEntityDead(ped) then
            RemoveBlip(blip2)
            nveh2 = nil
            blip2 = nil
            PlaySoundFrontend(-1, "PROPERTY_PURCHASE", "HUD_AWARDS", 0)
            TriggerEvent("Notify","negado",Lang[Config.lang]['you_died_2'])
            return
        end
        Citizen.Wait(timer)
    end
end



-- FUNCIONES
------------

RegisterNetEvent("lixeiroHeist:ptfx_c")
AddEventHandler("lixeiroHeist:ptfx_c", function(x,y,z)
    local ptfx

    RequestNamedPtfxAsset("scr_ornate_heist")
    while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do
        Citizen.Wait(1)
    end
    ptfx = vector3(x,y,z)
    SetPtfxAssetNextCall("scr_ornate_heist")
    local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", ptfx, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Citizen.Wait(13000)
    StopParticleFxLooped(effect, 0)
end)

RegisterNetEvent("vrp_empresas:playSound")
AddEventHandler("vrp_empresas:playSound", function(dict,name)
    PlaySound(-1,name,dict,0,0,1)
end)

function showScaleform(title, desc, sec)
    function Initialize(scaleform)
        local scaleform = RequestScaleformMovie(scaleform)

        while not HasScaleformMovieLoaded(scaleform) do
            Citizen.Wait(0)
        end
        PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
        PushScaleformMovieFunctionParameterString(title)
        PushScaleformMovieFunctionParameterString(desc)
        PopScaleformMovieFunctionVoid()
        return scaleform
    end
    scaleform = Initialize("mp_big_message_freemode")
    while sec > 0 do
        sec = sec - 0.02
        Citizen.Wait(0)
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end
    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

function spawnVehicle(name,x,y,z,h)
    local mhash = GetHashKey(name)
    while not HasModelLoaded(mhash) do
        RequestModel(mhash)
        Citizen.Wait(10)
    end

    if HasModelLoaded(mhash) then
        nveh = CreateVehicle(mhash,x,y,z+0.5,h,true,false)
        local netveh = VehToNet(nveh)

        SetVehicleNumberPlateText(NetToVeh(netveh),Lang[Config.lang]['vehicle_plate'])
        Citizen.InvokeNative(0xAD738C3085FE7E11,NetToVeh(netveh),true,true)
        Citizen.InvokeNative(0xAD738C3085FE7E11,nveh,true,true)
        SetVehicleHasBeenOwnedByPlayer(NetToVeh(netveh),true)
        SetVehicleNeedsToBeHotwired(NetToVeh(netveh),false)
        SetModelAsNoLongerNeeded(mhash)
        SetVehicleDoorsLocked(nveh,1)
        SetVehicleDoorsLocked(NetToVeh(netveh),1)

        RemoveBlip(blip)
        blip = AddBlipForEntity(nveh)
        SetBlipSprite(blip,477)
        SetBlipColour(blip,1)
        SetBlipAsShortRange(blip,false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Lang[Config.lang]['blip_stolen'])
        EndTextCommandSetBlipName(blip)
        SetBlipRoute(blip, 1)
    end
end

function createBlip(x,y,z)
    blip = AddBlipForCoord(x,y,z)
    SetBlipSprite(blip,161)
    SetBlipColour(blip,1)
    SetBlipAsShortRange(blip,false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Lang[Config.lang]['blip_stolen'])
    EndTextCommandSetBlipName(blip)
    SetBlipRoute(blip, 1)
end

function spawnVehicle2(name,x,y,z,h)
    local mhash = GetHashKey(name)
    while not HasModelLoaded(mhash) do
        RequestModel(mhash)
        Citizen.Wait(10)
    end

    if HasModelLoaded(mhash) then
        nveh2 = CreateVehicle(mhash,x,y,z+0.5,h,true,false)
        local netveh = VehToNet(nveh2)

        SetVehicleNumberPlateText(NetToVeh(netveh),Lang[Config.lang]['vehicle_plate'])
        Citizen.InvokeNative(0xAD738C3085FE7E11,NetToVeh(netveh),true,true)
        SetVehicleHasBeenOwnedByPlayer(NetToVeh(netveh),true)
        SetVehicleNeedsToBeHotwired(NetToVeh(netveh),false)
        SetModelAsNoLongerNeeded(mhash)
        SetPedIntoVehicle(PlayerPedId(),nveh2,-1)
        SetVehicleDoorsLocked(nveh2,1)
        SetVehicleDoorsLocked(NetToVeh(netveh),1)
    end
end


function SpawnEnemyNPC(x, y, z, target) -- Funciona decentemente pero no exactamente como yo quiero, todavía trabajando no mejorarlo
    local done, location, heading = GetClosestVehicleNodeWithHeading(x + math.random(-100, 100), y + math.random(-100, 100), z, 1, 3, 0)

    RequestModel(0x964D12DC)
    RequestModel(0x132D5A1A)
    if done and HasModelLoaded(0x964D12DC) and HasModelLoaded(0x132D5A1A) then
        Enemyveh = CreateVehicle(0x132D5A1A, location, heading, true, false)

        ClearAreaOfVehicles(GetEntityCoords(Enemyveh), 200, false, false, false, false, false);
        SetVehicleOnGroundProperly(Enemyveh)
        oke, Group = AddRelationshipGroup("Enemies")
        Driver = CreatePedInsideVehicle(Enemyveh, 12, GetHashKey("g_m_y_mexgoon_03"), -1, true, false)
        Passenger = CreatePedInsideVehicle(Enemyveh, 12, GetHashKey("g_m_y_mexgoon_03"), 0, true, false)
        Enemyblip = AddBlipForEntity(Driver)
        SetBlipAsFriendly(Enemyblip, false)
        SetBlipFlashes(Enemyblip, true)
        SetBlipSprite(Enemyblip, 270)
        SetBlipColour(Enemyblip, 1)

        SetPedRelationshipGroupHash(Driver, Group)             SetPedRelationshipGroupHash(Passenger, Group) -- Pasajero ahora funciona, pero es un poco estúpido :D
        SetEntityCanBeDamagedByRelationshipGroup(Driver, false, Group)  SetEntityCanBeDamagedByRelationshipGroup(Passenger, false, Group)
        GiveWeaponToPed(Driver, "WEAPON_MICROSMG", 400, false, true)    GiveWeaponToPed(Passenger, "WEAPON_MICROSMG", 400, false, true)
        SetPedCombatAttributes(Driver, 1, true)                SetPedCombatAttributes(Passenger, 1, true)
        SetPedCombatAttributes(Driver, 2, true)                SetPedCombatAttributes(Passenger, 2, true)
        SetPedCombatAttributes(Driver, 5, true)                SetPedCombatAttributes(Passenger, 5, true)
        SetPedCombatAttributes(Driver, 16, true)               SetPedCombatAttributes(Passenger, 16, true)
        SetPedCombatAttributes(Driver, 26, true)               SetPedCombatAttributes(Passenger, 26, true)
        SetPedCombatAttributes(Driver, 46, true)               SetPedCombatAttributes(Passenger, 46, true)
        SetPedCombatAttributes(Driver, 52, true)               SetPedCombatAttributes(Passenger, 52, true)
        SetPedFleeAttributes(Driver, 0, 0)                     SetPedFleeAttributes(Passenger, 0, 0)
        SetPedPathAvoidFire(Driver, 1)                         SetPedPathAvoidFire(Passenger, 1)
        SetPedAlertness(Driver,3)                              SetPedAlertness(Passenger,3)
        SetPedFiringPattern(Driver, 0xC6EE6B4C)                SetPedFiringPattern(Passenger, 0xC6EE6B4C)
        SetPedArmour(Driver, 100)                              SetPedArmour(Passenger, 100)
        TaskCombatPed(Driver, target, 0, 16)                   TaskCombatPed(Driver, target, 0, 16)
        TaskVehicleChase(Driver, target)                       SetPedVehicleForcedSeatUsage(Passenger, Enemyveh, 0, 1)
        SetTaskVehicleChaseBehaviorFlag(Driver, 262144, true)
        SetDriverRacingModifier(Driver, 1.0)
        SetDriverAbility(Driver, 1.0)
        --SetPedAsEnemy(Driver, true)                          --SetPedAsEnemy(Passenger, true)
        SetPedDropsWeaponsWhenDead(Driver, false)              SetPedDropsWeaponsWhenDead(Passenger, false)
    end
end

function loadModel(model)
    Citizen.CreateThread(function()
        while not HasModelLoaded(model) do
            RequestModel(model)
          Citizen.Wait(1)
        end
    end)
end


local anims = {}

function playAnim(upper, seq, looping)
    stopAnim(upper)

    local flags = 0
    if upper then flags = flags+48 end
    if looping then flags = flags+1 end

    Citizen.CreateThread(function()
      for k,v in pairs(seq) do
        local dict = v[1]
        local name = v[2]
        local loops = v[3] or 1

        for i=1,loops do
            local first = (k == 1 and i == 1)
            local last = (k == #seq and i == loops)

            -- request anim dict
            RequestAnimDict(dict)
            local i = 0
            while not HasAnimDictLoaded(dict) and i < 1000 do -- tiempo m
              Citizen.Wait(10)
              RequestAnimDict(dict)
              i = i+1
            end

            -- play anim
            if HasAnimDictLoaded(dict)then
              local inspeed = 8.0001
              local outspeed = -8.0001
              if not first then inspeed = 2.0001 end
              if not last then outspeed = 2.0001 end

              TaskPlayAnim(GetPlayerPed(-1),dict,name,inspeed,outspeed,-1,flags,0,0,0,0)
            end

            Citizen.Wait(0)
            while GetEntityAnimCurrentTime(GetPlayerPed(-1),dict,name) <= 0.95 and IsEntityPlayingAnim(GetPlayerPed(-1),dict,name,3) and anims[id] do
              Citizen.Wait(0)
            end
          end
      end
    end)
end
function stopAnim(upper)
    anims = {} -- detener todas las secuencias
    if upper then
        ClearPedSecondaryTask(GetPlayerPed(-1))
    else
        ClearPedTasks(GetPlayerPed(-1))
    end
end


function addBlip(x,y,z,idtype,idcolor,text,scale,route)
    local blip = AddBlipForCoord(x,y,z)
    SetBlipSprite(blip,idtype)
    SetBlipAsShortRange(blip,true)
    SetBlipColour(blip,idcolor)
    SetBlipScale(blip,scale)

    if route then
        SetBlipRoute(blip,true)
    end

    if text then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(text)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

Citizen.CreateThread(function()
    for k,v in pairs(Config.blips) do
        addBlip(v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8])
    end
end)

Citizen.CreateThread(function()
    local timer = 3000
    while true do
        timer = 3000
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped) then
            local x,y,z = table.unpack(GetEntityCoords(ped))
            for k,v in pairs(Config.teleports) do
                local distF = Vdist2(v.positionFrom.x,v.positionFrom.y,v.positionFrom.z,x,y,z)
                local distT = Vdist2(v.positionTo.x,v.positionTo.y,v.positionTo.z,x,y,z)
                if distF <= 20.0 or distT <= 20.0 then
                    timer = 5
                    if distF <= 2.0 then
                        DrawMarker(3,v.positionFrom.x,v.positionFrom.y,v.positionFrom.z-0.6,0,0,0,0.0,0,0,0.5,0.5,0.4,232,67,147,100,1,0,0,1)
                        if IsControlJustPressed(0,38) then
                            SetEntityCoords(ped,v.positionTo.x,v.positionTo.y,v.positionTo.z-0.50)
                        end
                    end

                    if distT <= 2.0 then
                        DrawMarker(3,v.positionTo.x,v.positionTo.y,v.positionTo.z-0.6,0,0,0,0.0,0,0,0.5,0.5,0.4,232,67,147,100,1,0,0,1)
                        if IsControlJustPressed(0,38) then
                            SetEntityCoords(ped,v.positionFrom.x,v.positionFrom.y,v.positionFrom.z-0.50)
                        end
                    end
                end
            end
        end
        Citizen.Wait(timer)
    end
end)