
--[[
  Southland RP: Character Creation (SERVER)
  Created by Michael Harris (mike@harrisonline.us)
  03/26/2019
  
  This file handles all serversided interaction to verifying character
  information, and saving/recalling MySQL Information from the server.
  
  Permission denied to edit, redistribute, or otherwise use this script.
--]]

--[[------------------------------------------------------------------------
  INITIALIZATION / REGISTERNETEVENT / REGISTERCOMMAND
--]]--------------------------------------------------

local rpName, charid, charInfo = {}
local playerPositions = {}

local badNames = {"fuck", "nigger", "nigga", "shit", "iilil", "captain",
  "ilili", "asdf", "general", "slut", "whore", "cunt", "bastard",
  "bitch", "asshole", "arsehole", "arse", "ass", "bitch", "sexy",
  "puberty", "sexi", "sir", "lady", "king", "queen", "clit", "penis", "boob"
}


--[[------------------------------------------------------------------------
  FUNCTIONS
--]]--------


-- firstToUpper()
-- Capitalize first letter of string
-- @param str The string to capitalize
-- @return A string with the first character capitalized
function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end


-- RandAscii()
-- Generates a random Ascii character. Used for Ctrl Panel Reg Code.
-- Always generates a number if both params are false
-- @param useLower Allows generation of a lower case letter
-- @param useUpper Allows generation of an upper case letter
-- @return The character that was generated
function RandAscii(useLower, useUpper)
	local temp = {}
	table.insert(temp, math.random(48, 57))
	if useLower then table.insert(temp, math.random(97, 122)) end
	if useUpper then table.insert(temp, math.random(65, 90)) end
	return string.char(temp[math.random(#temp)])
end


-- UnpackLocation()
-- Saves the playerPositions position into the MySQL Database
-- @param ply int The player's server ID
function UnpackLocation(ply, cid)
	if playerPositions[ply] and cid then
		local x, y, z = table.unpack(playerPositions[ply])	-- Turns the coordinates saves in the table into x, y, z values
		if x then
			if cid then
				exports['GHMattiMySQL']:Query("UPDATE srp_characters SET xpos = @xpos, ypos = @ypos, zpos = @zpos WHERE dbid = @charid",
					{
						['xpos'] 	  = x,
						['ypos'] 	  = y,
						['zpos'] 	  = z,
						['charid'] 	= cid
					}
				)
				playerPositions[ply] = nil
			end
		end
	end
end

-- playerDropped
-- Retrieves the player who just disconnected, from MySQL;
-- Uses that information to save where they logged off from.
AddEventHandler('playerDropped', function(reason)
	local ply  = source
  local name = GetPlayerName(ply)
	local uid  = exports['southland']:UniqueId(ply)
	local cid  = exports['southland']:GetCharacterId(ply)
	local rpn  = exports['southland']:GetRPName(ply)
  exports['GHMattiMySQL']:QueryAsync(
    "UPDATE srp_characters SET active = 0 WHERE dbid = @charid",
    {['charid'] = cid}
  )
  if not rpn then rpn = "" end
	TriggerClientEvent('srp:conn_status_message', (-1), false, rpn, name, uid, reason)
	print("[SRP] Player (#"..tostring(ply)..") [UID "..tostring(uid).."] disconnected. Reason: "..tostring(reason)..".")
	if rpn ~= "nil" then 
	  exports['srp_chat']:DiscordMessages("Server", tostring(rpn).." disconnected. ["..tostring(reason).."]")
	else
	  exports['srp_chat']:DiscordMessages("Server", name.." disconnected before logging in. ["..tostring(reason).."]")
	end
	if cid then
    if cid > 0 then
    
      UnpackLocation(ply, cid)	-- Turns the saved coordinates into a MySQL save
      
      -- Dispatches a messages that someone has disconnected
      TriggerEvent('srp:plyDisconnected', -1, ply, uid, cid)	
      TriggerClientEvent('srp:plyDisconnected', -1, ply, uid, cid)	
	      
    end
  end
  
  -- Get the time the player connected so we can close off their stats entry
  local stats = exports['GHMattiMySQL']:QueryResult(
    "SELECT idStat,time FROM stats_connect "..
    "WHERE idUser = @uid ORDER BY idStat DESC LIMIT 1",
    {['uid'] = uid}
  )
  
  -- Only update if the entry was found (it should have been)
  -- Anything left empty will just be ignored as a "bad stat"
  if stats[1] then
  
    -- Since Epoch is sec since 0, subtracting the two gives us secs played
    -- Add 1 second to os time to ensure the result is always positive
    local playTime = tonumber((os.time() + 1) - (stats[1]['time']/1000))
    print("DEBUG - "..(os.time() + 1).." - "..(stats[1]['time']/1000).." = "..playTime)
  
    -- SQL: Add seconds played to the connection entry.
    -- 'seconds' not null in this table means the player signed off
    exports['GHMattiMySQL']:Query(
      "UPDATE stats_connect SET seconds = @sec WHERE idStat = @id",
      {['sec'] = math.abs(playTime), ['id'] = stats[1]['idStat']}
    )
    
  end
  
  
end)


-- srp:updatePos
-- Periodically saves player's coordinates to the playerPositions table
-- NOTE: The interval that this saves is set clientside 'cl_create.lua' (Default: 30 seconds)
RegisterServerEvent('srp:updatePos')
AddEventHandler('srp:updatePos', function(coords, doNow)
	local ply = source
	playerPositions[ply] = coords
  if doNow then
    local cid = exports['southland']:GetCharacterId(ply)
	  exports['GHMattiMySQL']:Query("UPDATE srp_characters SET xpos = @xpos, ypos = @ypos, zpos = @zpos WHERE dbid = @charid",
	  	{
	  		['xpos'] 	 = coords[1],
	  		['ypos'] 	 = coords[2],
	  		['zpos'] 	 = coords[3],
	  		['charid'] = cid
	  	}
	  )
  end
end)


--[[RegisterServerEvent('srp:motd_info')
AddEventHandler('srp:motd_info', function()
  local ply       = source
  local changeLog = io.open("changelog.txt", "r")
  local logLines  = {}
  if not changeLog then 
  else
    for line in io.lines("changelog.txt") do 
      if line ~= "" and line then
        logLines[#logLines + 1] = line
      end
    end
  end
  TriggerClientEvent('srp:receive_motd', ply, logLines)
end)]]

local cloaded = {}
function InitCharacters(ply, uid)
  if not ply then print("DEBUG - No player id given to InitCharacters. Failed.");return 0 end
  if not uid then uid = exports['southland']:UniqueId(ply) end
  
  if uid then
    if uid > 0 then
      local charList = exports['GHMattiMySQL']:QueryResult(
        "SELECT dbid,firstname,lastname FROM srp_characters "..
        "WHERE idUser = @uid ORDER BY lastplay DESC",
        {['uid'] = uid}
      )
      
      TriggerClientEvent('srp:load_character', ply, charList)
      print("DEBUG - InitCharacters(): Sending "..#charList.." characters to ID #"..ply)
    else print("DEBUG - InitCharacters(): UID was invalid. Waiting and trying again.")
    end
  else print("DEBUG - InitCharacters(): UID nil. Waiting and then trying again.")
  end
  
  -- While player is un-initialized, keep trying
  Citizen.Wait(3000)
  if not cloaded[ply] then
    print("DEBUG - InitCharacters(): No receipt. Recurse.")
    InitCharacters(ply, uid)
  end
  
end
RegisterServerEvent('srp:request_characters')
AddEventHandler('srp:request_characters', function()
  InitCharacters(source) -- Player has loaded in and has not got their characters
end)
RegisterServerEvent('srp:characters_rx')
AddEventHandler('srp:characters_rx', function()
  cloaded[source] = true
end)

-- srp:restore_position
-- Retrieves the last known location of character stored in SQL
RegisterServerEvent('srp:restore_position')
AddEventHandler('srp:restore_position', function()
	local ply = source
	local cid = exports['southland']:GetCharacterId(ply)
	local loc = exports['GHMattiMySQL']:QueryResult("SELECT * FROM srp_characters WHERE dbid = @charid",
		{['charid'] = cid}
	)
  
	TriggerServerEvent('srp:restore_location', ply, loc[1]["xpos"], loc["ypos"], loc["zpos"], loc["gender"])
	
end)


function GetCharactersForMenu(ply, uid)
	-- MySQL: Retrieve all names of characters the player has, then open the menu.
	-- Doesn't matter if this is nil. The client will handle that.
  local count = exports['GHMattiMySQL']:QueryScalar(
    "SELECT COUNT(*) FROM srp_characters WHERE idUser = @user",
    {['user'] = uid}
  )
  
  local names = {}
  if count > 0 then 
	  names = exports['GHMattiMySQL']:QueryResult(
      "SELECT c.dbid,c.firstname,c.lastname,c.bank,c.cash,c.facRank,f.* "..
      "FROM srp_characters c LEFT JOIN srp_factions f ON "..
      "c.idFaction = f.idFaction WHERE idUser = @user",
	  	{['user'] = uid}
	  )
  end
  TriggerClientEvent('srp:main_menu', ply, names, count)
  return count
end


-- srp:joined
-- Retrieves client's database info from MySQL when they connect to the server.
-- If no record found, creates their first character.
RegisterServerEvent('srp:joined')
AddEventHandler('srp:joined', function(currPlaying)


	local ply 	= source
  local pName = GetPlayerName(ply)
  local uid   = exports['southland']:UniqueId(ply)
  
  print("[SRP] "..pName.." ("..uid..") has cleared the welcome screen!")
  
  print("[SRP] Loaded "..GetCharactersForMenu(ply, tonumber(uid)).." characters for "..pName)
  
end)

-- GenerateNumerics()
-- Creates a unique 8 character driver's license number
-- Also creates a unique 7 digit phone number
-- @return license First return is the unique license number
-- @return phoneNum Second return is the unique phone number
function GenerateNumerics()

	local letters  = {"A", "E", "F", "L", "M", "N", "P", "T"}
	local numbers  = {"1","2","3","4","5","6","7","8","9","0"}
  local license  = ""
  local phoneNum = ""
  local unique = {
    lic = false,
    ph  = false
  }
  
  -- Loops until both a unique license and unique phone number exists
  while not unique.lic or not unique.ph do
    Citizen.Wait(1)
    
    -- If it's not unique, wipe it
    if not unique.lic then license  = "" end
    if not unique.ph  then phoneNum = "" end
    
    -- Generates the values
    for i=1, 8, 1 do
      Citizen.Wait(0)
      if i == 1 then
        if not unique.lic then
          license  = letters[math.random(#letters)]
        end
      else
        if not unique.lic then
          license  = license..(numbers[math.random(#numbers)])
        end
        if not unique.ph then
          phoneNum = phoneNum..(numbers[math.random(#numbers)])
        end
      end
    end
    
    -- Checks the values for uniqueness in SQL
    local licFound = exports['GHMattiMySQL']:QueryScalar(
      "SELECT COUNT(*) FROM srp_licenses WHERE idLicense = @dlNumber",
      {['dlNumber'] = license}
    )
    
    local phFound = exports['GHMattiMySQL']:QueryScalar(
      "SELECT COUNT(*) FROM srp_characters WHERE phone = @phnum",
      {['phnum'] = phoneNum}
    )
    
    if licFound < 1 then unique.lic = true
    end
    if phFound  < 1 then unique.ph  = true
    end
  end
  return license, phoneNum
end

function NameValidated(f, l)
  for k,v in pairs (badNames) do
    if string.match(f, v) then
      print("[SRP] Character Rejected: First name uses banned word '"..tostring(v).."'.")
      return ("First name uses banned word ("..tostring(v)..").")
    end
    if string.match(l, v) then
      print("[SRP] Character Rejected: Last name uses banned word '"..tostring(v).."'.")
      return ("Last name uses banned word ("..tostring(v)..").")
    end
  end
  return "valid"
end

-- srp:char_verify
-- Checks to see if chosen name already exists in SQL
RegisterServerEvent('srp:char_verify')
AddEventHandler('srp:char_verify', function(data)

  local ply = source

  -- Sanitize the firstname and lastname input
  local firsttemp = string.gsub(data.firstname, "[%c%p%s%d]", "")
  local lasttemp  = string.gsub(data.surname, "[%c%p%s%d]", "")
  
  -- Verify firsttemp and lasttemp are valid
  if not firsttemp or not firsttemp then
    TriggerClientEvent('srp:character_deny', ply, "Invalid first or last name.")
    print("[SRP] Character Rejected: Invalid first/last name or combination.")
    return -- End function
  end
  
  if firsttemp == "" or lasttemp == "" then
    TriggerClientEvent('srp:character_deny', ply, "Invalid first or last name.")
    print("[SRP] Character Rejected: Invalid first/last name or combination.")
  end
  
  -- Lowercase all letters
  firsttemp = string.lower(firsttemp)
  lasttemp  = string.lower(lasttemp)
  
  -- Capitalize first character, and reassign new names
  data.firstname = firstToUpper(firsttemp)
  data.surname   = firstToUpper(lasttemp)

  local nv = NameValidated(firsttemp, lasttemp)
  if nv == "valid" then
    --SQL: Checks if the firstname and lastname already exists
    local exists = exports['GHMattiMySQL']:QueryScalar(
      "SELECT COUNT(*) FROM srp_characters WHERE firstname = @fname AND lastname = @lname",
      {['fname'] = data.firstname, ['lname'] = data.surname}
    )
    
    
    if exists > 0 then
      TriggerClientEvent('srp:character_deny', ply,
        "That name has already been taken"
      )
      print("[SRP] Character Rejected: Name already in use by another character.")
    else
    
      -- Generate a unique driver's license number
      local myLicense, phNumber = GenerateNumerics()
      
      -- Tell client they are good to go for character creation
      TriggerClientEvent('srp:character_approved', ply,
        data, myLicense, phNumber
      )
      
    end
  else
    if nv then 
      TriggerClientEvent('srp:character_deny', ply, nv)
    else
      TriggerClientEvent('srp:character_deny', ply, "An error occurred.")
    end
  end
end)


-- srp:char_submit
-- Complete information for character creation
-- All info should be verified already before coming in as this event
-- @param data Char data; firstname, lastname, dob, license, phNumber
RegisterServerEvent('srp:char_submit')
AddEventHandler('srp:char_submit', function(data)

  local ply = source
  
	local y,m,d   = string.match(data.dob, '(%d+)-(%d+)-(%d+)')	-- Sets y,m,d based on user given date of birth
	local newdob  = string.format('%s/%s/%s', m, d, y)			    -- Formats the date appropriately
	local today   = os.date("%m/%d/%Y")							            -- Retrieves today's date
	local expires = os.date('%m/%d/%Y', os.time()+15778800)		  -- Adds 6 mos (for license expiration date)
	
  local pbook   = '{"Roadside Asst":"824-7000","Regional 911":"544-8400","Fire Command Center":"401-2600","Ambulance":"922-1000"}'
  
  local uid = exports['southland']:UniqueId(ply)
  
  -- SQL: Runs add character procedure with settings
  local cid = exports['GHMattiMySQL']:QueryScalar(
    "SELECT addchar(@id, @fname, @lname, @birth, @sex, @skin, @lays, "..
    "@pnum, @contacts, @dlnum, @outfit, @issu, @exp, @feats, @blender)",
    {
      ['id']    = uid,          ['fname']  = data.firstname, ['lname']    = data.surname,
      ['birth'] = newdob,       ['sex']    = data.gender,    ['skin']     = data.mdl,
      ['lays']  = data.overlay, ['pnum']   = data.phNumber,  ['contacts'] = pbook,
      ['dlnum'] = data.license, ['outfit'] = data.outfit,    ['feats']    = data.features,
      ['issu']  = today,        ['exp']    = expires,        ['blender']  = data.blender
    }
  )
  
  
  local rpn = (data.firstname.." "..data.surname)
  
  TriggerEvent('srp:srp_assigncharinfo', ply, rpn, cid, uid, data.license, data.phNumber)
  TriggerClientEvent('srp:wallet_cash', ply, 500)
  
  TriggerClientEvent('srp:character_ready', ply, uid, cid, true)
  TriggerEvent('srp:character_ready', ply, uid, cid, true)
  
  TriggerClientEvent('srp:new_character_spawn', ply,
    cid, data.mdl, 450.42, -650.75, 28.475, true
  )
  
  exports['srp_chat']:DiscordMessages("Game Monitor", "Please welcome our newest character, "..(rpn).."!")
  TriggerClientEvent('chatMessage',
    "^3Southland RP: ^1((^7Please welcome out newest Character, ^3"..(rpn).."^7!^1))"
  )
	
  Citizen.CreateThread(function()
		Citizen.Wait(1000)
		TriggerClientEvent('srp:conn_status_message', (-1), true, rpn, GetPlayerName(ply), uid)
	end)

end)

-- srp:select_character
-- Retrieves the selected character, or starts a new character if not found
RegisterServerEvent('srp:select_character')
AddEventHandler('srp:select_character', function(chid, sameChar, tempName, sameSession)

	local ply  = source
	local cid  = tonumber(chid)
	local ccid = exports['southland']:GetCharacterId(ply)
  local uid  = exports['southland']:UniqueId(ply)
  
  -- SQL: Does idUser match?
  local cuid = exports['GHMattiMySQL']:QueryScalar(
    "SELECT (u.idUser = c.idUser) FROM srp_characters c "..
    "LEFT JOIN srp_users u ON u.idUser = c.idUser "..
    "WHERE c.dbid = @charid",
    {['charid'] = cid}
  )
  
  -- If idUser doesn't match, update it.
  if cuid == 1 then 
    print("DEBUG - idUser was a match. Ignoring update.")
  else
    print("DEBUG - Updating idUser.")
    -- SQL: Update idUser for existing character
    exports['GHMattiMySQL']:QueryAsync(
      "UPDATE srp_characters SET idUser = @uid WHERE dbid = @charid",
      {['uid'] = uid, ['charid'] = cid}
    )
  end
  
  print("[SRP] "..GetPlayerName(ply).." has chosen Character ID #"..tostring(cid))
	
  if cid and ply then
		-- SQL: Returns character information
		local results = exports['GHMattiMySQL']:QueryResult(
      "SELECT * FROM srp_characters WHERE dbid = @charid",
			{['charid'] = cid}
		)
	
		if results[1] then
    
      local rpn = results[1]["firstname"].." "..results[1]["lastname"]
    
      local isActive = exports['GHMattiMySQL']:QueryScalar(
        "SELECT active FROM srp_characters WHERE dbid = @charid",
        {['charid'] = cid}
      )
      
      if isActive > 0 then 
      
        exports['southland']:PrettyPrint(
          "^1LOG IN DENIED! ^7"..tostring(rpn).." is already being played!", true
        )
        
        GetCharactersForMenu(ply, uid)
      
      else
      
        local ipaddr = GetPlayerEP(ply)
        local uname  = GetPlayerName(ply)
        
        -- SQL: Sets the selected character as active
        exports['GHMattiMySQL']:QueryAsync(
          "UPDATE srp_characters SET active = 1, lastplay = NOW() WHERE dbid = @charid",
          {['charid'] = cid}
        )
          
        -- Assign RP information to southland clInfo table
        if not sameChar then
          TriggerEvent('srp:srp_assigncharinfo', ply, rpn, cid, uid, nil, results[1]["phone"]) 
        
          -- Assign RP info to clients tables
          local plInfo = {
            charid  = cid,
            unique  = uid,
            name    = rpn
          }
          TriggerClientEvent('srp:playerinfo', (-1), ply, plInfo)
        end
        
        -- All done. Let the scripts fire off what they need to do now
        Citizen.Wait(1000)
        TriggerClientEvent('srp:character_ready', ply, uid, cid)
        TriggerEvent('srp:character_ready', ply, uid, cid)
        
        -- Spawns the character then triggers features/overlay build
        TriggerClientEvent('srp:character_spawn', ply, cid,
          results[1]["skin"], results[1]["xpos"],
          results[1]["ypos"], results[1]["zpos"]
        )
        
        if not sameSession then		
          exports['srp_chat']:DiscordMessages("Game Monitor", tostring(rpn).." has joined the game!")
          Citizen.CreateThread(function()
            Citizen.Wait(2000)
            TriggerClientEvent('srp:conn_status_message', (-1), true, rpn, GetPlayerName(ply), uid)
          end)
        elseif (cid ~= ccid) and (ccid > 0) then
          exports['srp_chat']:DiscordMessages("Game Monitor", tostring(rpn).." has joined the game! [Changed Characters].")
        end
        
      end
      
		-- Character was invalid, make a new one.
		else
			TriggerClientEvent('chatMessage', ply, '^1ERROR', {255,255,255}, "That character was not found, starting creation.")
			exports['southland']:SouthlandError(2, "srp:select_character", "sv_create.lua", "No character found for database id #"..tostring(chid))
			TriggerClientEvent('srp:create_new', ply)
			
		end
	end
end)


-- srp:sql_stats_update
-- Updates the values such as hours played, etc
RegisterServerEvent('srp:sql_stats_update')
AddEventHandler('srp:sql_stats_update', function(walk, drive)
	local cid = exports['southland']:GetCharacterId(source)
	exports['GHMattiMySQL']:QueryAsync("UPDATE srp_characters SET milesWalk = milesWalk + @walked, milesDrive = milesDrive + @driven, playtime = playtime + 1 WHERE dbid = @charid",
		{['walked'] = walk, ['driven'] = drive, ['charid'] = cid},
		function()
		end
	)
end)


-- srp:character_ready
-- Called when the character is fully loaded and ready to be played 
-- This generates a control panel registration code with RandAscii()
RegisterServerEvent('srp:character_ready')
AddEventHandler('srp:character_ready', function(ply, uid, cid)

	local entry = exports['GHMattiMySQL']:QueryScalar(
    "SELECT COUNT(*) FROM srp_ctrlpanel WHERE idUser = @user",
		{['user'] = uid}
	)			
  
	local vc = ""
	for i = 1, 6, 1 do
		vc = vc..(RandAscii(true, true))
	end
  
  local uid = exports['southland']:UniqueId(ply)
  
	if tonumber(entry) < 1 then
		exports['GHMattiMySQL']:QueryAsync(
      "INSERT INTO srp_ctrlpanel(idUser, code) "..
      "VALUES (@uid, @vcode)",
			{['uid'] = uid, ['vcode'] = vc}
		)
	else
		exports['GHMattiMySQL']:QueryAsync(
      "UPDATE srp_ctrlpanel SET code = @vcode "..
      "WHERE idUser = @user",
			{['user'] = uid, ['vcode'] = vc}
		)
	end
  print("DEBUG - Control Panel Registration")
end)

-- srp:display_regcode
-- Prints the character's control panel registration code to the chat
RegisterServerEvent('srp:display_regcode')
AddEventHandler('srp:display_regcode', function()
	local ply = source
	local uid = exports['southland']:UniqueId(ply)
	local code = exports['GHMattiMySQL']:QueryScalar("SELECT code FROM srp_ctrlpanel WHERE idUser = @user",
		{['user'] = uid}
	)
	TriggerClientEvent('chatMessage', ply, '', {255,255,255}, "^3CONTROL PANEL REGISTRATION INFORMATION -\n\nUID: '^2"..tostring(uid).."^7'\nREGISTRATION CODE: '^2"..tostring(code).."^7'")
end)


RegisterServerEvent('srp:unload')
AddEventHandler('srp:unload', function()
  local ply = source
  local cid = exports['southland']:GetCharacterId(ply)
  local uid = exports['southland']:UniqueId(ply)
  
  TriggerEvent('srp:srp_assigncharinfo', ply) -- Reset charinfo
  TriggerClientEvent('srp:playerinfo', (-1), ply, {})
  
  local rpname = exports['GHMattiMySQL']:QueryScalar(
    "SELECT CONCAT(firstname, ' ', lastname) FROM srp_characters WHERE dbid = @charid",
    {['charid'] = cid}
  )
  exports['GHMattiMySQL']:Query(
    "UPDATE srp_characters SET active = 0 WHERE idUser = @uid",
    {['uid'] = uid}
  )
  TriggerClientEvent('chatMessage', (-1), "", {255,255,255},
    "^6"..tostring(rpname).." logged off. [Changing Characters (/relog)]"
  )
  
end)

