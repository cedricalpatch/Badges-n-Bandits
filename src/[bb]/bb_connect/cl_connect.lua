
--[[
  Southland RP: Character Creation (CLIENT)
  Created by Michael Harris (mike@harrisonline.us)
  03/26/2019
  
  This file handles all clientsided interaction to joining the game,
  choosing a character, remaking a character, and handling interface.
  
  Permission denied to edit, redistribute, or otherwise use this script.
--]]


-- General Char Creation stuff
local myName = "Soandso Noname"
local chars  = {}
local charid = 0

local isCreating, isPlaying, isLoaded = false, false, false
local isMenuOpen = true
local waitingAccept = false


-- Script related vars
local reportLocn        = false


-- Used for facial feats/overlays/bodyhair, etc
local hColor, hStyle, hLight = 0, 0, 0
local modifyFeature     = 0
local eyeColor          = 0
local oNumber 		      = 0
local faceOne, faceTwo  = 0, 0
local faceTwo           = 0
local likeMom, likeDad  = 0.5, 0.5
local myGender          = "M"

local charsLoaded = false

--[[  ------------------------------------------------------------------------------------------
-- 'onClientGameTypeStart'																	  
-- Called when the player is fully isLoadedinto the game										  
-- ** THIS TRIGGERS ALL FUNCTIONS ACROSS THE SCRIPT **	  
-- ** STOPPING THIS WILL BREAK THE ENTIRE GAME MODE **	  
AddEventHandler('onClientGameTypeStart', function()   
	  exports.spawnmanager:setAutoSpawn(false)
	  Citizen.Wait(1000)
    
    -- Spawns a nobody on the beach
	  exports.spawnmanager:spawnPlayer({
	  	x = cams.ped.vine.x,
	  	y = cams.ped.vine.y,
	  	z = cams.ped.vine.z + 1.0,
	  	model = "mp_m_freemode_01"
	  }, function()
	  	SetPedDefaultComponentVariation(PlayerPedId())
	  end)
    
	  CreationCam(true, cams.scr.vine.x, cams.scr.vine.y, cams.scr.vine.z, cams.scr.vine.h)
    
    -- Request MOTD Window
    TriggerServerEvent('srp:motd_info')
	  
    -- Hide radar until ready
    Citizen.CreateThread(function()
      while not isPlaying do
        Citizen.Wait(0)
        HideHudAndRadarThisFrame()
      end
    end)
    
    if IsScreenFadedOut() then DoScreenFadeIn(2000) end
    
end)
----------------------------------------------------------------------------------------------]]

AddEventHandler('onClientResourceStart', function(rn)
  if GetCurrentResourceName() == rn then
    if not charsLoaded then 
      Citizen.CreateThread(function()
        while not charsLoaded do 
          TriggerServerEvent('srp:request_characters')
          Citizen.Wait(3000)
          print("DEBUG - Server hasn't sent us our characters yet. Retry.")
        end
      end)
    end
  end
end)

RegisterNetEvent('srp:load_character')
AddEventHandler('srp:load_character', function(charList)
  if not charsLoaded then
    charsLoaded = true
    chars = charList
    Citizen.Wait(1000)
    if not chars[1] then
      TriggerEvent('srp:create_new')
    else
      TriggerServerEvent('srp:select_character', chars[1]['dbid'])
    end
  end
  TriggerServerEvent('srp:characters_rx')
end)

RegisterNetEvent('srp:receive_motd')
AddEventHandler('srp:receive_motd', function(motd)
  local msgInfo = {}
  table.insert(msgInfo, '<ul>')
  for k,v in pairs(motd) do
    if v ~= "" then
      table.insert(msgInfo,
        '<li>'..v..'</li>'
      )
    end
  end
  table.insert(msgInfo, '</ul>')
  SendNUIMessage({showwelcome = true})
  SendNUIMessage({motdinfo = true,
    changeLog = table.concat(msgInfo)
  })
  SetNuiFocus(true, true)
end)


