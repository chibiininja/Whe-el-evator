extends Node3D

@onready var elevator_panel: ElevatorPanel = $ElevatorPanel
@onready var elevator_display: ElevatorDisplay = $ElevatorDisplay
@onready var elevator_shaft: ElevatorShaft = $ElevatorShaft
@onready var first_person_player: Player = $FirstPersonPlayer

func _ready() -> void:
	elevator_panel.floor_selected.connect(_floor_selected)
	elevator_shaft.animation_stack_completed.connect(_arrived_at_floor)
	elevator_shaft.animation_stack_completed.connect(func(): elevator_display.display_result(false))
	elevator_shaft.animation_shake.connect(first_person_player.camera_shake)
	elevator_shaft.current_floor_changed.connect(elevator_display.update_current_number)

func _floor_selected(target_floor_level: int):
	if elevator_shaft.target_floor_level == target_floor_level:
		if not elevator_panel.malfunctioned:
			elevator_panel.reset_choice()
		return
	elevator_shaft.target_floor_level = target_floor_level

func _arrived_at_floor():
	elevator_panel.reset_choice()
