CONTESTED_SPRAYS = {}

RegisterFunctions = function()
    GetCurrentGang = function(source)
        local Player = Fetch:Source(source)
        local Char = Player:GetData("Character")

        if Char:GetData("Gang") ~= "" and Char:GetData("Gang") ~= nil then
            local p = promise.new()

            Database.Game:findOne({
                collection = "gangs",
                query = {
                    Name = Char:GetData("Gang")
                },
            }, function(success, result)
		    	if not result then p:resolve(false) return end

		    	p:resolve(result[1])
            end)

		    return Citizen.Await(p)
        end
    end

    GetGangPlayersOnline = function(source, GangSpray)
        local p = promise.new()
        local Count = 0

        Database.Game:findOne({
            collection = "gangs",
            query = {
                Spray = GangSpray,
            },
        }, function(success, state)
            if not state then p:resolve(false) return end

            for k, v in pairs(state[1].Members) do
                local Player = Fetch:SID(tonumber(v.SID))

                if Player ~= nil then
                    Count = Count + 1
                end
            end

            p:resolve(Count)
        end)

        return Citizen.Await(p)
    end

    AlertGang = function(source, Gang, State)
        Database.Game:findOne({
            collection = "gangs",
            query = {
                Spray = Gang.Spray.Model,
            },
        }, function(success, state)
            for k, v in pairs(state[1].Members) do
                local Player = Fetch:SID(tonumber(v.SID))

                if Player ~= nil then
                    local Char = Player:GetData("Character")

                    Logger:Info('Gang System', 'Alerting ' .. Char.Owner .. ' that something is going on with their gang spray.')

                    Phone.Notification:Add(Char.Owner, "Gang System", State.Text, os.time() * 1000, 10000, "email", {
                        accept = State.AcceptEvent,
                        cancel = State.DenyEvent,
                    }, State.Params)
                end
            end
        end)
    end

    BeginContestSpray = function(source, sprayId, sprayData, Gang)
        CONTESTED_SPRAYS[sprayId] = sprayData

        Wait(60000 * _CONFIG.CONTEST_MINUTES)

        Database.Game:findOne({
            collection = "gang_sprays",
            query = {
                _id = sprayId
            },
        }, function(success, result)
			if not result then return end

            if result[1].ContestState then
                Logger:Info('Gang System', 'Finished contesting spray with Id: ' .. sprayId)

                Database.Game:updateOne({
                    collection = "gang_sprays",
                    query = {
                        _id = sprayId,
                    },
                    update = {
                        ["$set"] = {
                            BlipColor = Gang.Color,
                            Model = Gang.Spray,
                            ContestState = false
                        },
                    },
                }, function(success, res)
                    if not success then cb(false) end
                end)

                local Player = Fetch:Source(source)

                if Player then
                    local Char = Player:GetData('Character')
                    Phone.Email:Send(Char:GetData("Source"), 'Aspect@evorp.net', os.time() * 1000, 'Spray', 'You successfully finished contesting a spray.')
                end
            end
        end)
    end

    Callbacks:RegisterServerCallback('GangSystem:Server:AddMember', function(source, data, cb)
        local MyChar = Fetch:Source(source):GetData('Character')
        local Player = Fetch:SID(tonumber(data.SID))

        if Player == nil then return end
        local Char = Player:GetData("Character")

        Database.Game:findOne({
            collection = "gangs",
            query = {
                Name = MyChar:GetData("Gang"),
            },
        }, function(success, state)
            if not success then return end

            if not Char.Owner then Logger:Error('Gang System', 'Error when adding member to gang [Char.Owner]') return end

            Phone.Notification:Add(Char.Owner, "Invite to " .. MyChar:GetData("Gang"), 'Would you like to join ?', os.time() * 1000, 7500, "email", {
                accept = "Phone:Nui:GangSystem:AcceptInvite",
                cancel = "Phone:Nui:GangSystem:DenyInvite",
            }, {
                Gang = state[1]._id,
                GangName = state[1].Name,
                Name = Char:GetData('First') .. ' ' .. Char:GetData('Last'),
                SID = data.SID
            })
        end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:JoinGang', function(source, data, cb)
        local Char = Fetch:Source(source):GetData('Character')

        Database.Game:updateOne({
            collection = "gangs",
            query = { _id = data.data.Gang },
            update = {
                ["$push"] = {
                    Members = {
                        SID = tonumber(data.data.SID),
                        Name = data.data.Name,
                        Leader = false
                    },
                },
            },
        }, function(success, res)
            if not success then return end
        
            local PLAYER_STATES = Char:GetData("States") or {}
            table.insert(PLAYER_STATES, "ACCESS_GANGAPP")
            Char:SetData("States", PLAYER_STATES)

            local PLAYER_LAPTOP_APPS = Char:GetData("LaptopApps") or {}
            AddApp = true
            for k, v in pairs(PLAYER_LAPTOP_APPS.home) do
                if v == 'gangs' then
                    AddApp = false
                end
            end

            if AddApp then
                table.insert(PLAYER_LAPTOP_APPS.home, "gangs")
                table.insert(PLAYER_LAPTOP_APPS.installed, "gangs")
                Char:SetData("LaptopApps", PLAYER_LAPTOP_APPS)
            end

            Char:SetData("Gang", data.data.GangName)
        end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:LeaveGang', function(source, data, cb)
        local Char = Fetch:Source(source):GetData('Character')
        local PLAYER_STATES = Char:GetData("States") or {}

        Database.Game:updateOne({
            collection = "gangs",
            filter = {
                Name = Char:GetData("Gang")
            },
            update = {
                ["$pull"] = {
                    Members = {
                        SID = Char:GetData("SID")
                    }
                }
            }
        }, function(success, results)
            if not success then return end

            for k, v in ipairs(PLAYER_STATES) do
                if v == 'ACCESS_GANGAPP' then
                    table.remove(PLAYER_STATES, k)
                end
            end

            Char:SetData("Gang", '')
            Char:SetData("States", PLAYER_STATES)
        end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:KickMember', function(source, data, cb)
        local Char = Fetch:Source(source):GetData('Character')
        local OtherChar = Fetch:SID(tonumber(data.SID)):GetData('Character')

        Database.Game:updateOne({
            collection = "gangs",
            filter = {
                Name = Char:GetData("Gang")
            },
            update = {
                ["$pull"] = {
                    Members = {
                        SID = data.SID
                    }
                }
            }
        }, function(success, results)
            if not success then return end

            local PLAYER_STATES = OtherChar:GetData("States") or {}

            for k, v in ipairs(PLAYER_STATES) do
                if v == 'ACCESS_GANGAPP' then
                    table.remove(PLAYER_STATES, k)
                end
            end

            OtherChar:SetData("States", PLAYER_STATES)
            OtherChar:SetData("Gang", "")
        end)
    end)
end