
extends Panel

var game_is_paused = true
var playerview_scene = preload('res://scenes/playerview.tscn')
var playerview

@onready var score_buttons = $question_card/score_buttons

var points = [ 100, 200, 300, 400, 500 ] # duplicated in playerview.gd
var current_question: QuestionId = null
var already_buzzed: Array[int] = []
var buzzer_locked_until: Array[int]

var current_revealed_category = -1
var buzzers_enabled = false

var waiting_audio_position = null
var buzzer_wait_music_fadeout_tween = null

@onready var questions := $questions

@onready var toggle_intro_screen := $top_controls/show_intro
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

@onready var sounds = [
	preload("res://assets/audio/sfx_buzzer_0.ogg"),
	preload("res://assets/audio/sfx_buzzer_1.ogg"),
	preload("res://assets/audio/sfx_buzzer_2.ogg"),
	preload("res://assets/audio/sfx_buzzer_3.ogg"),
	preload("res://assets/audio/sfx_buzzer_4.ogg"),
	preload("res://assets/audio/sfx_buzzer_5.ogg"),
	preload("res://assets/audio/sfx_buzzer_6.ogg"),
	preload("res://assets/audio/sfx_buzzer_7.ogg"),
	preload("res://assets/audio/sfx_buzzer_8.ogg"),
	preload("res://assets/audio/sfx_buzzer_9.ogg"),
	preload("res://assets/audio/sfx_buzzer_10.ogg"),
]

var game = GlobalNode.game
var game_state = GlobalNode.game_state

func _ready() -> void:
	question_card.hide()
	questions.hide()
	
	$question_card/score_buttons.columns = len(game.teams)
	$score_adjustments.columns = len(game.teams)
	
	buzzer_locked_until = zeros(len(game.teams))
	
	for i in range(len(game.teams)):
		var b = Button.new()
		b.text = "correct"
		score_buttons.add_child(b)
		b.pressed.connect(func(): _on_team_correct_pressed(i))

	for i in range(len(game.teams)):
		var b = Button.new()
		b.text = "wrong"
		score_buttons.add_child(b)
		b.pressed.connect(func(): _on_team_wrong_pressed(i))
		
	for i in range(len(game.teams)):
		var b = Button.new()
		b.text = "+100"
		$score_adjustments.add_child(b)
		b.pressed.connect(func(): _on_manual_score_increase(i))
	
	for i in range(len(game.teams)):
		var b = Button.new()
		b.text = "-100"
		$score_adjustments.add_child(b)
		b.pressed.connect(func(): _on_manual_score_decrease(i))
	
	add_player_window()
	#add_player_window()
	
	$SerialControl.SerialReceived.connect(_on_serial_received)

	for cat in range(5):
		questions.add_child(create_category_button(cat))

	for q in range(5):
		for cat in range(5):
			questions.add_child(create_question_button(cat, q))
		
func add_player_window():
	var win = get_window()
	win.gui_embed_subwindows = false

	var playerwin = Window.new()
	playerwin.size = get_tree().root.size
	
	playerview = playerview_scene.instantiate()
	playerview.name = "playerview"
	
	playerwin.content_scale_aspect = win.content_scale_aspect
	playerwin.content_scale_mode = win.content_scale_mode
	playerwin.content_scale_size = win.content_scale_size
	playerwin.size = win.size

	playerwin.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	playerwin.add_child(playerview)
	add_child(playerwin)
	
func create_category_button(cat):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = str(game["rounds"][game_state.current_round]["categories"][cat]["name"])
	btn.disabled = true
	btn.size_flags_stretch_ratio = 2
	return btn	
	
func get_category_button(cat):
	return questions.get_child(cat)
	
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
			
	for q in game_state.get_current_round_questions():
		get_question_button(q).text = "---"
	
func show_question(cat_idx, question_idx):
	if current_question:
		hide_question()
		questions.show()
	else:
		GlobalNode.question_selected.emit(QuestionId.new(game_state.current_round, cat_idx, question_idx))
		question_card.show()
		questions.hide()
		disable_buzzers()
		already_buzzed = []
		buzzer_locked_until = zeros(len(game.teams))
		question_done.disabled = false
		question_category.text = game.rounds[game_state.current_round].categories[cat_idx]["name"]
		current_question = QuestionId.new(game_state.current_round, cat_idx, question_idx)
		var question = game.rounds[game_state.current_round].categories[cat_idx]["questions"][question_idx]
		question_value.text = str(points[question_idx])
		question_label.text = question["q"]
		answer.text = question["a"]
		if "n" in game.rounds[game_state.current_round].categories[cat_idx]["questions"][question_idx]:
			note.text = question["n"]
		else:
			note.text = "---"
	
