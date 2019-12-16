
--[[
  Badges n' Bandits
  A Cops and Robbers Gamemode for RedM
  
  Contributors:
  - RhapidFyre
  
  This resource contains all the information needed for players who are 
  connecting, and how to handle their information. For example, when someone
  connects to the server and needs to retrieve their stats, this script handles
  that. Once connected, this script will pass their global details (unique ID,
  etc) to the gamemode's 'bb' script for safekeeping, until they disconnect.
]]

fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

dependency 'bb'
ui_page "nui/ui.html"
files {
  "nui/discord.jpg",
	"nui/ui.html",
	"nui/ui.js", 
	"nui/ui.css"
}


client_scripts {
  "cl_config.lua", 
  "cl_connect.lua"
}


server_scripts {
  "sv_config.lua", 
  "sv_connect.lua"
}


server_exports {
}


exports {
  'IsMainMenuOpen', -- Returns true if the MOTD/News window is open
}
