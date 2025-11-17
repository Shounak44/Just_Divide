extends Control

var grid: Array = []
var grid_tiles: Array = []
var grid_slots: Array = []

var current_tile: Tile = null
var queue: Array = [0, 0]
var preview_tile1: Tile = null
var preview_tile2: Tile = null
var kept_tile: Tile = null
var score: int = 0
var level: int = 1
var trash_count: int = 10
var undo_stack: Array = []

@onready var grid_container = $Grid
@onready var level_label = $CatAndStats/LevelBadge/Label
@onready var score_label = $CatAndStats/ScoreBadge/Label
@onready var display1 = $Display1
@onready var display2 = $Display2
@onready var trash_count_label = $Label3
@onready var keep_slot = $Keep
@onready var keep_tile_slot = $Keep/MarginContainer/KeepTile
@onready var trash_slot = $Trash
@onready var undo_button = $UndoButton
@onready var voices = $Voices
@onready var lose_canvas = $Lose
@onready var play_again_button = $Lose/LoseMenu/Panel/Play_Again
@onready var info_button = $Info
@onready var info_audio = $Info/AudioStreamPlayer2D

var TileScene = preload("res://Scenes/Tile.tscn")

# Preload voice audio files
var voice_great = preload("res://Assets/music/Voices/GREAT.mp3")
var voice_nice = preload("res://Assets/music/Voices/NICE.mp3")
var voice_wow = preload("res://Assets/music/Voices/WOW.mp3")
var voice_fantastic = preload("res://Assets/music/Voices/FANTASTIC.mp3")

func _ready():
	randomize()
	init_grid()
	generate_queue()
	spawn_tile()
	update_ui()
	
	if undo_button:
		undo_button.pressed.connect(do_undo)
	
	if play_again_button:
		play_again_button.pressed.connect(restart_game)
	
	if info_button:
		info_button.pressed.connect(play_info_audio)
	
	if lose_canvas:
		lose_canvas.visible = false

func init_grid():
	grid.resize(16)
	grid_tiles.resize(16)
	grid_slots.resize(16)
	
	for i in range(16):
		grid[i] = 0
		grid_tiles[i] = null
		grid_slots[i] = grid_container.get_child(i)

func generate_queue():
	queue[0] = random_value()
	queue[1] = random_value()
	update_previews()

func random_value() -> int:
	# Base numbers (Level 1: 2/10 difficulty)
	var vals = [2, 3, 4, 6]
	
	# Level 2+: 4/10 difficulty - Add medium numbers
	if level >= 2:
		vals += [8, 9]
	
	# Level 3+: 5/10 difficulty - Add harder numbers
	if level >= 3:
		vals += [12, 15]
	
	# Level 4+: 6/10 difficulty - Add challenging numbers
	if level >= 4:
		vals += [18, 20]
	
	# Level 5+: 7/10 difficulty - Add tough numbers
	if level >= 5:
		vals += [24, 27]
	
	# Level 6+: 8/10 difficulty - Add very hard numbers
	if level >= 6:
		vals += [32, 36]
	
	# Level 7+: 9/10 difficulty - Add extreme numbers
	if level >= 7:
		vals += [40, 45, 48]
	
	# Level 8+: 10/10 difficulty - Maximum challenge (continues endlessly)
	if level >= 8:
		vals += [54, 60, 72, 80, 90, 96]
	
	# Level 10+: Ultra difficulty (endless scaling)
	if level >= 10:
		vals += [100, 108, 120, 144]
	
	# Level 12+: Extreme difficulty (keeps getting harder)
	if level >= 12:
		vals += [150, 180, 200, 240]
	
	# Level 15+: Insane difficulty (endless progression)
	if level >= 15:
		vals += [300, 360, 400, 480]
	
	return vals[randi() % vals.size()]

