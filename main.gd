extends Node3D

@onready var elevator_controller: ElevatorController = $ElevatorController
@onready var gameover: Control = $gameover
@onready var play_again: Button = $gameover/MarginContainer/play_again
@onready var game_over_animation_player: AnimationPlayer = $gameover/GameOverAnimationPlayer
@onready var thanks: MarginContainer = $gameover/thanks
@onready var world_environment: WorldEnvironment = $WorldEnvironment

@onready var resume: Button = $pause/CenterContainer/VBoxContainer/resume
@onready var quit: Button = $pause/CenterContainer/VBoxContainer/quit
@onready var pause: Control = $pause
@onready var quit_2: Button = $gameover/MarginContainer2/quit2
@onready var toggle_fullscreen: Button = $gameover/MarginContainer3/toggle_fullscreen
@onready var toggle_fullscreen_2: Button = $pause/MarginContainer3/toggle_fullscreen2

const npc = preload("res://npc/npc.tscn")
const malfunction_npc = preload("res://npc/malfunction_npc.tscn")
const crash_npc = preload("res://npc/crash_npc.tscn")

const ELEVATOR_CLOSE = preload("uid://c5lku7hw2nms6")

enum GameState {
	default,
	malfunction,
	crashing
}

var game_state: GameState = GameState.default
var npc_count: int = 0
var current_npc: Node3D
var playing: bool = false

func _ready() -> void:
	elevator_controller.ready_for_npc.connect(query_npc)
	play_again.pressed.connect(reset)
	world_environment.environment.adjustment_contrast = 1.15
	world_environment.environment.adjustment_saturation = 1.8
	resume.pressed.connect(_unpause)
	quit.pressed.connect(func(): get_tree().quit())
	quit_2.pressed.connect(func(): get_tree().quit())
	toggle_fullscreen.pressed.connect(_toggle_fullscreen)
	toggle_fullscreen_2.pressed.connect(_toggle_fullscreen)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and playing:
		if get_tree().paused:
			_unpause()
		else:
			_pause()

func query_npc():
	if current_npc == null:
		if npc_count == 3:
			elevator_controller.malfunction()
			game_state = GameState.malfunction
			world_environment.environment.adjustment_contrast = 2.1
			world_environment.environment.adjustment_saturation = 3.3
		elif npc_count == 6:
			game_state = GameState.crashing
		match game_state:
			GameState.default:
				current_npc = npc.instantiate()
			GameState.malfunction:
				current_npc = malfunction_npc.instantiate()
			GameState.crashing:
				current_npc = crash_npc.instantiate()
		add_child(current_npc)
		current_npc.position = Vector3(0,0,-3.25)
		elevator_controller.door_animation_player.animation_finished.connect(_npc_enter)
	else:
		match game_state:
			GameState.default, GameState.malfunction:
				elevator_controller.door_animation_player.animation_finished.connect(_npc_exit)
			GameState.crashing:
				pass

func _npc_enter(_anim_name: StringName):
	elevator_controller.door_animation_player.animation_finished.disconnect(_npc_enter)
	current_npc.enter()
	current_npc.finished_entering.connect(_door_closed)

func _npc_exit(_anim_name: StringName):
	elevator_controller.door_animation_player.animation_finished.disconnect(_npc_exit)
	current_npc.exit()
	current_npc.finished_exiting.connect(_despawn_npc)

func _despawn_npc():
	npc_count += 1
	current_npc.finished_exiting.disconnect(_despawn_npc)
	remove_child(current_npc)
	current_npc.queue_free()
	current_npc = null
	_door_closed()

func _door_closed():
	if current_npc != null:
		current_npc.finished_entering.disconnect(_door_closed)
	elevator_controller.door_animation_player.play("close")
	Global._play_sound(ELEVATOR_CLOSE)
	elevator_controller.door_animation_player.animation_finished.connect(_disconnect_door_closed)

func _disconnect_door_closed(_anim_name: StringName):
	elevator_controller.door_animation_player.animation_finished.disconnect(_disconnect_door_closed)
	match game_state:
		GameState.default:
			if not elevator_controller.elevator_panel.malfunctioned:
				elevator_controller.elevator_panel.reset_choice()
			if npc_count == 3:
				elevator_controller.elevator_panel.set_secret()
				elevator_controller.lobby.visible = false
				elevator_controller.space.visible = true
				elevator_controller.target_floor = 25
			else:
				elevator_controller.target_floor = (elevator_controller.target_floor + randi_range(1,24)) % 25
		GameState.malfunction:
			elevator_controller.target_floor += 6
		GameState.crashing:
			elevator_controller.crash()
			elevator_controller.respond.connect(current_npc.wheel_selection)
			current_npc.start_dialogue()
			current_npc.gun_out.connect(_gun_out)
			current_npc.get_response.connect(_reset_crash_wheel)
			current_npc.end_game.connect(_end_game)
	elevator_controller.reset_wheel()

func _gun_out():
	world_environment.environment.adjustment_contrast = 1.7
	world_environment.environment.adjustment_saturation = 3.65

func _reset_crash_wheel():
	elevator_controller.wheel_3d.covers_covered = [true, false, true, false]
	elevator_controller.reset_wheel()

func _end_game():
	playing = false
	Global.game_state = Global.GameState.UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	gameover.visible = true
	play_again.visible = true
	play_again.disabled = false
	quit_2.visible = true
	quit_2.disabled = false
	play_again.text = "play again?"
	thanks.visible = true
	game_over_animation_player.play("end_game")
	game_over_animation_player.animation_finished.disconnect(_hide_gameover)

func reset():
	play_again.disabled = true
	play_again.visible = false
	quit_2.visible = false
	quit_2.disabled = true
	playing = true
	world_environment.environment.adjustment_contrast = 1.15
	world_environment.environment.adjustment_saturation = 1.8
	game_over_animation_player.play("fade_away")
	game_over_animation_player.animation_finished.connect(_hide_gameover)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.game_state = Global.GameState.FirstPerson
	game_state = GameState.default
	npc_count = 0
	if current_npc != null:
		current_npc.queue_free()
		current_npc = null
	elevator_controller.reset()

func _hide_gameover(_anim_name: StringName):
	gameover.visible = false

func _pause():
	get_tree().paused = true
	Global.game_state = Global.GameState.UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pause.visible = true

func _unpause():
	get_tree().paused = false
	Global.game_state = Global.GameState.FirstPerson
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pause.visible = false

func _toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
