extends StartXR

const ENVIRONMENT_DEPTH_MATERIAL = preload("res://environment_depth_material.tres")
const BLUE_MATERIAL = preload("res://blue_material.tres")

var passthrough_enabled: bool = false
var scene_and_spatial_anchors_displayed: bool = true
var selected_spatial_anchor_node: Node3D = null
var global_environment_depth_enabled: bool = true
var vert3d = preload("res://vert_3d.tscn")
# regular camera to help with getting 2d locations of elements
@onready var cam = $Camera3D
@onready var testicon = preload("res://assets/mural_background.png")


@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var right_hand: XRController3D = $XROrigin3D/RightHand
@onready var right_hand_pointer: XRController3D = $XROrigin3D/RightHandPointer
@onready var right_hand_pointer_raycast: RayCast3D = $XROrigin3D/RightHandPointer/RayCast3D
@onready var scene_pointer_mesh: MeshInstance3D = $XROrigin3D/RightHandPointer/ScenePointerMesh
@onready var scene_colliding_mesh: MeshInstance3D = $XROrigin3D/RightHandPointer/SceneCollidingMesh
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var scene_manager: OpenXRFbSceneManager = $XROrigin3D/OpenXRFbSceneManager
@onready var spatial_anchor_manager: OpenXRFbSpatialAnchorManager = $XROrigin3D/OpenXRFbSpatialAnchorManager
# Don't statically type this as `OpenXRMetaEnvironmentDepth` because it doesn't exist on Godot 4.4.
@onready var environment_depth_node = $XROrigin3D/XRCamera3D/OpenXRMetaEnvironmentDepth
@onready var depth_testing_mesh: MeshInstance3D = $XROrigin3D/RightHand/DepthTestingMesh

const SPATIAL_ANCHORS_FILE = "user://openxr_fb_spatial_anchors.json"

#const SPATIAL_ANCHORS_FILE = "res://openxr_fb_spatial_anchors.json"

var _setup := false

const COLORS = [
	"#FF0000",  # Red
	"#00FF00",  # Green
	"#0000FF",  # Blue
	"#FFFF00",  # Yellow
	"#00FFFF",  # Cyan
	"#FF00FF",  # Magenta
	"#FF8000",  # Orange
	"#800080",  # Purple
]


func _ready():
	super._ready()
	if xr_interface and xr_interface.is_initialized():
		xr_interface.session_begun.connect(_on_openxr_session_begun)

	for render_model in [%LeftControllerFbRenderModel, %RightControllerFbRenderModel]:
		render_model.openxr_fb_render_model_loaded.connect(_on_openxr_fb_render_model_loaded.bind(render_model))


func _on_openxr_session_begun() -> void:
	if _setup:
		return
	_setup = true

	load_spatial_anchors_from_file()
	enable_passthrough(true)

	var environment_depth = Engine.get_singleton("OpenXRMetaEnvironmentDepthExtensionWrapper")
	if environment_depth:
		print("Supports environment depth: ", environment_depth.is_environment_depth_supported())
		print("Supports hand removal: ", environment_depth.is_hand_removal_supported())
		if environment_depth.is_environment_depth_supported():
			environment_depth.start_environment_depth()
			print("Environment depth started: ", environment_depth.is_environment_depth_started())


func load_spatial_anchors_from_file() -> void:
	var file := FileAccess.open(SPATIAL_ANCHORS_FILE, FileAccess.READ)
	if not file:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("ERROR: Unable to parse ", SPATIAL_ANCHORS_FILE)
		return

	if not json.data is Dictionary:
		print("ERROR: ", SPATIAL_ANCHORS_FILE, " contains invalid data")
		return

	var anchor_data: Dictionary = json.data
	if anchor_data.size() > 0:
		spatial_anchor_manager.load_anchors(anchor_data.keys(), anchor_data, OpenXRFbSpatialEntity.STORAGE_LOCAL, true)
		#var lim = 8
		#for anchor_key in anchor_data:
			#var data =anchor_data[anchor_key]
			#spatial_anchor_manager.load_anchor(anchor_key,data,OpenXRFbSpatialEntity.STORAGE_LOCAL)
			#lim-=1
			#if lim <0:
				#break

