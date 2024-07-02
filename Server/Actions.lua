CONTEST_COOLDOWNS = {}

RegisterActions = function()
    Callbacks:RegisterServerCallback('GangSystem:Server:CanScrubSpray', function(source, data, cb)
        Logger:Info('Gang System', 'Attempting to scrub a spray with ' .. GetGangPlayersOnline(source, data.Spray.Model) .. ' of the opposing gang online.')

        if GetGangPlayersOnline(source, data.Spray.Model) < _CONFIG.MIN_MEMBERS then
            Execute:Client(source, "Notification", "Error", "It seems there are not 3 of the other gang around!")

            cb(false)
            return
        end

        AlertGang(source, data, {
            Text = 'Someone is scrubbing one of your sprays.',
            AcceptEvent = 'Phone:Nui:GangSystem:AcceptWaypoint',
            DenyEvent = 'Phone:Nui:GangSystem:DenyWaypoint',
            Params = {
                Coords = {
                    x = data.Spray.Coords.x,
                    y = data.Spray.Coords.y,
                }
            }
        })

        cb(true)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:ScrubSpray', function(source, data, cb)
        local Player = Fetch:Source(source)
        local Char = Player:GetData('Character')

        if Inventory.Items:Remove(Char:GetData('SID'), 1, 'scrubbing_cloth', 1) then
            Database.Game:deleteOne({
                collection = "gang_sprays",
                query = {
                    _id = data.Spray._id,
                },
            }, function(success, deleted)
                cb(success)
            end)

            Database.Game:update({
                collection = "gangs",
                filter = {},
                update = {
                    ["$pull"] = {
                        DiscoveredSprays = data.Spray._id
                    }
                }
            }, function(success, results)
                if not success then return end
            end)

            Callbacks:ClientCallback(-1, 'GangSystem:Client:SyncSprays', { Id = data.Spray._id, Type = 'Remove' }, function(cb) end)
        end
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:DiscoverSpray', function(source, Id, cb)
        local Player = Fetch:Source(source)
        local Char = Player:GetData('Character')

        Database.Game:updateOne({
            collection = "gangs",
            query = { Name = Char:GetData("Gang") },
            update = {
                ["$push"] = {
                    DiscoveredSprays = Id,
                },
            },
        }, function(success, res)
            if not success then
                cb(false)
            end
        end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:ContestSpray', function(source, data, cb)
        local Player = Fetch:Source(source)
        local Char = Player:GetData('Character')
        local Gang = GetCurrentGang(source)

        if CONTEST_COOLDOWNS[Gang.Name] ~= nil then
            if CONTEST_COOLDOWNS[Gang.Name] >= os.time() then
                Execute:Client(source, "Notification", "Error", "You cannot contest a spray right now.")
                return
            end
        end

        Logger:Info('Gang System', 'Attempting to contest a spray with ' .. GetGangPlayersOnline(source, data.Spray.Model) .. ' of the opposing gang online.')

        if GetGangPlayersOnline(source, data.Spray.Model) < _CONFIG.MIN_MEMBERS then
            Execute:Client(source, "Notification", "Error", "It seems there are not 3 of the other gang around!")
            return
        end

        if Inventory.Items:Remove(Char:GetData('SID'), 1, 'scrubbing_cloth', 1) then
            CONTEST_COOLDOWNS[Gang.Name] = os.time() + 5 * 60 * 60

            AlertGang(source, data, {
                Text = 'Someone is contesting one of your sprays.',
                AcceptEvent = 'Phone:Nui:GangSystem:AcceptWaypoint',
                DenyEvent = 'Phone:Nui:GangSystem:DenyWaypoint',
                Params = {
                    Coords = {
                        x = data.Spray.Coords.x,
                        y = data.Spray.Coords.y,
                    }
                }
            })                

            Database.Game:updateOne({
                collection = "gang_sprays",
                query = {
                    _id = data.Spray._id,
                },
                update = {
                    ["$set"] = {
                        ContestState = true,
                    },
                },
            }, function(success, res)
                if not success then
                    cb(false)
                end
            end)

            BeginContestSpray(source, data.Spray._id, data.Spray, Gang)

            Callbacks:ClientCallback(-1, 'GangSystem:Client:SyncSprays', { Type = 'Update', data = data.Spray, SprayId = data.Spray._id, PlyGang = Gang }, function(data) end)
        end    
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:CancelContest', function(source, data, cb)
        Database.Game:updateOne({
            collection = "gang_sprays",
            query = {
                _id = data._id
            },
            update = {
                ["$set"] = {
                    ContestState = false,
                    LastContested = os.time()
                }
            }
        }, function(success, res)
            if not success then cb(false) end
        end)
    end)
end