TriggerEvent('chat:addSuggestion', '/relog', 'Allows you to switch to another character', {})
local lastRelog = 0 - 900000
RegisterCommand('relog', function()
  if isPlaying then
    if lastRelog + 10 < GetGameTimer() then
    
      -- Update latest position to the server and update upon receipt
      local coord = GetEntityCoords(PlayerPedId())
      local locPackage = {table.unpack(coord)}
  		TriggerServerEvent('srp:updatePos', locPackage, true)
      
      TriggerEvent('srp:ammu_weapons_strip', false)
      TriggerEvent('srp:weapons_report', false) -- Stop reporting weapons to MySQL
      
      local start = GetGameTimer()
      DoScreenFadeOut(900)
      Citizen.Wait(900)
      TriggerServerEvent('srp:unload')
      TriggerEvent('srp:unload')
      
      TriggerServerEvent('srp:end_faction_duty') -- Reset Faction Duty Values
      
      
      isLoaded  = false
      isPlaying = false
      
      lastRelog = GetGameTimer()
      
      SetEntityCoords(PlayerPedId(), cams.ped.vine.x, cams.ped.vine.y, cams.ped.vine.z)
	    CreationCam(true, cams.scr.vine.x, cams.scr.vine.y, cams.scr.vine.z, cams.scr.vine.h)
      
	    
      -- Hide radar until ready
      Citizen.CreateThread(function()
        while not isPlaying do
          Citizen.Wait(0)
          HideHudAndRadarThisFrame()
        end
      end)
    
      FreezeEntityPosition(PlayerPedId(), true)
      RequestCollisionAtCoord(coord)
      local zFound, zCoord
      local GroundCheck = function()
        RequestCollisionAtCoord(coord.x, coord.y, coord.z)
        zFound, zCoord = GetGroundZFor_3dCoord(coord.x, coord.y, 1000.0)
        return zFound
      end
      
      while not GroundCheck() do
        Wait(100)
        if GetGameTimer() > start + 5000 then
          break
        end
      end
      
      if zFound then SetEntityCoords(ped, coord.x, coord.y, zCoord) end
      
      -- Show MOTD Window
      SendNUIMessage({showwelcome = true})
      SetNuiFocus(true, true)
      FreezeEntityPosition(ped, false)
      
      DoScreenFadeIn(500)
      
    else
      TriggerEvent('chatMessage',
        "^1RELOG ERROR: ^7Can only switch characters every 15 minutes."..
        "\nYou must wait approximately ^1"..
        ((math.floor(lastRelog + 900000 - GetGameTimer())/1000)%60)
      )
    end
  else
    TriggerEvent('chatMessage',
      "^1RELOG ERROR: ^7Not currently playing a character."
    )
  end
 
end)

--- EXPORT IsMainMenuOpen()
-- Returns true if the character select or welcome screens are open
-- @return True if menu is open
function IsMainMenuOpen()
  return isMenuOpen
end


--- EXPORT CheckLoadStatus()
-- Returns true if the character has fully loaded into the game
function CheckLoadStatus()
  return isPlaying
end


--- EXPORT EndStartingCam()
-- Closes the camera view if active
function EndStartingCam()
  CreationCam(false)
end


--- EXPORT GetRoleplayName()
-- Returns the first and last name of the character that is loaded
-- @return String with name; Returns empty string if not loaded
function GetRoleplayName()
  if isLoaded then
    return myName
  else
    return "Not Loaded"
  end
end

-- ModifyTorso()
-- Picks a Torso that matches the top selected
function ModifyTorso(item, drawable)
	if item then
		SetPedComponentVariation(PlayerPedId(), 11, item, drawable, 1)
		local torso = exports['srp_clothing']:GetComponentTorso(item)
		SetPedComponentVariation(PlayerPedId(), 3, tonumber(torso), 0, 1)
	end
end


-- CreationCamera()
-- Sets the player and camera up at the starting location
function CreationCam(toggle, x, y, z, h)
	if toggle then
		if not DoesCamExist(cam) then cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true) end
		SetCamActive(cam, true)
		RenderScriptCams(true, true, 500, true, true)
		SetCamParams(cam, x, y, z, 350.0, 0.0, h, 80.0)
	else
		SetCamActive(cam, false)
		RenderScriptCams(false, true, 500, true, true)
		cam = nil
	end
end

function ChangeCameraPos(cPos)
  if cPos == 0 then -- Face
		local ox,oy,oz = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.1, 0.45, 0.625))
		SetCamParams(cam, ox, oy, oz, 350.0, 0.0, cams.ped.clothes.h + 195.0, 80.0)
  elseif cPos == 1 then -- Body
		local ox,oy,oz = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.5, 1.5, 0.3))
		SetCamParams(cam, ox, oy, oz, 350.0, 0.0, cams.ped.clothes.h + 195.0, 80.0)
  else -- Feet
		local ox,oy,oz = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.12, 0.7, -0.66))
		SetCamParams(cam, ox, oy, oz, 350.0, 0.0, cams.ped.clothes.h + 195.0, 80.0)
    
  end
