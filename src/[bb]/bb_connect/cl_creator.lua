
-- Badges & Bandits: Character Creator Script (CLIENT)
RegisterNetEvent('bb:character_approval')
local myHash = nil

--- LOCAL CharacterApproved()
-- RX'd when the server approves of the character client created
-- Localized to ensure no other scripts can call this
local function CharacterApproved(charInfo)

  -- DEBUG - This is only temporary, to get people into the game
  print("DEBUG - Character Approved! Spawning."); Wait(200)
  if not charInfo then charInfo = {model = 'mp_male'} end
  exports.spawnmanager:spawnPlayer({
    x     = -262.85,
    y     = 793.41,
    z     = 118.09,
    model = charInfo.model
  }, function()
    exports.bb:ReportPosition(true)
    --SetPedDefaultComponentVariation(PlayerPedId())
    --TriggerEvent('bb:client_loaded', true)
    TriggerServerEvent('bb:client_loaded', true)
  end)

end

AddEventHandler('bb:character_approval', function(passed, reason)
  if not passed then
    print("DEBUG - Server denied our request to create a character."); Wait(200)
    TriggerEvent('chat:addMessage', {multiline = true, args = {
      "^1REJECTED", "Character Creation was not approved.\n"..
      "Reason: "..reason
    }})

  else
    print("DEBUG - Server accepted our character!."); Wait(200)
    TriggerEvent('chat:addMessage', {multiline = true, args = {
      "^2APPROVED", "Your character, as designed, has been approved!"
    }})
    -- If passed, `reason` will be the same table of char info we sent
    CharacterApproved(reason)

  end
end)

--- SubmitCharacter()
-- Sends the info the client chose to the server for approval
-- @param cInfo A table with all of the creation details
function SubmitCharacter(cInfo)
  print("DEBUG - Submitting Character to Server!"); Wait(200)
  if not cInfo then cInfo = {model = 'mp_male'} end
  print("DEBUG - Created cInfo"); Wait(200)
  TriggerServerEvent('bb:request_creation', cInfo)

end

--- CreateCharacter()
-- Loads the character creator
function CreateCharacter(charHash)

  -- DEBUG - Future Note: This will launch the character creator.
  -- For now, we're just going to jump straight to SubmitCharacter()
  print("DEBUG - Creating Character!"); Wait(200)
  SubmitCharacter( {hash  = charHash, model = 'mp_male'} )

end

--- ReloadCharacter()
-- Reloads the last played character with argument charInfo
-- @param charInfo Table with character information
-- @table model, clothes, weapons, gold, cash
function ReloadCharacter(charInfo)
  -- DEBUG - This is only temporary, to get people into the game
  print("DEBUG - Reloading existing character.")
  exports.spawnmanager:spawnPlayer({
    x     = charInfo['x'],
    y     = charInfo['y'],
    z     = charInfo['z'],
    model = charInfo['model']
  }, function()
    print("DEBUG - Player spawned with their last played character!")
    exports.bb:ReportPosition(true)
    SetEntityHeading(PlayerPedId(), charInfo['heading'])
    --TriggerEvent('bb:client_loaded')
    TriggerServerEvent('bb:client_loaded', false)
  end)
end