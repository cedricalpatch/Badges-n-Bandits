
--[[--------------------------------
	Southland Server Master File
	Created by RhapidFyre
--------------------------------]]--

RegisterServerEvent("setmapname")
AddEventHandler("setmapname", function()
  SetMapName("Southland")
end)

local clInfo       = {}
local recentDrop   = {}
local adminName    = {}
local useAdminName = {}
local useDiscord   = true


--- EXPORT: PrettyPrint()
-- Prints a nice formatted message to the console
-- @param msg The message to print
-- @param timestamp Boolean; If true, affixes timestamp
function PrettyPrint(msg, timestamp)
  local prefix = ""
  if timestamp then
    local dt = os.date("%m/%d/%Y %H:%M.%S", os.time())
    prefix = "^3["..dt.."]^7 "
  else
    prefix = "^3[SRP CONSOLE]^7 "
  end
  print(prefix..msg.."^7")
end


Citizen.CreateThread(function()
	Citizen.Wait(5000)
	if useDiscord then
    
    -- Announce the Server coming up
    exports['srp_chat']:DiscordAlert(
      "["..(os.date("%m/%d/%Y %H:%M",os.time())).."] "..
      "The server is up and running. Players may begin connecting anytime."
    )
    
    -- Set all characters to inactive (there's nobody on the server)
    exports['GHMattiMySQL']:Query("UPDATE srp_characters SET active = 0")
    PrettyPrint("SQL: All characters have been set to inactive.")
    
  end
end)

RegisterServerEvent('srp:request_plytables')
AddEventHandler('srp:request_plytables', function()--[[
  local ply = source
  local plys = GetPlayers()
  for k,v in pairs(plys) do
    TriggerClientEvent('srp:playerinfo', ply, v, clInfo[v])
  end]]
end)

--- Reports a major error to the console, admins, and player(s)
-- @param level The level of error (1=Critical, 2=Warning, 3=WarningNoAdmins, 4=NoticeNoAdmins, Other=Generic)
-- @param eFunc The name of the function that ran this error
-- @param eFile The file that sent the error
-- @param message The message (if given, prints nil if not given)
function SouthlandError(level, eFunc, eFile, message)
	if level == 1 then
		print("\n[********* Southland RP Critical Error *********]")
		print("This error means that a script somewhere has failed, possibly catastrophic.")
		print("Message: "..tostring(message).."")
		print("FUNCTION ["..tostring(eFunc).."] in file: '"..tostring(eFile).."'")
		print("[******************** END **********************]\n")
		TriggerEvent('ham:asay', "Fatal Script Error in file '"..tostring(eFile).."', function: ["..tostring(eFunc).."]\nMESSAGE: "..tostring(message))
		TriggerEvent('ham:asay', "A critical script error has ocurred. Someone somewhere broke something bad.")
		
	elseif level == 2 then
		print("[SRP WARNING] "..tostring(message))
		print("[SRP WARNING] Function ["..tostring(eFunc).."] in file '"..tostring(eFile).."'\n")
		TriggerEvent('ham:asay', "Script Error (Priority) in file '"..tostring(eFile).."', function: ["..tostring(eFunc).."]\nMESSAGE: "..tostring(message))
		
	elseif level == 3 then
		print("[SRP LOG ERROR ONLY] "..tostring(message))
		print("[SRP LOG ERROR ONLY] Function ["..tostring(eFunc).."] in file '"..tostring(eFile).."'.\n")
		
	elseif level == 4 then
		print("[SRP NOTICE] "..tostring(message))
		print("[SRP NOTICE] Function ["..tostring(eFunc).."] in file '"..tostring(eFile).."'\n")
		TriggerEvent('ham:asay', "Script Error (Urgent) in file '"..tostring(eFile).."', function: ["..tostring(eFunc).."]\nMESSAGE: "..tostring(message))
	
	else
		print("[SRP ERROR] Failure in function ["..tostring(eFunc).."], in file: '"..tostring(eFile).."'")
		print("[SRP ERROR] The message was: "..tostring(message))
		TriggerEvent('ham:asay', "Script Error (Low Priority) in file '"..tostring(eFile).."', function: ["..tostring(eFunc).."]\nMESSAGE: "..tostring(message))
		
	end
end


function AssignUniqueId(ply)
  
  local pInfo = GetPlayerIdentifiers(ply)
	local sid, xid, wid, did, lid = 0, 0, 0, 0, 0
  
  for k,v in pairs(pInfo) do 
    if     string.find(v, "steam")   then sid = v
    elseif string.find(v, "xbl")     then xid = v
    elseif string.find(v, "live")    then wid = v
    elseif string.find(v, "discord") then did = v
    elseif string.find(v, "license") then lid = v
    end
  end
  
  local uid = exports['GHMattiMySQL']:QueryScalar(
    "SELECT SouthlandUser(@sid, @lid, @xid, @wid, @did, @user, @ipaddr) LIMIT 1",
    {
      ['sid'] = sid, ['lid'] = lid, ['xid'] = xid, ['wid'] = wid,
      ['did'] = did, ['user'] = GetPlayerName(ply),
      ['ipaddr'] = GetPlayerEP(ply)
    }
  )
  if uid < 1 then print("DEBUG - Unable to retrieve UID (wut?)") end
  print("DEBUG - UID "..uid.." recovered for "..GetPlayerName(ply).." (#"..ply..")")
  return uid
end


function UniqueId(ply, idUser)
  if ply then 
  
    -- If no meta, build meta. If uid exists in meta, return it
    if not clInfo[ply] then clInfo[ply] = {} end
    
    if idUser then
      clInfo[ply].unique = idUser
      print("DEBUG - Assigned uid "..idUser.." to Player #"..ply)
      return idUser
      
    else
      if not clInfo[ply].unique then
        print("DEBUG - Checking SQL for Unique ID.")
        clInfo[ply].unique = AssignUniqueId(ply)
      end
    end
    return clInfo[ply].unique
  end
  print("[SRP] No player ID given to UniqueId() from "..GetInvokingResource())
  return nil -- If player ID not given return nil
end


--- Clears the entry in the table as to avoid bad callbacks, and to also free up memory
-- @param ply The server ID of the player info to clear
function ClearCharInfo(ply)
	clInfo[ply] = {}
end

-- 'playerDropped'
-- Assigns the clInfo table to recentDrop[cid]
-- This info can be used to tell the server if they were on duty, etc
-- at the time of their disconnect. Also clears the clInfo slot.
AddEventHandler('playerDropped', function(reason)
	local ply = source
  local cid = clInfo[ply].charid
  Citizen.Wait(10000)
  print("[SRP Disconnect] Preserving character disconnect information.")
  if not recentDrop[cid] then 
    recentDrop[cid] = {}
  end
  recentDrop[cid] = clInfo[ply]
  print("[SRP Disconnect] Finished preserving Character #"..tostring(cid).." for player #"..tostring(ply)..".")
  Citizen.Wait(100)
  ClearCharInfo(ply)
end)

-- GLOBAL GetCharacterId()
-- Retrieves the character id for the ply source given. If cid is nil, it will attempt once to retrieve it from MySQL
-- @param ply (Int) The player's Server ID
function GetCharacterId(ply)
	if ply then
    if type(ply) ~= "number" then
      print("DEBUG - GetCharacterID(ply); ply = nan; tonumber(ply)")
      ply = tonumber(ply)
    end
		local cid = nil
		if clInfo[ply] then
      cid = clInfo[ply].charid
      if not cid then 
        local uid = UniqueId(ply)
        if uid then 
          cid = exports['GHMattiMySQL']:QueryScalar(
            "SELECT dbid FROM srp_characters WHERE idUser = @uid AND active = 1",
            {['uid'] = uid}
          )
          if not cid then 
            SouthlandError(4,
              "GetCharacterId", GetInvokingResource(),
              "CID not found. Tried searching with idUser["..uid.."], but nothing came back."
            )
          end
        else
          SouthlandError(4,
            "GetCharacterId", GetInvokingResource(),
            "CID not found. Tried to find it based on UID, but UID came back nil."
          )
        end
      end
    end
		
		if cid then return cid
		else return 0
		end
    
	else
		SouthlandError(4,
      "GetCharacterId", GetInvokingResource(),
      "Could not retrieve Character ID from MySQL for player nil."
    )
    return 0
	end
end

-- GLOBAL GetRPName()
-- Returns the RP Firstname and Lastname of active character under steamid
-- @param ply The player ID of request
-- @return string Returns firstname.." "..lastname
function GetRPName(ply)
  if useAdminName[ply] then 
    return adminName[ply]
  end
	if not clInfo[ply] then
		return SetRPName(ply)
	end
	if not clInfo[ply].fullname or clInfo[ply].fullname == "" then
		return SetRPName(ply)
	end
	return clInfo[ply].fullname
end


AddEventHandler('ham:toggle_admin_name', function(ply, toggleUse, aid)
  adminName[ply]    = aid
  useAdminName[ply] = toggleUse
end)

-- GLOBAL CheckPublicSafety()
-- Checks if the player is a public servant
-- @param ply Int The server ID of the request
-- @return bool True if the player is a medic/cop/firefighter/agent
function CheckPublicSafety(ply)
	if not clInfo[ply] then
		return false
	end
	if not clInfo[ply].psafety then
		exports['GHMattiMySQL']:QueryScalarAsync("SELECT f.factype FROM srp_characters c LEFT JOIN srp_factions f ON f.idFaction = c.idFaction WHERE c.dbid = @charid",
			{['charid'] = cid},
			function(fac)
				local fctn = tonumber(fac)
				if fctn > 1 then
					clInfo[ply].psafety = true
					return true
				else
					return false
				end
			end
		)
	else
		return true
	end
	return false
end

-- GLOBAL FindPhoneNumber()
-- Searches the online player list for supplied phone number 
-- @param pNum String The phone number to look for
-- @return Int The player ID that matches, returns 0 on failure
function FindPhoneNumber(pNum)
  for k,v in pairs(clInfo) do
    if v.phone == pNum then
      return k
    end
  end
  return 0
end

-- SetRPName(ply)
-- Compliment to GetRPName, sets the RPName if it was nil above
-- @param ply (Int) The Server ID of the request
-- @return string The player's roleplay name
function SetRPName(ply)
	local cid = GetCharacterId(ply)
	if cid then
		local results = exports['GHMattiMySQL']:QueryResult("SELECT firstname, lastname FROM srp_characters WHERE dbid = @charid LIMIT 1",
			{['charid'] = cid}
    )
    if results[1] then
		  if not clInfo[ply] then
		  	clInfo[ply] 			= {}
		  	clInfo[ply].fullname 	= results[1]["firstname"].." "..results[1]["lastname"]
		  	clInfo[ply].firstname = string.sub(results[1]["firstname"], 1, string.find(results[1]["firstname"], " ")-1)
		  	clInfo[ply].lastname 	= string.sub(resultsresults[1]["lastname"], string.find(results[1]["lastname"], " ")+1, string.len(results[1]["lastname"]))
		  end
		  return (results[1]["firstname"].." "..results[1]["lastname"])
    else return "nil"
    end
	end
end


--- EXPORT GetPlayerFaction()
function GetPlayerFaction(ply)
  if clInfo[ply] then 
    if clInfo[ply].faction then 
      return clInfo[ply].faction
    else return 0
    end
  else return 0
  end
end


--- EXPORT IsFactionLeader()
function IsFactionLeader(ply)
  if clInfo[ply] then 
    if clInfo[ply].facRank then 
      return (clInfo[ply].facRank > 6)
    else return false
    end
  else return false
  end
end


--- EXPORT IsFactionSupervisor()
function IsFactionSupervisor(ply)
  if clInfo[ply] then 
    if clInfo[ply].facRank then 
      return (clInfo[ply].facRank > 4)
    else return false
    end
  else return false
  end
end


--- EXPORT GetPlayerFactionRank()
function GetPlayerFactionRank(ply)
  if clInfo[ply] then 
    if clInfo[ply].facRank then 
      return (clInfo[ply].facRank)
    else return 1
    end
  else return 1
  end
end


--- Event srp:srp_assigncharinfo.
-- Builds a table of player info to avoid running SQL queries unnecessarily
-- @param ply Server id of the player being assigned
-- @param name The full roleplay name of the character
-- @param cid The sql database index of the character
-- @param uid The Unique id of the player
-- @param dl The characters driver's license number
-- @usage AddEventHandler('srp:srp_assigncharinfo', serverid, rpname, charid, steamid, licensenum)
function AssignClientInfo(ply, name, cid, uid, dl, phNum)
  print("[SRP] Assigning character info table: clInfo["..tostring(ply).."].")
	if ply then
  
    -- If the table doesn't exist, create it - Otherwise, it's an update
    if not clInfo[ply] then 
      print("DEBUG - Player #"..ply.. " meta created.")
      clInfo[ply] = {}
    end
    
		-- Assign the name value fields
		if not name then
			name = "NoName Found"
		end
    
    if not uid then clInfo[ply].unique = AssignUniqueId(ply)
    else
      clInfo[ply].unique = uid
    end
    PrettyPrint(("UID #"..clInfo[ply].unique.." assigned to Player #"..ply), true)
    
		clInfo[ply].fullname 	= name
		clInfo[ply].firstname = string.sub(name, 1, string.find(name, " ")-1)
		clInfo[ply].lastname 	= string.sub(name, string.find(name, " ")+1, string.len(name))
      print("DEBUG - Character Name "..clInfo[ply].fullname.." assigned to Player #"..ply)
    
    -- If player did not supply a CID, make sure it exists
		if not cid then
      -- If doesn't exist, we're in trouble
      if not clInfo[ply].charid then 
        print("^1[SRP CRITICAL ERROR] ^7Character ID didn't exist when passed to AssignClientInfo()!")
        print("^1[SRP CRITICAL ERROR] ^7Character table assignment has failed, and was terminated.")
        return 0
      end
    -- If they did, update it
    else
      clInfo[ply].charid = cid
      PrettyPrint(
        ("CID #"..tostring(clInfo[ply].charid).." assigned to Player #"..ply),
        true
      )
    end
    
    -- Get player faction information
    local temp = exports['GHMattiMySQL']:QueryResult(
      "SELECT idFaction FROM srp_characters WHERE dbid = @charid",
      {['charid'] = cid}
    )
    if temp[1] then 
      clInfo[ply].faction = temp[1]["idFaction"]
      clInfo[ply].facRank = temp[1]["facRank"]
    else
      clInfo[ply].faction = 0
      clInfo[ply].facRank = 1
    end
    
    -- If not supplied a phone number, make sure it exists
    if not phNum then 
      if not clInfo[ply].phone then
        clInfo[ply].phone = exports['GHMattiMySQL']:QueryScalar("SELECT phone FROM srp_characters WHERE dbid = @char",
          {['char'] = cid}
        )
      end
    else 
      clInfo[ply].phone = phNum
    end
		
		-- Assign the Driver's License Number
		if not dl or dl == "" then
      if not clInfo[ply].license then
        -- MySQL: Retrieve license number from srp_licenses
        if cid then
          local dll = exports['GHMattiMySQL']:QueryScalar("SELECT idLicense FROM srp_licenses WHERE idCharacter = @char",
            {['char'] = cid}
          )
          
          clInfo[ply].license = dll
      
        else
          print("[SRP CRITICAL ERROR] * * Character Info table failed to process. [southland/server.lua]")
          
        end
      end
		else
      clInfo[ply].license = dl
		end
		Citizen.Wait(1000)
		TriggerClientEvent('srp:clientinfo', ply, clInfo[ply])
    print("[SRP] Character info table finished.")
	end
end
AddEventHandler('srp:srp_assigncharinfo', AssignClientInfo)

--- Event srp:character_ready.
-- Send client their character information once loaded
-- @param ply server id
-- @param cid character id
-- @param rpname full roleplay name
-- @usage TriggerEvent('srp:character_ready', serverid, steamid, charid, rpname)
function ClientReady(ply, uid, cid)
	local rpn = exports['GHMattiMySQL']:QueryResult("SELECT firstname,lastname FROM srp_characters WHERE dbid = @charid",
		{['charid'] = cid}
	)
	if rpn[1] then rpn = (rpn[1]["firstname"].." "..rpn[1]["lastname"])
  else rpn = "NameNot Found" end
  local infoTables = {
  
  }
	for k,v in pairs (clInfo) do
		local plInfo = {
			charid  = cid,
      unique  = uid,
			name    = rpn
		}
		TriggerClientEvent('srp:playerinfo', ply, k, plInfo)
	end
end
--RegisterNetEvent('srp:character_ready')
AddEventHandler('srp:character_ready', ClientReady)

AddEventHandler('srp:unload', function()
  ClearCharInfo(source)
end)
