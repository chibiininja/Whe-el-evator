class_name CrashNPC extends Node3D

signal finished_entering()
signal gun_out()
signal get_response()
signal end_game()

@onready var static_body_3d: Interactable = $StaticBody3D
@onready var dialogue_bubble: DialogueBubble = $DialogueBubble
@onready var gun: Node3D = $gun
@onready var gun_animation_player: AnimationPlayer = $gun/GunAnimationPlayer
@onready var flash: MeshInstance3D = $gun/flash
@onready var gunshot: AudioStreamPlayer3D = $gun/gunshot

const dialogue: Array[String] = [
	"it's judgement time", #0
	"god, i love and hate my job",
	"do you know what you have done?", #response 2
	"DON'T BOAST ABOUT IT", #yes1, 3
	"many lives could have been spared",
	"LIAR", #no1, 5
	"you can't coerce me with your mind games",
	"and now i have to clean up this mess", #combine 7
	"do you believe you are innocent?", #response 8
	"hah", #yes2, 9
	"that's a funny joke",
	"not sure your other victims are laughing though",
	"aww, how admirable", #no2, 12
	"owning up to your mistakes now?",
	"well tell that to those who suffered",
	"do you remember how you got here?", #response combine, 15
	"yeah, that's what i thought", #yes3, 16
	"i feel bad for the person who you once were",
	"but they're probably gone already",
	"huh, i guess this is your first one then", #no3, 19
	"either you aren't who you think you are",
	"or you're being influenced by your body",
	"fucking anomalous wheel elevators", #combine 22
	"i'll be seeing you again"
]

var looking: bool = false
var interactable: bool = false
var look_counter: float = 0
var previous_rotation: float = 0
var dialogue_index: int = 0:
	set(value):
		dialogue_index = value
		match value:
			2,8,15:
				response_needed = true
			_:
				response_needed = false
var response_needed: bool = false

func _ready() -> void:
	static_body_3d.interacted.connect(_interacted)

func _process(delta: float) -> void:
	if looking:
		look_counter += delta
		var look_direction = Global.camera.global_position - global_position
		rotation.y = lerp_angle(previous_rotation, atan2(look_direction.x, look_direction.z), smoothstep(0, 1, look_counter))
	else:
		look_counter = 0
		previous_rotation = rotation.y

func start_dialogue():
	dialogue_bubble.sprite_3d.texture = dialogue_bubble.NOISE
	dialogue_bubble.visible = true
	dialogue_bubble.display_text(dialogue[dialogue_index])
	dialogue_bubble.finished_displaying.connect(_show_gun)

#region Interaction Functions
func _interacted():
	if not interactable:
		return
	dialogue_index += 1
	match dialogue_index:
		5:
			dialogue_index = 7
		12:
			dialogue_index = 15
		19:
			dialogue_index = 22
		24:
			shoot_gun()
			interactable = false
			return
	play_dialogue()

func play_dialogue():
	if dialogue_bubble.finished_displaying.is_connected(_make_interactable):
		dialogue_bubble.finished_displaying.disconnect(_make_interactable)
	if dialogue_bubble.finished_displaying.is_connected(get_response.emit):
		dialogue_bubble.finished_displaying.disconnect(get_response.emit)
	interactable = false
	dialogue_bubble.display_text(dialogue[dialogue_index])
	if not response_needed:
		dialogue_bubble.finished_displaying.connect(_make_interactable)
	else:
		dialogue_bubble.finished_displaying.connect(get_response.emit)

func _make_interactable():
	interactable = true

#90 left yes, -90 right no
func wheel_selection(value: int):
	match dialogue_index:
		2:
			if value == 90:
				dialogue_index = 3
				play_dialogue()
			else:
				dialogue_index = 5
				play_dialogue()
		8:
			if value == 90:
				dialogue_index = 9
				play_dialogue()
			else:
				dialogue_index = 12
				play_dialogue()
		15:
			if value == 90:
				dialogue_index = 16
				play_dialogue()
			else:
				dialogue_index = 19
				play_dialogue()

func shoot_gun():
	flash.visible = true
	gunshot.play()
	await get_tree().create_timer(0.05).timeout
	end_game.emit()
#endregion

#region Spawn and Despawn Functions
func enter():
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position", Vector3.ZERO, 2.0)
	tween.finished.connect(func(): looking = true; interactable = true; finished_entering.emit())

func _show_gun():
	dialogue_bubble.finished_displaying.disconnect(_show_gun)
	gun.visible = true
	gun_animation_player.play("reveal")
	gun_animation_player.animation_finished.connect(func(_anim_name: StringName): dialogue_index += 1; play_dialogue())

func emit_gun_signal():
	gun_out.emit()
#endregion
