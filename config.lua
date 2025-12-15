Config = {}
Config.Webhook = {
	Enabled = true,
	URL = "YOUR WEBHOOK URL HERE",
	BotName = "Henny Logs",
	BotAvatar = "https://media.discordapp.net/attachments/1391007012434874392/1403365041121661051/Henny_LOGO_Blue.png"
}

Config.Framework = 'esx'
Config.LootboxItemName = 'loot_case'

Config.RarityChances = {
	common = 50,
	uncommon = 30,
	rare = 12,
	epic = 6,
	legendary = 2
}

Config.Rewards = {
	{ name = 'charmander', label = 'Charmander Card', amount = 1, rarity = 'common', type = 'item' },
	{ name = 'bulbasaur', label = 'Bulbasaur Card', amount = 1, rarity = 'common', type = 'item' },
	{ name = 'cubone', label = 'Cubone Card', amount = 1, rarity = 'common', type = 'item' },
	{ name = 'weed', label = 'Weed', amount = 300, rarity = 'uncommon', type = 'item' },
	{ name = 'thc_gummies', label = 'thc gummies', amount = 300, rarity = 'uncommon', type = 'item' },
	{ name = 'treasurekey', label = 'Treasure Key', amount = 1, rarity = 'uncommon', type = 'item' },
	{ name = 'WEAPON_PISTOL50', label = 'Deagle', amount = 1, rarity = 'rare', type = 'weapon' },
	{ name = 'WEAPON_MP7HK', label = 'MP7 HK', amount = 1, rarity = 'rare', type = 'weapon' },
	{ name = 'heroin', label = 'Heroin', amount = 350, rarity = 'epic', type = 'item' },
	{ name = 'gun_case', label = 'Loot Case', amount = 1, rarity = 'epic', type = 'item' },
	{ name = 'WEAPON_SCARH', label = 'Scarh', amount = 1, rarity = 'legendary', type = 'weapon' },
	{ name = 'WEAPON_FAMAS', label = 'Famas', amount = 1, rarity = 'legendary', type = 'weapon' }
}