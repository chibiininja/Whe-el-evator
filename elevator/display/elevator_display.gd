class_name ElevatorDisplay extends Node3D

@onready var target_label: Label3D = $TargetLabel
@onready var target_number: Label3D = $TargetNumber
@onready var current_label: Label3D = $CurrentLabel
@onready var current_number: Label3D = $CurrentNumber
@onready var result_label: Label3D = $ResultLabel
@onready var result_number: Label3D = $ResultNumber
@onready var base_label: Label3D = $BaseLabel
@onready var base_number: Label3D = $BaseNumber
@onready var slice_label: Label3D = $SliceLabel
@onready var slice_number: Label3D = $SliceNumber
@onready var x: Label3D = $x

const characters = "abcdefghijklmnopqrstuvwxyz!@#$%^&*"
var jumble: bool = false
var jumble_delta: float = 0
var jumble_cooldown: float = 0.1

func _ready() -> void:
	result_number.visible = false

func _process(delta: float) -> void:
	if not jumble:
		return
	jumble_delta += delta
	if jumble_delta > jumble_cooldown:
		update_current_label(_generate_word(characters, 7))
		update_result_label(_generate_word(characters, 6))
		update_target_label(_generate_word(characters, 6))
		update_base_label(_generate_word(characters, 4))
		update_slice_label(_generate_word(characters, 5))
		jumble_delta = 0

func _generate_word(chars, length):
	randomize()
	var word: String = ""
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi() % n_char]
	return word

func update_target_number(value):
	target_number.text = str(value) if value is int else value

func update_current_number(value):
	current_number.text = str(value) if value is int else value

func update_result_number(value):
	result_number.text = str(value) if value is int else value

func update_base_number(value):
	base_number.text = str(value) if value is int else value

func update_slice_number(value):
	slice_number.text = str(value) if value is int else value

func update_target_label(value: String):
	target_label.text = value

func update_current_label(value: String):
	current_label.text = value

func update_result_label(value: String):
	result_label.text = value

func update_base_label(value: String):
	base_label.text = value

func update_slice_label(value: String):
	slice_label.text = value

func display_result(value: bool):
	result_number.visible = value

func display_base(value: bool):
	base_label.visible = value
	base_number.visible = value

func display_slice(value: bool):
	slice_label.visible = value
	slice_number.visible = value

func display_x(value: bool):
	x.visible = value

func wheel_selection(_current_value):
	update_base_number(_current_value.base_value)
	update_slice_number(_current_value.slice_value)

func reset():
	jumble = false
	result_number.visible = false
	target_label.text = "TARGET"
	current_label.text = "CURRENT"
	result_label.text = "RESULT"
	current_number.text = "0"
	display_base(false)
	display_slice(false)
	display_x(false)
