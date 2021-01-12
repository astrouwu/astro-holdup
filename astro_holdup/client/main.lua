local holdingUp = false
local store = ""
local blipRobbery = nil
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if ("astro_holdup" ~= resourceName) then
      return
    end
end)


function drawTxt(x,y, width, height, scale, text, r,g,b,a, outline)
	SetTextFont(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropshadow(0, 0, 0, 0,255)
	SetTextDropShadow()
	if outline then SetTextOutline() end

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x - width/2, y - height/2 + 0.005)
end

RegisterNetEvent('astro_holdup:currentlyRobbing')
AddEventHandler('astro_holdup:currentlyRobbing', function(currentStore)
	holdingUp, store = true, currentStore
end)

RegisterNetEvent('astro_holdup:killBlip')
AddEventHandler('astro_holdup:killBlip', function()
	RemoveBlip(blipRobbery)
end)

RegisterNetEvent('astro_holdup:setBlip')
AddEventHandler('astro_holdup:setBlip', function(position)
	blipRobbery = AddBlipForCoord(position.x, position.y, position.z)

	SetBlipSprite(blipRobbery, 161)
	SetBlipScale(blipRobbery, 0.7)
	SetBlipColour(blipRobbery, 3)

	PulseBlip(blipRobbery)
end)

RegisterNetEvent('astro_holdup:tooFar')
AddEventHandler('astro_holdup:tooFar', function()
	holdingUp, store = false, ''
	ESX.ShowNotification(_U('robbery_cancelled'))
end)

RegisterNetEvent('astro_holdup:robberyComplete')
AddEventHandler('astro_holdup:robberyComplete', function(award)
	holdingUp, store = false, ''
	ESX.ShowNotification(_U('robbery_complete', award))
end)

RegisterNetEvent('astro_holdup:startTimer')
AddEventHandler('astro_holdup:startTimer', function()
	local timer = Stores[store].secondsRemaining

	Citizen.CreateThread(function()
		while timer > 0 and holdingUp do
			Citizen.Wait(1000)

			if timer > 0 then
				timer = timer - 1
			end
		end
	end)

	Citizen.CreateThread(function()
		while holdingUp do
			Citizen.Wait(0)
			drawTxt(0.66, 1.44, 1.0, 1.0, 0.4, _U('robbery_timer', timer), 255, 255, 255, 255)
		end
	end)
end)

Citizen.CreateThread(function()
	for k,v in pairs(Stores) do
		local blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
		SetBlipSprite(blip, 156)
		SetBlipScale(blip, 0.7)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('shop_robbery'))
		EndTextCommandSetBlipName(blip)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		local playerPos = GetEntityCoords(PlayerPedId(), true)

		for k,v in pairs(Stores) do
			local storePos = v.position
			local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, storePos.x, storePos.y, storePos.z)

			if distance < 3 then
				if not holdingUp then
					ESX.Game.Utils.DrawText3D({x = storePos.x, y = storePos.y, z = storePos.z + 0.2}, 'Press [~r~E~w~] to rob the store', 0.9)
					if distance < 0.5 then
						
							if IsControlJustReleased(0, 38) then
								if IsPedArmed(PlayerPedId(), 4) then
								TriggerServerEvent('astro_holdup:checkstore', k)
									ESX.TriggerServerCallback('astro_holdup:server:checkcops', function(canRob)
                        			if canRob then
										exports['mythic_notify']:DoCustomHudText('inform', 'A and D to rotate. W to accept, S to cancel', 10000)
										--exports['stress']:AddStress('slow', 50000, 5)
										local res = exports['astro_holdup']:createSafe({math.random(0,99), math.random(0,99), math.random(0,99)})
										if res == true then
											local player = GetPlayerFromServerId(source)
											TriggerServerEvent('astro_holdup:robberyStarted', k)
										else
												exports['mythic_notify']:DoHudText('error', 'Cracking Failed')
										end
									else
										exports["mythic_notify"]:SendAlert('error', "You need " ..Config.PoliceNumberRequired.. " cops in town to rob")
									end
								end)
								else
									exports["mythic_notify"]:SendAlert('error', _U('no_threat'))
								end
							end
					end
				end
			end
		end

		if holdingUp then
			local storePos = Stores[store].position
			if Vdist(playerPos.x, playerPos.y, playerPos.z, storePos.x, storePos.y, storePos.z) > Config.MaxDistance then
				TriggerServerEvent('astro_holdup:tooFar', store)
			end
		end
	end
end)
