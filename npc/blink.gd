extends Node3D

@export var blink_delay_range: Vector2 = Vector2(1,3)

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var timer: Timer = $Timer

func _ready() -> void:
	randomize()
	timer.timeout.connect(_blink)
	timer.start(get_random_delay())

func _blink():
	animation_tree["parameters/blink_oneshot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	timer.start(get_random_delay())

func get_random_delay()->float:
	return randf_range(blink_delay_range.x, blink_delay_range.y)
