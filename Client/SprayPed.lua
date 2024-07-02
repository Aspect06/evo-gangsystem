AddEventHandler('GangSystem:Client:PurchaseSpray', function()
	Callbacks:ServerCallback('GangSystem:Client:GetSprayCost', {}, function(callback)
		if callback then
			ListMenu:Show({
				main = {
					label = 'Purchase Tools',
					items = {
						{
							label = 'Spray',
							description = 'Purchase Spray for $' .. callback,
							event = 'GangSystem:Client:GetSprayCan',
						},
						{
							label = 'Purchase Scrubbing Cloth',
							description = 'Purchase Scrubbing Cloth for $50,000',
							event = 'GangSystem:Client:PurchaseCloth'
						}
					}
				}
			})
		else
			ListMenu:Show({
				main = {
					label = 'Purchase Tools',
					items = {
						{
							label = 'Purchase Scrubbing Cloth',
							description = 'Purchase Scrubbing Cloth for $50,000',
							event = 'GangSystem:Client:PurchaseCloth'
						}
					}
				}
			})
		end
	end)
end)

AddEventHandler('GangSystem:Client:GetSprayCan', function()
	Callbacks:ServerCallback('GangSystem:Client:GetSprayCost', {}, function(callback)
		Callbacks:ServerCallback('GangSystem:Server:GetSpray', { price = callback }, function(cb)
			if cb then
				Notification:Info('Successfully purchased spray!')
			else
				Notification:Error('Are you sure you have enough money in the bank ?')
			end
		end)
	end)
end)

AddEventHandler('GangSystem:Client:PurchaseCloth', function()
	Callbacks:ServerCallback('GangSystem:Server:PurchaseScrubbingCloth', {}, function(cb)
		if cb then
			Notification:Info('Successfully purchased scrubbing cloth!')
		else
			Notification:Error('Are you sure you have enough money in the bank ?')
		end
	end)
end)