func zeros(n):
	var result: Array[int] = []
	result.resize(n)
	result.fill(0)
	return result
	
func hide_question():
	# state
	current_question = null
	disable_buzzers()
	#$buzzer_wait_music.stop()
	
	fade_out_wait_music()
	
	send_enable_disable_message([], [-1])
	disable_answer_grading_buttons()

	# ui	
	question_done.disabled = true
	
	question_card.hide()
	questions.show()
	GlobalNode.question_deselected.emit()
	
func fade_out_wait_music():
	if buzzer_wait_music_fadeout_tween:
		buzzer_wait_music_fadeout_tween.stop()
	buzzer_wait_music_fadeout_tween = create_tween()
	waiting_audio_position = $buzzer_wait_music.get_playback_position()
	buzzer_wait_music_fadeout_tween.tween_property($buzzer_wait_music, "volume_db", -80, 5)
	buzzer_wait_music_fadeout_tween.connect("tween_completed", _on_audio_faded_out)

func _on_audio_faded_out():
	$buzzer_wait_music.stop()

func _process(_delta: float) -> void:
	pass
	
func on_show_intro_pressed() -> void:
	disable_reveal_category_buttons()
	questions.hide()
	for btn in questions.get_children():
		btn.disabled = true
	GlobalNode.game_paused.emit()
	
func all_categories_revealed():
	return current_revealed_category == 5

func on_reveal_next_category_pressed() -> void:
	if current_revealed_category < 5:
		current_revealed_category += 1
		print("emitting category_revealed")
		GlobalNode.category_revealed.emit(current_revealed_category - 1, current_revealed_category)
		if current_revealed_category == 5:
			for btn in questions.get_children():
				btn.disabled = false
			
	
func on_reveal_previous_category_pressed() -> void:
	if current_revealed_category <= -1:
		return
	current_revealed_category -= 1
	GlobalNode.category_revealed.emit(current_revealed_category + 1, current_revealed_category)
	for btn in questions.get_children():
		btn.disabled = true
		
func on_random_team_pressed() -> void:
	GlobalNode.random_team_selection_requested.emit()

func _on_team_correct_pressed(team_idx: int) -> void:
	if current_question:
		game_state.mark_correct(team_idx, current_question)
		disable_answer_grading_buttons()
		# mark question completed but don't hide it from playerview
		var btn = get_question_button(current_question)
		btn.text = "---"
		GlobalNode.question_answered_correctly.emit(current_question)
		$buzzer_correct.play()
		persist_state()
	
func mark_question_completed():
	if current_question:
		game_state.mark_question_complete(current_question)
		var btn = get_question_button(current_question)
		btn.text = "---"
		GlobalNode.question_completed.emit(current_question)
		persist_state()
		hide_question()
		current_question = null
	
func get_question_button(question_id: QuestionId):
	return questions.get_child((1 + question_id.question) * 5 + question_id.category)
	
func _on_team_wrong_pressed(team_idx: int) -> void:
	if current_question:
		already_buzzed.append(team_idx)
		game_state.mark_wrong(team_idx, current_question)
		disable_answer_grading_buttons()
		if len(already_buzzed) < len(game.teams):
			send_enable_disable_message([-1], already_buzzed)
			enable_buzzers_with_position(waiting_audio_position)
		else:
			send_enable_disable_message([], [-1])
		$buzzer_wrong.play()
		persist_state()

func _on_manual_score_increase(team_idx: int) -> void:
	print("manually incrementing score for team ", team_idx)
	game_state.increment_score(team_idx, 100)
	persist_state()

func _on_manual_score_decrease(team_idx: int) -> void:
	game_state.decrement_score(team_idx, 100)
	persist_state()

func persist_state():
	GlobalNode.save_state()

func enable_buzzers():
	enable_buzzers_with_position(null)
	send_enable_disable_message([-1], already_buzzed)

func enable_buzzers_with_position(pos):
	buzzers_enabled = true
	disable_buzzers_btn.disabled = false
	enable_buzzers_btn.disabled = true
	GlobalNode.team_deselected.emit()
	disable_answer_grading_buttons()
	if buzzer_wait_music_fadeout_tween:
		buzzer_wait_music_fadeout_tween.stop()
	$buzzer_wait_music.volume_db = 0
	if pos:
		$buzzer_wait_music.play(pos)
	else:
		$buzzer_wait_music.play()
		

