fx_version 'cerulean'
game 'gta5'

author 'Henny/TuanAnh'
description 'Henny FiveM LootCase Script for ESX'
version '1.0.0'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'web/index.html'

files {
	'web/index.html',
	'web/style.css',
	'web/script.js',
	'web/sounds/*.ogg'
}

dependencies {
	'es_extended',
	'ox_inventory',
	'ox_lib'
}