func update_previews():
	# Clean up old previews
	if preview_tile1:
		preview_tile1.queue_free()
	if preview_tile2:
		preview_tile2.queue_free()
	
	# Preview 1 - Shows queue[0] (current tile value)
	preview_tile1 = TileScene.instantiate()
	preview_tile1.set_value(queue[0])
	preview_tile1.is_placed = true
	add_child(preview_tile1)
	preview_tile1.global_position = display1.global_position + (display1.size - preview_tile1.size) / 2
	preview_tile1.z_index = -10
	preview_tile1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Preview 2 - Shows queue[1] (next tile value)
	preview_tile2 = TileScene.instantiate()
	preview_tile2.set_value(queue[1])
	preview_tile2.is_placed = true
	add_child(preview_tile2)
	preview_tile2.global_position = display2.global_position + (display2.size - preview_tile2.size) / 2
	preview_tile2.z_index = 5
	preview_tile2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	print("📺 Display1: ", queue[0], " | Display2: ", queue[1])

func spawn_tile():
	# Spawn the draggable tile with queue[0] value
	current_tile = TileScene.instantiate()
	current_tile.set_value(queue[0])
	add_child(current_tile)
	current_tile.global_position = display1.global_position + (display1.size - current_tile.size) / 2
	current_tile.z_index = 0
	current_tile.tile_dropped.connect(_on_dropped)
	
	print("🎲 Spawned draggable tile: ", current_tile.value)

func advance_queue():
	# Move queue forward: queue[1] becomes queue[0], generate new queue[1]
	queue[0] = queue[1]
	queue[1] = random_value()
	update_previews()
	
	print("➡️ Queue advanced | Display1: ", queue[0], " | Display2: ", queue[1])

func play_solve_voice():
	# Play random voice for regular solves (GREAT, NICE, WOW)
	var random_voices = [voice_great, voice_nice, voice_wow]
	var selected_voice = random_voices[randi() % random_voices.size()]
	voices.stream = selected_voice
	voices.play()

func play_level_up_voice():
	# Play FANTASTIC voice for level ups
	voices.stream = voice_fantastic
	voices.play()

func play_info_audio():
	if info_audio:
		info_audio.play()
		print("ℹ️ Playing info audio")

func _on_kept_tile_dropped(tile: Tile, pos: Vector2):
	# Kept tiles can ONLY go to grid, not back to display or keep
	var cell = -1
	var closest_distance = 999999.0
	
	for i in range(16):
		var slot_center = grid_slots[i].global_position + grid_slots[i].size / 2
		var distance = pos.distance_to(slot_center)
		
		if distance < closest_distance and distance < 60:
			closest_distance = distance
			cell = i
	
	# If no valid cell or cell occupied, return to keep position
	if cell == -1 or grid[cell] != 0:
		print("↩️ Kept tile returned to keep slot")
		tile.scale = Vector2(0.7, 0.7)  # Keep the scale when returning
		tile.global_position = Vector2(1008.0, 375.0)
		tile.is_dragging = false
		return
	
	# Place on grid
	save_state()
	
	# Keep the 0.7 scale instead of resetting to 1.0
	tile.scale = Vector2(0.7, 0.7)
	grid[cell] = tile.value
	grid_tiles[cell] = tile
	var center = grid_slots[cell].global_position + (grid_slots[cell].size - tile.size) / 2
	tile.snap_to(center)
	kept_tile = null  # Clear kept_tile reference
	
	print("✅ Placed kept tile ", tile.value, " at cell ", cell)
	
	await get_tree().create_timer(0.2).timeout
	process_merges(cell)
	update_ui()
	check_level()
	update_ui()
	
	# Check if game is over
	check_game_over()

