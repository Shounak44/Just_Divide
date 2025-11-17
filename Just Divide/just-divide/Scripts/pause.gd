extends TextureButton

@onready var pause_menu = $"../CanvasLayer/PauseMenu"

func _ready():
	connect("pressed", _on_pause_pressed)

func _on_pause_pressed():
	pause_menu.show()
	get_tree().paused = true
