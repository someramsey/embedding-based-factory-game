extends Node2D

func _process(_d):
	RenderingServer.global_shader_parameter_set("mouse_world_position", get_global_mouse_position())