end


-- NUI: playerWelcome
-- Received when player clicks "PLAY" from the welcome screen
RegisterNUICallback('playerWelcome', function()
  Citizen.Wait(1000)
  TriggerServerEvent('srp:joined', false)
  --[[SetCamParams(cam, cams.scr.sel.x,
    cams.scr.sel.y,
    cams.scr.sel.z,
    0.0, 0.0, cams.scr.sel.h,
    60.0
  )]]
end)


-- addComma()
-- Adds a comma every 3 digits to format the cash value
-- @param
function addComma(str)
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)","%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

-- srp:main_menu
-- Opens the character select window
RegisterNetEvent('srp:main_menu')
AddEventHandler('srp:main_menu', function(names, count)

	atMenu = true
  if not names then names = {}
  else chars = names end
  print("DEBUG - Found "..tostring(count).." characters!")
  
	local tbl = {
		showmain  = true, upnames   = true,
		charone   = "Start a New Character", id1 = (-1),
		chartwo   = "Start a New Character", id2 = (-1),
		charthree = "Start a New Character", id3 = (-1),
		charfour  = "Start a New Character", id4 = (-1)
  }
		
	if names[1] then
		tbl.charone = (names[1]["firstname"].." "..names[1]["lastname"])
    tbl.c1cash  = "$"..addComma(tostring(names[1]["cash"]))
    tbl.c1bank  = "$"..addComma(tostring(names[1]["bank"]))
    tbl.c1fac   = names[1]["title"]
    tbl.c1rank  = names[1]["rank"..tostring(names[1]["facRank"])]
		tbl.id1		  = names[1]["dbid"]
    print("DEBUG - Character 1 ("..(tbl.charone)..") exists! [ID "..tbl.id1.."]")
	end
	if names[2] then 
		tbl.chartwo = (names[2]["firstname"].." "..names[2]["lastname"])
    tbl.c2cash  = "$"..addComma(tostring(names[2]["cash"]))
    tbl.c2bank  = "$"..addComma(tostring(names[2]["bank"]))
    tbl.c2fac   = names[2]["title"]
    tbl.c2rank  = names[2]["rank"..tostring(names[2]["facRank"])]
		tbl.id2		  = names[2]["dbid"]
    print("DEBUG - Character 1 ("..(tbl.chartwo)..") exists! [ID "..tbl.id2.."]")
	end
	if names[3] then
		tbl.charthree = (names[3]["firstname"].." "..names[3]["lastname"])
    tbl.c3cash  = "$"..addComma(tostring(names[3]["cash"]))
    tbl.c3bank  = "$"..addComma(tostring(names[3]["bank"]))
    tbl.c3fac   = names[3]["title"]
    tbl.c3rank  = names[3]["rank"..tostring(names[3]["facRank"])]
		tbl.id3		  = names[3]["dbid"]
    print("DEBUG - Character 1 ("..(tbl.charthree)..") exists! [ID "..tbl.id3.."]")
	end
	if names[4] then
		tbl.charfour = (names[4]["firstname"].." "..names[4]["lastname"])
    tbl.c4cash  = "$"..addComma(tostring(names[4]["cash"]))
    tbl.c4bank  = "$"..addComma(tostring(names[4]["bank"]))
    tbl.c4fac   = names[4]["title"]
    tbl.c4rank  = names[4]["rank"..tostring(names[4]["facRank"])]
		tbl.id4		  = names[4]["dbid"]
    print("DEBUG - Character 1 ("..(tbl.charfour)..") exists! [ID "..tbl.id4.."]")
	end
	
  if not DoesCamExist(cam) then
	  CreationCam(true, cams.scr.vine.x, cams.scr.vine.y, cams.scr.vine.z, cams.scr.vine.h)
  end
  
	SendNUIMessage(tbl)
	SetNuiFocus(true, true)
	
end)