func save_spatial_anchors_to_file() -> void:
	var file := FileAccess.open(SPATIAL_ANCHORS_FILE, FileAccess.WRITE)
	if not file:
		print("ERROR: Unable to open file for writing: ", SPATIAL_ANCHORS_FILE)
		return

	var anchor_data := {}
	for uuid in spatial_anchor_manager.get_anchor_uuids():
		var entity: OpenXRFbSpatialEntity = spatial_anchor_manager.get_spatial_entity(uuid)
		anchor_data[uuid] = entity.custom_data

	file.store_string(JSON.stringify(anchor_data))
	file.close()


func _on_spatial_anchor_tracked(_anchor_node: XRAnchor3D, _spatial_entity: OpenXRFbSpatialEntity, is_new: bool) -> void:
	if is_new:
		save_spatial_anchors_to_file()


func _on_spatial_anchor_untracked(_anchor_node: XRAnchor3D, _spatial_entity: OpenXRFbSpatialEntity) -> void:
	save_spatial_anchors_to_file()


func _on_openxr_fb_render_model_loaded(render_model: OpenXRFbRenderModel) -> void:
	for mesh_instance in render_model.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh_instance.mesh.get_surface_count()):
			var material: Material = mesh_instance.mesh.surface_get_material(i)
			# Make sure these render before the depth buffer is filled with environment depth info.
			material.render_priority = -100


func enable_passthrough(enable: bool) -> void:
	if passthrough_enabled == enable:
		return

	var supported_blend_modes = xr_interface.get_supported_environment_blend_modes()
	if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in supported_blend_modes and XRInterface.XR_ENV_BLEND_MODE_OPAQUE in supported_blend_modes:
		if enable:
			# Switch to passthrough.
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
			get_viewport().transparent_bg = true
			world_environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
		else:
			# Switch back to VR.
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
			get_viewport().transparent_bg = false
			world_environment.environment.background_color = Color(0.3, 0.3, 0.3, 1.0)
		passthrough_enabled = enable


func display_scene_and_spatial_anchors(value: bool) -> void:
	if scene_and_spatial_anchors_displayed == value:
		return

	scene_manager.visible = value
	spatial_anchor_manager.visible = value
	right_hand_pointer.visible = value
	right_hand_pointer_raycast.enabled = value

	scene_and_spatial_anchors_displayed = value

var col_pos
var col
var last_selected_node

func _physics_process(_delta: float) -> void:
	if not on_menu:
		
		right_hand_pointer.visible = true
		var previous_selected_spatial_anchor_node = selected_spatial_anchor_node

		if right_hand_pointer_raycast.is_colliding():
			var collision_point: Vector3 = right_hand_pointer_raycast.get_collision_point()
			scene_colliding_mesh.global_position = collision_point
			col_pos = collision_point

			var pointer_length: float = (collision_point - right_hand_pointer.global_position).length()
			scene_pointer_mesh.mesh.size.z = pointer_length
			scene_pointer_mesh.position.z = -pointer_length / 2.0

			var collider: CollisionObject3D = right_hand_pointer_raycast.get_collider()
			col = collider
			# check if the collider is part of the vert3d 
			if col:
				var col_group = col.get_parent().get_groups()
				if col_group.size()> 0 and col_group[0] =="verts":
					#print("highlighting sphere")
					# use the method on the parent to highlight the element
					hovered_element = col.get_parent()
			if collider and collider.get_collision_layer_value(3):
				selected_spatial_anchor_node = collider
				selected_spatial_anchor_node.turnOnAnimation()
				
			else:
				selected_spatial_anchor_node = null
		else:
			scene_pointer_mesh.mesh.size.z = 5
			scene_pointer_mesh.position.z = -2.5
			selected_spatial_anchor_node = null

		if previous_selected_spatial_anchor_node != selected_spatial_anchor_node:
			if previous_selected_spatial_anchor_node:
				previous_selected_spatial_anchor_node.set_selected(false)
			if selected_spatial_anchor_node:
				selected_spatial_anchor_node.set_selected(true)
				scene_colliding_mesh.visible = false
			else:
				scene_colliding_mesh.visible = true
	else:
		# make the point not visible for a moment
		#print("hiding pionter on menu")
		right_hand_pointer.visible = false
		
