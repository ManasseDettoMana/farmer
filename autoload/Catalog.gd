extends Node
## Static definitions for everything buyable. Autoloaded as `Catalog`.
##
## Each structure entry:
##   name    : display name
##   cost    : point cost to buy
##   income  : points/second once placed
##   color   : placeholder tint (used when `sprite` is empty)
##   label   : short text on the placeholder card
##   sprite  : "" for a drawn placeholder, or "tree" for a real pine sprite
##   spawns  : "", "villager", or "animal" — an NPC created on placement

const STRUCTURES := {
	"field": {
		"name": "Crop Field", "cost": 10, "income": 1.0,
		"color": Color("e0b84a"), "label": "FIELD", "sprite": "", "spawns": "",
	},
	"well": {
		"name": "Well", "cost": 25, "income": 0.0,
		"color": Color("6aa0c8"), "label": "WELL", "sprite": "", "spawns": "",
	},
	"tree": {
		"name": "Pine Tree", "cost": 15, "income": 0.0,
		"color": Color("3a8a3a"), "label": "TREE", "sprite": "tree", "spawns": "",
	},
	"stable": {
		"name": "Stable", "cost": 80, "income": 3.0,
		"color": Color("9c6b3f"), "label": "STABLE", "sprite": "", "spawns": "animal",
	},
	"mill": {
		"name": "Mill", "cost": 150, "income": 6.0,
		"color": Color("9a9a9a"), "label": "MILL", "sprite": "", "spawns": "",
	},
	"house": {
		"name": "House", "cost": 120, "income": 2.0,
		"color": Color("caa472"), "label": "HOUSE", "sprite": "", "spawns": "villager",
	},
	"river": {
		"name": "River", "cost": 60, "income": 0.0,
		"color": Color("4f8fd0"), "label": "RIVER", "sprite": "", "spawns": "",
	},
}

## Ordered list of structure ids as they should appear in the market.
const MARKET_ORDER := ["field", "well", "tree", "river", "stable", "house", "mill"]

const LAND_BLOCK_SIZE: int = 4          # buying land adds a 4x4 chunk
const LAND_BASE_COST: int = 200         # cost of the next block = base * 2^(blocks_owned-1)

func get_structure(id: String) -> Dictionary:
	return STRUCTURES.get(id, {})

func land_block_cost(blocks_owned: int) -> int:
	return int(LAND_BASE_COST * pow(2, max(0, blocks_owned - 1)))
