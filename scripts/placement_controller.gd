extends Node

@export var placement_ghost: Sprite2D
@export var card_deck: CardDeck

@export var cards: Array[BuildingDef]
var ghost_enabled = false

func _ready() -> void:
	card_deck.card_pulled.connect(on_pull)
	pass 

func set_ghost_enabled(enabled) -> void:
	placement_ghost.visible = enabled
	placement_ghost.position = placement_ghost.get_global_mouse_position()
	ghost_enabled = enabled

func on_pull(buildingDef: BuildingDef) -> void:
	set_ghost_enabled(true)
	
	
	card_deck.set_docked(true)
	pass
