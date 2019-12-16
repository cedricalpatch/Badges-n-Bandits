
-- Badges & Bandits: Character Creator Script (CLIENT)

--- CreateCharacter()
-- Loads the character creator
function CreateCharacter()
  -- DEBUG - This is only temporary, to get people into the game
  exports.spawnmanager:spawnPlayer({
    x = -262.85,
    y = 793.41,
    z = 118.09,
    model = 'mp_male'
  }, function()
    print("DEBUG - Player spawned as a new character!")
    --exports['bb']:ReportPosition(true)
    --SetPedDefaultComponentVariation(PlayerPedId())
    --TriggerEvent('bb:client_new_spawn')
    --TriggerServerEvent('bb:client_new_spawn')
  end)
end

--- ReloadCharacter()
-- Reloads the last played character with argument charInfo
-- @param charInfo Table with character information
-- @table model, clothes, weapons, gold, cash
function ReloadCharacter(charInfo)
  -- DEBUG - This is only temporary, to get people into the game
  exports.spawnmanager:spawnPlayer({
    x = -262.85,
    y = 793.41,
    z = 118.09,
    model = 'mp_male'
  }, function()
    print("DEBUG - Player spawned with their last played character!")
    --exports['bb']:ReportPosition(true)
    --TriggerEvent('bb:client_new_spawn')
    --TriggerServerEvent('bb:client_new_spawn')
  end)
end