-- NUI: selectChar
-- Called when a player clicks on a character / create new character
RegisterNUICallback('selectChar', function(data)

	SendNUIMessage({hideallmenus = true})
	SetNuiFocus(false, false)
  
	if data.action == "SelCharacter" then
    
		-- Send request to log into character from MySQL/Server
    local cid = data.charid
		if chars[cid] then
			local fname = chars[cid]["firstname"].." "..chars[cid]["lastname"]
			if isPlaying and fname == myName then
				TriggerEvent('chatMessage', "^2Already logged in as ^7"..tostring(fname).."^2. Restoring.")
				TriggerServerEvent('srp:select_character', chars[cid]["dbid"], true, fname)
				
			elseif isPlaying then
				TriggerEvent('chatMessage', "^2Switching to ^7"..tostring(fname).."^2.")
				TriggerServerEvent('srp:select_character', chars[cid]["dbid"], false, fname, true)
			
			else
				TriggerEvent('chatMessage', "^2Logging in to ^7"..tostring(fname).."^2.")
				TriggerServerEvent('srp:select_character', chars[cid]["dbid"])
			
			end
			isPlaying = true
			
		-- If that character ID doesn't exist, chances are it said "NEW CHARACTER"
		-- Optimize this later
		else
			
      TriggerEvent('srp:create_new')
			
		end
	end
end)


-- srp:create_new
-- The server detects the player has never played before.
RegisterNetEvent('srp:create_new')
AddEventHandler('srp:create_new', function()
  
  isCreating = true 
  myGender   = "M"
  
  DoScreenFadeOut(200)
  Citizen.Wait(250)
  
	CreationCam(false)
    
	exports.spawnmanager:spawnPlayer({
		x = cams.ped.clothes.x,
		y = cams.ped.clothes.y,
		z = cams.ped.clothes.z,
		model = "mp_m_freemode_01"
	}, function()
    
	  SendNUIMessage({hideallmenus = true})
		SetNuiFocus(true, true)
    
		Citizen.Wait(100)
    
    SetPedDefaultComponentVariation(PlayerPedId())
    if myGender == "M" then 
      SetPedComponentVariation(PlayerPedId(), 8, 15, 0) -- Accessory OFF 
    else
      SetPedComponentVariation(PlayerPedId(), 8, 14, 0) -- Females
    end
    
		Citizen.Wait(100)
    
		if not DoesCamExist(cam) then cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true) end
    
		SetCamActive(cam, true)
		RenderScriptCams(true, true, 500, true, true)
    
    Citizen.Wait(1000)
    
		local ox,oy,oz = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.5, 1.5, 0.3))
		SetCamParams(cam, ox, oy, oz, 350.0, 0.0, cams.ped.clothes.h + 195.0, 80.0)
    
    DoScreenFadeIn(200)
    
	  SetNuiFocus(true, true)
	  SendNUIMessage({showcreator = true})
    
	end)
end)


-- NUI: genderChange
-- Called during character creation to change gender
RegisterNUICallback('genderChange', function(gModel)

  DoScreenFadeOut(200)
  Citizen.Wait(200)

	exports.spawnmanager:spawnPlayer({
		x = cams.ped.clothes.x,
		y = cams.ped.clothes.y,
		z = cams.ped.clothes.z,
		model = gModel
	}, function()
  
    Citizen.Wait(200)
    
    SetPedDefaultComponentVariation(PlayerPedId())
    
    if gModel == "mp_m_freemode_01" then
      myGender = "M"
    else
      myGender = "F"
    end
    if myGender == "M" then 
      SetPedComponentVariation(PlayerPedId(), 8, 15, 0) -- Accessory OFF 
    else
      SetPedComponentVariation(PlayerPedId(), 8, 14, 0) -- Females
    end
    
    
    Citizen.Wait(50)
  
    local ped = PlayerPedId()
    for k,v in pairs (faceFeats[myGender]) do
      SetPedFaceFeature(ped, k, v)
    end
    
    Citizen.Wait(50)
    
    SetPedHeadBlendData(PlayerPedId(), faceOne, faceTwo, 0, faceOne, faceTwo, 0, likeMom, likeDad, 0.0, false)
    
    for i = 0, 12, 1 do
		  SetPedHeadOverlay(PlayerPedId(), i, overlaySet[myGender][i].index, 1.0)
      if i == 10 then 
        SetPedHeadOverlayColor(PlayerPedId(), i, 1, 1, 1)
      end
    end
    
    Citizen.Wait(50)
    
    local tNum = newbClothes.shirt.choices[myGender].curr
    ModifyTorso(newbClothes.shirt.choices[myGender].text[tNum], newbClothes.shirt.choices[myGender].draw[tNum])
    
    tNum = newbClothes.pants.choices[myGender].curr
    SetPedComponentVariation(PlayerPedId(), 4,
    newbClothes.pants.choices[myGender].text[tNum], 1
    )
      
    tNum = newbClothes.shoes.choices[myGender].curr
    SetPedComponentVariation(PlayerPedId(), 6,
    newbClothes.shoes.choices[myGender].text[tNum], 1
    )
    
    DoScreenFadeIn(200)
    ChangeCameraPos(1)
  end)
end)

