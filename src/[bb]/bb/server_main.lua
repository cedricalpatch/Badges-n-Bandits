
RegisterServerEvent('bb:client_ready')
RegisterServerEvent('bb:save_pos')
RegisterServerEvent('bb:unload')

local useDiscord = false  -- Toggles discord messages created by this script
local positions  = {}     -- Holds last known position ( [ID] => vector3() )
local clInfo     = {}     -- Client Info ( see AssignInfo() )

--- EXPORT: PrettyPrint()
-- Prints a nice formatted message to the console
-- @param msg The message to print
-- @param timestamp Boolean; If true, affixes timestamp
function PrettyPrint(msg, timestamp)
  local prefix = "^3[B&B]^7 "
  if timestamp then
    local dt = os.date("%m/%d/%Y %H:%M.%S", os.time())
    prefix = "^3[B&B "..dt.."]^7 "
  end
  -- We need the final '^7' to ensure this doesn't paint the console
  -- after it has finished running.
  print(prefix..msg.."^7")
end

--[[ --------------------------------------------------------------------------

  ~ BEGIN POSITION AQUISITION SCRIPTS

  1) Players, when loaded, will submit their position every 12 seconds
  2) The server, every 30 seconds, loops through the positions table
  3) For each entry found, it will update their last known position in SQL
  4) When the update succeeds, it will remove the position entry
  5) When a player drops, it will send and immediate update.

  *) If no position is found, it will skip the SQL Query.

]]-----------------------------------------------------------------------------

AddEventHandler('bb:save_pos', function(pos)
  local client = source
  local cid    = clInfo[client]
  if cid and pos then
    positions[cid] = pos
  end
end)

function SavePlayerPos(cid, pos)
  if cid then

    -- If pos not given, check positions table
    if not pos then pos = positions[cid] end

    -- Only update if positions table has changed (is not nil)
    if pos then
      exports.ghmattimysql:execute(
        "UPDATE characters SET x = @x, y = @y, z = @z WHERE id = @cid",
        {
          ['x']   = (math.floor(pos.x * 100))/100, -- Ensures 2 decimal places
          ['y']   = (math.floor(pos.y * 100))/100,
          ['z']   = (math.floor(pos.z * 100))/100,
          ['cid'] = cid
        },
        function()
          -- Once updated, remove entry
          print("DEBUG - Position saved for cid #"..cid)
          positions[cid] = nil
        end
      )
    end

  end
end

AddEventHandler('playerDropped', function(reason)
  local client     = source
  local cid        = clInfo[client].charid
  local clientInfo = GetPlayerName(client)
  StoreBounty(client, clInfo[client].bounty)
  if cid then SavePlayerPos(cid, positions[cid]) end
    PrettyPrint(
      "^1"..tostring(clientInfo).." disconnected. ^7("..tostring(reason)..")"
    )
  if useDiscord then
    exports['bb_chat']:DiscordMessage(
      16711680, tostring(clientInfo).." Disconnected", tostring(reason), ""
    )
  end
  RecentDisconnect(client, reason)
end)

--[[---------------------------------------------------------------------------

  ~ END OF POSITION ACQUISITION SCRIPTS

--]]---------------------------------------------------------------------------

--- EXPORT: UniqueId()
-- Retrieves the user's Unique ID, or, if given an id, will assign it
-- If a player connects with no identification methods, the 'sv_connect' script
-- will drop them, so we can safely assume 'clInfo[id].unique' exists.
-- @param client The Player's Server ID
-- @param id The player's Unique ID
-- @return Client's Unique ID. Returns 0 if no client ID was passed
function UniqueId(client, id)
  if client then

    -- If no meta, build meta. If uid exists in meta, return it
    if not clInfo[client] then clInfo[client] = {} end

    if id then
      clInfo[client].unique = id
      print("DEBUG - Assigned uid "..id.." to Player #"..client)
      return id
    end

    return clInfo[client].unique
  end
  PrettyPrint("No player ID given to UniqueId() from "..GetInvokingResource())
  return nil -- If player ID not given return nil
end

--- EXPORT GetCharacterId()
-- Retrieve's the active character ID for given Server ID
-- @param client The player's Server ID
-- @return The character ID number, or 0 if failed
function GetCharacterId(client)

  local cid = 0

  -- Retrieve CID from clInfo table
  if clInfo[client] then cid = clInfo[client].charid end

  -- If not available, check SQL
  if not cid then
    cid = exports.ghmattimysql:scalarSync(
      "SELECT id FROM characters WHERE player_id = @uid "..
      "ORDER BY lastplay DESC LIMIT 1",
      {['uid'] = UniqueId(client)}
    )
  end

  if not cid then cid = 0 end
  return cid
