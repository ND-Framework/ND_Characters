-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666"
description "ND Character Selection (legacy)"
version "2.0.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

dependency "ND_Core"

shared_scripts {
    "@ox_lib/init.lua",
    "@ND_Core/init.lua",
    "config.lua"
}
server_script "source/server.lua"
client_script "source/client.lua"

files {
	"ui/index.html",
	"ui/script.js",
	"ui/style.css"
}
ui_page "ui/index.html"
