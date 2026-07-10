@tool
extends EditorScript

func _run():
	# find folders in the sprites folder
	# for each folder
	# make a new animated resource
	# get contents and for each png, make a frame in the sprite system
	var sprite_folders = ResourceLoader.list_directory("res://sprites")
	print(sprite_folders)
	for entry in sprite_folders:
		# check if it's directory or not
		var dir_check = DirAccess.open("res://")
		#DirAccess.remove_absolute("res://"+entry.replace("/","") + "_sprites.tres")
		if dir_check.dir_exists("res://sprites/"+entry):
			print("yes",entry)
			# go forward with sprite creation
			var sprite_frames = SpriteFrames.new()
			var images = ResourceLoader.list_directory("res://sprites/"+entry)
			
			for im in images.slice(0,200):
				var texture =load("res://sprites/"+entry+im)
				sprite_frames.add_frame("default",texture)
			# remove the previous tres
			
			ResourceSaver.save(sprite_frames,"res://"+entry.replace("/","") + "_sprites.tres")
	# save the resource our as a tres
	pass
