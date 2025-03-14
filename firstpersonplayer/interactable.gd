class_name Interactable extends Node3D

@export var can_grab: bool = false

@warning_ignore("unused_signal")
signal on_ray_entered()
@warning_ignore("unused_signal")
signal on_ray_exited()
@warning_ignore("unused_signal")
signal interacted()
