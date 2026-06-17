@tool
extends EditorScript

func _run():
	#print("hello")
	# find content
	var path = "../sprites"
	var dir = DirAccess.open(path)
	var dirs = dir.get_directories()
	var sprites = []
	for _lv1 in dirs.slice(0,1):
		# get the files per dir
		var subdir: DirAccess = DirAccess.open(path+"/"+_lv1)
		var spritef = SpriteFrames.new()
		var imagePaths = subdir.get_files()
		var i =0
		print("number of images",imagePaths.size())
		var packer = PCKPacker.new()
		packer.pck_start("test.pck")
		
		for _lv2 in imagePaths:
			#var im = Image.load_from_file(path+"/" + _lv1 + "/" +_lv2)
			#var texture = ImageTexture.create_from_image(im)
			##print(texture)
			#spritef.add_frame("default",path+"/" + _lv1 + "/" +_lv2,1.0,i)
			#i+=1
			packer.add_file("res://pngs/"+_lv2,path+"/" + _lv1 + "/" +_lv2)
		var result = packer.flush(true)
		print("done",result )
		ResourceSaver.save(spritef,_lv1+"_auto.res")
		
	# save it to a pack file
