class_name DialogueBubble extends Node3D

signal begin_displaying()
signal finished_displaying()

const DEFAULT = preload("uid://c2nr6ssvj36on")
const NOISE = preload("uid://bc0w8sliibyxq")
const SPEECH = preload("uid://bljswremj5jm")

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Sprite3D/Label3D
@onready var timer: Timer = $LetterDisplayTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_multiline var text: String = "test":
	set(value):
		text = value
		if Engine.is_editor_hint():
			label_3d.text = text
			_resize()
@export var letter_delay:float = 0.05
@export var base_pitch:float = 1.0

var letter_index: int = 0

func _ready() -> void:
	visibility_changed.connect(_check_texture)
	timer.timeout.connect(_on_letter_display_timer_timeout)

func display_text(text_to_display: String):
	if sprite_3d.texture is NoiseTexture2D:
		animation_player.play("static")
	letter_index = 0
	text = text_to_display
	label_3d.text = ""
	_resize()
	_display_letter()
	begin_displaying.emit()

func _display_letter():
	label_3d.text += text[letter_index]
	_resize()
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		return
	
	timer.start(letter_delay)
	
	if text[letter_index] in ["a","e","i","o","u"]:
		Global._play_speech(SPEECH, base_pitch + 0.2)
	elif text[letter_index] in [" ",",","'","!","?"]:
		return
	else:
		Global._play_speech(SPEECH, base_pitch)

func _on_letter_display_timer_timeout() -> void:
	_display_letter()

func _resize():
	await get_tree().process_frame
	var word_pixel_size = label_3d.font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, label_3d.font_size)
	var word_meter_size = word_pixel_size * label_3d.pixel_size
	sprite_3d.texture.width = word_pixel_size.x / 2 + 10
	sprite_3d.texture.height = word_pixel_size.y / 2 + 10
	sprite_3d.position.y = word_meter_size.y / 2

func _check_texture():
	if not visible:
		animation_player.stop()
