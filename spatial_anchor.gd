extends Node3D
var animscene = preload("res://animated_sprite_anchor.tscn")
var vertscene = preload("res://vert_3d_anchor.tscn")
func setup_scene(spatial_entity: OpenXRFbSpatialEntity) -> void:
	# read the data and figure out which scene to instantiate
	var data = spatial_entity.custom_data
	if data.get("uv"):
		var vert = vertscene.instantiate()
		add_child(vert)
		vert.setup_scene(spatial_entity)
		
	else:
		# it's an animated element
		var anim = animscene.instantiate()
		add_child(anim)
		anim.setup_scene(spatial_entity)
	
