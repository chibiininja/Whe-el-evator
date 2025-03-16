class_name ControlsDisplay extends Node3D

@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var interactable_3d: Interactable = $RigidBody3D

func _ready() -> void:
	interactable_3d.interacted.connect(func(): rigid_body_3d.freeze = false)

func reset():
	rigid_body_3d.position = Vector3.ZERO
	rigid_body_3d.rotation = Vector3.ZERO
	rigid_body_3d.freeze = true
