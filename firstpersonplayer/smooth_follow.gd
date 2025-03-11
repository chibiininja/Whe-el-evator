extends Node3D

@export var follow_target: NodePath

var target: Node3D
var update = false
var gt_prev: Transform3D
var gt_current: Transform3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_as_top_level(true)
	target = get_node_or_null(follow_target)
	if target == null:
		target = get_parent()
	global_transform = target.global_transform
	
	gt_prev = target.global_transform
	gt_current = target.global_transform

func update_transform() -> void:
	gt_prev = gt_current
	gt_current = target.global_transform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if update:
		update_transform()
		update = false
	
	var f = clamp(Engine.get_physics_interpolation_fraction(), 0, 1)
	global_transform = gt_prev.interpolate_with(gt_current, f)

func _physics_process(_delta: float) -> void:
	update = true
