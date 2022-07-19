local QBCore = exports['qb-core']:GetCoreObject()

function installCheck()	for k, v in pairs(Config.Products) do for i = 1, #v do	if not QBCore.Shared.Items[v[i].name] then print("Error: Cannot find '"..v[i].name.."' in your shared items") end end end end

PlayerJob = {}
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job end) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerJob = JobInfo end)
RegisterNetEvent('QBCore:Client:SetDuty', function(duty) onDuty = duty end)
AddEventHandler('onResourceStart', function(resource) if GetCurrentResourceName() ~= resource then return end
	installCheck()
	QBCore.Functions.GetPlayerData(function(PlayerData) PlayerJob = PlayerData.job end)
end)

ped = {}
CreateThread(function()
	for k, v in pairs(Config.Locations) do
		if k == "blackmarket" and not Config.BlackMarket then else
			for l, b in pairs(v["coords"]) do
				if not v["hideblip"] then
					StoreBlip = AddBlipForCoord(b)
					SetBlipSprite(StoreBlip, v["blipsprite"])
					SetBlipScale(StoreBlip, 0.7)
					SetBlipDisplay(StoreBlip, 6)
					SetBlipColour(StoreBlip, v["blipcolour"])
					SetBlipAsShortRange(StoreBlip, true)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentSubstringPlayerName(v["label"])
					EndTextCommandSetBlipName(StoreBlip)
				end
				if Config.Peds then
					if v["model"] then
						local i = math.random(1, #v["model"])
						RequestModel(v["model"][i]) while not HasModelLoaded(v["model"][i]) do Wait(0) end
						if ped["Shop - ['"..k.."("..l..")']"] == nil then ped["Shop - ['"..k.."("..l..")']"] = CreatePed(0, v["model"][i], b.x, b.y, b.z-1.0, b.a, false, false) end
						if not v["killable"] then SetEntityInvincible(ped["Shop - ['"..k.."("..l..")']"], true) end
						local scenarios = { "WORLD_HUMAN_AA_COFFEE", "WORLD_HUMAN_GUARD_PATROL", "WORLD_HUMAN_JANITOR", "WORLD_HUMAN_STAND_MOBILE_UPRIGHT", "WORLD_HUMAN_STAND_MOBILE", "PROP_HUMAN_STAND_IMPATIENT", }
						scenario = math.random(1, #scenarios)
						TaskStartScenarioInPlace(ped["Shop - ['"..k.."("..l..")']"], scenarios[scenario], -1, true)
						SetBlockingOfNonTemporaryEvents(ped["Shop - ['"..k.."("..l..")']"], true)
						FreezeEntityPosition(ped["Shop - ['"..k.."("..l..")']"], true)
						SetEntityNoCollisionEntity(ped["Shop - ['"..k.."("..l..")']"], PlayerPedId(), false) 
						if Config.Debug then print("Ped Created for Shop - ['"..k.."("..l..")']") end
					end
				end
				if Config.Debug then print("Shop - ['"..k.."("..l..")']") end
				exports['qb-target']:AddCircleZone("Shop - ['"..k.."("..l..")']", vector3(b.x, b.y, b.z), 2.0, { name="Shop - ['"..k.."("..l..")']", debugPoly=Config.Debug, useZ=true, }, 
				{ options = { { event = "jim-shops:ShopMenu", icon = "fas fa-certificate", label = "Browse Shop", 
					shoptable = v, name = v["label"], k = k, l = l, }, },
				distance = 2.0 })
			end
		end
	end
end)

RegisterNetEvent('jim-shops:ShopMenu', function(data, custom)
	local products = data.shoptable.products
	local ShopMenu = {}
	local hasLicense, hasLicenseItem = nil
	local stashItems = nil
	local setheader = ""
	if Config.Limit and not custom then
		local p = promise.new() 
		QBCore.Functions.TriggerCallback('jim-shops:server:GetStashItems', function(stash) p:resolve(stash) end, "["..data.k.."("..data.l..")]")
		stashItems = Citizen.Await(p)
	end
	if data.shoptable["logo"] ~= nil then ShopMenu[#ShopMenu + 1] = { isDisabled = true, header = "<center><img src="..data.shoptable["logo"].." width=100%>", txt = "", isMenuHeader = true }
	else ShopMenu[#ShopMenu + 1] = { header = data.shoptable["label"], txt = "", isMenuHeader = true }
	end
	
	if Config.JimMenu then ShopMenu[#ShopMenu + 1] = { icon = "fas fa-circle-xmark", header = "", txt = "Close", params = { event = "jim-shops:CloseMenu" } }
	else ShopMenu[#ShopMenu + 1] = { header = "", txt = "❌ Close", params = { event = "jim-shops:CloseMenu" } } end
	
	if data.shoptable["type"] == "weapons" then
		local p = promise.new()
		local p2 = promise.new()
		QBCore.Functions.TriggerCallback("jim-shops:server:getLicenseStatus", function(hasLic, hasLicItem) p:resolve(hasLic) p2:resolve(hasLicItem) end)
		hasLicense = Citizen.Await(p)
		hasLicenseItem = Citizen.Await(p2)
	end
	for i = 1, #products do
		local amount = nil
		local lock = false
		if Config.Limit and not custom then if stashItems[i].amount == 0 then amount = 0 lock = true else amount = tonumber(stashItems[i].amount) end end
		if products[i].price == 0 then price = "Free" else price = "Cost: $"..products[i].price end
		if Config.Debug then print("ShopMenu - Searching for item '"..products[i].name.."'")
			if not QBCore.Shared.Items[products[i].name:lower()] then 
				print ("RestockShopItems - Can't find item '"..products[i].name.."'")
			end
		end
		
		if not Config.JimMenu then setheader = "<img src=nui://"..Config.img..QBCore.Shared.Items[products[i].name].image.." width=30px>"..QBCore.Shared.Items[products[i].name].label
		else setheader = QBCore.Shared.Items[products[i].name].label end
		local text = price.."<br>Weight: "..(QBCore.Shared.Items[products[i].name].weight / 1000)..Config.Measurement
		if Config.Limit and not custom then text = price.."<br>Amount: x"..amount.."<br>Weight: "..(QBCore.Shared.Items[products[i].name].weight / 1000)..Config.Measurement end
		if products[i].requiredJob then
			for i2 = 1, #products[i].requiredJob do
				if QBCore.Functions.GetPlayerData().job.name == products[i].requiredJob[i2] then
					ShopMenu[#ShopMenu + 1] = { icon = products[i].name, header = setheader, txt = text, isMenuHeader = lock,
						params = { event = "jim-shops:Charge", args = { item = products[i].name, cost = products[i].price, info = products[i].info, shoptable = data.shoptable, k = data.k, l = data.l, amount = amount, custom = custom } } }
				end
			end
		elseif products[i].requiresLicense then
			if hasLicense and hasLicenseItem then
			ShopMenu[#ShopMenu + 1] = { icon = products[i].name, header = setheader, txt = text, isMenuHeader = lock,
					params = { event = "jim-shops:Charge", args = { item = products[i].name, cost = products[i].price, info = products[i].info, shoptable = data.shoptable, k = data.k, l = data.l, amount = amount, custom = custom } } }
			end
		else
			ShopMenu[#ShopMenu + 1] = { icon = products[i].name, header = setheader, txt = text, isMenuHeader = lock,
					params = { event = "jim-shops:Charge", args = { 
									item = products[i].name, 
									cost = products[i].price,
									info = products[i].info,
									shoptable = data.shoptable,
									k = data.k,
									l = data.l, 
									amount = amount,
									custom = custom,
								} } }
		end
	text, setheader = nil
	end
	exports['qb-menu']:openMenu(ShopMenu)
end)

RegisterNetEvent('jim-shops:CloseMenu', function() exports['qb-menu']:closeMenu() end)

RegisterNetEvent('jim-shops:Charge', function(data)
	if data.cost == "Free" then price = data.cost else price = "$"..data.cost end
	if QBCore.Shared.Items[data.item].weight == 0 then weight = "" else weight = "Weight: "..(QBCore.Shared.Items[data.item].weight / 1000)..Config.Measurement end
	local settext = "- Confirm Purchase -<br><br>"
	if Config.Limit and data.amount ~= nil then settext = settext.."Amount: "..data.amount.."<br>" end
	settext = settext..weight.."<br> Cost per item: "..price.."<br><br>- Payment Type -"
	local header = "<center><p><img src=nui://"..Config.img..QBCore.Shared.Items[data.item].image.." width=100px></p>"..QBCore.Shared.Items[data.item].label
	if data.shoptable["logo"] ~= nil then header = "<center><p><img src="..data.shoptable["logo"].." width=150px></img></p>"..header end
	
	local newinputs = {}
	if data.shoptable["label"] == Config.Locations["blackmarket"]["label"] and Config.BlackCrypto then 
		newinputs[#newinputs+1] = { type = 'radio', name = 'billtype', text = settext, options = { { value = "crypto", text = "Crypto" } } }
	else
		newinputs[#newinputs+1] = { type = 'radio', name = 'billtype', text = settext, options = { { value = "cash", text = "Cash" }, { value = "bank", text = "Card" } } }
	end
	newinputs[#newinputs+1] = { type = 'number', isRequired = true, name = 'amount', text = 'Amount to buy' }
	
	local dialog = exports['qb-input']:ShowInput({ header = header, submitText = "Pay", inputs = newinputs })
	if dialog then
		if not dialog.amount then return end
		if Config.Limit and data.custom == nil then	if tonumber(dialog.amount) > tonumber(data.amount) then TriggerEvent("QBCore:Notify", "Incorrect amount", "error") TriggerEvent("jim-shops:Charge", data) return end end
		if tonumber(dialog.amount) <= 0 then TriggerEvent("QBCore:Notify", "Incorrect amount", "error") TriggerEvent("jim-shops:Charge", data) return end
		if data.cost == "Free" then data.cost = 0 end
		if data.amount == nil then nostash = true end
		TriggerServerEvent('jim-shops:GetItem', dialog.amount, dialog.billtype, data.item, data.shoptable, data.cost, data.info, data.k, data.l, nostash)
		RequestAnimDict('amb@prop_human_atm@male@enter')
        while not HasAnimDictLoaded('amb@prop_human_atm@male@enter') do Wait(1) end
        if HasAnimDictLoaded('amb@prop_human_atm@male@enter') then TaskPlayAnim(PlayerPedId(), 'amb@prop_human_atm@male@enter', "enter", 1.0,-1.0, 1500, 1, 1, true, true, true) end
	end
end)

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
	for k, v in pairs(Config.Locations) do
		for l, b in pairs(v["coords"]) do
			exports['qb-target']:RemoveZone("Shop - ['"..k.."("..l..")']")
			if Config.Peds then	DeletePed(ped["Shop - ['"..k.."("..l..")']"]) end
		end 
	end 
end)
