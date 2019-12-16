
-- Badges & Bandits: Client Main Script (CLIENT MASTER)


-- Discord Rich Presence
Citizen.CreateThread(function()
	while true do
		SetDiscordAppId(611712266164895744) -- Discord app id
		SetDiscordRichPresenceAsset('SouthlandRP') -- Big picture asset name
    SetDiscordRichPresenceAssetText('Southland Roleplay FiveM') -- Big picture hover text
    SetDiscordRichPresenceAssetSmall('srp_logo') -- Small picture asset name
    SetDiscordRichPresenceAssetSmallText('Southland Roleplay FiveM') -- Small picture hover text
		Citizen.Wait(600000) --How often should this script check for updated assets? (in MS)
	end
end)

-- Format; To get local client's info, use index 'ServerId(PlayerId())'
-- Access with given Accessors/Mutators
local plyInfo = {}
	-- name: The player's display name
  -- duty: True if player is on law duty
  -- leo:  Player's cop rank
  -- civ:  Player's pivilian rank
  

--- EXPORT GetZoneName()
-- Returns the name for the area defined by script
-- @param zName The result of GetNameOfZone(x,y,z)
-- @return A string with the name for the area, if not found, returns zName
function GetZoneName(zName)
	if zName then
		if zones[zName] then
			return zones[zName]
		end
	end
	return zName
end


---------- ENTITY ENUMERATOR --------------
local entityEnumerator = {
  __gc = function(enum)
    if enum.destructor and enum.handle then
      enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
  end
}


local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iter)
      return
    end
    
    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)
    
    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iter)
    until not next
    
    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
  end)
end


--- EXPORT EnumerateObjects()
-- Used to loop through all objects rendered by the client
-- @return The table of entities
-- @usage for objs in EnumerateObjects() do
function EnumerateObjects()
  return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end


--- EXPORT EnumeratePeds()
-- Used to loop through all objects rendered by the client
-- @return The table of entities
-- @usage for peds in EnumeratePeds() do
function EnumeratePeds()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end


--- EXPORT EnumerateVehicles()
-- Used to loop through all objects rendered by the client
-- @return The table of entities
-- @usage for vehs in EnumerateVehicles() do
function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end


--- EXPORT EnumeratePickups()
-- Used to loop through all pickups rendered by the client
-- @return The table of entities
-- @usage for pickups in EnumeratePickups() do
function EnumeratePickups()
  return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end
-------------------------------------------------	
	

--- EXPORT GetClosestPlayer()
-- Finds the closest player
-- @return Player local ID. nil if client's alone
function GetClosestPlayer()
	local ped  = PlayerPedId()
	local plys = GetActivePlayers()
	local cPly = nil
	local cDst = -1
	for k,v in pairs (plys) do
		local tgt = GetPlayerPed(v)
		if tgt ~= ped then
			local dist = #(GetEntityCoords(ped) - GetEntityCoords(tgt))
			if cDst == -1 or cDst > dist then
				cPly = v
				cDst = dist
			end
		end
	end
	return cPly
end


-- Enable PVP
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		SetCanAttackFriendly(PlayerPedId(), true, false)
		NetworkSetFriendlyFireOption(true)
	end
end)


--- Event: bnb:playerinfo
-- Sets plyInfo to the values passed by the server
-- @param client the player server id of whose info client is receiving
-- @param plInfo A table of client information (name, character id, etc)
function PlayerInfo(client, plInfo)
	plyInfo[client] = plInfo
end
RegisterNetEvent('bnb:playerinfo')
AddEventHandler('bnb:playerinfo', PlayerInfo)


--- EXPORT GetMyInfo()
-- Called by other scripts to retrieve their character info from MySQL
-- @return Table of info from myInfo/clInfo
function GetMyInfo()
	return myInfo
end


--- EXPORT GetPlayerInfo()
-- Called by other scripts to retrieve their character info from MySQL
-- @param iPly the server id of the player client wants the info from
-- @return Table of info from myInfo/clInfo
function GetPlayerInfo(iPly)
	return plyInfo[iPly]
end


-- NUI: MainMenu
-- Handles NUI functionality from JQuery/JS to Lua
RegisterNUICallback("MainMenu", function(data, callback)

  if data.action == "exit" then 
    SendNUIMessage({hidemenu = true})
    SetNuiFocus(false, false)
  
  end

end)

