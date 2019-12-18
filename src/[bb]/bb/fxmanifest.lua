
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

dependency 'ghmattimysql'
client_script "client_main.lua"
server_script "server_main.lua"

ui_page "nui/ui.html"

file {
	"nui/ui.css",
	"nui/ui.js",
	"nui/ui.html"
}

server_exports {
  'UniqueId',      -- The Database ID of the Player's Account
  'PrettyPrint',   -- A nicely formatted print message
  'AssignInfo',    -- Assigns character values rx'd from SQL
  'GetBounty',     -- Gets the bounty level for Server Id (arg)
  'SetBounty',     -- Adjusts the bounty level for (server_id, adjust)
  'CharacterId',   -- Returns the Database ID number of the active character
}

exports {
  'UniqueId',      -- The Database ID of the local client
  'CharacterId',   -- The Database ID of the active character
  'GetBounty',     -- Gets the bounty level for Server Id (arg)
  'ReportPosition',
}