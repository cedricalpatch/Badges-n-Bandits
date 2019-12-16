
-- Badges & Bandits: Connection Script (SERVER)
RegisterServerEvent('bb:create_player')

local cprint = function(msg) exports['bb']:PrettyPrint(msg) end


--- GetPlayerInformation()
-- Retrieves all of the IDs we need and returns them as a table
-- @param ply The player's Server ID
-- @return A table of identifiers stm soc red discd
function GetPlayerInformation(ply)

  local plyInfo = GetPlayerIdentifiers(ply)
  local infoTable = {
    ['stm'] = "", ['soc'] = "", ['red'] = "", ['discd'] = "",
    ['ip'] = GetPlayerEndpoint(ply)
  }
  
  for _,id in pairs (plyInfo) do 
    if string.sub(id, 1, string.len("steam:")) == "steam:" then
      infoTable['stm'] = id
    elseif string.sub(id, 1, string.len("license:")) == "license:" then
      infoTable['soc'] = id
    elseif string.sub(id, 1, string.len("redm:")) == "redm:" then
      infoTable['red'] = id
    elseif string.sub(id, 1, string.len("discord:")) == "steam:" then
      infoTable['discd'] = id
    end
  end
  
  local filtered = GetPlayerName(ply)
  infoTable['user'] = string.gsub(GetPlayerName(ply), "[%W]", "")
  print("DEBUG - User Values:\n"..json.encode(infoTable))
  return infoTable
end


--- CreateUniqueId()
-- Creates a new entry to the 'players' table of the SQL Database, and then 
-- assigns the Unique ID to the 'unique' table variable.
-- @param ply The Player's Server ID.
-- @return nil if invalid, 0 if not found.
function CreateUniqueId(ply)
  
  if not ply then return 0 end
  
  -- Filter username for special characters
  
  -- SQL: Insert new user account for new player
  -- If steamid and fiveid are nil, the procedure will return 0
  local ids = GetPlayerInformation(ply)
  local uid = exports.ghmattimysql:scalarSync(
    "SELECT PlayerJoining (@stm, @soc, @redm, @disc, @ip, @user)",
    {
      ['stm'] = ids['stm'], ['soc'] = ids['soc'], ['redm'] = ids['red'],
      ['disc'] = ids['discd'], ['ip'] = ids['ip'], ['user'] = ids['user']
    }
  )
  if uid > 0 then 
    exports['bb']:UniqueId(ply, tonumber(uid)) -- Set UID for session
    cprint("Created ("..(uid)..") created for  "..GetPlayerName(ply))
  else
    cprint("^1A Fatal Error has occurred, and the player has been dropped.")
    print("5M:BNB was unable to obtain a Unique ID for "..GetPlayerName(ply))
    print("The player is not using any valid methods of identification.")
    DropPlayer(ply, "Steam, Social Club, RedM, or a Discord License is required on this server for stats tracking.")
  end
  return exports['bb']:UniqueId(ply)
end


--- CreateSession()
-- Retrieves the player's last played character, OR sends them to creation
-- @param ply The Player's Server ID
function CreateSession(ply)
  
  -- Retrieve all their character information
  exports['ghmattimysql']:execute(
    "SELECT * FROM characters WHERE id = @uid",
    {['uid'] = exports['bb']:UniqueId(ply)},
    function(plyr)

      -- If character exists, load it.
      if plyr[1] then
        local pName = GetPlayerName(ply).."'s"
        cprint("Reloading "..pName.." last known character information.")
        --[[exports['bb_chat']:DiscordMessage(
          65280, GetPlayerName(ply).." has joined the game!", "", ""
        )]]
        TriggerClientEvent('bb:create_reload', ply, plyr[1])
      
      -- Otherwise, create it.
      else
        Citizen.Wait(1000)
        cprint("Sending "..GetPlayerName(ply).." to Character Creator.")
        Citizen.CreateThread(function()
          --exports['bb_chat']:DiscordMessage(
          --  7864575, "New Player",
          --  "**Please welcome our newest player, "..GetPlayerName(ply).."!**", ""
          --)
        end)
        TriggerClientEvent('bb:create_character', ply)
      end
    end
  )
  
end


--- EVENT 'bb:create_player'
-- Received by a client when they're spawned and ready to click play
AddEventHandler('bb:create_player', function()

  local ply     = source
  local ids     = GetPlayerInformation(ply)
  local ustring = GetPlayerName(ply).." ("..ply..")"
  
  if doJoin then
    cprint("^2"..ustring.." connected.^7")
  end
  
  if ids then
    if dMsg then
      cprint("Steam ID or FiveM License exists. Retrieving Unique ID.")
    end
  
    -- SQL: Retrieve character information
    exports['ghmattimysql']:scalar(
      "SELECT id FROM players "..
      "WHERE steam_id = @steam OR redm_id = @red OR club_id = @soc "..
      "OR discord_id = @disc LIMIT 1",
      {['steam'] = ids['stm'], ['red'] = ids['red'], ['soc'] = ids['soc'], ['disc'] = ids['discd']},
      function(uid)
        if uid then 
          cprint("Found Unique ID "..uid.." for "..ustring)
          exports['bb']:UniqueId(ply, uid)
        else
          print("DEBUG - UID Nonexistant")
          local uid = CreateUniqueId(ply)
          if uid < 1 then 
            cprint("^1A Fatal Error has Occurred.")
            cprint("No player ID given to CreateUniqueId() in sv_create.lua")
          else
            cprint(
              "Successfully created UID ("..tostring(uid)..
              ") for player "..GetPlayerName(ply)
            )
          end
        end
        Citizen.Wait(200) 
        cprint(ustring.." is loaded in, and ready to play!")
        TriggerClientEvent('bb:create_ready', ply)
        CreateSession(ply)
      end
    )
    
  else
    cprint("^1"..ustring.." disconnected. ^7(No ID Validation Obtained)")
    DropPlayer(ply,
      "Your FiveM License was invalid, and you are not using Steam. "..
      "Please relaunch FiveM, or log into Steam to play on this server."
    )
  end
end)
