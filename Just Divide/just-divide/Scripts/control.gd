extends Control

@onready var resume_button = $ResumeButton
@onready var home_button = $HomeButton

func _ready():
	hide()

	# IMPORTANT: allowing the pause menu to work while paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	home_button.process_mode   = Node.PROCESS_MODE_WHEN_PAUSED

	resume_button.pressed.connect(_on_resume_pressed)
	home_button.pressed.connect(_on_home_pressed)

func _on_resume_pressed():
	get_tree().paused = false
	hide()

func _on_home_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/title.tscn")
