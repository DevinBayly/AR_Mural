extends Control

@export var display_string: String = ""

@onready var pointer_left: ColorRect = $PointerLeft
@onready var pointer_right: ColorRect = $PointerRight

var start_pos: Vector2


func _ready() -> void:
	start_pos = $Label.position
	$Label.text = display_string


func _process(delta: float) -> void:
	pass

func update_pointers(p_position_left: Vector2, p_position_right: Vector2) -> void:
	if p_position_left:
		pointer_left.position = size * p_position_left - (0.5 * pointer_left.size)
	if p_position_right:
		pointer_right.position = size * p_position_right - (0.5 * pointer_left.size)


func _on_button_pressed() -> void:
	print("button got pressed")
	pass # Replace with function body.
