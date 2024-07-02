RegisterCommands = function()
    Chat:RegisterAdminCommand("creategang", function(source, args, rawCommand)
        local GANGSID, GANGName, GANGColor, GANGSpray = table.unpack(args)
        local Char = Fetch:SID(tonumber(GANGSID)):GetData("Character")

        Database.Game:insertOne({
			collection = "gangs",
			document = {
                Name = GANGName,
                Color = tonumber(GANGColor),
                Spray = GANGSpray,
                LeadersSid = {tonumber(GANGSID)},
                Progression = {},
                DiscoveredSprays = {},
                Members = {
                    {
                        SID = tonumber(GANGSID),
                        Name = Char:GetData("First") .. ' ' .. Char:GetData("Last"),
                        Leader = true
                    }
                }
            },
		}, function(success, results)
			if not success then
                Chat.Send.System:Single(source, 'Failed to create gang!')
            end

            Logger:Info('Gang System', 'Created new gang Name: ' .. GANGName .. ' | Color: ' .. GANGColor .. ' | Spray: ' .. GANGSpray .. ' | Leader SID: ' .. GANGSID)
            Chat.Send.System:Single(source, 'Successfully created gang ' .. GANGName)

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

            if Char ~= nil then
                local inGang = Char:GetData("Gang")

                if not inGang then
                    Char:SetData("Gang", GANGName)
                end
            end
		end)
    end, {
		help = "Create Gang",
		params = {
            { name = "SID", help = "Gang leaders SID." },
			{ name = "Gang Name", help = "The name of the gang you want to create." },
			{ name = "Gang Color", help = "Color of the gang sprays clothing ect. [GET THIS FROM https://docs.fivem.net/docs/game-references/blips/]" },
			{ name = "Gang Spray", help = "The gang spray model." },
		},
	}, 4)

    Chat:RegisterAdminCommand('removefromgang', function(source, args, rawCommand)
        local SIDToRemove, GANGName = table.unpack(args)

        Database.Game:updateOne({
            collection = "gangs",
            filter = {
                Name = GANGName
            },
            update = {
                ["$pull"] = {
                    Members = {
                        SID = SIDToRemove
                    }
                }
            }
        }, function(success, results)
            if not success then
                Chat.Send.System:Single(source, 'Failed to remove ' .. SIDToRemove .. ' from gang.')
            end

            -- Make it removed installed app from LaptopApps.

            local Char = Fetch:SID(tonumber(SIDToRemove)):GetData("Character")
            if Char ~= nil then
                local inGang = Char:GetData("Gang")
    
                if inGang then
                    Char:SetData("Gang", nil)
                end
            end

            Chat.Send.System:Single(source, 'Successfully removed ' .. SIDToRemove .. ' from gang ' .. GANGName)
        end)
    end, {
		help = "Remove person from gang",
		params = {
            { name = "SID", help = "Persons SID you want to remove." },
			{ name = "Gang", help = "The gang the person is in." },
		},
	}, 2)

    Chat:RegisterAdminCommand('admin:togglegangmap', function(source, args, rawCommand)
        Database.Game:find({
            collection = "gang_sprays",
            query = {}
        }, function(success, results)
            if not success then return end
    
            Callbacks:ClientCallback(source, 'GangSystem:Client:ShowAllSprays', results, function(data, cb) end)
        end)
    end, {
        help = "Shows the blips of every spray",
    })
end