## this part of the code is responsible for positioning the ortho camera in the right spot to give consistent screen coords for the points which we can use for uv calculations 
func custom_sort(a,b):
	if a[1]>b[1]:
		return a
func position_cam() -> void:
	# get the min and max of all the verts
	var verts = get_tree().get_nodes_in_group("verts")
	
		
	# calculate the center, move the camera to this spot
	var centroid = Vector3(0,0,0)
	# get the corners by finding the 4 verts that are furthest from the center
	var distances = []
	
	for v in verts:
		centroid +=v.position
	centroid/=verts.size()
	for v in verts:
		var dif = v.position - centroid
		distances.push_back([v,dif.length()])
	distances.sort_custom(custom_sort)
	# get 3 of the verts and get 2 vectors (center, get vectors going out to each frmo center) 
	var corners = []
	for c in distances.slice(0,4):
		corners.push_back(c[0])
	
	# go through the corner options and figure out which combo gives biggest
	var c1
	var c2
	var max = 0
	for v in corners:
		for vo in corners:
			if v == vo:
				continue
			if (v.position - vo.position).length() > max:
				c1 = v
				c2 = vo
				max = (v.position - vo.position).length()
	var center = (c2.position - c1.position)/2 + c1.position
	var v1 = corners[0].position - center
	# pick another but double check that it's not 
	var v2
	for oc in corners.slice(1):
		v2 =  oc.position - center
		# check for parallel
		var check= abs(v2.dot(v1) - (v1.length()*v2.length()) )
		print(check)
		if check <1:
			continue
		else:
			break
		
	
	
	# get normal from cross product
	var v3 = v1.cross(v2)*-1
	#v3.z*=-1
	#if v3.z<0:
		#v3.z*=-1
	#v3*=-1
	print(v1,v2,v3)
		 
	
	
	# LATER use normal to move the camera out in the direction of the player
	cam.position = center + v3
	# figure out the vector that goes in the min to max direction, use the length of this to determine the size of the camera view
	# get the furthest distance point, and set it as the size
	cam.size = distances[0][1]
	cam.look_at(center)
	
	


var prev: Node3D = null
var corners = []
var edges = []
var dist_threshold = 5
var last_intersections = []
# helps us figure out the uvs of the border points created at intersections
var last_intersections_uvs =[]
var triangle_vertices=[]
var hovered_element
var center = Vector2(0,0)
var backgroundDrawing=false
func calc_center():
	position_cam()
	# use the group to get all the verts, calculate their position in a list
	var all_verts = get_tree().get_nodes_in_group("verts")
	var total = Vector2(0,0)
	for v in all_verts:
		if v.corner:
			v.unprojectedPosition = cam.unproject_position(v.position)
			total +=v.unprojectedPosition
	center.x = total.x/4
	center.y = total.y/4
	uv_exterior()
# these are ordered in how we look at them, not any y axis flipped graphics sense, it will mean bottomLeft has a higher screen y value though
var topLeft 
var bottomLeft    
var topRight
var bottomRight
func uv_exterior():
	position_cam()
	var all_verts = get_tree().get_nodes_in_group("verts")

	for v in all_verts:
		if v.corner:
			var dif = center - v.unprojectedPosition
			print("unprojected",v.name,v.unprojectedPosition)
			if dif.x >0:
				# v left of center
				if dif.y >0:
					# v top left
					v.uv = Vector2(0,0)
					topLeft = v
				else:
					v.uv = Vector2(0,1)
					bottomLeft = v
			else:
				if dif.y > 0:
					#v top right
					v.uv = Vector2(1,0)
					topRight = v
				else:
					v.uv = Vector2(1,1)
					bottomRight= v
	# establish edges from the all_vertx list    
	# assume we are calculating for the initial bounding box 
