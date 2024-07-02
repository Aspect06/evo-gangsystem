CREATED_SPRAYS = {}

SprayCoords = function()
    local Cam = GetGameplayCamCoord()
    local _, _, Coords, _, _ = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(Cam, GetCoordsFromCamDistance(10.0, Cam), -1, PlayerPedId(), 4))
    return Coords
end

GetCoordsFromCamDistance = function(distance, coords)
    local rotation = GetGameplayCamRot()
    local adjustedRotation = vector3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    local direction = vector3(-math.sin(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.cos(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.sin(adjustedRotation[1]))
    return vector3(coords[1] + direction[1] * distance, coords[2] + direction[2] * distance, coords[3] + direction[3] * distance)
end

RaycastFromCamera = function()
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local forwardVector = RotationToDirection(camRot)
    local startPos = camPos + (forwardVector * 1.0)
    local endPos = camPos + (forwardVector * 1000.0)

    local rayHandle = StartShapeTestRay(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, 1, GetPlayerPed(PlayerId()), 0)
    local _, hit, hitPos, surfaceNormal, _ = GetShapeTestResult(rayHandle)

    return hit, hitPos, surfaceNormal
end

RotationToDirection = function(rotation)
    local adjustedRotation = vector3(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
    local direction = vector3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
    return direction
end

CalculateHeadingFromNormal = function(normal)
    local heading = -math.deg(math.atan2(normal.x, normal.y))
    return heading - 180 % 360
end

AddEventHandler("Polyzone:Enter", function(Id)
    if string.find(Id, 'SPRAY_') then
        EnterSprayZone(Id)
    end
end)

EnterSprayZone = function(Id)
    if string.find(Id, 'SPRAY_') then
        Logger:Info('Gang System', 'Entering zone ' .. Id)
        if not CREATED_SPRAYS[Id] == nil then return end
        CREATED_SPRAYS[Id].Object = CreateObject(CREATED_SPRAYS[Id].Model, CREATED_SPRAYS[Id].Coords.x, CREATED_SPRAYS[Id].Coords.y, CREATED_SPRAYS[Id].Coords.z, false, true, true)
        SetEntityHeading(CREATED_SPRAYS[Id].Object, CREATED_SPRAYS[Id].Heading)
    end
end

AddEventHandler('Polyzone:Exit', function(Id)
    if string.find(Id, 'SPRAY_') then
        Logger:Info('Gang System', 'Leaving zone ' .. Id)
        if not CREATED_SPRAYS[Id] == nil then return end
        DeleteObject(CREATED_SPRAYS[Id].Object)
    end
end)

AddSprayZone = function(name, center, state, addPoly)
    Polyzone.Create:Circle(name, vector3(center.x, center.y, center.z), 55.0, { useZ = true })
    CREATED_SPRAYS[name] = state

    Targeting.Zones:AddCircle(name .. '_SPRAY_INTERACT', "spray-can-sparkles", vector3(center.x, center.y, center.z + 2), 1, {
        name = name .. '_SPRAY_INTERACT',
        useZ = true,
    }, {
        {
            icon = 'soap',
            text = 'Scrub',
            event = 'GangSystem:Client:Scrub',
            data = { Spray = CREATED_SPRAYS[name], Name = name },
        },
        {
            icon = 'hand-holding',
            text = 'Contest Graffiti',
            event = 'GangSystem:Client:Contest',
            data = { Spray = CREATED_SPRAYS[name] },

            isEnabled = function()

                if IsPlayerInGang() and not GetContestState(CREATED_SPRAYS[name]._id) then
                    return true
                else
                    return false
                end

            end
        },
        {
            icon = 'hand-holding',
            text = 'Cancel Contest',
            event = 'GangSystem:Client:CancelContest',
            data = CREATED_SPRAYS[name],
            isEnabled = function()

                if IsPlayerInGang() then
                    return true
                else
                    return false
                end

            end
        },
        {
            icon = 'eye',
            text = 'Discover Graffiti',
            event = 'GangSystem:Client:DiscoverSpray',
            data = CREATED_SPRAYS[name]._id,
            isEnabled = function()

                if IsPlayerInGang() and not HasGangDiscoveredSpray(CREATED_SPRAYS[name]._id) and not GetContestState(CREATED_SPRAYS[name]._id) then
                    return true
                else
                    return false
                end

            end
        }
    }, 3.0, true)

    Targeting.Zones:Refresh()
end