@tool
extends EditorScript

func _run():
	# find folders in the sprites folder
	# for each folder
	# make a new animated resource
	# get contents and for each png, make a frame in the sprite system
	var sprite_folders = ResourceLoader.list_directory("res://sprites")
	print(sprite_folders)
	var newPck = PCKPacker.new()
	newPck.pck_start("sprite_frames.pck")
	
	for entry in sprite_folders:
		# check if it's directory or not
		var dir_check = DirAccess.open("res://")
		if dir_check.dir_exists("res://sprites/"+entry):
			print("yes",entry)
			# go forward with sprite creation
			var sprite_frames = SpriteFrames.new()
			var images = ResourceLoader.list_directory("res://sprites/"+entry)
			for im in images:
				var texture =load("res://sprites/"+entry+im)
				sprite_frames.add_frame("default",texture)
				newPck.add_file("res://sprites/"+entry+im,"res://sprites/"+entry+im)
			ResourceSaver.save(sprite_frames,"res://"+entry.replace("/","") + "_sprites.tres")
			newPck.add_file("res://"+entry.replace("/","") + "_sprites.tres","res://"+entry.replace("/","") + "_sprites.tres")
	newPck.flush(true)
	# save the resource our as a tres
	# make a .pck file now
	
	pass
