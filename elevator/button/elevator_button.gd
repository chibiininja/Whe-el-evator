class_name ElevatorButton extends Node3D

@export var default_color: Color = Color("ffdecc")
@export var hovered_color: Color = Color("bfa699")
@export var pressed_color: Color = Color("ffe926")

@onready var static_body_3d: Interactable = $StaticBody3D
@onready var button_mesh: MeshInstance3D = $meshes/ButtonMesh
@onready var text_mesh: MeshInstance3D = $meshes/TextMesh
@onready var meshes: Node3D = $meshes
@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D

const hover_sound = preload("uid://cxg4q58es2u77")
const select_sound = preload("uid://c43qhby2kqxxj")

var number: int = 0:
	set(value):
		number = value
		_set_text(value)
var pressed: bool = false:
	set(value):
		pressed = value
		if pressed == false:
			reset()
var interactable: bool = true

signal interacted(floor_level: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	static_body_3d.on_ray_entered.connect(_on_ray_entered)
	static_body_3d.on_ray_exited.connect(_on_ray_exited)
	static_body_3d.interacted.connect(_interacted)

func _on_ray_entered():
	if pressed:
		return
	Global._play_sound(hover_sound)
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(meshes, "position", Vector3(0, -0.01, 0), 0.2)
	button_mesh.get_surface_override_material(0).set("emission", hovered_color)

func _on_ray_exited():
	if pressed:
		return
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(meshes, "position", Vector3(0, 0, 0), 0.2)
	button_mesh.get_surface_override_material(0).set("emission", default_color)

func _interacted():
	if not interactable:
		return
	pressed = true
	Global._play_sound(select_sound)
	interacted.emit(number)
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(meshes, "position", Vector3(0, -0.015, 0), 0.2)
	button_mesh.get_surface_override_material(0).set("emission", pressed_color)

func _set_text(value: int):
	text_mesh.mesh.text = str(value)

func reset():
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(meshes, "position", Vector3(0, 0, 0), 0.2)
	button_mesh.get_surface_override_material(0).set("emission", default_color)