-- NUI: doOverlayMenu
-- Handles changing features of the player model body

RegisterNUICallback('doOverlayMenu', function(data)

	-- Opens the overlay submenu
	-- overlaySet[overlay_type] {index, col1, col2}
	if data.action == "DoOverlay" then
		oNumber = data.val
		overlaySet[myGender][oNumber].index = overlaySet[myGender][oNumber].index + 1
		if tonumber(overlaySet[myGender][oNumber].index) > 250 then
			overlaySet[myGender][oNumber].index = 0 
		elseif overlaySet[myGender][oNumber].index > overlaySet[myGender][oNumber].max then
			overlaySet[myGender][oNumber].index = 255
		end
    
		SetPedHeadOverlay(PlayerPedId(), oNumber, overlaySet[myGender][oNumber].index, 1.0)
    if oNumber == 10 then 
      SetPedHeadOverlayColor(PlayerPedId(), oNumber, 1, 1, 1)
    end
	
    -- 0 = head, 1 = body, 2 = feet
    if data.val == 0 or data.val == 9 then
      ChangeCameraPos(0)
    else
      ChangeCameraPos(1)
    end
	
	elseif data.action == "hairChange" then
		if tonumber(data.ind) == 1 then
			hStyle = hStyle + 1
			if hStyle > 25 then hStyle = 0 end
		else
			hColor = hColor + 1
			if hColor > GetNumHairColors() then hColor = 0 end
		end
		SetPedComponentVariation(PlayerPedId(), 2, hStyle, 0, 2)
		SetPedHairColor(PlayerPedId(), hColor, 0)
	
    ChangeCameraPos(0)
	
	elseif data.action == "facialFeature" then
    modifyFeature = tonumber(data.slot)
  --[[
		SetPedFaceFeature(PlayerPedId(), tonumber(data.slot), (data.val)/100)
		faceFeats[tonumber(data.slot)] = tonumber((data.val)/100)
		]]
    
	elseif data.action == "eyeColor" then
		eyeColor = eyeColor + 1
		if eyeColor > 9 then eyeColor = 0 end
		SetPedEyeColor(PlayerPedId(), eyeColor)
    ChangeCameraPos(0)
		
	end
end)


-- NUI: doModelSelect
-- Handles changing facial features, similarity, and model setup
RegisterNUICallback('doModelSelect', function(data)

	local ped = PlayerPedId()
  ChangeCameraPos(0) -- face
  -- Changes the facial similarities
	if data.action == "FaceChange" then
		if data.direction == 2 then
			if data.select == 1 then
				faceOne = faceOne + 1
				if faceOne > 45 then faceOne = 0 end
				SendNUIMessage({faceupdate = true, fOne = faceOne, fTwo = faceTwo})
				
			else
				faceTwo = faceTwo + 1
				if faceTwo > 45 then faceTwo = 0 end
				SendNUIMessage({faceupdate = true, fOne = faceOne, fTwo = faceTwo})
				
			end
		else
			if data.select == 1 then
				faceOne = faceOne - 1
				if faceOne < 0 then faceOne = 45 end
				SendNUIMessage({faceupdate = true, fOne = faceOne, fTwo = faceTwo})
				
			else
				faceTwo = faceTwo - 1
				if faceTwo < 0 then faceTwo = 45 end
				SendNUIMessage({faceupdate = true, fOne = faceOne, fTwo = faceTwo})
				
			end
		end
		SetPedHeadBlendData(ped, faceOne, faceTwo, 0, faceOne, faceTwo, 0, likeMom, likeDad, 0.0, false)
		--BeachWear(ped)
	
  -- APplies facial features
  elseif data.action == "applyFeat" then
    local value = (tonumber(data.setting)/100)
    SetPedFaceFeature(PlayerPedId(), modifyFeature, value)
    faceFeats[myGender][modifyFeature] = value
    
  -- Changes percentage similarities between parents
	elseif data.action == "doPercent" then
		likeMom = (data.mom)/100
		likeDad = (data.dad)/100
		SetPedHeadBlendData(ped, faceOne, faceTwo, 0, faceOne, faceTwo, 0, likeMom, likeDad, 0.0, false)
		
	elseif data == "setModel" then
		SendNUIMessage({showcreatetwo = true})
		TriggerServerEvent('srp:create_setmodel', faceOne, faceTwo, likeDad)
		
	elseif data == "finishModel" then
		SetNuiFocus(false, false)
		SendNUIMessage({hidemenu = true})
		CreationCam(false)
		isPlaying = true
		TriggerEvent('srp:clothing_newplayer')
	
	end
end)


