extends Node2D

var game_is_paused = true
var playerview_scene = preload('res://playerview.tscn')
var playerview

var points = [ 100, 200, 300, 400, 500 ] # duplicated in playerview.gd
var current_question: QuestionId = null

var current_revealed_category = -1
var buzzers_enabled = false

signal game_started
signal game_paused
signal round_started
signal round_finished
signal category_revealed
# TODO
#signal category_introduction_finished
signal question_selected
signal question_deselected
# TODO
#signal question_completed

@onready var questions := $questions

@onready var toggle_intro_screen := $top_controls/play_pause
@onready var reveal_category_buttons := $top_controls/reveal_category_buttons

@onready var question_card = $question_card
@onready var question_category := $question_card/question_category
@onready var question_value := $question_card/question_value
@onready var question_label := $question_card/question
@onready var note := $question_card/note
@onready var answer := $question_card/answer
@onready var question_done := $question_card/question_done
@onready var enable_buzzers_btn := $question_card/buzzer_toggle/enable
@onready var disable_buzzers_btn := $question_card/buzzer_toggle/disable

var game_location = "../jeopardy.json"
var game = JSON.parse_string(FileAccess.open(game_location, FileAccess.READ).get_as_text())
var game_state: GameState = GameState.new()
var categories = game["rounds"][0]["categories"]

func _ready() -> void:
	var win = get_window()
	win.gui_embed_subwindows = false
	question_card.hide()
	
	var state_file_location = game_location + ".state"
	
	var playerwin = Window.new()
	playerwin.size = get_tree().root.size
	
	playerview = playerview_scene.instantiate()
	playerview.name = "playerview"
	# todo: signal
	playerview.init_game(game, game_state)
	
	playerwin.content_scale_aspect = win.content_scale_aspect
	playerwin.content_scale_mode = win.content_scale_mode
	playerwin.content_scale_size = win.content_scale_size
	playerwin.size = win.size

	playerwin.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	playerwin.add_child(playerview)
	add_child(playerwin)

	for q in range(5):
		for cat in range(5):
			questions.add_child(create_question_button(cat, q))
			
	game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	
	if FileAccess.file_exists(state_file_location):
		game_state.load(state_file_location)
	emit_signal("round_started", game_state.current_round)

func _on_game_state_loaded():
	reset_question_buttons()
	
func create_question_button(cat, q):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = str(points[q])
	btn.pressed.connect(Callable(self, "show_question").bind(cat, q))
	btn.disabled = true
	return btn
	
func reset_question_buttons():
	for cat_idx in range(5):
		for question_idx in range(5):
			var btn = get_question_button(QuestionId.new(game_state.current_round, cat_idx, question_idx))
			btn.text = str(points[question_idx])
			btn.disabled = true
			
	# TODO: move this into the first for loop? Requires 'in questions' to work
	# call reset_question_buttons when game_state is loaded instead of duplicated code
	for q in game_state.questions:
		if q.round == game_state.current_round:
			get_question_button(q).text = "---"
	
func show_question(cat_idx, question_idx):
	if current_question:
		hide_question()
	else:
		emit_signal("question_selected", QuestionId.new(game_state.current_round, cat_idx, question_idx))
		question_card.show()
		disable_buzzers()
		question_done.disabled = false
		question_category.text = categories[cat_idx]["name"]
		current_question = QuestionId.new(game_state.current_round, cat_idx, question_idx)
		var question = categories[cat_idx]["questions"][question_idx]
		question_value.text = str(points[question_idx])
		question_label.text = question["q"]
		answer.text = question["a"]
		if "n" in categories[cat_idx]["questions"][question_idx]:
			note.text = question["n"]
		else:
			note.text = "---"
	
func hide_question():
	# state
	current_question = null
	disable_buzzers()
	disable_answer_grading_buttons()

	# ui	
	playerview.hide_question()
	question_done.disabled = true
	
	question_card.hide()
	question_deselected.emit()

