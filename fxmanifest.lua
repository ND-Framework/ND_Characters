-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy7666"
description "ND Character Selection (legacy)"
version "2.1.5"

fx_version "cerulean"
game "gta5"
lua54 "yes"

dependencies {
    "ND_Core",
    "ox_lib"
}

files {
    "ui/index.html",
    "ui/script.js",
    "ui/style.css",
    "data/configuration.lua",
    "data/spawns.lua",
    "images/**"
}
ui_page "ui/index.html"

shared_scripts {
    "@ox_lib/init.lua",
    "@ND_Core/init.lua"
}
server_script "source/server.lua"
client_script "source/client.lua"
