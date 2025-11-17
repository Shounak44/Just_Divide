extends Control
class_name Tile

var value: int = 2
var is_dragging: bool = false
var drag_offset: Vector2
var is_placed: bool = false

signal tile_dropped(tile, drop_pos)

func _ready():
	set_value(value)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_value(val: int):
	value = val
	$CenterContainer/NumberLabel.text = str(value)
	update_color()

func update_color():
	# Use your tile sprites here
	var sprite_path = ""
	if value >= 30:
		sprite_path = "res://Assets/Tiles/red.png"
	elif value >= 20:
		sprite_path = "res://Assets/Tiles/purple.png"
	elif value >= 10:
		sprite_path = "res://Assets/Tiles/orange.png"
	elif value >= 6:
		sprite_path = "res://Assets/Tiles/pink.png"
	else:
		sprite_path = "res://Assets/Tiles/blue.png"
	
	# If using TextureRect as background
	if has_node("Panel/Background"):
		$Panel/Background.texture = load(sprite_path)

func _gui_input(event):
	if is_placed:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag()
		else:
			end_drag()

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func start_drag():
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	z_index = 1000

func end_drag():
	is_dragging = false
	z_index = 0
	tile_dropped.emit(self, get_global_mouse_position())

func snap_to(pos: Vector2):
	global_position = pos
	is_placed = true
	is_dragging = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
