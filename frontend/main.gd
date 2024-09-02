extends Node2D

var game_paused = true
var playerview_scene = preload('res://playerview.tscn')
var playerview

var points = [ 100, 200, 300, 400, 500 ] # duplicated in playerview.gd
var current_question = []

var current_revealed_category = -1
var buzzers_enabled = false

@onready var questions := $questions

@onready var toggle_intro_screen := $"toggle intro screen"
@onready var question_category := $question_category
@onready var question_value := $question_value
@onready var question := $question
@onready var reveal_category := $reveal_cat
@onready var note := $note
@onready var question_done := $question_done
@onready var buzzer_toggle_btn := $buzzer_toggle_btn
@onready var reveal_category_buttons := $reveal_category_buttons

var data = JSON.parse_string(FileAccess.open("../jeopardy.json", FileAccess.READ).get_as_text())
var categories = data ["categories"]

func _ready() -> void:
	print("main ready")
	var win = get_window()
	win.gui_embed_subwindows = false
	
	var playerwin = Window.new()
	playerwin.size = get_tree().root.size
	playerview = playerview_scene.instantiate()
	playerview.init_game(data)

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
	btn.text = str(points[q])
	btn.pressed.connect(Callable(self, "show_question").bind(cat, q))
	btn.disabled = true
	return btn
	
func show_question(cat_idx, question_idx):
	if current_question:
		# state
		current_question = null
		disable_buzzers()
		buzzer_toggle_btn.disabled = true
		
		# ui
		playerview.hide_question()
		question_done.disabled = true
		buzzer_toggle_btn.disabled = true
		
		question_category.text = "Question category"
		question.text = "Question"
		question_value.text = "---"
		note.text = "---"
	else:
		question_done.disabled = false
		disable_buzzers()
		buzzer_toggle_btn.disabled = false

		question_category.text = categories[cat_idx]["name"]
		current_question = [cat_idx, question_idx]
		question_value.text = str(points[question_idx])
		question.text = categories[cat_idx]["questions"][question_idx]["q"]
		if "n" in categories[cat_idx]["questions"][question_idx]:
			note.text = categories[cat_idx]["questions"][question_idx]["n"]
		else:
			note.text = "---"
		playerview.show_question(cat_idx, question_idx)
	
func _process(_delta: float) -> void:
	pass
	
func on_toggle_intro_screen_pressed() -> void:
	game_paused = !game_paused
	if game_paused:
		toggle_intro_screen.text = "Unpause game"
		playerview.pause_game()
		for btn in reveal_category_buttons.get_children():
			btn.disabled = true
		for btn in questions.get_children():
			btn.disabled = true
	
	else:
		toggle_intro_screen.text = "Pause game"
		for btn in reveal_category_buttons.get_children():
			btn.disabled = false
		if all_categories_revealed():
			for btn in questions.get_children():
				btn.disabled = false
		
		playerview.start_game()
		
func all_categories_revealed():
	return current_revealed_category == 5

func on_reveal_next_category_pressed() -> void:
	if current_revealed_category < 5:
		current_revealed_category += 1
		if current_revealed_category < 5:
			playerview.reveal_category(current_revealed_category)
		else:
			playerview.hide_categories_slider()
			playerview.show_category_names()
			for btn in questions.get_children():
				btn.disabled = false
			
	
func on_reveal_previous_category_pressed() -> void:
	if current_revealed_category >= 0:
		current_revealed_category -= 1
		if current_revealed_category >= 0:
			playerview.reveal_category(current_revealed_category)
		else:
			playerview.hide_categories_slider()
	for btn in questions.get_children():
		btn.disabled = true
		
func on_random_team_pressed() -> void:
	playerview.select_random_team()

func _on_team_correct_pressed(team_idx: int) -> void:
	if current_question:
		playerview.scoreboard.increase_score(team_idx, points[current_question[1]])
		mark_question_completed()
	current_question = null
	disable_answer_grading_buttons()
	question_done.disabled = true
	buzzer_toggle_btn.disabled = true

	
	
func mark_question_completed():
	if current_question:
		var btn = get_question_button(current_question[0], current_question[1])
		btn.text = "---"
		playerview.mark_question_completed(current_question[0], current_question[1])
		playerview.hide_question()
		current_question = null
	
func get_question_button(cat_idx, question_idx):
	return questions.get_child(question_idx * 5 + cat_idx)
	
func _on_team_wrong_pressed(team_idx: int) -> void:
	if current_question:
		playerview.scoreboard.decrease_score(team_idx, points[current_question[1]])
		enable_buzzers()

func _on_manual_score_increase(team_idx: int) -> void:
	playerview.scoreboard.increase_score(team_idx, 100)

func _on_manual_score_decrease(team_idx: int) -> void:
	playerview.scoreboard.decrease_score(team_idx, 100)

func toggle_buzzers() -> void:
	if buzzers_enabled:
		disable_buzzers()
	else:
		enable_buzzers()

func enable_buzzers():
	buzzers_enabled = true
	buzzer_toggle_btn.text = "Disable buzzers"
	playerview.scoreboard.unselect_team()

func disable_buzzers():
	buzzers_enabled = false
	buzzer_toggle_btn.text = "Enable buzzers"

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			handle_buzzer(0)
		elif event.keycode == KEY_B:
			handle_buzzer(1)
		elif event.keycode == KEY_C:
			handle_buzzer(2)

func handle_buzzer(team_idx):
	if not buzzers_enabled:
		print("Team ", team_idx, " pressed buzzer early")
		# TODO: penalize team by making their buzzer unavailable for .5 sec
		return
		
	disable_buzzers()
	playerview.scoreboard.highlight_team(team_idx)
	
	enable_answer_grading_buttons()
	
func enable_answer_grading_buttons():
	$GridContainer/team_1_correct.disabled = false
	$GridContainer/team_2_correct.disabled = false
	$GridContainer/team_3_correct.disabled = false
	$GridContainer/team_1_wrong.disabled = false
	$GridContainer/team_2_wrong.disabled = false
	$GridContainer/team_3_wrong.disabled = false

func disable_answer_grading_buttons():
	$GridContainer/team_1_correct.disabled = true
	$GridContainer/team_2_correct.disabled = true
	$GridContainer/team_3_correct.disabled = true
	$GridContainer/team_1_wrong.disabled = true
	$GridContainer/team_2_wrong.disabled = true
	$GridContainer/team_3_wrong.disabled = true
