AddEventHandler('GangSystem:Client:Scrub', function(_, state)
    if GetContestState(state.Spray._id) then Notification:Error('This spray is currently being contested.', 2000) return end
    if Inventory.Check.Player:HasItem('scrubbing_cloth', 1) then
        Callbacks:ServerCallback('GangSystem:Server:CanScrubSpray', state, function(cb)
            if cb then
                TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_MAID_CLEAN', 0, true)

                Progress:Progress({
                    name = "spray_place",
                    duration = 300000,
                    label = "Scrubbing Spray...",
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
                        Callbacks:ServerCallback('GangSystem:Server:ScrubSpray', { Spray = state.Spray }, function(callback) end)
                    end

                    ClearPedTasks(PlayerPedId())
                end)
            end
        end)
    else
        Notification:Error('You dont have any Scrubbing Cloth', 1000)
    end
end)

AddEventHandler('GangSystem:Client:DiscoverSpray', function(_, id)
    if HasGangDiscoveredSpray(id) then Notification:Error('You have already discovered this spray.', 2000) return end

    Progress:Progress({
        name = 'discover_spray',
        duration = 60000,
        label = 'Discovering Spray',
        useWhileDead = false,
        canCancel = true,
        ignoreModifier = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }
    }, function(Cancelled)
        if not Cancelled then
            Callbacks:ServerCallback('GangSystem:Server:DiscoverSpray', id, function(callback) end)
        end
    end)
end)

AddEventHandler('GangSystem:Client:Contest', function(_, data)
    if Inventory.Check.Player:HasItem('scrubbing_cloth', 1) then
        Callbacks:ServerCallback('GangSystem:Server:ContestSpray', data, function(callback) end)
    else
        Notification:Error('You dont have any Scrubbing Cloth', 1000)
    end
end)

AddEventHandler('GangSystem:Client:CancelContest', function(_, data)
    if not GetContestState(data._id) then Notification:Error('This spray isnt currently being contested', 1000) return end
    Callbacks:ServerCallback('GangSystem:Server:CancelContest', data, function(callback) end)
end)

AddEventHandler("Phone:Nui:GangSystem:AcceptInvite", function(data)
	Callbacks:ServerCallback('GangSystem:Server:JoinGang', {
		data = data,
		notify = true
	})
end)

AddEventHandler('Phone:Nui:GangSystem:AcceptWaypoint', function(data)
    SetNewWaypoint(data.Coords.x, data.Coords.y)
end)