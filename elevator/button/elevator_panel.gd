class_name ElevatorPanel extends Node3D

@onready var panels: Array = [%RigidBody3D, %RigidBody3D2, %RigidBody3D3, %RigidBody3D4, %RigidBody3D5]
@onready var buttons: Array[ElevatorButton] = \
	[%Button, %Button2, %Button3, %Button4, %Button5, 
	%Button6, %Button7, %Button8, %Button9, %Button10, 
	%Button11, %Button12, %Button13, %Button14, %Button15, 
	%Button16, %Button17, %Button18, %Button19, %Button20, 
	%Button21, %Button22, %Button23, %Button24, %Button25]

var malfunctioned: bool = false

signal floor_selected(floor_level: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var panel = panels[0] as RigidBody3D
	for button in buttons:
		button.interacted.connect(_button_selected)
		panel.add_collision_exception_with(button.static_body_3d)

func _button_selected(floor_level: int):
	for button in buttons:
		button.interactable = false
	floor_selected.emit(floor_level)

func reset_choice():
	for button in buttons:
		button.pressed = false
		button.interactable = true

func malfunction():
	malfunctioned = true
	for button in buttons:
		button.pressed = false
		button.interactable = false
	for panel:RigidBody3D in panels:
		panel.freeze = false
	panels[0].apply_central_impulse(Vector3(0,0,1))
	panels[1].apply_central_impulse(Vector3(-1,0,0))
	panels[2].apply_central_impulse(Vector3(1,0,0))
	panels[3].apply_central_impulse(Vector3(0,-1,0))
	panels[4].apply_central_impulse(Vector3(0,1,0))
	await get_tree().create_timer(0.1).timeout
	panels[0].apply_central_impulse(Vector3(1,0,0))
	panels[1].apply_central_impulse(Vector3(0,0,1))
	panels[2].apply_central_impulse(Vector3(0,0,-1))
	panels[4].apply_central_impulse(Vector3(1,0,1))
	for panel:Interactable in panels:
		panel.can_grab = true
