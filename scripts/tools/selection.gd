@tool
extends EditorScript

func _run() -> void:
	var selection := EditorInterface.get_selection()
	for node in selection.get_selected_nodes() :
		for x in node.find_children("Inner", "", true, false):
			selection.add_node(x.get_parent())