#
# 
func uv_interior():
	position_cam()
	var all_verts = get_tree().get_nodes_in_group("verts")

	for v in all_verts:
		var newUV = Vector2(0,0)
		v.unprojectedPosition = cam.unproject_position(v.position)
		var stop = false
		if not v.corner:
			print("non corner",v.unprojectedPosition)
			# this variable will help us track which horizontal or vertical other we might want to use for similarity calculations
			var i =0
			var otherList = [topLeft,bottomLeft,topRight,bottomRight]
			var horizontalOther = [topRight,bottomRight,topLeft,bottomLeft]
			var verticalOther = [bottomLeft,topLeft,bottomRight,bottomLeft]
			for other in otherList:
				var similarityThresh
				var dif = other.unprojectedPosition - v.unprojectedPosition
				# figure out which component of dif is bigger
				if abs(dif.x) >abs(dif.y):
					#likely that the v and other are closer horizontally, 
					var hO = horizontalOther[i]
					similarityThresh = abs(other.position.y - hO.position.y)
				else:
				 	#likely that the v and other are closer vertically, 
					var vO = verticalOther[i]
					similarityThresh = abs(other.position.x - vO.position.x)
				if abs(dif.x) < similarityThresh:
					# this v is probably on a vertical edge
					# get dif from center
					var cenDif = center - v.unprojectedPosition
					if cenDif.x < 0:
						# we are on the right vertical edge
						newUV.x = 1
						# now calculate the vertical by seeing how far along the y edge we are
						newUV.y = (v.unprojectedPosition.y - topRight.unprojectedPosition.y)/(bottomRight.unprojectedPosition.y - topRight.unprojectedPosition.y )
						v.uv = newUV
						stop = true
					else:
						# we are on the left vertical edge
						newUV.x = 0
						# now calculate the vertical by seeing how far along the y edge we are
						newUV.y = (v.unprojectedPosition.y - topLeft.unprojectedPosition.y)/(bottomLeft.unprojectedPosition.y - topLeft.unprojectedPosition.y )
						v.uv = newUV
						stop = true
				elif abs(dif.y) < similarityThresh:
					# this v is probably on a horizontal edge 
					
					# get dif from center
					var cenDif = center - v.unprojectedPosition
					if cenDif.y < 0:
						# we are on the bottom horizontal edge (using user viewing perspective)
						newUV.y = 1
						# now calculate the vertical by seeing how far along the y edge we are
						newUV.x = (v.unprojectedPosition.x - bottomLeft.unprojectedPosition.x)/(bottomRight.unprojectedPosition.x - bottomLeft.unprojectedPosition.x )
						v.uv = newUV
						stop=true
					else:
						# we are on the top horizontal edge
						newUV.y = 0
						# now calculate the vertical by seeing how far along the y edge we are
						newUV.x = (v.unprojectedPosition.x - topLeft.unprojectedPosition.x)/(topRight.unprojectedPosition.x - topLeft.unprojectedPosition.x )
						v.uv = newUV
						stop = true
				if stop:
					break
				i+=1
			if stop:
				continue
			else:
				# we are a fully internal point, interpolate both the x and y
				# lets pick corners that are opposite of eachother, if the user picks a plane that's really wonky then this might not be right
				newUV.y = (v.unprojectedPosition.y - topLeft.unprojectedPosition.y)/(bottomRight.unprojectedPosition.y - topLeft.unprojectedPosition.y )
				newUV.x = (v.unprojectedPosition.x - topLeft.unprojectedPosition.x)/(bottomRight.unprojectedPosition.x - topLeft.unprojectedPosition.x )
				v.uv= newUV
	#

