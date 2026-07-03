extends Node3D

@onready var mark: MeshInstance3D = $mark
signal vertexhovered
var included_in_tri = false
var hovered = false
var uv = Vector2()
var unprojectedPosition = Vector2()
# this array is used when we want to put 
var interpolatingNeighbors
var triList =[]
var corner = false
var triangles = []
# these make it possible for an vertex to update it's UV info in all the triangles it belongs to
#ab is short for array buffer, since this is the ind that position and uv info is stored for the result triangle
var abInds =[]
func updateUvs():
	var i=0
	for m in triangles:
		var mesh:ArrayMesh = m.mesh
		# iterate over the vertices in the triangle
		var mesh_array = mesh.surface_get_arrays(0)
		var vertices = mesh_array[Mesh.ARRAY_VERTEX]
		var uvs = mesh_array[Mesh.ARRAY_TEX_UV]
		# modify the particular uv with new data 
		var abInd = abInds[i]
		var previousMat = mesh.surface_get_material(0)
		uvs[abInd] = uv
		mesh_array[Mesh.ARRAY_TEX_UV] = uvs
		mesh.surface_remove(0)
		# re add the data so the uvs get baked in properly
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
		mesh.surface_set_material(0,previousMat)
		i+=1
func remove_all():
	for t in triangles:
		t.queue_free()
	triangles = []
	triList =[]
	abInds = []
	queue_free()
func remove_mesh():
	for t in triangles:
		if t:
			t.queue_free()
	triangles = []
	abInds=[]
	triList=[]
func tri_clicked():
	included_in_tri = true
	turn_on()
func tri_cleared():
	included_in_tri = false
	turn_off()
func turn_on():
	
	var mat : StandardMaterial3D = mark.get_active_material(0)
	mat.albedo_color = Color("red")
	hovered = true
func turn_off():
	var mat : StandardMaterial3D = mark.get_active_material(0)
	mat.albedo_color = Color("white")
	hovered = false
func _on_area_2d_mouse_entered() -> void:
	if not included_in_tri:
		turn_on()
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	if not included_in_tri:
		turn_off()
	pass # Replace with function body.





func _on_mark_visibility_changed() -> void:
	pass # Replace with function body.


func _on_area_3d_area_entered(area: Area3D) -> void:
	if not included_in_tri:
		print("entered ",area)
		turn_on()
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed :
		#
		#vertexclicked.emit(self)
		#
		#pass
	#pass # Replace with function body.
	#pass # Replace with function body.
	vertexhovered.emit(self)


func _on_area_3d_area_exited(area: Area3D) -> void:
	if not included_in_tri:
		print("exited ",area)
		turn_off()
	vertexhovered.emit(null)
	pass # Replace with function body.
