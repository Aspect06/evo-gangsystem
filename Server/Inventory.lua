RegisterItemUses = function()
    Inventory.Items:RegisterUse("spray_can", "RandomItems", function(source, item)
		Callbacks:ClientCallback(source, 'GangSystem:Client:PlaceSpray', item, function(callback)
			if callback then
				Inventory.Items:RemoveSlot(item.Owner, item.Name, 1, item.Slot, item.invType)
			end
		end)
	end)
end