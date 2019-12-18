
-- Badges & Bandits: Character Creator Script (SERVER)
RegisterServerEvent('bb:client_loaded')
RegisterServerEvent('bb:request_creation')

local hashes = {}

--- ApprovalHash()
-- Creates a hash when called for the given player.
-- This hash ensures that the clients aren't sending us character creation
-- information outside of the parameters that we've allowed.
-- @return hash The player's hash
function ApprovalHash(client)
  local chars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
                "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                "U", "V", "W", "X", "Y", "Z"};
  local temp = ""
  for i=1, 16 do
    local idx = math.random(#chars); temp = temp..chars[idx]
  end
  hashes[client] = temp
  return temp
end

-- RX'd when a client creates a new character
AddEventHandler('bb:client_loaded', function(isNew)

  local client = source
  local uid_ = exports.bb:UniqueId(client)
  local cid_ = exports.bb:CharacterId(client)
  print("DEBUG - Client is ready to play.")

  -- If new character or client doesn't have a character
  if isNew or cid_ < 1 then

    print("DEBUG - Player created a new character!")
    if not modelChoice then modelChoice = 'mp_male' end

    -- SQL: Create the character and return the new character's ID
    cid_ = exports.ghmattimysql:scalarSync(
      "SELECT CharacterCreate(@pid, @mdl)",
      {['pid'] = uid_, ['mdl'] = modelChoice}
    )

    -- DEBUG - Send a discord welcome message..?

  else
    print("DEBUG - Player is reloading an existing character.")

  end

  exports.bb:AssignInfo(client, {uid = uid_, cid = cid_})

  -- Tells the client and the server scripts that the player
  -- is loaded and ready to execute relevant scripts
  TriggerEvent('bb:player_ready', client, uid_, cid_, isNew)
  TriggerClientEvent('bb:player_ready', client, uid_, cid_, isNew)


end)

-- Server attempts to validate the challenge to allow the character
AddEventHandler('bb:request_creation', function(charInfo)
  local client = source
  print("DEBUG - Received request from player #"..client.." to create a character.")
  if charInfo.hash then
    if charInfo.hash == hashes[client] then
      print("DEBUG - Hash challenge success!")
      ApprovalHash(client) -- Generate a new one
      TriggerClientEvent('bb:character_approval', client, true, charInfo)

    else
      TriggerClientEvent('bb:character_approval', client, false,
        "Server rejected the character creation challenge."
      )

    end
  else
    TriggerClientEvent('bb:character_approval', client, false,
      "No challenge presented to the server for creation authorization."
    )

  end
end)