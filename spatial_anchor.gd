extends Area3D

var prevInputScale=0
var moderation = .1
var imageScale: float
var imageId: int
var selected := false
# load all the different elements
var agave_frames = preload("res://agave_sprite.tres")
var pink_cactus_frames = preload("res://pink_cactus_sprites.tres")
@onready var animSprit = $AnimatedSprite3D
	

func setup_scene(spatial_entity: OpenXRFbSpatialEntity) -> void:
	var sprites_list = [agave_frames,pink_cactus_frames]
	var data: Dictionary = spatial_entity.custom_data
	imageScale = data.get("scale",1)
	imageId = data.get("imageid",0)
	
	print(agave_frames)
	animSprit.sprite_frames = sprites_list[imageId]
	animSprit.scale = Vector2(imageScale,imageScale)
	animSprit.play()
	
func adjustScale(newScale):
	var delta = (newScale.y - prevInputScale)*moderation
	prevInputScale = newScale.y
	# comes in as a vec2 and we just want to increment based on a scalar of the input 
	imageScale += delta
	animSprit.scale += Vector2(delta,delta)
	# unclear whether this is actually required
	#spatial_entity.save_to_storage(OpenXRFbSpatialEntity.STORAGE_CLOUD)


func set_selected(p_selected: bool) -> void:
	selected = p_selected
	
