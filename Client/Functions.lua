Toggle = false
SprayBlips = {}

RegisterFunctions = function()
    IsPlayerInGang = function()
        if LocalPlayer.state.Character:GetData("Gang") then
            if LocalPlayer.state.Character:GetData("Gang") ~= "" then
                return true
            else
                return false
            end
        else
            return false
        end
    end

    HasGangDiscoveredSpray = function(sprayId)
        local p = promise.new()

        Callbacks:ServerCallback('GangSystem:Server:HasGangDiscoveredSpray', sprayId, function(callback)
            p:resolve(callback)
        end)

        return Citizen.Await(p)
    end

    GetContestState = function(sprayId)
        local p = promise.new()

        Callbacks:ServerCallback('GangSystem:Server:GetContestState', sprayId, function(callback)
            if callback then
                p:resolve(true)
            else
                p:resolve(false)
            end
        end)

        return Citizen.Await(p)
    end

    IsSprayClose = function()
        for _, k in pairs(CREATED_SPRAYS) do
            if #(GetEntityCoords(PlayerPedId()) - vector3(k.Coords.x, k.Coords.y, k.Coords.z)) < 150 then
                return true
            end
        end

        return false
    end

    Callbacks:RegisterClientCallback('GangSystem:Client:ShowAllSprays', function(data, cb)
        Toggle = not Toggle

        if Toggle then
            Notification:Info('Showing all sprays.', 2000)
            for k, v in ipairs(data) do
                local Blip = AddBlipForRadius(v.Coords.x, v.Coords.y, v.Coords.z, 100.0)
                SetBlipHighDetail(Blip, true)
                SetBlipColour(Blip, v.BlipColor)
                SetBlipAlpha(Blip, 128)
                table.insert(SprayBlips, Blip)
            end
        else
            Notification:Error('Hiding all sprays.', 2000)
            for k, Blip in ipairs(SprayBlips) do
                RemoveBlip(Blip)
            end
            SprayBlips = {}
        end
    end)
end

RegisterNetEvent('GangSystem:Client:ToggleDiscoveredSprays', function()
    Toggle = not Toggle

    if Toggle then
        Notification:Info('Showing discovered sprays.', 2000)
        Callbacks:ServerCallback('GangSystem:Server:GetDiscoveredSprays', {}, function(callback)
            if callback then
                for k, v in ipairs(callback) do
                    local Blip = AddBlipForRadius(v.Coords.x, v.Coords.y, v.Coords.z, 100.0)
                    SetBlipHighDetail(Blip, true)
                    SetBlipColour(Blip, v.BlipColor)
                    SetBlipAlpha(Blip, 128)
                    table.insert(SprayBlips, Blip)
                end
            end
        end)
    else
        Notification:Error('Hiding discovered sprays.', 2000)
        for k, Blip in ipairs(SprayBlips) do
            RemoveBlip(Blip)
        end
        SprayBlips = {}
    end
end)