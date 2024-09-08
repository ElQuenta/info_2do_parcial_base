extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
var special_vertical = [
	preload("res://scenes/blue_specials/vertical.tscn"),
	preload("res://scenes/green_specials/vertical.tscn"),
	preload("res://scenes/light_green_specials/vertical.tscn"),
	preload("res://scenes/orange_specials/vertical.tscn"),
	preload("res://scenes/pink_specials/vertical.tscn"),
]
var special_horizontal = [
	preload("res://scenes/blue_specials/horizontal.tscn"),
	preload("res://scenes/green_specials/horizontal.tscn"),
	preload("res://scenes/light_green_specials/horizontal.tscn"),
	preload("res://scenes/orange_specials/horizontal.tscn"),
	preload("res://scenes/pink_specials/horizontal.tscn"),
]
var special_all = [
	preload("res://scenes/blue_specials/all.tscn"),
	preload("res://scenes/green_specials/all.tscn"),
	preload("res://scenes/light_green_specials/all.tscn"),
	preload("res://scenes/orange_specials/all.tscn"),
	preload("res://scenes/pink_specials/all.tscn"),
]
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# scoring variables and signals
var score = 0
var still_playing = true
var special_pieces_to_spawn = []

# counter variables and signals
signal current_score(score:int)
signal current_move()

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	if not still_playing:
		return
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		emit_signal("current_move")
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)
		

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func find_matches():
	var matches = []
	# Detectar matches horizontales
	for j in height:
		var start = 0
		while start < width:
			if all_pieces[start][j] == null:
				start += 1
				continue 
			var current_color = all_pieces[start][j].color
			var match_length = 1
			# Verificar piezas consecutivas del mismo color
			while start + match_length < width and all_pieces[start + match_length][j] != null and all_pieces[start + match_length][j].color == current_color:
				match_length += 1
			# Si el tamaño del match es 3 o más, agregar a matches
			if match_length >= 3:
				var tempMatch = []
				for k in range(match_length):
					tempMatch.append(all_pieces[start + k][j])
				matches.append(tempMatch)
			# Avanzar al siguiente posible match
			start += match_length
# Detectar matches verticales
	for i in width:
		var start = 0
		while start < height:
			if all_pieces[i][start] == null:
				start += 1
				continue
			var current_color = all_pieces[i][start].color
			var match_length = 1
			# Verificar piezas consecutivas del mismo color
			while start + match_length < height and all_pieces[i][start + match_length] != null and all_pieces[i][start + match_length].color == current_color:
				match_length += 1
			# Si el tamaño del match es 3 o más, agregar a matches
			if match_length >= 3:
				var tempMatch = []
				for k in range(match_length):
					tempMatch.append(all_pieces[i][start + k])
				matches.append(tempMatch)
			# Avanzar al siguiente posible match
			start += match_length
	# Aumentar el puntaje según el tamaño del match
	for match in matches:
		score += match.size() * 10
		print("Match size is:", match.size())
		if match.size() == 4:
			special_pieces_to_spawn.append({"color": match[0].color, "type": "vertical", position: match[0].position})
		elif match.size() == 5:
			special_pieces_to_spawn.append({"color": match[0].color, "type": "all", position: match[0].position})
	# Marcar piezas como "matched"
	for match in matches:
		for piece in match:
			piece.matched = true
	# Iniciar el temporizador para destruir las piezas
	get_parent().get_node("destroy_timer").start()

	
func destroy_matched():
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
				
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				if special_pieces_to_spawn.size() > 0:
					var special_piece = special_pieces_to_spawn.pop_front()
					if special_piece.type == "horizontal":
						match special_piece.color:
							"blue":
								piece = special_horizontal[0].instantiate()
							"green":
								piece = special_horizontal[1].instantiate()
							"light_green":
								piece = special_horizontal[2].instantiate()
							"orange":
								piece = special_horizontal[3].instantiate()
							"pink":
								piece = special_horizontal[4].instantiate()
					elif special_piece.type == "vertical":
						match special_piece.color:
							"blue":
								piece = special_vertical[0].instantiate()
							"green":
								piece = special_vertical[1].instantiate()
							"light_green":
								piece = special_vertical[2].instantiate()
							"orange":
								piece = special_vertical[3].instantiate()
							"pink":
								piece = special_vertical[4].instantiate()
					elif special_piece.type == "all":
						match special_piece.color:
							"blue":
								piece = special_all[0].instantiate()
							"green":
								piece = special_all[1].instantiate()
							"light_green":
								piece = special_all[2].instantiate()
							"orange":
								piece = special_all[3].instantiate()
							"pink":
								piece = special_all[4].instantiate()
					piece.position = special_piece.position
				else:
					piece.position = grid_to_pixel(i, j - y_offset)
					piece.move(grid_to_pixel(i, j))
				add_child(piece)
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	current_score.emit(score)
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	print("game over")
	still_playing = false
	$"../game_over_timer".paused = true


func _on_game_over_timer_timeout():
	game_over()


func _on_top_ui_last_move():
	game_over()