-- srp:character_approved
-- If character is accepted, send all information to create them
RegisterNetEvent('srp:character_approved')
AddEventHandler('srp:character_approved', function(data, dlNum, phNum)

  data.phNumber = phNum
  data.license  = dlNum
  data.gender   = "M"
  data.mdl      = "mp_m_freemode_01"
  
  if myGender == "F" then
    data.gender = "F"
    data.mdl    = "mp_f_freemode_01"
  end
  
  local ped = PlayerPedId()
	local comps = {
		[3]  = GetPedDrawableVariation(ped, 3),
		[4]  = GetPedDrawableVariation(ped, 4),
		[5]  = GetPedDrawableVariation(ped, 5),
		[6]  = GetPedDrawableVariation(ped, 6),
		[7]  = GetPedDrawableVariation(ped, 7),
		[8]  = GetPedDrawableVariation(ped, 8),
		[9]  = GetPedDrawableVariation(ped, 9),
		[10] = GetPedDrawableVariation(ped, 10),
		[11] = GetPedDrawableVariation(ped, 11)
	}
	
	local drawVar = {}
	for k,v in pairs (comps) do
		drawVar[#drawVar + 1] = {
      ['slot'] = k,['draw'] = v,
      ['text'] = GetPedTextureVariation(ped, k)
    }
	end
    
  data.outfit   = json.encode(drawVar)
  data.features = json.encode(faceFeats[myGender])
  
  -- Sets hair, eye, and overlay settings
  local myChoices = {
	  ["hairstyle"] = {
	  	["hComp"] = hStyle, ["hColor"] = hColor, ["hLight"] = hLight
	  },
	  ["overlay"]	= {
	  	[0]	 = {["index"] = 0,  ["item"] = overlaySet[myGender][0].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][0].col1,  ["colorTwo"] = overlaySet[myGender][0].col2},
	  	[1]  = {["index"] = 1,  ["item"] = overlaySet[myGender][1].index,  ["colorType"] = 1, ["colorOne"] = overlaySet[myGender][1].col1, 	["colorTwo"] = overlaySet[myGender][1].col2},
	  	[2]  = {["index"] = 2,  ["item"] = overlaySet[myGender][2].index,  ["colorType"] = 1, ["colorOne"] = overlaySet[myGender][2].col1, 	["colorTwo"] = overlaySet[myGender][2].col2},
	  	[3]	 = {["index"] = 3,  ["item"] = overlaySet[myGender][3].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][3].col1,  ["colorTwo"] = overlaySet[myGender][3].col2},
	  	[4]  = {["index"] = 4,  ["item"] = overlaySet[myGender][4].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][4].col1, 	["colorTwo"] = overlaySet[myGender][4].col2},
	  	[5]  = {["index"] = 5,  ["item"] = overlaySet[myGender][5].index,  ["colorType"] = 2, ["colorOne"] = overlaySet[myGender][5].col1, 	["colorTwo"] = overlaySet[myGender][5].col2},
	  	[6]	 = {["index"] = 6,  ["item"] = overlaySet[myGender][6].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][6].col1,  ["colorTwo"] = overlaySet[myGender][6].col2},
	  	[7]	 = {["index"] = 7,  ["item"] = overlaySet[myGender][7].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][7].col1,  ["colorTwo"] = overlaySet[myGender][7].col2},
	  	[8]  = {["index"] = 8,  ["item"] = overlaySet[myGender][8].index,  ["colorType"] = 2, ["colorOne"] = overlaySet[myGender][8].col1, 	["colorTwo"] = overlaySet[myGender][8].col2},
	  	[9]  = {["index"] = 9,  ["item"] = overlaySet[myGender][9].index,  ["colorType"] = 0, ["colorOne"] = overlaySet[myGender][9].col1,  ["colorTwo"] = overlaySet[myGender][9].col2},
	  	[10] = {["index"] = 10, ["item"] = overlaySet[myGender][10].index, ["colorType"] = 1, ["colorOne"] = overlaySet[myGender][10].col1,	["colorTwo"] = overlaySet[myGender][10].col2},
	  	[11] = {["index"] = 11, ["item"] = overlaySet[myGender][11].index, ["colorType"] = 1, ["colorOne"] = overlaySet[myGender][11].col1,	["colorTwo"] = overlaySet[myGender][11].col2},
	  	[12] = {["index"] = 12, ["item"] = overlaySet[myGender][12].index, ["colorType"] = 1, ["colorOne"] = overlaySet[myGender][12].col1,	["colorTwo"] = overlaySet[myGender][12].col2},
	  }
	}
  
  data.overlay = json.encode(myChoices)
  
  data.blender = json.encode({one = faceOne, two = faceTwo, val = likeDad})
  
  waitingAccept = true
  TriggerServerEvent('srp:char_submit', data)
  
  SendNUIMessage({hideallmenus = true})
  TriggerEvent('srp:basic_notification', "Awaiting approval from the server...")
  
  Citizen.Wait(3000)
  waitingAccept = false
