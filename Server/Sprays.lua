RegisterCallbacks = function()
    Callbacks:RegisterServerCallback('GangSystem:Server:SaveSpray', function(source, data, cb)
        Logger:Info("Gang System", "Created Gang Spray Model: " .. data.model .. " | Heading: " .. data.heading)
        local Gang = GetCurrentGang(source)

		Database.Game:insertOne({
			collection = "gang_sprays",
			document = {
                Coords = {
                    x = data.coords.x,
                    y = data.coords.y,
                    z = data.coords.z - 2,
                },
                BlipColor = Gang.Color,
                Heading = data.heading,
                Model = data.model,
                ContestState = false
            },
		}, function(success, results, Id)
			if not success then cb(false) end
            Callbacks:ClientCallback(-1, 'GangSystem:Client:SyncSprays', { Type = 'Add', data = data, SprayId = Id }, function(data) end)

            Database.Game:updateOne({
                collection = "gangs",
                query = { Name = Gang.Name },
                update = {
                    ["$push"] = {
                        DiscoveredSprays = Id[1],
                    },
                },
            })
			cb(true)
		end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:FetchAllSprays', function(source, data, cb)
        Database.Game:find({
            collection = "gang_sprays",
            query = {}
        }, function(success, results)
            if not success then
                cb(false)
            end
    
            cb(results)
        end)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:GetSpray', function(source, data, cb)
        local Player = Fetch:Source(source)
		local Char = Player:GetData("Character")
        local Gang = GetCurrentGang(source)

        if Banking.Balance:Charge(Char:GetData("BankAccount"), data.price, { type = 'bill', title = 'Spray Can Purchase', }) then
            Database.Game:updateOne({
                collection = "gangs",
                query = {
                    Name = Char:GetData("Gang"),
                },
                update = {
                    ["$inc"] = {
                        PurchasedSprays = 1,
                    },
                },
            }, function(success, res)
                if not success then
                    cb(false)
                end
            end)
            
            Inventory:AddItem(Char:GetData("SID"), 'spray_can', 1, {
                spray_model = Gang.Spray,
                Gang = Gang.Name
            }, 1)

            cb(true)
        end

        cb(false)
    end)
    
    Callbacks:RegisterServerCallback('GangSystem:Server:PurchaseScrubbingCloth', function(source, data, cb)
        local Player = Fetch:Source(source)
		local Char = Player:GetData("Character")

        if Banking.Balance:Charge(Char:GetData("BankAccount"), 50000, { type = 'bill', title = 'Scrubbing Cloth Purchase' }) then           
            Inventory:AddItem(Char:GetData("SID"), "scrubbing_cloth", 1, {}, 1)

            cb(true)
        end

        cb(false)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Client:GetSprayCost', function(source, data, cb)
        local Gang = GetCurrentGang(source)

        if Gang == nil then
            cb(false)
        elseif Gang.PurchasedSprays then
            cb(Gang.PurchasedSprays * _CONFIG.SPRAY_COST)
        else
            cb(_CONFIG.SPRAY_COST)
        end
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:HasGangDiscoveredSpray', function(source, sprayId, cb)
        local Gang = GetCurrentGang(source)

        for _, k in pairs(Gang.DiscoveredSprays) do
            if k == sprayId then
                cb(true)
            end
        end

        cb(false)
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:GetDiscoveredSprays', function(source, data, cb)
        local Gang = GetCurrentGang(source)
        local Sprays = {}
        local numQueries = #Gang.DiscoveredSprays
        local completedQueries = 0
    
        for _, k in pairs(Gang.DiscoveredSprays) do
            Database.Game:findOne({
                collection = "gang_sprays",
                query = {
                    _id = k,
                },
            }, function(success, state)
                if not success then 
                    cb(false)
                    return
                end
    
                table.insert(Sprays, state[1])
                completedQueries = completedQueries + 1
    
                if completedQueries == numQueries then
                    cb(Sprays)
                end
            end)
        end
    end)

    Callbacks:RegisterServerCallback('GangSystem:Server:GetContestState', function(source, data, cb)
        Database.Game:findOne({
            collection = "gang_sprays",
            query = {
                _id = data,
            },
        }, function(success, state)
            if not success then cb(false) return end

            cb(state[1].ContestState)
        end)
    end)
end