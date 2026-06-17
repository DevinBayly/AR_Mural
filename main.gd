extends StartXR

const ENVIRONMENT_DEPTH_MATERIAL = preload("res://environment_depth_material.tres")
const BLUE_MATERIAL = preload("res://blue_material.tres")

var passthrough_enabled: bool = false
var scene_and_spatial_anchors_displayed: bool = true
var selected_spatial_anchor_node: Node3D = null
var global_environment_depth_enabled: bool = true
var vert3d = preload("res://vert_3d.tscn")
@onready var testicon = preload("res://icon.svg")


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
            var col_group = col.get_parent().get_groups()
            if col_group.size()> 0 and col_group[0] =="verts":
                print("highlighting sphere")
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
        

var prev: Node3D = null
var corners = []
var edges = []
var dist_threshold = 5
var last_intersections = []
# helps us figure out the uvs of the border points created at intersections
var last_intersections_uvs =[]
var all_vertx: Array[Vector3] = []
var triangle_vertices=[]
var hovered_element
var center = Vector3(0,0,0)
var backgroundDrawing=false
func calc_center():
    var total = Vector3(0,0,0)
    for v in all_vertx:
        total +=v
    center.x = total.x/all_vertx.size()
    center.y = total.y/all_vertx.size()
    center.z = total.z/all_vertx.size()
func uv_edges():
    for pair in edges:		
        var start = pair[0]
        var end = pair[1]
        var dif = end.position - start.position
        # dir from center
        var centerdif = center - start.position
        # figure out if the horizontal dif is bigger than the vertical
        if abs(dif.x) > abs(dif.y):
            # we have a horizontal edge
            # figure out our v coordinate to hold steady
            var v = 0
            if centerdif.y > 0:
                # center point is above our starting vector so we are a horizontal "top" line with a 0 as v
                v = 1
            # keep in mind that we might need to figure out if we are a top or bottom horizontal
            if dif.x >0:
                start.uv = Vector2(0,v)
                end.uv = Vector2(1,v)
            else:
                start.uv = Vector2(1,v)
                end.uv = Vector2(0,v)
            # figure out which one needs to have the 0 vs 1 in the u coordinate
        else:
            # we have a vertical edge
            # figure out our u coordinate to hold steady
            var u =1
            if centerdif.x >0:
                #means center point is to the right of our spot so we are a vertical line with 0 as our u
                u =0
            if dif.y>0:
                start.uv = Vector2(u,1)
                end.uv = Vector2(u,0)
            else:
                start.uv = Vector2(u,0)
                end.uv = Vector2(u,1)
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
    
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    
    # Create the Mesh.
    arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(randf(),randf(),randf())
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    arr_mesh.surface_set_material(0,mat)
    var m = MeshInstance3D.new()
    m.mesh = arr_mesh
    
    # make this a random color
    add_child(m)

func remove_meshes():
    # also remove all meshes
    var meshes = get_children()
    
    for m in meshes:
        if m is MeshInstance3D:
            m.queue_free()
func clear_triangles_list():
    #clear the triangle list
    for v in triangle_vertices:
        # turn off their selection colors
        v.tri_cleared()
    triangle_vertices = []
func draw_im() -> void:
    calc_center()
    uv_edges()
    # go get all the other mesh2ds 
    # find the min and max of all their points
    # go back through each and update it's texture coordinates, and add a texture to the shape
    # OR
    # make one big ass mesh using all the triangles, and set all the uvs to correct values, and then at the end just assign a single texture
    var meshes = get_children()
    print("trying something different")
    
    
    # use the min and max values to help us establish uv coordinates
    for m in meshes:
        if m is MeshInstance3D:
            var mesh:ArrayMesh = m.mesh
            # iterate over the vertices in the triangle
            var mesh_array = mesh.surface_get_arrays(0)
            var vertices = mesh_array[Mesh.ARRAY_VERTEX]
            var uvs = mesh_array[Mesh.ARRAY_TEX_UV]
            
            mesh_array[Mesh.ARRAY_TEX_UV] = uvs
            mesh.surface_remove(0)
            # re add the data so the uvs get baked in properly
            mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
            
            var mat: StandardMaterial3D = StandardMaterial3D.new()
            mat.albedo_texture = testicon
            mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mat.cull_mode = BaseMaterial3D.CULL_DISABLED
            mesh.surface_set_material(0,mat)
            m.mesh = mesh
            
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
var on_menu = false
func _on_right_hand_button_pressed(name: String) -> void:
    if backgroundDrawing:
        print(name)
        if name == "ax_button":
            if col:
                print("position",col_pos)
                # maek a vertex there
                var new_vert = vert3d.instantiate()
                new_vert.position = col_pos
                new_vert.add_to_group("verts")
                add_child(new_vert)

                # this just makes sure we have a list of the edges
                all_vertx.push_back(col_pos)
                if prev:
                    edges.push_back([prev,new_vert])
                    prev = new_vert
                else:
                    prev = new_vert
        elif name == "by_button":
            # turn the hovered_element on for it's triangle 
            hovered_element.tri_clicked()
            triangle_vertices.push_back(hovered_element)
            print("tri verts are ", triangle_vertices)
            if triangle_vertices.size()==3:
                create_colored_geometry(triangle_vertices)
                clear_triangles_list()
            # check if we have a
        elif name == "grip_click":
            # use this to draw over the triangles
            draw_im()
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

                        spatial_anchor_manager.create_anchor(anchor_transform, {scale=imageScale,priority=0,imageid=imageId})
                        imageId+=1
                        
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
    if selected_spatial_anchor_node:
        print("scaling ",value)
        selected_spatial_anchor_node.adjustScale(value)
    pass # Replace with function body.


func _on_xr_controller_3d_input_vector_2_changed(name: String, value: Vector2) -> void:
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


func _on_control_order_slider_update() -> void:
    # use these to update the previously selected element
    pass # Replace with function body.


func _on_control_scale_slider_update(sliderValue) -> void:
    if last_selected_node:
        last_selected_node.sliderScale(sliderValue)
    pass # Replace with function body.


func _on_control_background_drawing(toggle) -> void:
    backgroundDrawing = toggle
    ## TODO consider  whether to hide the menu at this point?
    pass # Replace with function body.
