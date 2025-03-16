extends Node3D

@onready var wheel_3d: Node3D = $Wheel3D

func _process(delta: float) -> void:
	wheel_3d.rotation_degrees.z += delta