end)

-- If character is denied, show why
RegisterNetEvent('srp:character_deny')
AddEventHandler('srp:character_deny', function(reason)
  waitingAccept = false
  SendNUIMessage({showdeny = true, rsn = reason})
  Citizen.Wait(3000)
  SendNUIMessage({hidedeny = true})
end)


-- NUI: newbieSet
-- Handles NUI functionality from JQuery/JS to Lua
RegisterNUICallback("newbieSet", function(data, callback)

  -- Shirt
  if data.action == 1 then
  
    newbClothes.shirt.choices[myGender].curr = newbClothes.shirt.choices[myGender].curr + 1
    if newbClothes.shirt.choices[myGender].curr > #newbClothes.shirt.choices[myGender].text then
      newbClothes.shirt.choices[myGender].curr = 1
    end
    
    local tNum = newbClothes.shirt.choices[myGender].curr
    ModifyTorso(newbClothes.shirt.choices[myGender].text[tNum], newbClothes.shirt.choices[myGender].draw[tNum])
    ChangeCameraPos(1)
    
  -- Pants
  elseif data.action == 2 then
  
      newbClothes.pants.choices[myGender].curr = newbClothes.pants.choices[myGender].curr + 1
      if newbClothes.pants.choices[myGender].curr > #newbClothes.pants.choices[myGender].text then
        newbClothes.pants.choices[myGender].curr = 1
      end
      
      local tNum = newbClothes.pants.choices[myGender].curr
      SetPedComponentVariation(PlayerPedId(), 4,
      newbClothes.pants.choices[myGender].text[tNum], 1
      )
    ChangeCameraPos(1)
  -- Shoes
  elseif data.action == 3 then
  
    newbClothes.shoes.choices[myGender].curr = newbClothes.shoes.choices[myGender].curr + 1
    if newbClothes.shoes.choices[myGender].curr > #newbClothes.shoes.choices[myGender].text then
      newbClothes.shoes.choices[myGender].curr = 1
    end
      
    local tNum = newbClothes.shoes.choices[myGender].curr
    SetPedComponentVariation(PlayerPedId(), 6,
    newbClothes.shoes.choices[myGender].text[tNum], 1
    )
    ChangeCameraPos(2)
  end
end)


-- NUI: submitCharacter
-- Called to submit all settings to SQL
RegisterNUICallback('submitCharacter', function(data)
  if not waitingAccept then
    waitingAccept = true
    -- Simply asks the server if the name is available
    TriggerServerEvent('srp:char_verify', data)
  else
    TriggerEvent('chatMessage',
      "^1Awaiting character approval, please wait."
    )
  end
end)

