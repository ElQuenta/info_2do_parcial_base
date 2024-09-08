extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var move_lavel = $MarginContainer/HBoxContainer/move_lavel

var current_score = 0
var current_count = 0
@export var current_moves = 30

signal lastMove()

func _ready():
	move_lavel.text = str(current_moves).pad_zeros(2)

func _process(delta):
	counter_label.text = str(int($"../game_over_timer".time_left)).pad_zeros(3)

func _on_grid_current_score(score):
	current_score = score
	score_label.text = str(current_score).pad_zeros(4)


func _on_grid_current_move():
	current_moves-=1
	move_lavel.text = str(current_moves).pad_zeros(2)
	if current_moves <= 0:
		lastMove.emit()
