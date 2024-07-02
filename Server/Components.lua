AddEventHandler("GangSystem:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports["evo-base"]:FetchComponent("Callbacks")
    Chat = exports["evo-base"]:FetchComponent("Chat")
	Database = exports["evo-base"]:FetchComponent("Database")
	Logger = exports["evo-base"]:FetchComponent("Logger")
	Inventory = exports["evo-base"]:FetchComponent("Inventory")
	Chat = exports["evo-base"]:FetchComponent("Chat")
	Fetch = exports["evo-base"]:FetchComponent("Fetch")
	Banking = exports["evo-base"]:FetchComponent("Banking")
	Phone = exports["evo-base"]:FetchComponent("Phone")
	Execute = exports["evo-base"]:FetchComponent("Execute")
end

AddEventHandler("Core:Shared:Ready", function()
	exports["evo-base"]:RequestDependencies("GangSystem", {
		"Callbacks",
		"Chat",
		"Database",
		"Logger",
		"Inventory",
		"Fetch",
		"Banking",
		"Phone",
		"Execute"
	}, function(error)
		if #error > 0 then
			return
		end

		RetrieveComponents()
		RegisterCallbacks()
		RegisterCommands()
		RegisterItemUses()
		RegisterFunctions()
		RegisterActions()
	end)
end)