func create_colored_geometry(verts):
	var vpos = []
	for vert in verts:
		vpos.push_back(vert.position)
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var ind =0
	for v in vpos:
		var vert3d =verts[ind]
		vertices.push_back(v)
		uvs.push_back(vert3d.uv)
		ind+=1
	# Initialize the ArrayMesh.
	var arr_mesh:ArrayMesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	print("the uvs are",uvs)
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = testicon
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority  =-1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	arr_mesh.surface_set_material(0,mat)
	var m = MeshInstance3D.new()
	m.mesh = arr_mesh
	
	# make this a random color
	add_child(m)
	# make ref for triangles to the verts
	ind =0
	for v in verts:
		v.triangles.push_back(m)
		v.triInds.push_back(ind)
		ind+=1
func remove_meshes():
	var all_verts = get_tree().get_nodes_in_group("verts")
	for v in all_verts:
		v.remove_mesh()
func clear_triangles_list():
	#clear the triangle list
	for v in triangle_vertices:
		# turn off their selection colors
		v.tri_cleared()
	triangle_vertices = []

			
			
func _on_left_hand_button_pressed(name):
	if name == "ax_button":
		#display_scene_and_spatial_anchors(not scene_and_spatial_anchors_displayed)
		load_spatial_anchors_from_file()
	elif name == "by_button":
		enable_passthrough(not passthrough_enabled)
		
	elif name == "menu_button":
		scene_manager.request_scene_capture()
# used to help anchor pick which image it will be displaying
var imageId=0
var imageScale = 1
var spritePriority=2
var on_menu = false
func _on_right_hand_button_pressed(name: String) -> void:
	if backgroundDrawing:
		print(name)
		if name == "ax_button":
			if hovered_element ==  col.get_parent():
				# remove the new vert
				hovered_element.remove_all()
				# make sure to remove from the global tracking
			elif col:
				print("position",col_pos)
				# maek a vertex there
				var new_vert = vert3d.instantiate()
				
				new_vert.position = col_pos
				new_vert.add_to_group("verts")
				
				add_child(new_vert)
				if get_tree().get_nodes_in_group("verts").size() <=4:
					new_vert.corner = true
				if get_tree().get_nodes_in_group("verts").size() ==4:
					# launch the corner calculation so we don't need to click it
					print("launching corner uv calculation")
					calc_center()
				if get_tree().get_nodes_in_group("verts").size() >4:
					# run the interior calculation for the point created
					uv_interior()
				# this just makes sure we have a list of the edges
		elif name == "by_button":
			# turn the hovered_element on for it's triangle 
			hovered_element.tri_clicked()
			triangle_vertices.push_back(hovered_element)
			print("tri verts are ", triangle_vertices)
			if triangle_vertices.size()==3:
				# make a check for "repeat" triangle in list
				var no_repeats = true
				for i in range(0,3):
					for j in range(0,3):
						if i!=j:
							var v1 = triangle_vertices[i]
							var v2 = triangle_vertices[j]
							if v1 == v2:
								no_repeats = false
				if no_repeats:
					create_colored_geometry(triangle_vertices)
				clear_triangles_list()
				
			# check if we have a
		
	# only trigger this if the cursor isn't being interrupted by the menu
	else:
		if not on_menu:
			if name == "trigger_click" and right_hand_pointer.visible:
				if right_hand_pointer_raycast.is_colliding():
					if selected_spatial_anchor_node:
						var anchor_parent = selected_spatial_anchor_node.get_parent()
						if anchor_parent is XRAnchor3D:
							spatial_anchor_manager.untrack_anchor(anchor_parent.tracker)
							# take on the imageId and scale from the removed element to make reposition easier
							imageId = selected_spatial_anchor_node.imageId
							imageScale = selected_spatial_anchor_node.imageScale
							# decrease the imageId because we removed that image
					else:
						var anchor_transform := Transform3D()
						anchor_transform.origin = right_hand_pointer_raycast.get_collision_point()

						var collision_normal: Vector3 = right_hand_pointer_raycast.get_collision_normal()
						if collision_normal.is_equal_approx(Vector3.UP):
							anchor_transform.basis = anchor_transform.basis.rotated(Vector3(1.0, 0.0, 0.0), PI / 2.0)
						elif collision_normal.is_equal_approx(Vector3.DOWN):
							anchor_transform.basis = anchor_transform.basis.rotated(Vector3(1.0, 0.0, 0.0), -PI / 2.0)
						else:
							anchor_transform.basis = Basis.looking_at(right_hand_pointer_raycast.get_collision_normal())

						spatial_anchor_manager.create_anchor(anchor_transform, {scale=imageScale,priority=spritePriority,imageid=imageId})
						
			elif name == "ax_button":
				# remove the previous anchor
				if selected_spatial_anchor_node:
					var anchor_parent: XRAnchor3D = selected_spatial_anchor_node.get_parent()
					var prev_position = anchor_parent.global_transform.origin
					var prev_basis = anchor_parent.basis
					if anchor_parent is XRAnchor3D:
						spatial_anchor_manager.untrack_anchor(anchor_parent.tracker)
					# bake the scale into the anchor
					var anchor_transform = Transform3D()
					anchor_transform.origin =  prev_position
					anchor_transform.basis = prev_basis
					
					
					spatial_anchor_manager.untrack_anchor(anchor_parent.tracker)
					spatial_anchor_manager.create_anchor(anchor_transform,{scale=selected_spatial_anchor_node.imageScale,priority=selected_spatial_anchor_node.spritepriority,
					imageid=selected_spatial_anchor_node.imageId})
				
			elif name == "by_button":
				if selected_spatial_anchor_node:
					last_selected_node = selected_spatial_anchor_node
				


