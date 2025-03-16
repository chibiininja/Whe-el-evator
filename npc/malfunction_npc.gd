class_name MalfunctionNPC extends Node3D

signal finished_exiting()
signal finished_entering()

const COLORS: Array[Color] = [
	Color.BLUE_VIOLET,
	Color.DEEP_PINK,
	Color.FOREST_GREEN,
	Color.GOLD,
	Color.ORANGE_RED,
	Color.RED,
	Color.MEDIUM_BLUE
]

@onready var static_body_3d: Interactable = $StaticBody3D
@onready var dialogue_bubble: DialogueBubble = $DialogueBubble
@onready var mesh_instance_3d: MeshInstance3D = $StaticBody3D/MeshInstance3D

const dialogue: Array[String] = [
	"LET'S GO UP",
	"the voices are getting louder",
	"it's a long way down to the bottom",
	"ERROR",
	"i hope you find what you're looking for",
	"AHAHAHAHAHAHAHAHAHAHA",
	"shhhhhhhhhhh",
	"...",
	"TIME TO PARTY!11!!1",
	"WHEEEEEEEEEE"
]

var looking: bool = false
var interactable: bool = false
var look_counter: float = 0
var previous_rotation: float = 0

var dialogue_bag: Array[String]

func _ready() -> void:
	randomize()
	static_body_3d.interacted.connect(_interacted)
	dialogue_bag = dialogue.duplicate()
	dialogue_bag.shuffle()
	mesh_instance_3d.get_surface_override_material(0).set("albedo_color", COLORS.pick_random())
	dialogue_bubble.base_pitch = randf_range(0.8, 1.8)

func _process(delta: float) -> void:
	if looking:
		look_counter += delta
		var look_direction = Global.camera.global_position - global_position
		rotation.y = lerp_angle(previous_rotation, atan2(look_direction.x, look_direction.z), smoothstep(0, 1, look_counter))
	else:
		look_counter = 0
		previous_rotation = rotation.y

#region Interaction Functions
func _interacted():
	if not interactable:
		return
	if not dialogue_bubble.visible:
		interactable = false
		dialogue_bubble.sprite_3d.texture = dialogue_bubble.DEFAULT
		dialogue_bubble.visible = true
		if dialogue_bag.size() == 0:
			dialogue_bag = dialogue.duplicate()
			dialogue_bag.shuffle()
		dialogue_bubble.display_text(dialogue_bag.pop_front())
		dialogue_bubble.finished_displaying.connect(func(): interactable = true)
	else:
		dialogue_bubble.visible = false
#endregion

#region Spawn and Despawn Functions
func enter():
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position", Vector3.ZERO, 2.0)
	tween.tween_property(self, "rotation_degrees", Vector3(0,-45,0), .25)
	tween.tween_property(self, "position", Vector3(-0.5,0,0.5), 1.0)
	tween.finished.connect(func(): 
		looking = true
		interactable = true
		finished_entering.emit()
		interactable = false
		dialogue_bubble.sprite_3d.texture = dialogue_bubble.DEFAULT
		dialogue_bubble.visible = true
		if dialogue_bag.size() == 0:
			dialogue_bag = dialogue.duplicate()
			dialogue_bag.shuffle()
		dialogue_bubble.display_text(dialogue_bag.pop_front())
		dialogue_bubble.finished_displaying.connect(func(): interactable = true))

func exit():
	looking = false
	dialogue_bubble.visible = false
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "rotation_degrees", Vector3(0,135,0), .25)
	tween.tween_property(self, "position", Vector3.ZERO, 1.0)
	tween.tween_property(self, "rotation_degrees", Vector3(0,180,0), .25)
	tween.tween_property(self, "position", Vector3(0,0,-3.25), 2.0)
	tween.finished.connect(func(): finished_exiting.emit())
#endregion
