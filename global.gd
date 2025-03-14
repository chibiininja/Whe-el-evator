extends Node

enum GameState {
	FirstPerson,
	UI
}
var game_state: GameState = GameState.FirstPerson

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and game_state == GameState.FirstPerson and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
