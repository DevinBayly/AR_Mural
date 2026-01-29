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
	animSprit.scale = Vector3(imageScale,imageScale,imageScale)
	animSprit.play()
var scaledelta=0
func adjustScale(newScale):
	if abs(newScale.y) > .1:
		scaledelta = newScale.y*moderation
	else:
		scaledelta =0
		
var timeout =.1
func _process(delta: float) -> void:	
	if timeout<0:
		# comes in as a vec2 and we just want to increment based on a scalar of the input 
		imageScale += scaledelta
		animSprit.scale += Vector3(scaledelta,scaledelta,scaledelta)
		timeout=.1
	# unclear whether this is actually required
	#spatial_entity.save_to_storage(OpenXRFbSpatialEntity.STORAGE_CLOUD)
	timeout-=delta


func set_selected(p_selected: bool) -> void:
	selected = p_selected
	
