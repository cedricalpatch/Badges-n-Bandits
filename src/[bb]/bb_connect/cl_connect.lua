
-- Badges & Bandits: Connection Script (CLIENT)
RegisterNetEvent('bb:connect_ack')
local connected = false

-- NUI: Connect
-- Handles NUI functionality from JQuery/JS to Lua
RegisterNUICallback("ConnectMenu", function(data, callback)

  if data.action == "exit" then 
    SendNUIMessage({hidemenu = true})
    SetNuiFocus(false, false)

  end

end)

-- COMMAND: relog
-- Allows the player to bring up the character menu to choose another character
RegisterCommand('relog', function()
  TriggerServerEvent('bb:create_player')
end)

-- On connection to the server
--AddEventHandler('onClientGameTypeStart', function()   
AddEventHandler('onClientResourceStart', function(resname)
  if GetCurrentResourceName() == resname then

    Citizen.Wait(100)

    print("DEBUG - Requesting for the server to let me spawn.")

    Citizen.CreateThread(function()
      -- Keep probing the server until we're loaded
      while not connected do 
        TriggerServerEvent('bb:create_player')
        Citizen.Wait(3000)
      end
      print("DEBUG - The Server has acknowledged my connection.")
    end)
  end
end)

AddEventHandler('bb:connect_ack', function(charInfo)
  connected = true
  if charInfo then
    print("DEBUG - Reloading last played character.")
    ReloadCharacter(charInfo)
  else
    print("DEBUG - Going to character creator.")
    CreateCharacter()
  end
end)
