extends Node2D

var playerview_scene = preload('res://playerview.tscn')
var playerview

var points = [ 100, 200, 300, 400, 500 ] # duplicated in playerview.gd
var current_question_points = null

@onready var questions := $questions

@onready var question_category := $question_category
@onready var question_value := $question_value
@onready var question := $question
@onready var note := $note

var data = JSON.parse_string(FileAccess.open("../jeopardy.json", FileAccess.READ).get_as_text())
var categories = data ["categories"]

func _ready() -> void:
	var win = get_window()
	win.gui_embed_subwindows = false
	
	var playerwin = Window.new()
	playerwin.size = get_tree().root.size
	playerview = playerview_scene.instantiate()
	playerwin.add_child(playerview)
	
	add_child(playerwin)
	
	playerwin.content_scale_aspect = win.content_scale_aspect
	playerwin.content_scale_mode = win.content_scale_mode
	playerwin.content_scale_size = win.content_scale_size
	playerwin.size = win.size

	playerwin.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	for q in range(5):
		for cat in range(5):
			questions.add_child(create_question_button(cat, q))
	
func create_question_button(cat, q):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = "??"
	btn.pressed.connect(Callable(self, "show_question").bind(cat, q))
	#btn.pressed.connect(self.show_question)
	return btn
	
func show_question(cat_idx, question_idx):
	if current_question_points:
		current_question_points = null
		playerview.hide_question()
	else:
		question_category.text = categories[cat_idx]["name"]
		current_question_points = points[question_idx]
		question_value.text = str(points[question_idx])
		question.text = categories[cat_idx]["questions"][question_idx]["q"]
		if "n" in categories[cat_idx]["questions"][question_idx]:
			note.text = categories[cat_idx]["questions"][question_idx]["n"]
		else:
			note.text = "---"
		playerview.show_question(cat_idx, question_idx)
	
func _process(_delta: float) -> void:
	pass
	
func _on_start_game_pressed() -> void:
	playerview.init_game(data)

func on_reveal_category_pressed(cat_idx: int) -> void:
	playerview.reveal_category(cat_idx)

func on_random_team_pressed() -> void:
	playerview.select_random_team()


func _on_team_correct_pressed(team_idx: int) -> void:
	if current_question_points:
		print("should add ", current_question_points)
		playerview.scoreboard.increase_score(team_idx, current_question_points)
		playerview.hide_question()
	current_question_points = null
	
func _on_team_wrong_pressed(team_idx: int) -> void:
	if current_question_points:
		playerview.scoreboard.decrease_score(team_idx, current_question_points)
		playerview.hide_question()
	current_question_points = null
