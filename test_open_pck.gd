extends Node

func _ready() -> void:
	var success  = ProjectSettings.load_resource_pack("res://test.pck")
	if success:
		print("yes")
		var files = Image.load_from_file("pngs/1_agave_0165.png")
		print(files)
