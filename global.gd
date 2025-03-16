extends Node

enum GameState {
	FirstPerson,
	UI
}
var game_state: GameState = GameState.UI
var camera: Camera3D
var bg_msc:AudioStreamPlayer

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and game_state == GameState.FirstPerson and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#region Helper Functions
# helper function that plays our sounds modulated at a random pitch range of 0.95-1.05
func _play_sound(sound:AudioStream)->void:
	randomize()
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.pitch_scale = randf_range(0.95,1.05)
	self.add_child(player)
	player.play()
	player.finished.connect(func():player.queue_free())

func _play_speech(sound:AudioStream, base_pitch:float)->void:
	randomize()
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.pitch_scale = base_pitch + randf_range(-0.05,0.05)
	player.volume_db = -10
	self.add_child(player)
	player.play()
	player.finished.connect(func():player.queue_free())

# plays the background music in a loop dependant on the checkbox enabling it.
func _play_music(music:AudioStream) -> void:
	if bg_msc == null:
		bg_msc = AudioStreamPlayer.new()
		self.add_child(bg_msc)
	if bg_msc.stream == music:
		return
	bg_msc.stream = music
	bg_msc.pitch_scale = 1.02
	bg_msc.volume_db = -20
	bg_msc.play()
#endregion