func _on_scene_manager_scene_capture_completed(success: bool) -> void:
	if success:
		# Recreate scene anchors since the user may have changed them.
		if scene_manager.are_scene_anchors_created():
			scene_manager.remove_scene_anchors()
		scene_manager.create_scene_anchors()


func _on_scene_manager_scene_data_missing() -> void:
	scene_manager.request_scene_capture()


func _on_right_hand_input_vector_2_changed(name: String, value: Vector2) -> void:
	#if selected_spatial_anchor_node:
		#print("scaling ",value)
		#selected_spatial_anchor_node.adjustScale(value)
	
	pass # Replace with function body.


func _on_xr_controller_3d_input_vector_2_changed(name: String, value: Vector2) -> void:
	
	# hav ethis check our last intersection and if it's a vertex3d then we should attempt to raise or lower it's uv
			# check if the collider is part of the vert3d 
	if col:
		var col_group = col.get_parent().get_groups()
		if col_group.size()> 0 and col_group[0] =="verts":
			#typically want opposite horizontal behavior
			#value.x*=-1
			var vert = col.get_parent()
			vert.uv+= value*.001
			vert.updateUvs()
	pass # Replace with function body.


func _on_open_xr_composition_layer_quad_intersected_interface(is_on_menu) -> void:
	on_menu = is_on_menu
	#$QuadViewport/Control.update(intersection)
	pass # Replace with function body.


func _on_control_anim_selected(btn_name) -> void:
	# set the animation that should be placed on the next trigger click
	var names_id_map = ["center","man","woman","spikes","roundcact","pink","agave","ocotillo"]
	var index_of_name = names_id_map.find(btn_name)
	
	# do a index of search for the image id we need to set
	if index_of_name !=-1:
		imageId = index_of_name
		print(imageId)
	pass # Replace with function body.


func _on_control_order_slider_update(orderValue) -> void:
	# use these to update the previously selected element
	spritePriority = orderValue
	if last_selected_node:
		last_selected_node.setPriority(orderValue)
	pass # Replace with function body.


func _on_control_scale_slider_update(sliderValue) -> void:
	if last_selected_node:
		last_selected_node.sliderScale(sliderValue)
	imageScale = sliderValue
	pass # Replace with function body.


func _on_control_background_drawing(toggle) -> void:
	backgroundDrawing = toggle
	## TODO consider  whether to hide the menu at this point?
	pass # Replace with function body.


func _on_right_hand_pointer_input_vector_2_changed(name: String, value: Vector2) -> void:
	pass # Replace with function body.
