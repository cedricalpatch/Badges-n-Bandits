
fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

resource_type 'gametype' { name = 'Badges & Bandits'}

client_script "client_main.lua"
server_script "server_man.lua"

ui_page "nui/ui.html"

file {
	"nui/ui.css",
	"nui/ui.js",
	"nui/ui.html"
}

server_exports {
  'UniqueId', -- The UniqueID of the Player
}

exports {
  'UniqueId', -- The UID of the server ID given//Local player if nil
}