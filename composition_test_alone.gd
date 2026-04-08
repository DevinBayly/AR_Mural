extends StartXR
@onready var world_environment = $WorldEnvironment
var _setup := false
func _ready():
	super._ready()
	if xr_interface and xr_interface.is_initialized():
		xr_interface.session_begun.connect(_on_openxr_session_begun)


var passthrough_enabled = true
func _on_openxr_session_begun() -> void:
	if _setup:
		return
	_setup = true

	
	enable_passthrough(true)

	var environment_depth = Engine.get_singleton("OpenXRMetaEnvironmentDepthExtensionWrapper")
	if environment_depth:
		print("Supports environment depth: ", environment_depth.is_environment_depth_supported())
		print("Supports hand removal: ", environment_depth.is_hand_removal_supported())
		if environment_depth.is_environment_depth_supported():
			environment_depth.start_environment_depth()
			print("Environment depth started: ", environment_depth.is_environment_depth_started())


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
