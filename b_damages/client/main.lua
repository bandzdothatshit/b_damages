ESX = exports.es_extended:getSharedObject()

local HitTimes = 0
local Weapon = "Unknown"
local Dmg = 0
local fatal = 'No'
local tableDamages = {}

CreateThread(function()
    local lastDamageBone = nil
    local lastHealth = GetEntityHealth(PlayerPedId())
    local dead = false

    while true do
        local isDamaged, boneIndex = GetPedLastDamageBone(PlayerPedId())

        if not isDamaged then
            lastDamageBone = nil
        end

        if dead then
            if GetEntityHealth(PlayerPedId()) > 0 then
                lastHealth = GetEntityHealth(PlayerPedId())
                tableDamages = {}
                dead = false
            end
        end

        if lastHealth < GetEntityHealth(PlayerPedId()) then
            lastHealth = GetEntityHealth(PlayerPedId())
            tableDamages = {}
        end

        if isDamaged and lastHealth > GetEntityHealth(PlayerPedId()) then
            lastDamageBone = boneIndex
            local damage = (lastHealth - GetEntityHealth(PlayerPedId()))
            lastHealth = GetEntityHealth(PlayerPedId())

            local idOfOwner = nil
            ESX.TriggerServerCallback('b_damages:getOwnerOfDamage', function(owner)
                idOfOwner = owner
            end)

            while idOfOwner == nil do
                Wait(100)
            end

            if idOfOwner then
                local _, weapon = GetCurrentPedWeapon(GetPlayerPed(GetPlayerFromServerId(idOfOwner)))

                if IsEntityDead(PlayerPedId()) then
                    fatal = 'Yes'
                else
                    fatal = 'No'
                end

                table.insert(tableDamages, {damage = damage, weapon = weapon, boneIndex = boneIndex, fatal = fatal, time = GetGameTimer()})
            end
        end

        if IsEntityDead(PlayerPedId()) and not dead then
            dead = true

            ESX.TriggerServerCallback('b_damages:getOwnerOfDamage', function(owner)
                idOfOwner = owner
            end)

            while idOfOwner == nil do
                Wait(100)
            end

            if idOfOwner then
                local lastHitTime, lastWeapon, lastDmg

                for i=1, #tableDamages do
                    lastHitTime = tableDamages[i].time
                    lastWeapon = Config.Weapons[tableDamages[i].weapon] or 'Undefined'
                    lastDmg = tableDamages[i].damage
                end

                HitTimes = #tableDamages
                Weapon = lastWeapon
                Dmg = lastDmg

                TriggerEvent('chat:addMessage', {
                    template = '<span style="color: red;">{0}</span> {1}',
                    args = {'', "^1[ ! ]^0 You have been hit " .. HitTimes .. " times, do /damage for more info."}
                })                
            end
        end

        Wait(0)
    end
end)

function convert_to_time(tenths)
    local hh = (tenths // (60 * 60 * 1000)) % 24
    local mm = (tenths // (60 * 1000)) % 60
    local ss = (tenths // 1000) % 60

    return string.format("%02dh, %02dm, %02ds", hh, mm, ss)
end

-- /damage [id] - Bandz

RegisterCommand('damage', function(source, args, rawCommand)
    local id = args[1]
    local message = "You have been hit ^8" .. HitTimes .. '^0 times with a ^8' .. Weapon .. '^0 for ^8' .. Dmg .. '^0 dmg fatal ^8 '.. fatal .. '^0.'
    for i=1, #tableDamages do
        local logMessage = "^1»^0 " .. tableDamages[i].damage .. " from " .. Config.Weapons[tableDamages[i].weapon] .. " to " .. (Config.bodyParts[tableDamages[i].boneIndex].part or 'Undefined') .. " (Fatal: " .. tableDamages[i].fatal .. ")"
        TriggerEvent('b_damages:displayDamage', id, logMessage)
    end
end, false)

RegisterNetEvent('b_damages:displayDamage')
AddEventHandler('b_damages:displayDamage', function(id, message)
    TriggerEvent('chat:addMessage', {
        color = {30, 144, 255},
        args = {'', message}
    })
end)
