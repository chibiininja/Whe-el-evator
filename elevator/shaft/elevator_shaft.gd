class_name ElevatorShaft extends Node3D

signal animation_stack_completed()
signal animation_shake(anim_name: String)
signal current_floor_changed(current_floor_level: int)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum ElevatorState {
	down,
	up
}

var elevator_state: ElevatorState = ElevatorState.down
var animation_stack: Array[String] = []
var target_floor_level: int = 0:
	set(value):
		_update_floor_animation(value)
		target_floor_level = value
var current_floor: int = 0:
	set(value):
		current_floor = value
		current_floor_changed.emit(value)

func _ready() -> void:
	animation_player.animation_finished.connect(_check_animation_stack)

func elevator_crash():
	animation_player.play("shake")
	animation_stack.push_front("scroll_loop")

func reset():
	target_floor_level = 0
	animation_stack.clear()
	animation_player.stop()

func _check_animation_stack(_anim_name: StringName):
	if _anim_name.contains("scroll"):
		if _anim_name.contains("fall"):
			current_floor -= 1
		elif _anim_name.contains("rise"):
			current_floor += 1
		elif elevator_state == ElevatorState.up:
			current_floor += 1
		else:
			current_floor -= 1
	if animation_stack.size() != 0:
		var animation_name: String = animation_stack.pop_front()
		if animation_name.contains("shake"):
			animation_shake.emit(animation_name)
		if animation_name == "scroll" or animation_name == "scroll_once":
			if elevator_state == ElevatorState.up:
				animation_player.play(animation_name)
			else:
				animation_player.play_backwards(animation_name)
		else:
			animation_player.play(animation_name)
	else:
		animation_stack_completed.emit()

func _update_floor_animation(value: int)->void:
	if target_floor_level == value:
		return
	elevator_state = ElevatorState.up if target_floor_level < value else ElevatorState.down
	animation_player.play("shake")
	animation_shake.emit("shake")
	animation_stack.push_back("shake_rise" if elevator_state == ElevatorState.up else "shake_fall")
	if abs(value-target_floor_level) == 1:
		animation_stack.push_front("scroll_once")
	else:
		animation_stack.push_front("scroll_rise_end" if elevator_state == ElevatorState.up else "scroll_fall_end")
		for x:int in abs(value-target_floor_level)-2:
			animation_stack.push_front("scroll")
		animation_stack.push_front("scroll_rise" if elevator_state == ElevatorState.up else "scroll_fall")
