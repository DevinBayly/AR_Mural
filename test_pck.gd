extends Node3D

@onready var anim = $AnimatedSprite3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var success = ProjectSettings.load_resource_pack("res://sprite_frames.pck")
	if success:
		print("yes")
		var frames = load("res://agave_sprites.tres")
		anim.sprite_frames = frames
		anim.play()
		print(frames,anim)
	else:
		print("no")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
