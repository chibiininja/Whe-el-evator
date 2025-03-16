class_name ElevatorController extends Node3D

signal ready_for_npc()
signal respond(direction: int)

@onready var elevator_panel: ElevatorPanel = $ElevatorPanel
@onready var elevator_display: ElevatorDisplay = $ElevatorDisplay
@onready var elevator_shaft: ElevatorShaft = $ElevatorShaft
@onready var first_person_player: Player = $FirstPersonPlayer
@onready var wheel_3d: Wheel3D = $Wheel3D
@onready var headline_display: HeadlineDisplay = $HeadlineDisplay
@onready var light_animation_player: AnimationPlayer = $Elevator/LightAnimationPlayer
@onready var door_animation_player: AnimationPlayer = $Elevator/DoorAnimationPlayer
@onready var lobby: MeshInstance3D = $Elevator/elevator/lobby
@onready var space: MeshInstance3D = $Elevator/elevator/space
@onready var controls_display: ControlsDisplay = $ControlsDisplay

var select_sound:AudioStream = preload("uid://cxg4q58es2u77")
var rotate_sound:AudioStream = preload("uid://c43qhby2kqxxj")
var current_wheel_value:int = 0

enum GameState {
	default,
	malfunction,
	crashing
}

var game_state: GameState = GameState.default

var target_floor:int:
	set(value):
		target_floor = value
		elevator_display.update_target_number(value)

const wheel1: Array[String] = ["DID", "YOU", "DO", "WHAT"]
const wheel2: Array[String] = ["TIME", "IS", "UP", "YOUR"]
const wheel3: Array[String] = ["FOR", "YOUR", "CRIMES", "PAY"]
const wheel4: Array[String] = ["IS", "NOT", "OVER", "THIS"]
var crash_wheel_text: Array = [wheel1, wheel2, wheel3, wheel4]
var crash_index: int = 0

const ELEVATOR_CLOSE = preload("uid://c5lku7hw2nms6")
const ELEVATOR_DING = preload("uid://cssc25e2x3h5e")
const ELEVATOR_OPEN = preload("uid://dg18ln6q08yio")

const ELEVATOR_MUSIC = preload("uid://dcew36o621vsa")
const ELEVATOR_MUSIC_MALFUNK = preload("uid://rbvunwp0obow")
const ELEVATOR_MUSIC_SPACE = preload("uid://b7tu3piaqxhmn")

#region Built-in Functions
func _ready() -> void:
	randomize()
	elevator_panel.floor_selected.connect(_floor_selected)
	elevator_shaft.animation_stack_completed.connect(_arrived_at_floor)
	elevator_shaft.animation_shake.connect(first_person_player.camera_shake)
	elevator_shaft.current_floor_changed.connect(elevator_display.update_current_number)
	# connects the new dir chosen signal to a lambda function that plays the selector sound 
	wheel_3d.new_dir_selected.connect(func():if wheel_3d.num_selections != wheel_3d.target_selections: Global._play_sound(select_sound))
	wheel_3d.new_dir_selected.connect(_base_slice_display)
	# connects our new dir chosen signal to the update wheel value function
	wheel_3d.new_dir_chosen.connect(update_wheel_value)
	# connects the dir confirmed signal to a lambda function that plays the confirm sound
	wheel_3d.rotation_started.connect(func():Global._play_sound(rotate_sound))
	# play some tunes :)
	wheel_3d.puzzle_finished.connect(_floor_selected_wheel)
	target_floor = randi_range(1, 24)
	Global._play_music(ELEVATOR_MUSIC)
#regionend

#region Elevator State Functions
func malfunction():
	game_state = GameState.malfunction
	elevator_shaft.animation_player.speed_scale = 2.0
	elevator_panel.malfunction()
	elevator_display.display_base(true)
	elevator_display.display_slice(true)
	elevator_display.display_x(true)
	headline_display.game_state = HeadlineDisplay.GameState.malfunction
	wheel_3d.covers_covered = [true, true, true, true]
	wheel_3d._state = wheel_3d.WheelState.NO_INPUT
	light_animation_player.play("flicker")
	Global._play_music(ELEVATOR_MUSIC_MALFUNK)

