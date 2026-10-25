extends Node

@export var def: BuildingDef

func _ready() -> void:
	$Label.text = def.label
	$Price.text = str(def.cost)
	$Icon.texture = def.icon