func _on_dropped(tile: Tile, pos: Vector2):
	# Check TRASH
	var trash_rect = Rect2(trash_slot.global_position, trash_slot.size).grow(20)
	if trash_rect.has_point(pos):
		if trash_count > 0:
			trash_count -= 1
			print("🗑️ Trashed! x", trash_count)
		tile.queue_free()
		current_tile = null
		advance_queue()  # Move queue forward
		spawn_tile()     # Spawn new tile
		update_ui()
		return
	
	# Check KEEP
	var keep_rect = Rect2(keep_slot.global_position, keep_slot.size).grow(20)
	if keep_rect.has_point(pos):
		# Only allow placing from current_tile (Display1), not from kept_tile
		if tile != current_tile:
			print("❌ Can't move kept tile back to keep")
			tile.global_position = Vector2(1008.0, 375.0)  # Return to keep position
			return
		
		if kept_tile:
			kept_tile.queue_free()
		
		kept_tile = tile
		tile.scale = Vector2(0.7, 0.7)
		tile.global_position = Vector2(1008.0, 375.0)
		tile.is_placed = false  # Keep it draggable
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.tile_dropped.disconnect(_on_dropped)  # Disconnect old signal
		tile.tile_dropped.connect(_on_kept_tile_dropped)  # Connect to new handler
		current_tile = null
		
		print("📦 Kept: ", tile.value)
		advance_queue()  # Move queue forward
		spawn_tile()     # Spawn new tile
		return
	
	# Check GRID
	var cell = -1
	var closest_distance = 999999.0
	
	for i in range(16):
		var slot_center = grid_slots[i].global_position + grid_slots[i].size / 2
		var distance = pos.distance_to(slot_center)
		
		if distance < closest_distance and distance < 60:
			closest_distance = distance
			cell = i
	
	# If no valid cell found or cell is occupied, return tile to display1
	if cell == -1 or grid[cell] != 0:
		print("↩️ Tile returned to display")
		tile.global_position = display1.global_position + (display1.size - tile.size) / 2
		tile.z_index = 0
		tile.is_dragging = false
		return
	
	# Place on grid
	save_state()
	
	grid[cell] = tile.value
	grid_tiles[cell] = tile
	var center = grid_slots[cell].global_position + (grid_slots[cell].size - tile.size) / 2
	tile.snap_to(center)
	current_tile = null
	
	print("✅ Placed ", tile.value, " at cell ", cell)
	
	await get_tree().create_timer(0.2).timeout
	process_merges(cell)
	update_ui()
	check_level()
	
	advance_queue()  # Move queue forward AFTER placement
	spawn_tile()     # Spawn new tile
	update_ui()
	
	# Check if game is over
	check_game_over()

func process_merges(cell: int):
	var val = grid[cell]
	if val == 0:
		return
	
	var neighbors = get_neighbors(cell)
	
	# STEP 1: Equal tiles
	var equals = []
	for n in neighbors:
		if grid[n] == val:
			equals.append(n)
	
	if equals.size() > 0:
		print("💥 EQUAL: ", val, " | +", equals.size(), " points")
		remove_tile(cell)
		for n in equals:
			remove_tile(n)
		score += equals.size()
		play_solve_voice()  # Play random voice for solve
		await get_tree().create_timer(0.1).timeout
		update_ui()
		check_level()
	
	# STEP 2: Division
	for n in neighbors:
		if grid[n] == 0:
			continue
		
		var bigger = max(val, grid[n])
		var smaller = min(val, grid[n])
		
		if bigger % smaller == 0:
			var result = int(bigger / float(smaller))
			var big_cell = cell if grid[cell] == bigger else n
			var small_cell = n if grid[cell] == bigger else cell
			
			print("⚡ DIV: ", bigger, "÷", smaller, "=", result, " | +2 points")
			
			remove_tile(small_cell)
			score += 2
			play_solve_voice()  # Play random voice for solve
			
			if result == 1:
				remove_tile(big_cell)
			else:
				grid[big_cell] = result
				if grid_tiles[big_cell]:
					grid_tiles[big_cell].set_value(result)
				
				await get_tree().create_timer(0.15).timeout
				process_merges(big_cell)
			
			update_ui()
			check_level()
			return

func get_neighbors(i: int) -> Array:
	var n = []
	var row = int(i / 4.0)
	var col = i % 4
	
	if col > 0: n.append(i - 1)
	if col < 3: n.append(i + 1)
	if row > 0: n.append(i - 4)
	if row < 3: n.append(i + 4)
	
	return n

func remove_tile(i: int):
	grid[i] = 0
	if grid_tiles[i]:
		grid_tiles[i].queue_free()
		grid_tiles[i] = null

func save_state():
	# Save complete game state including queue and kept tile
	var kept_value = 0
	if kept_tile:
		kept_value = kept_tile.value
	
	var state = {
		"grid": grid.duplicate(),
		"score": score,
		"level": level,
		"trash": trash_count,
		"queue": queue.duplicate(),
		"kept_value": kept_value
	}
	undo_stack.append(state)
	if undo_stack.size() > 10:
		undo_stack.pop_front()

