extends Control
signal scaleSliderUpdate
signal sortSliderUpdate
signal imageSelected
signal backgroundDrawing
@onready var orderSlider = $BoxContainer/HBoxContainer2/orderSlider
@onready var scaleSlider = $BoxContainer/HBoxContainer/HSlider
@onready var background_check:CheckBox = $BoxContainer/HBoxContainer3/CheckBox
@onready var anims: GridContainer = $Animations
@onready var pointer_right: ColorRect = $PointerRight

func _ready() -> void:
	if background_check.is_pressed():
		# hide the animations menu when pressed
		anims.hide()
		backgroundDrawing.emit()
	background_check.toggled.connect(hide_anims)
	
func hide_anims(toggled):
	if toggled:
		anims.hide()
	else:
		anims.show()


func _on_sort_order_slider_drag_ended(value_changed: bool) -> void:
	print(orderSlider.value, " is the new order value")
	pass # Replace with function body.


func _on_scale_slider_drag_ended(value_changed: bool) -> void:
	print(scaleSlider.value," is the new scale value")
	pass # Replace with function body.

func update_pointer(p_position_right: Vector2) -> void:
	pointer_right.position = size * p_position_right - (0.5 * pointer_right.size)
