extends Node
class_name ItemDb

const ITEMS := {
	"swift_boots": {
		"name": "Swift Boots",
		"cost": 450,
		"mods": { "move_speed": 1.4 },
		"desc": "Move speed boost."
	},
	"agile_amulet": {
		"name": "Agile Amulet",
		"cost": 520,
		"mods": { "agility": 8 },
		"desc": "Agility boost."
	},
	"bladed_edge": {
		"name": "Bladed Edge",
		"cost": 600,
		"mods": { "attack_damage": 12 },
		"desc": "Attack damage boost."
	},
	"shadow_talisman": {
		"name": "Shadow Talisman",
		"cost": 700,
		"mods": { "attack_speed": 0.15 },
		"desc": "Faster attacks."
	},
	"healing_salve": {
		"name": "Healing Salve",
		"cost": 110,
		"mods": { },
		"active": { "type": "heal", "amount": 120 },
		"desc": "Restore health over time."
	}
}

const SHOP_ITEMS: Array[String] = [
	"swift_boots",
	"agile_amulet",
	"bladed_edge",
	"shadow_talisman",
	"healing_salve"
]

static func get_item(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id):
		return {}
	return ITEMS[item_id]

static func get_shop_items() -> Array[String]:
	return SHOP_ITEMS.duplicate() as Array[String]