local isLooping = false 
function StartCharacterLoops()
  if not isLooping then 
    isLooping = true
    Citizen.CreateThread(function()
      reportLocn = true 
      
	    local milesWalked  = 0
	    local milesDriven  = 0
	    local lastPosWalk  = {x=0.0,y=0.0,z=0.0}
	    local lastPosDrive = {x=0.0,y=0.0,z=0.0}
      
      -- Request everyone's player info tables
      TriggerServerEvent('srp:request_plytables')
      
      -- Updates player's statistics/location to server periodically
	    Citizen.CreateThread(function()
	    	while isLoaded do
	    		Citizen.Wait(30000)
	    		TriggerServerEvent('srp:sql_stats_update', milesWalked, milesDriven)
      		if reportLocn then
            local locPackage = {table.unpack(GetEntityCoords(PlayerPedId()))}
      			TriggerServerEvent('srp:updatePos', locPackage)
      		end
	    		milesWalked = 0
	    		milesDriven = 0
	    	end
	    end)
      
	    -- Keeps track of distance walked/driven
	    Citizen.CreateThread(function()
	    	while isLoaded do
	    		Citizen.Wait(1000)
	    		local dist = 0
	    		local ped = PlayerPedId()
	    		local pPos = GetEntityCoords(ped)
	    		if IsPedInAnyVehicle(ped) then
	    			if GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
	    				if lastPosDrive.x ~= 0.0 then
	    					dist = CalculateTravelDistanceBetweenPoints(lastPosDrive.x, lastPosDrive.y, lastPosDrive.z, pPos.x, pPos.y, pPos.z)
	    					milesDriven = milesDriven + (dist * 0.000621371)
	    				end
	    				lastPosDrive = GetEntityCoords(ped)
	    			end
	    		else
	    			if lastPosWalk.x ~= 0.0 then
	    				dist = CalculateTravelDistanceBetweenPoints(lastPosWalk.x, lastPosWalk.y, lastPosWalk.z, pPos.x, pPos.y, pPos.z)
	    				milesWalked = milesWalked + (dist * 0.000621371)
	    				
	    			end
	    			lastPosWalk = GetEntityCoords(ped)
	    		end
	    	end
        isLooping = false
	    end)
    end)
  end
end

RegisterNetEvent('srp:new_character_spawn')
AddEventHandler('srp:new_character_spawn', function(cid, spawnModel, xpos, ypos, zpos, newChar)
  
	isLoaded   = true
  isMenuOpen = false
  isPlaying  = true
  
  isCreating = false
  SetNuiFocus(false)
  SendNUIMessage({hidemenu = true})
  TriggerEvent('srp:show_help_new_char')
  
  if not spawnModel then spawnModel = "mp_m_freemode_01" end
  
  -- Spawns the player
  exports.spawnmanager:spawnPlayer({
    x = xpos,
    y = ypos,
    z = zpos,
    model = GetHashKey(spawnModel)
  }, function()
    -- Tells all of the other scripts that we're ready
    EndStartingCam()
    Citizen.Wait(100)
		TriggerServerEvent('srp:jailed_relog')
    Citizen.Wait(100)
		TriggerServerEvent('srp:ammu_respawned')
    Citizen.Wait(2000)
    TriggerServerEvent('srp:character_loaded', cid)
  end)
  
	charid = cid
  StartCharacterLoops()
  
end)


RegisterNetEvent('srp:character_spawn')
AddEventHandler('srp:character_spawn', function(cid, spawnModel, xpos, ypos, zpos, isCreating)


	isLoaded   = true
  isMenuOpen = false
  isPlaying  = true
  
  -- Spawn the ped
  if not xpos or not ypos or not zpos then 
    xpos = 0.0
    ypos = 0.0
    zpos = 0.0
  end
  if not spawnModel then spawnModel = "mp_m_freemode_01" end
  
  -- Spawns the player
  exports.spawnmanager:spawnPlayer({
    x = xpos,
    y = ypos,
    z = zpos,
    model = GetHashKey(spawnModel)
  }, function()
    -- Tells all of the other scripts that we're ready
    EndStartingCam()
    Citizen.Wait(100)
		TriggerServerEvent('srp:jailed_relog')
    Citizen.Wait(100)
		TriggerServerEvent('srp:ammu_respawned')
    Citizen.Wait(2000)
    TriggerServerEvent('srp:character_loaded', cid)
  end)
  
	charid = cid
  
  StartCharacterLoops()
end)