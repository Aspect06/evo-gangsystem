-- _CONFIG = {}

AddEventHandler("GangSystem:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Callbacks = exports["evo-base"]:FetchComponent("Callbacks")
	PedInteraction = exports["evo-base"]:FetchComponent("PedInteraction")
	ListMenu = exports["evo-base"]:FetchComponent("ListMenu")
	Action = exports["evo-base"]:FetchComponent("Action")
	Progress = exports["evo-base"]:FetchComponent("Progress")
	Notification = exports["evo-base"]:FetchComponent("Notification")
	Animations = exports["evo-base"]:FetchComponent("Animations")
	Polyzone = exports["evo-base"]:FetchComponent("Polyzone")
	Targeting = exports["evo-base"]:FetchComponent("Targeting")
	Inventory = exports["evo-base"]:FetchComponent("Inventory")
	Logger = exports["evo-base"]:FetchComponent("Logger")
	NPCDialog = exports["evo-base"]:FetchComponent("NPCDialog")
end

AddEventHandler("Core:Shared:Ready", function()
	exports["evo-base"]:RequestDependencies("GangSystem", {
		"Callbacks",
		"PedInteraction",
		"ListMenu",
		"Action",
		"Polyzone",
		"Targeting",
		"Inventory",
		"Logger"
	}, function(error)
		if #error > 0 then return end

		RetrieveComponents()
		RegisterCallbacks()
		RegisterFunctions()
		RegisterJob()

		PedInteraction:Add("PurchaseSprayPed", `s_m_y_dealer_01`, vector3(-298.193, -1332.476, 30.297), 297.840, 25.0, {
			{
				icon = "hand-holding",
				text = "Purchase Tools",
				event = "GangSystem:Client:PurchaseSpray",
			}
		}, 'spray-can-sparkles')
	end)
end)

RegisterNetEvent('Characters:Client:Logout', function()
	for k, v in pairs(CREATED_SPRAYS) do
		Logger:Info('Gang System', 'Removed spray ' .. k)
		Targeting.Zones:RemoveZone(k .. '_SPRAY_INTERACT')
		Polyzone:Remove(k)
	end
end)

AddEventHandler("Characters:Client:Spawn", function()
	-- Callbacks:ServerCallback('GangSystem:Server:FetchConfig', {}, function(cb)
	-- 	_CONFIG = cb
	-- end)

	Callbacks:ServerCallback('GangSystem:Server:FetchAllSprays', {}, function(cb)
		for k, v in ipairs(cb) do
			AddSprayZone('SPRAY_ZONE_' .. k, { x = v.Coords.x, y = v.Coords.y, z = v.Coords.z }, v)
		end
	end)
end)
