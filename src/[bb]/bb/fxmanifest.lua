
--[[
  Badges n' Bandits
  A Cops and Robbers Gamemode for RedM
  
  Contributors:
  - RhapidFyre
  
  This is the master resource for the BB gamemode for RedM. This file will hold
  all of the information for running the gamemode that should be accessible
  from other scripts. Such as the player's stats, last known location, etc
]]

fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

resource_type 'gametype' { name = 'Badges & Bandits'}

client_script "client_main.lua"
server_script "server_main.lua"

ui_page "nui/ui.html"

file {
	"nui/ui.css",
	"nui/ui.js",
	"nui/ui.html"
}

server_exports {
  'UniqueId',    -- The UniqueID of the Player
  'PrettyPrint', -- A nicely formatted print message
  'AssignInfo',  -- Assigns character values rx'd from SQL
}

exports {
  'UniqueId', -- The UID of the server ID given//Local player if nil
}