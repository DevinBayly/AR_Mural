extends Area3D

var prevInputScale=0
var moderation = .05
var imageScale: float
var imageId: int
var spritepriority =0
var selected := false
# load all the different elements
var center = preload("res://center_sprites.tres")
var agave = preload("res://agave_sprites.tres")
var pink = preload("res://pink_sprites.tres")
var ocotillo = preload("res://ocotillo_sprites.tres")
var man = preload("res://man_sprites.tres")
var roundcact = preload("res://round_sprites.tres")
var woman = preload("res://woman_sprites.tres")
var spikes = preload("res://spikey_sprites.tres")
var pulse = preload("res://pulse_icon.tres")


@onready var animSprit = $AnimatedSprite3D
	
var triggered = false
var sprites_list = [center,man,woman,spikes,roundcact,pink,agave,ocotillo]
func setup_scene(spatial_entity: OpenXRFbSpatialEntity) -> void:
	
	var data: Dictionary = spatial_entity.custom_data
	
	imageScale = data.get("scale",1)
	imageId = data.get("imageid",0)
	spritepriority = data.get("priority",0)
	if imageId ==8:
		$AnimatedSprite3D.queue_free()
	else:
		$Sprite3D.queue_free()
		animSprit.sprite_frames = pulse
		animSprit.render_priority = 4
		
		animSprit.play()
	
var scaledelta=0
func adjustScale(newScale):
	if abs(newScale.y) > .1:
		scaledelta = newScale.y*moderation
	else:
		scaledelta =0
func sliderScale(newScale):
	if animSprit:
		animSprit.scale = Vector3(newScale,newScale,newScale)
		imageScale = newScale
	else:
		print("no sprite?")
func setPriority(newOrder):
	if animSprit:
		spritepriority = newOrder
		animSprit.render_priority = spritepriority
func turnOnAnimation():
	
	if triggered ==false:
		if imageId == 8:
			return
		animSprit.sprite_frames = sprites_list[imageId]
		animSprit.scale = Vector3(imageScale,imageScale,imageScale)
		animSprit.render_priority = spritepriority
		animSprit.play()
	triggered=true

var timeout =.1
func _process(delta: float) -> void:	
	if timeout<0:
		if imageId ==8:
			imageScale += scaledelta
			$Sprite3D.scale += Vector3(scaledelta,scaledelta,scaledelta)
			timeout=.1
		else:
			imageScale += scaledelta
			animSprit.scale += Vector3(scaledelta,scaledelta,scaledelta)
			timeout=.1
			
		# comes in as a vec2 and we just want to increment based on a scalar of the input 
		
	# unclear whether this is actually required
	#spatial_entity.save_to_storage(OpenXRFbSpatialEntity.STORAGE_CLOUD)
	timeout-=delta


func set_selected(p_selected: bool) -> void:
	selected = p_selected
	
