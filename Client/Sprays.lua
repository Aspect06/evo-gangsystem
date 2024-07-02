Placement = {
    CurrentlyPlacing = false,
    Placing = false
}

RegisterCallbacks = function()
    Callbacks:RegisterClientCallback('GangSystem:Client:SyncSprays', function(data, cb)
        if data.Type == 'Add' then
            SPRAY_COUNT = 0

            for _ in pairs(CREATED_SPRAYS) do
                SPRAY_COUNT = SPRAY_COUNT + 1
            end

            AddSprayZone('SPRAY_ZONE_' .. SPRAY_COUNT + 1, {
                x = data.data.coords.x,
                y = data.data.coords.y,
                z = data.data.coords.z - 2
            },
            {
                _id = data.SprayId[1],
                Model = data.data.model,
                Heading = data.data.heading,
                Coords = {
                    x = data.data.coords.x,
                    y = data.data.coords.y,
                    z = data.data.coords.z - 2
                }
            })
        elseif data.Type == 'Remove' then
            for _, k in pairs(CREATED_SPRAYS) do
                if data.Id == k._id then
                    Polyzone:Remove(_)
                    Targeting.Zones:RemoveZone(_ .. '_SPRAY_INTERACT')
                    -- DeleteObject(CREATED_SPRAYS[_].Object)
                    CREATED_SPRAYS[_] = nil
                end
            end
        elseif data.Type == 'Update' then
            EnterZone = false

            for _, k in pairs(CREATED_SPRAYS) do
                if data.SprayId == k._id then
                    if CREATED_SPRAYS[_].Object then
                        EnterZone = true
                    end

                    Polyzone:Remove(_)
                    Targeting.Zones:RemoveZone(_ .. '_SPRAY_INTERACT')

                    AddSprayZone(_, { x = data.data.Coords.x, y = data.data.Coords.y, z = data.data.Coords.z }, {
                        _id = k._id,
                        Model = data.PlyGang.Spray,
                        Heading = data.data.Heading,
                        Coords = { x = data.data.Coords.x, y = data.data.Coords.y, z = data.data.Coords.z }
                    })

                    if EnterZone then
                        Wait(1000)

                        Logger:Info('Gang System', 'Update is sending polyzone.')
                        EnterSprayZone(_)
                    end
                end
            end
        end
    end)

    Callbacks:RegisterClientCallback('GangSystem:Client:PlaceSpray', function(data, cb)
        if not Placement.CurrentlyPlacing then
            Action:Show('[E] To Place | ESC To Cancel')
            Placement.CurrentlyPlacing = true
            local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
            local PropSpawned = CreateObject(GetHashKey(data.MetaData.spray_model), plyCoords.x, plyCoords.y, plyCoords.z, 0, 1, 1)
            Wait(500)
            SetEntityCollision(PropSpawned, false)
            SetEntityHeading(PropSpawned, GetEntityHeading(GetPlayerPed(PlayerId())))

            Placement.Placing = true

            while Placement.Placing do
                Wait(0)
                DisableControlAction(0, 200, true)
                local hit, hitPos, surfaceNormal = RaycastFromCamera()
                if hit then
                    local newPos = hitPos + surfaceNormal * 0.01
                    SetEntityCoordsNoOffset(PropSpawned, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    local heading = CalculateHeadingFromNormal(surfaceNormal)
                    SetEntityHeading(PropSpawned, heading)
                end

                if IsControlJustPressed(0, 15) then
                    local rot = GetEntityHeading(PropSpawned)
                    SetEntityHeading(PropSpawned, rot + 0.5)
                elseif IsControlJustPressed(0, 14) then
                    local rot = GetEntityHeading(PropSpawned)
                    SetEntityHeading(PropSpawned, rot - 0.5)
                end

                if IsControlJustPressed(0, 322) then
                    Action:Hide()
                    DeleteObject(PropSpawned)
                    Placement.Placing = false
                    Placement.CurrentlyPlacing = false
                    break
                end

                if IsControlJustPressed(0, 38) then
                    if IsSprayClose() then
                        Action:Hide()
                        Notification:Error('You cant place a spray this close to another.', 1000)
                        DeleteObject(PropSpawned)
                        Placement.Placing = false
                        Placement.CurrentlyPlacing = false
                        return
                    end
               
                    if #(GetEntityCoords(PlayerPedId()) - vector3(GetEntityCoords(PropSpawned).x, GetEntityCoords(PropSpawned).y, GetEntityCoords(PropSpawned).z)) > 2 then
                        Action:Hide()
                        Notification:Error('You cant place a spray from this far away.', 2000)
                        DeleteObject(PropSpawned)
                        Placement.Placing = false
                        Placement.CurrentlyPlacing = false
                        return
                    end

                    Action:Hide()
                    local inzone, _ = false, false
                    if not inzone then
                        if hitPos.x == 0.0 or hitPos.y == 0.0 or hitPos.z == 0.0 then
                            Placement.CurrentlyPlacing = false
                            Placement.Placing = false

                            DeleteObject(PropSpawned)
                            return
                        end

                        Placement.CurrentlyPlacing = false
                        Placement.Placing = false

                        if data.Name == "gang_flag" then
                            local coords = GetEntityCoords(PropSpawned)
                            local heading = GetEntityHeading(PropSpawned)
                            DeleteObject(PropSpawned)
                        elseif data.Name == "spray_can" then
                            RequestAnimDict('switch@franklin@lamar_tagging_wall')

                            while not HasAnimDictLoaded('switch@franklin@lamar_tagging_wall') do
                                Wait(0)
                            end
                        
                            TaskPlayAnim(PlayerPedId(), 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_wall_loop_lamar', 8.0, -8.0, -1, 8192, 0, false, false, false)

                            Wait(3000)

                            TaskPlayAnim(PlayerPedId(), 'switch@franklin@lamar_tagging_wall', 'lamar_tagging_exit_loop_lamar', 8.0, -8.0, -1, 8193, 0, false, false, false)

                            Progress:Progress({
                                name = "spray_place",
                                duration = 15000,
                                label = "Spraying Wall...",
                                useWhileDead = false,
                                canCancel = true,
                                ignoreModifier = true,
                                controlDisables = {
                                    disableMovement = true,
                                    disableCarMovement = true,
                                    disableMouse = false,
                                    disableCombat = true,
                                },
                            }, function(cancelled)
                                if not cancelled then
                                    cb(true)
                                    local coords = GetEntityCoords(PropSpawned)
                                    local heading = GetEntityHeading(PropSpawned)
                                    DeleteObject(PropSpawned)

                                    Callbacks:ServerCallback('GangSystem:Server:SaveSpray', {
                                        coords = { x = coords.x, y = coords.y, z = coords.z },
                                        heading = heading,
                                        model = data.MetaData.spray_model
                                    }, function(cb)
                                        if cb then
                                            Notification:Info('Spray placed!', 1000)
                                        else
                                            Notification:Error('Failed to place spray.', 1000)
                                        end
                                    end)
                                else
                                    cb(false)
                                    DeleteObject(PropSpawned)
                                end
                                ClearPedTasksImmediately(PlayerPedId())
                            end)
                        end

                        return
                    else
                        Notification:Error('Cant place this spray here.', 1000)
                        Placement.CurrentlyPlacing = false
                        Placement.Placing = false
                        DeleteObject(PropSpawned)
                        TriggerEvent('trp-prop:DestroyProps')
                        return
                    end

                    FreezeEntityPosition(PropSpawned, true)
                    SetEntityCollision(PropSpawned, true)
                end
            end
        end
    end)
end