func _on_disable_buzzers():
	fade_out_wait_music()
	disable_buzzers()

func disable_buzzers():
	buzzers_enabled = false
	disable_buzzers_btn.disabled = true
	enable_buzzers_btn.disabled = false
	disable_answer_grading_buttons()
	send_enable_disable_message([], [-1])

func _on_serial_received(line: String):
	var json_data = JSON.parse_string(line)
	if json_data and ("buzzer" in json_data):
		handle_buzzer(int(json_data["buzzer"]))
		return
		
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A:
			handle_buzzer(0)
		elif event.keycode == KEY_B:
			handle_buzzer(1)
		elif event.keycode == KEY_C:
			handle_buzzer(2)
		elif event.keycode == KEY_D:
			handle_buzzer(3)
			
func handle_buzzer(team_idx):
	if team_idx >= len(GlobalNode.game.teams):
		print("Not a valid team number: ", team_idx)
		return
		
	print("AAA already buzzed ", already_buzzed)
	if already_buzzed:
		print("---")
	if already_buzzed.has(team_idx):
		print("Team ", team_idx, " already buzzed. Ignoring.")
		return

	if not buzzers_enabled:
		print("Team ", team_idx, " pressed buzzer early. Disabling for .5 seconds")
		# TODO: also turn off buzzer light?
		# Needs a timer to re-enable the buzzer light,
		# We can do this in _Process
		buzzer_locked_until[team_idx] = Time.get_ticks_msec() + 500
		return
	
	if Time.get_ticks_msec() < buzzer_locked_until[team_idx]:
		print("Team ", team_idx, " buzzer is still locked out")
		return

	GlobalNode.buzzer_accepted.emit(team_idx)
	waiting_audio_position = $buzzer_wait_music.get_playback_position()
	$buzzer_wait_music.stop()
	disable_buzzers()
	send_enable_disable_message([team_idx], [0,1,2].filter(func(i):return i != team_idx), game.teams[team_idx])
	
	var rand_index:int = randi() % sounds.size()
	$buzzer_beep.stream = sounds[rand_index]
	$buzzer_beep.play()
	enable_answer_grading_buttons(team_idx)
	
func enable_answer_grading_buttons(team_idx: int):
	get_correct_button(team_idx).disabled = false
	get_wrong_button(team_idx).disabled = false

func get_correct_button(i):
	return $question_card/score_buttons.get_child(i)
	
func get_wrong_button(i):
	return $question_card/score_buttons.get_child(i + len(game.teams))
	
func disable_answer_grading_buttons():
	for i in range(len(game.teams)):
		get_correct_button(i).disabled = true
		get_wrong_button(i).disabled = true

func start_round(round_number: int) -> void:
	current_revealed_category = -1
	current_question = null
	game_state.current_round = round_number
	
	for cat in range(5):
		var btn = get_category_button(cat)
		btn.text = str(game["rounds"][game_state.current_round]["categories"][cat]["name"])
	print("starting round ", round_number)
	GlobalNode.round_started.emit(round_number)
	enable_reveal_category_buttons()
	reset_question_buttons()
	question_card.hide()
	questions.show()

func enable_reveal_category_buttons():
	for btn in reveal_category_buttons.get_children():
			btn.disabled = false
			
func disable_reveal_category_buttons():
	for btn in reveal_category_buttons.get_children():
			btn.disabled = true

func on_halfway_pressed() -> void:
	disable_reveal_category_buttons()
	questions.hide()
	GlobalNode.round_finished.emit()

func on_gameover_pressed() -> void:
	disable_reveal_category_buttons()
	questions.hide()
	GlobalNode.game_over.emit()
	
func show_answer() -> void:
	send_enable_disable_message([], [-1])
	GlobalNode.answer_revealed.emit(current_question)

func enable_disable_message(enable, disable, display_text = null) -> String:
	var data = {}
	data["enable"] = enable
	data["disable"] = disable
	if display_text:
		data["display"] = display_text

	return JSON.stringify(data)
	
func send_enable_disable_message(enable, disable, display_text = null):
	$SerialControl.SendLine(enable_disable_message(enable, disable, display_text))


func _on_enable_buzzers() -> void:
	GlobalNode.buzzers_enabled.emit(current_question)
	already_buzzed = []
	send_enable_disable_message([-1], [], "...")
	enable_buzzers_with_position(0)