end

--- EXPORT SetBounty()
-- Adjusts the player's bounty
-- @param client Server ID
-- @param adj Adjusts the client's bounty; Negative lowers the bounty
-- @return The new bounty level
function SetBounty(client, adj)
  if not client then return 0 end
  if not adj    then adj = 0  end
  clInfo[client].bounty = clInfo[client].bounty + adj
  return (clInfo[client].bounty)
end

--- EXPORT GetBounty()
-- Gets the player's bounty
-- @param client Server ID
-- @return The bounty level
function GetBounty(client)
  if not client then return 0 end
  return (clInfo[client].bounty)
end

--- StoreBounty()
-- When a player disconnects, this is called to store their bounty into SQL
-- @param client The Server ID
function StoreBounty(client)
  local cid = GetCharacterId(client)
  exports.ghmattimysql:execute(
    "UPDATE characters SET bounty = @value WHERE id = @char",
    {['value'] = clInfo[client].bounty, ['char'] = cid}
  )
end

--- RetrieveBounty()
-- When a player disconnects, this is called to store their bounty into SQL
-- @param client The Server ID
function RetrieveBounty(client)
  local cid = GetCharacterId(client)
  exports.ghmattimysql:scalar(
    "SELECT bounty FROM characters WHERE id = @char",
    {['value'] = clInfo[client].bounty, ['char'] = cid},
    function(bty)
      clInfo[client].bounty = bty
      TriggerClientEvent('bb:bounty', client, bty)
    end
  )
end

--- ClearCharInfo()
-- Clears the entry in the table as to avoid bad callbacks, and memclear
-- @param client The server ID of the player info to clear
function ClearCharInfo(client)
	clInfo[client] = {}
  TriggerClientEvent('bb:playerinfo', (-1), client, nil)
end

--- RecentDisconnect()
-- Assigns the clInfo table to recentDrop[cid]
-- Allows the server to reobtain player information without redoing the query
-- when a disconnected player rejoins shortly after disconnecting
function RecentDisconnect(client, reason)
  local cid = clInfo[client].charid
  Citizen.Wait(8000)
  PrettyPrint("Preserving character disconnect information.")
  PrettyPrint("Finished preserving Character #"..tostring(cid).." for Player #"..tostring(client)..".")
  ClearCharInfo(client)
end

--- EXPORT: AssignInfo()
-- Builds a table of player info to avoid running SQL queries unnecessarily
-- @param client Server id of the player being assigned
-- @param tbl The table of info to assign
function AssignInfo(client, tbl, rejoin)
  if not tbl then tbl = {} end

	if client then
    -- If rejoining, then tbl is a copy of clInfo[client]
    if rejoin then clInfo[client] = tbl
    else
      -- tbl: 'uid', 'cid', (more to come)
      if not tbl then tbl = {} end

      -- If the table doesn't exist, create it - Otherwise, it's an update
      if not clInfo[client] then clInfo[client] = {} end

      -- Filter out magic/special characters
      clInfo[client].name = string.gsub(GetPlayerName(client), "[^a-zA-Z0-9 %p]", "")

      -- If no UID passed, find one. Otherwise, use it.
      if not tbl.uid then clInfo[client].unique = AssignUniqueId(client)
      else                clInfo[client].unique = tbl.uid
      end
      PrettyPrint("UID #"..tostring(clInfo[client].unique).." assigned to Player #"..client)

      -- DEBUG - Revisit this, CID should never be passed to this nil
      -- If no CID passed, use nil for now. Otherwise, use it.
      if not tbl.cid then clInfo[client].charid = nil
      else                clInfo[client].charid = tbl.cid
      end
      PrettyPrint("CID #"..tostring(clInfo[client].charid).." assigned to Player #"..client)

    end
    TriggerClientEvent('bb:playerinfo', (-1), client, clInfo[client])

	end
end

--- 'bb:unload'
-- Received when a player is changing characters
AddEventHandler('bb:unload', function()
  ClearCharInfo(source)
end)

--- 'bb:client_ready'
-- When a player has loaded in, restore their bounty level
AddEventHandler('bb:client_ready', function()
  RetrieveBounty(source)
end)