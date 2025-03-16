extends TextureRect

@onready var logosetup: SubViewport = $"../../logosetup"

func _ready() -> void:
	var text = texture as ViewportTexture
	text.viewport_path = logosetup.get_path()
