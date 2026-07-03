extends Node3D
signal registerCorner
var vert3d = preload("res://vert_3d.tscn")

func setup_scene(spatial_entity: OpenXRFbSpatialEntity) -> void:
	# instantiate a vert3d
	var v = vert3d.instantiate()
	var data: Dictionary = spatial_entity.custom_data
	# get the custom data 
	v.uv = Vector2(data.get("uv")[0],data.get("uv")[1])
	v.triList = data.get("triList")
	v.abInds = data.get("abInds")
	v.corner = data.get("corner")
	if v.corner:
		registerCorner.emit(v)
	add_child(v)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
