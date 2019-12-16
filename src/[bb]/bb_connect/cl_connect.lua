
-- Badges & Bandits: Connection Script (CLIENT)


-- NUI: Connect
-- Handles NUI functionality from JQuery/JS to Lua
RegisterNUICallback("ConnectMenu", function(data, callback)

  if data.action == "exit" then 
    SendNUIMessage({hidemenu = true})
    SetNuiFocus(false, false)
  
  end

end)

