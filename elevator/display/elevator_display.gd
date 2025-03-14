class_name ElevatorDisplay extends Node3D

@onready var target_label: Label3D = $TargetLabel
@onready var target_number: Label3D = $TargetNumber
@onready var current_label: Label3D = $CurrentLabel
@onready var current_number: Label3D = $CurrentNumber
@onready var result_label: Label3D = $ResultLabel
@onready var result_number: Label3D = $ResultNumber

func update_target_number(value: int):
	target_number.text = str(value)

func update_current_number(value: int):
	current_number.text = str(value)

func update_result_number(value: int):
	result_number.text = str(value)

func update_target_label(value: String):
	target_label.text = value

func update_current_label(value: String):
	current_label.text = value

func update_result_label(value: String):
	result_label.text = value

func display_result(value: bool):
	result_number.visible = value
