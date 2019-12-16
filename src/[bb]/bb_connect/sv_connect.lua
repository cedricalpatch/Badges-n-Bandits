
-- Badges & Bandits: Connection Script (SERVER)
RegisterServerEvent('bb:create_player')

local pprint = function(msg) exports['bb']:PrettyPrint(msg) end

--- GetPlayerInformation()
-- Retrieves all of the IDs we need and returns them as a table
-- @param client The player's Server ID
-- @return A table of identifiers stm soc red discd
function GetPlayerInformation(client)

  local clientInfo = GetPlayerIdentifiers(client)
  local infoTable = {
    ['stm'] = "", ['soc'] = "", ['red'] = "", ['discd'] = "",
    ['ip'] = GetPlayerEndpoint(client)
  }

  for _,id in pairs (clientInfo) do 
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

  local filtered = GetPlayerName(client)
  infoTable['user'] = string.gsub(GetPlayerName(client), "[%W]", "")
  print("DEBUG - User Values:\n"..json.encode(infoTable))
  return infoTable
end

--- CreateUniqueId()
-- Creates a new entry to the 'players' table of the SQL Database, and then 
-- assigns the Unique ID to the 'unique' table variable.
-- @param client The Player's Server ID.
-- @return nil if invalid, 0 if not found.
function CreateUniqueId(client)

  if not client then return 0 end

  -- Filter username for special characters

  -- SQL: Insert new user account for new player
  -- If steamid and fiveid are nil, the procedure will return 0
  local ids = GetPlayerInformation(client)
  local uid = exports.ghmattimysql:scalarSync(
    "SELECT PlayerJoining (@stm, @soc, @redm, @disc, @ip, @user)",
    {
      ['stm'] = ids['stm'], ['soc'] = ids['soc'], ['redm'] = ids['red'],
      ['disc'] = ids['discd'], ['ip'] = ids['ip'], ['user'] = ids['user']
    }
  )
  if uid > 0 then 
    exports['bb']:UniqueId(client, tonumber(uid)) -- Set UID for session
    pprint("Unique ID ("..(uid)..") created for  "..GetPlayerName(client))
  else
    pprint("^1A Fatal Error has occurred, and the player has been dropped.")
    print("5M:BNB was unable to obtain a Unique ID for "..GetPlayerName(client))
    print("The player is not using any valid methods of identification.")
    DropPlayer(client, "Steam, Social Club, RedM, or a Discord License is required on this server for stats tracking.")
  end
  return uid
end

--- CreateSession()
-- Retrieves the player's last played character, OR sends them to creation
-- @param client The Player's Server ID
function CreateSession(client)

  -- Retrieve all their character information
  exports['ghmattimysql']:execute(
    "SELECT * FROM characters WHERE id = @uid",
    {['uid'] = exports['bb']:UniqueId(client)},
    function(charInfo)

      -- If character exists, load it.
      if charInfo[1] then
        local pName = GetPlayerName(client).."'s"
        pprint("Reloading "..pName.." last known character.")
        --[[ exports['bb_chat']:DiscordMessage(
          65280, GetPlayerName(client).." has joined the game!", "", ""
        ) ]]

      else
        Citizen.Wait(1000)
        pprint("No characters found for "..GetPlayerName(client)..".")
        Citizen.CreateThread(function()
          --[[ exports['bb_chat']:DiscordMessage(
            7864575, "New Player",
            "**Please welcome our newest player, "..GetPlayerName(client).."!**", ""
          ) ]]
        end)
      end
      TriggerClientEvent('bb:connect_ack', client, charInfo[1])
    end
  )

end

--- EVENT 'bb:create_player'
-- Received by a client when they're spawned and ready to click play
AddEventHandler('bb:create_player', function()

  local client     = source
  local ids     = GetPlayerInformation(client)
  local ustring = GetPlayerName(client).." ("..client..")"

  if doJoin then
    pprint("^2"..ustring.." connected.^7")
  end

  if ids then
    if dMsg then
      pprint("Steam ID or FiveM License exists. Retrieving Unique ID.")
    end

    -- SQL: Retrieve character information
    exports['ghmattimysql']:scalar(
      "SELECT id FROM players "..
      "WHERE steam_id = @steam OR redm_id = @red OR club_id = @soc "..
      "OR discord_id = @disc LIMIT 1",
      {['steam'] = ids['stm'], ['red'] = ids['red'], ['soc'] = ids['soc'], ['disc'] = ids['discd']},
      function(uid)
        if uid then 
          pprint("Found Unique ID "..uid.." for "..ustring)
          exports['bb']:UniqueId(client, uid)
        else
          print("DEBUG - UID Nonexistant")
          local uid = CreateUniqueId(client)
          if uid < 1 then 
            pprint("^1A Fatal Error has Occurred.")
            pprint("No player ID given to CreateUniqueId() in sv_create.lua")
          else
            pprint(
              "Successfully created UID ("..tostring(uid)..
              ") for player "..GetPlayerName(client)
            )
          end
        end
        Citizen.Wait(200) 
        pprint(ustring.." is loaded in, and ready to play!")
        TriggerClientEvent('bb:create_ready', client)
        CreateSession(client)
      end
    )

  else
    pprint("^1"..ustring.." disconnected. ^7(No ID Validation Obtained)")
    DropPlayer(client,
      "Your FiveM License was invalid, and you are not using Steam. "..
      "Please relaunch FiveM, or log into Steam to play on this server."
    )
  end
end)
