@tool
extends EditorScript

func _run():
	print("hello world")
	var spritef = SpriteFrames.new()
	#get the 
	print(spritef)
	var spriteImages = ResourceLoader.list_directory("res://sprites")
	var i =0
	for im in spriteImages:
		
		if "transparent" in im:
			print(im)
			var texture = load("res://sprites/"+im)
			print(texture)
			spritef.add_frame("default",texture,1.0,i)
			i+=1
	ResourceSaver.save(spritef,"res://pulse_icon.tres")
