extends Node3D

@onready var mark: MeshInstance3D = $mark
signal vertexhovered
var included_in_tri = false
var hovered = false
var uv = Vector2()
var unprojectedPosition = Vector2()
# this array is used when we want to put 
var interpolatingNeighbors
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
