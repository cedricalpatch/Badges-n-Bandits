
-- Badges & Bandits: Character Creator Script (SERVER)
RegisterServerEvent('bb:client_new_spawn')
RegisterServerEvent('bb:client_ready')

-- RX'd when a client creates a new character
AddEventHandler('bb:client_new_spawn', function(modelChoice)
  
  local client = source
  local uid = exports.bb:UniqueId(client)
  
  print("DEBUG - Player created a new character!")
  if not modelChoice then modelChoice = 'mp_male' end
  
  -- SQL: Create the character and return the new character's ID
  local cid = exports.ghmattimysql:scalarSync(
    "SELECT CreateCharacter(@pid, @mdl)",
    {['pid'] = uid, ['mdl'] = modelChoice}
  )
  
end)

-- RX'd when a client reloads a previous character
AddEventHandler('bb:client_request'. function()
  print("DEBUG - Player spawned with an old character!")
end)