func do_undo():
	if undo_stack.size() == 0:
		print("❌ No undo available")
		return
	
	# Remove current tile if exists
	if current_tile:
		current_tile.queue_free()
		current_tile = null
	
	# Remove kept tile if exists
	if kept_tile:
		kept_tile.queue_free()
		kept_tile = null
	
	var state = undo_stack.pop_back()
	grid = state.grid.duplicate()
	score = state.score
	level = state.level
	trash_count = state.trash
	queue = state.queue.duplicate()
	
	# Restore grid tiles
	for i in range(16):
		if grid_tiles[i]:
			grid_tiles[i].queue_free()
			grid_tiles[i] = null
	
	for i in range(16):
		if grid[i] > 0:
			var t = TileScene.instantiate()
			t.set_value(grid[i])
			add_child(t)
			var pos = grid_slots[i].global_position + (grid_slots[i].size - t.size) / 2
			t.snap_to(pos)
			grid_tiles[i] = t
	
	# Restore kept tile
	if state.kept_value > 0:
		kept_tile = TileScene.instantiate()
		kept_tile.set_value(state.kept_value)
		add_child(kept_tile)
		kept_tile.scale = Vector2(0.7, 0.7)
		kept_tile.global_position = Vector2(1008.0, 375.0)
		kept_tile.is_placed = false  # Keep it draggable
		kept_tile.mouse_filter = Control.MOUSE_FILTER_STOP
		kept_tile.tile_dropped.connect(_on_kept_tile_dropped)
	
	# Update previews and spawn new tile
	update_previews()
	spawn_tile()
	update_ui()
	print("⏪ UNDO")

func check_level():
	# Level up every 10 points
	var new_level = int(score / 10.0) + 1
	if new_level > level:
		level = new_level
		trash_count += 2
		play_level_up_voice()  # Play FANTASTIC voice for level up
		print("🎉 LEVEL ", level, " | Difficulty increased!")

func update_ui():
	level_label.text = "LEVEL " + str(level)
	score_label.text = "SCORE " + str(score)
	trash_count_label.text = "x" + str(trash_count)

func _input(event):
	if event.is_action_pressed("ui_select"):
		toggle_hints()

func toggle_hints():
	for i in range(16):
		if grid[i] == 0:
			grid_slots[i].modulate = Color(1, 1, 0, 0.5)
		else:
			grid_slots[i].modulate = Color(1, 1, 1, 1)

func check_game_over():
	# Check if grid is full
	var grid_full = true
	for i in range(16):
		if grid[i] == 0:
			grid_full = false
			break
	
	if not grid_full:
		return
	
	# Grid is full, check if any moves are possible
	for i in range(16):
		var val = grid[i]
		var neighbors = get_neighbors(i)
		
		# Check for equal neighbors
		for n in neighbors:
			if grid[n] == val:
				return  # Move possible, game continues
		
		# Check for division possibilities
		for n in neighbors:
			var bigger = max(val, grid[n])
			var smaller = min(val, grid[n])
			
			if bigger % smaller == 0:
				return  # Move possible, game continues
	
	# No moves possible, game over
	game_over()

func game_over():
	print("💀 GAME OVER!")
	
	# Remove current tile
	if current_tile:
		current_tile.queue_free()
		current_tile = null
	
	# Show lose screen
	if lose_canvas:
		lose_canvas.visible = true

func restart_game():
	print("🔄 Restarting game...")
	
	# Hide lose screen
	if lose_canvas:
		lose_canvas.visible = false
	
	# Remove all tiles
	for i in range(16):
		if grid_tiles[i]:
			grid_tiles[i].queue_free()
			grid_tiles[i] = null
	
	# Remove current tile
	if current_tile:
		current_tile.queue_free()
		current_tile = null
	
	# Remove kept tile
	if kept_tile:
		kept_tile.queue_free()
		kept_tile = null
	
	# Remove preview tiles
	if preview_tile1:
		preview_tile1.queue_free()
		preview_tile1 = null
	if preview_tile2:
		preview_tile2.queue_free()
		preview_tile2 = null
	
	# Reset game state
	score = 0
	level = 1
	trash_count = 10
	undo_stack.clear()
	
	# Reinitialize
	init_grid()
	generate_queue()
	spawn_tile()
	update_ui()
