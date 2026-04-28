extends Control
signal scaleSliderUpdate
signal sortSliderUpdate
# not sure, this might be from a previous part
signal imageSelected
signal backgroundDrawing
# signal that the main program uses to determine which animation to place on next real trigger click in the background
signal animSelected
@onready var orderSlider = $BoxContainer/HBoxContainer2/orderSlider
@onready var scaleSlider = $BoxContainer/HBoxContainer/HSlider
@onready var background_check:CheckBox = $BoxContainer/HBoxContainer3/CheckBox
@onready var anims: GridContainer = $Animations
@onready var pointer_right: ColorRect = $PointerRight
@onready var Anims = $Animations
func _ready() -> void:
	if background_check.is_pressed():
		# hide the animations menu when pressed
		anims.hide()
		backgroundDrawing.emit()
	background_check.toggled.connect(hide_anims)
	# go through and wire up connections for all of the button children
	for child in Anims.get_children():
		# wire up a function that handles the pressed event
		child.connect("pressed",Anim_button_pressed.bind(child))
	
func Anim_button_pressed(btn):
	print("this btn was pressed",btn)
	animSelected.emit(btn.text)
	
func hide_anims(toggled):
	if toggled:
		anims.hide()
	else:
		anims.show()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$PointerRight.position = event.position

func _on_sort_order_slider_drag_ended(value_changed: bool) -> void:
	print(orderSlider.value, " is the new order value")
	pass # Replace with function body.


func _on_scale_slider_drag_ended(value_changed: bool) -> void:
	print(scaleSlider.value," is the new scale value")
	pass # Replace with function body.

func update(p_position_right: Vector2) -> void:
	pointer_right.position = size * p_position_right - (0.5 * pointer_right.size)