func crash():
	game_state = GameState.crashing
	elevator_shaft.animation_player.speed_scale = 1.0
	elevator_shaft.elevator_crash()
	light_animation_player.play("flicker_crash", -1, 3.0)
	headline_display.game_state = HeadlineDisplay.GameState.crash
	wheel_3d.new_dir_chosen.disconnect(update_wheel_value)
	wheel_3d.puzzle_finished.disconnect(_floor_selected_wheel)
	wheel_3d.new_dir_selected.disconnect(_base_slice_display)
	wheel_3d.new_dir_chosen.connect(_respond_to_executioner)
	elevator_display.jumble = true
	elevator_display.update_target_number("-inf")
	elevator_display.update_base_number("YES")
	elevator_display.update_slice_number("NO")
	elevator_display.display_x(false)
	crash_index = 0
	wheel_3d.slice_text = crash_wheel_text[crash_index]
	wheel_3d.covers_covered = [true, true, true, true]
	wheel_3d.randomize_slices = false
	wheel_3d.hide_covers_on_reset = false
	wheel_3d.target_selections = 1
	wheel_3d.base_numbers = [1, -2, 1, 2]
	Global._play_music(ELEVATOR_MUSIC_SPACE)

func reset():
	door_animation_player.play("RESET")
	light_animation_player.play("RESET")
	lobby.visible = true
	space.visible = false
	elevator_panel.reset()
	elevator_display.reset()
	controls_display.reset()
	elevator_shaft.reset()
	reset_wheel()
	headline_display.reset()
	first_person_player.reset()
	if not wheel_3d.new_dir_chosen.is_connected(update_wheel_value):
		wheel_3d.new_dir_chosen.connect(update_wheel_value)
	if not wheel_3d.puzzle_finished.is_connected(_floor_selected_wheel):
		wheel_3d.puzzle_finished.connect(_floor_selected_wheel)
	if not wheel_3d.new_dir_selected.is_connected(_base_slice_display):
		wheel_3d.new_dir_selected.connect(_base_slice_display)
	if wheel_3d.new_dir_chosen.is_connected(_respond_to_executioner):
		wheel_3d.new_dir_chosen.disconnect(_respond_to_executioner)
	target_floor = randi_range(1, 24)
	Global._play_music(ELEVATOR_MUSIC)
#endregion

#region Elevator Shaft and Panel Functions
func _floor_selected(target_floor_level: int):
	if elevator_shaft.target_floor_level == target_floor_level:
		if not elevator_panel.malfunctioned:
			elevator_panel.reset_choice()
		return
	elevator_shaft.target_floor_level = target_floor_level
	current_wheel_value = target_floor_level

func _floor_selected_wheel():
	if current_wheel_value == elevator_shaft.target_floor_level:
		reset_wheel()
	elevator_shaft.target_floor_level = current_wheel_value

func _arrived_at_floor():
	match game_state:
		GameState.default:
			if target_floor == elevator_shaft.target_floor_level:
				door_animation_player.play("open")
				Global._play_sound(ELEVATOR_OPEN)
				Global._play_sound(ELEVATOR_DING)
				ready_for_npc.emit()
			else:
				reset_wheel()
				if not elevator_panel.malfunctioned:
					elevator_panel.reset_choice()
		GameState.malfunction:
			if target_floor <= elevator_shaft.target_floor_level:
				door_animation_player.play("open")
				Global._play_sound(ELEVATOR_OPEN)
				Global._play_sound(ELEVATOR_DING)
				ready_for_npc.emit()
			else:
				reset_wheel()
#endregion

#region Wheel Functions
# the new_dir_chosen signal passes the current wheel value of the chosen segment
func update_wheel_value(_current_value):
	current_wheel_value += _current_value.total_value
	elevator_display.update_result_number(current_wheel_value)
	elevator_display.display_result(true)

func reset_wheel():
	elevator_display.display_result(false)
	if game_state != GameState.crashing:
		wheel_3d.randomize_slices = true
		wheel_3d.hide_covers_on_reset = true
	wheel_3d.reset()

func _respond_to_executioner(_current_value):
	wheel_3d.covers_covered = [true, true, true, true]
	crash_index = (crash_index + 1) % 4
	wheel_3d.slice_text = crash_wheel_text[crash_index]
	respond.emit(_current_value.current_direction)

func _base_slice_display():
	elevator_display.wheel_selection(wheel_3d._current_value)
#endregion