func _process(_delta: float) -> void:
	pass
	
func on_toggle_intro_screen_pressed() -> void:
	game_is_paused = !game_is_paused
	if game_is_paused:
		toggle_intro_screen.text = "Unpause game"
		for btn in reveal_category_buttons.get_children():
			btn.disabled = true
		for btn in questions.get_children():
			btn.disabled = true
		game_paused.emit()
	
	else:
		toggle_intro_screen.text = "Pause game"
		for btn in reveal_category_buttons.get_children():
			btn.disabled = false
		if all_categories_revealed():
			for btn in questions.get_children():
				btn.disabled = false
		game_started.emit()
		
func all_categories_revealed():
	return current_revealed_category == 5

func on_reveal_next_category_pressed() -> void:
	if current_revealed_category < 5:
		current_revealed_category += 1
		category_revealed.emit(current_revealed_category - 1, current_revealed_category)
		if current_revealed_category == 5:
			for btn in questions.get_children():
				btn.disabled = false
			
	
func on_reveal_previous_category_pressed() -> void:
	if current_revealed_category <= -1:
		return
	current_revealed_category -= 1
	category_revealed.emit(current_revealed_category + 1, current_revealed_category)
	for btn in questions.get_children():
		btn.disabled = true
		
func on_random_team_pressed() -> void:
	playerview.select_random_team()

func _on_team_correct_pressed(team_idx: int) -> void:
	if current_question:
		game_state.mark_correct(current_question, team_idx)
		mark_question_completed()
		persist_state()
	hide_question()
	
func mark_question_completed():
	if current_question:
		game_state.mark_question_complete(current_question)
		var btn = get_question_button(current_question)
		btn.text = "---"
		playerview.mark_question_completed(current_question)
		persist_state()
		hide_question()
		current_question = null
	
func get_question_button(question_id):
	return questions.get_child(question_id.question * 5 + question_id.category)
	
func _on_team_wrong_pressed(team_idx: int) -> void:
	if current_question:
		game_state.mark_wrong(current_question, team_idx)
		enable_buzzers()
		persist_state()

func _on_manual_score_increase(team_idx: int) -> void:
	game_state.increment_score(team_idx, 100)
	persist_state()

func _on_manual_score_decrease(team_idx: int) -> void:
	game_state.decrement_score(team_idx, 100)
	persist_state()

func persist_state():
	game_state.save(game_location + ".state")
	
func enable_buzzers():
	buzzers_enabled = true
	disable_buzzers_btn.disabled = false
	enable_buzzers_btn.disabled = true
	playerview.scoreboard.unselect_team()

func disable_buzzers():
	buzzers_enabled = false
	disable_buzzers_btn.disabled = true
	enable_buzzers_btn.disabled = false

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
	$question_card/score_buttons/team_1_correct.disabled = false
	$question_card/score_buttons/team_2_correct.disabled = false
	$question_card/score_buttons/team_3_correct.disabled = false
	$question_card/score_buttons/team_1_wrong.disabled = false
	$question_card/score_buttons/team_2_wrong.disabled = false
	$question_card/score_buttons/team_3_wrong.disabled = false

func disable_answer_grading_buttons():
	$question_card/score_buttons/team_1_correct.disabled = true
	$question_card/score_buttons/team_2_correct.disabled = true
	$question_card/score_buttons/team_3_correct.disabled = true
	$question_card/score_buttons/team_1_wrong.disabled = true
	$question_card/score_buttons/team_2_wrong.disabled = true
	$question_card/score_buttons/team_3_wrong.disabled = true

func start_round(round_number: int) -> void:
	current_revealed_category = -1
	current_question = null
	game_state.current_round = round_number
	
	round_started.emit(round_number)
	reset_question_buttons()
	question_card.hide()
	categories = game["rounds"][round_number]["categories"]


func on_halfway_pressed() -> void:
	print("emitting round_finished")
	round_finished.emit()
