extends Area3D

var prevInputScale=0
var moderation = .05
var imageScale: float
var imageId: int
var spritepriority =0
var selected := false
# load all the different elements
var pulse = preload("res://pulse_icon.tres")

@onready var animSprit = $AnimatedSprite3D
	
var triggered = false
var sprites_list=["center","man","woman","spikes","roundcact","pink","agave","ocotillo"]
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
var loading=false
func turnOnAnimation():
	
	if triggered ==false:
		if imageId == 8:
			return
		# switch to loading with thread to keep main going
		var result = ResourceLoader.load_threaded_request("res://"+sprites_list[imageId]+"_sprites.tres")
		print("thread loading res",result)
		if result ==OK:
			loading=true
	triggered=true
	
func turnOffAnimation():
	if triggered ==true:
		if imageId == 8:
			return
		# switch back to the pulse icon
		animSprit.sprite_frames = pulse
		animSprit.render_priority = 4
		
		animSprit.play()
		# reset the loading variables	
		loading=false
		loadComplete = false
		
	triggered=false

func modulate_color():
	animSprit.modulate = Color(1.0, 0.75, 0.75, 0.902)

func unmodulate_color():
	animSprit.modulate = Color(1,1,1,1)
var timeout =.1
var loadComplete = false
func _process(delta: float) -> void:
	if triggered and loading:
		var progress =[0]
		ResourceLoader.load_threaded_get_status("res://"+sprites_list[imageId]+"_sprites.tres",progress)
		print("loading progress,",progress[0])
		if progress[0] ==1:
			loading = false
			
	if triggered and not loading and not loadComplete:
		var frames = ResourceLoader.load_threaded_get("res://"+sprites_list[imageId]+"_sprites.tres")
		animSprit.sprite_frames = frames
		animSprit.scale = Vector3(imageScale,imageScale,imageScale)
		animSprit.render_priority = spritepriority
		animSprit.play()
		loadComplete = true	
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
	
