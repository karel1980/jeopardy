
extends Panel

var game_is_paused = true
var playerview_scene = preload('res://scenes/playerview.tscn')
var playerview

var current_question: QuestionId = null
var already_buzzed: Array[int] = []

var current_revealed_category = -1
var buzzers_enabled = false

var waiting_audio_position = null
var buzzer_wait_music_fadeout_tween = null

@onready var questions := $questions

@onready var toggle_intro_screen := $top_controls/show_intro


@onready var question_control = $question_view
@onready var question_category := $question_view/game_state_values/question_category
@onready var question_value := $question_view/game_state_values/question_value
@onready var question_label := $question_view/game_state_values/question
@onready var note := $question_view/game_state_values/note
@onready var answer := $question_view/game_state_values/answer
@onready var question_done := $question_view/question_control/question_controls/question_done
@onready var enable_buzzers_btn := $question_view/question_control/buzzer_toggle/enable
@onready var disable_buzzers_btn := $question_view/question_control/buzzer_toggle/disable
@onready var show_points_btn := $question_view/question_control/question_control/show_points
@onready var show_question_btn := $question_view/question_control/question_control/show_question
@onready var show_awnser_btn := $question_view/question_control/question_control/show_answer
@onready var current_team_name_lbl := $question_view/game_state_values/current_team_name

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
	question_control.hide()
	questions.hide()
	
	$question_view/question_control/score_buttons.columns = len(game.teams)
	
	
	
	for i in range(len(game.teams)):
		var item_list = VBoxContainer.new()
		item_list.custom_minimum_size = Vector2(150, 0)
		item_list.add_theme_constant_override("margin_left", 50)

		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_FILL
		label.text = GlobalNode.game["teams"][i]
		item_list.add_child(label)
	
		var correct_button = Button.new()
		correct_button.text = "correct"
		correct_button.size_flags_horizontal = Control.SIZE_FILL
		correct_button.pressed.connect(func(): _on_team_correct_pressed(i))
		correct_button.name = "grading_correct_%d" % i 
		correct_button.set_meta("team_id", i) 
		correct_button.set_meta("action", "grade")
		item_list.add_child(correct_button)
	
		var wrong_button = Button.new()
		wrong_button.text = "wrong"
		wrong_button.size_flags_horizontal = Control.SIZE_FILL
		wrong_button.pressed.connect(func(): _on_team_wrong_pressed(i))
		wrong_button.name = "grading_wrong_%d"% i 
		wrong_button.set_meta("team_id", i) 
		wrong_button.set_meta("action", "grade")
		item_list.add_child(wrong_button)
		
		var add_points_button = Button.new()
		add_points_button.size_flags_horizontal = Control.SIZE_FILL
		add_points_button.text = "+" + str(GameState.score_increments)
		add_points_button.pressed.connect(func(): _on_manual_score_adjust(i,GameState.score_increments))
		item_list.add_child(add_points_button)
		
		var deduct_points_button = Button.new()
		deduct_points_button.size_flags_horizontal = Control.SIZE_FILL
		deduct_points_button.text = str(-GameState.score_increments)
		deduct_points_button.pressed.connect(func():  _on_manual_score_adjust(i, -GameState.score_increments))
		item_list.add_child(deduct_points_button)
		
		$question_view/question_control/score_buttons.add_child(item_list)
	
	add_player_window()
	
	$SerialControl.SerialReceived.connect(_on_serial_received)
	GlobalNode.team_selected.connect(_on_team_selected)

	for cat in range(5):
		questions.add_child(create_category_button(cat))

	for q in range(5):
		for cat in range(5):
			questions.add_child(create_question_button(cat, q))
func _on_team_selected():
	print("selected team updated in main")
	current_team_name_lbl.text = game.teams[game_state.current_team_idx]
	
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
	btn.text = str(GameState.question_values[q])
	btn.pressed.connect(Callable(self, "show_question").bind(cat, q))
	btn.disabled = true
	return btn
	
func reset_question_buttons():
	for cat_idx in range(5):
		for question_idx in range(5):
			var btn = get_question_button(QuestionId.new(game_state.current_round, cat_idx, question_idx))
			btn.text = str(GameState.question_values[question_idx])
			btn.disabled = true
			
	for q in game_state.get_current_round_questions():
		get_question_button(q).text = "---"
	
func show_question(cat_idx, question_idx):
	if current_question:
		hide_question()
		questions.show()
	else:
		GlobalNode.question_selected.emit(QuestionId.new(game_state.current_round, cat_idx, question_idx))
		enable_fysical_buzzers()
		question_control.show()
		questions.hide()
		already_buzzed = []
		question_done.disabled = false
		question_category.text = game.rounds[game_state.current_round].categories[cat_idx]["name"]
		current_question = QuestionId.new(game_state.current_round, cat_idx, question_idx)
		var question = game.rounds[game_state.current_round].categories[cat_idx]["questions"][question_idx]
		question_value.text = str(GameState.question_values[question_idx])
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
		
	send_enable_disable_message([], [-1])
	disable_answer_grading_buttons()

	# ui	
	question_done.disabled = true
	
	question_control.hide()
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
		fade_out_wait_music()
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
		GlobalNode.team_selected.emit()
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
			enable_buzzers_with_position()
			if waiting_audio_position:
				start_music_on_position(waiting_audio_position)
		else:
			send_enable_disable_message([], [-1])
		$buzzer_wrong.play()
		persist_state()

func _on_manual_score_adjust(team_idx: int, amount) -> void:
	print("manually incrementing score for team ", team_idx)
	game_state.increment_score(team_idx, amount)
	persist_state()

func persist_state():
	GlobalNode.save_state()

func enable_buzzers():
	enable_buzzers_with_position()
	send_enable_disable_message([-1], already_buzzed)

func enable_buzzers_with_position():
	buzzers_enabled = true
	disable_buzzers_btn.disabled = false
	enable_buzzers_btn.disabled = true
	show_question_btn.disabled = false
	GlobalNode.team_deselected.emit()
	disable_answer_grading_buttons()
		
func start_music_on_position(pos):
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
	print("AAA already buzzed ", already_buzzed)
	if already_buzzed:
		print("---")
	if already_buzzed.has(team_idx):
		print("Team ", team_idx, " already buzzed. Ignoring.")
		return




	GlobalNode.buzzer_accepted.emit(team_idx)
	waiting_audio_position = $buzzer_wait_music.get_playback_position()
	$buzzer_wait_music.stop()
	disable_buzzers()
	send_enable_disable_message([team_idx], [0,1,2].filter(func(i):return i != team_idx))
	
	var rand_index:int = randi() % sounds.size()
	$buzzer_beep.stream = sounds[rand_index]
	$buzzer_beep.play()
	enable_answer_grading_buttons(team_idx)
	
func enable_answer_grading_buttons(team_idx: int):
	for container in $question_view/question_control/score_buttons.get_children():
		for child in container.get_children():
			if child.get_meta("action") == "grade"  and  child.get_meta("team_id") == team_idx:
				child.disabled = false

	

	
func disable_answer_grading_buttons():
	for container in $question_view/question_control/score_buttons.get_children():
		for child in container.get_children():
			if child.get_meta("action") == "grade" :
				child.disabled = true


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
	question_control.hide()
	questions.show()

func enable_reveal_category_buttons():
	change_reveal_buttons(false)
func disable_reveal_category_buttons():
	change_reveal_buttons(true)
func change_reveal_buttons(disabled:bool):
	for btn in $top_controls.get_children():
		if btn.get_meta("category") == "reveal":
			btn.disabled = disabled
func on_halfway_pressed() -> void:
	disable_reveal_category_buttons()
	questions.hide()
	GlobalNode.round_finished.emit()

func on_gameover_pressed() -> void:
	disable_reveal_category_buttons()
	questions.hide()
	GlobalNode.game_over.emit()
	


func enable_disable_message(enable, disable) -> String:
	var data = {}
	data["enable"] = enable
	data["disable"] = disable
	return JSON.stringify(data)
	
func send_enable_disable_message(enable, disable):
	$SerialControl.SendLine(enable_disable_message(enable, disable))


func _on_enable_buzzers() -> void:
	enable_fysical_buzzers()
	
func enable_fysical_buzzers() -> void:
	already_buzzed = []
	send_enable_disable_message([-1], [])
	enable_buzzers_with_position()

func _on_show_answer_pressed() -> void:
	send_enable_disable_message([], [-1])
	fade_out_wait_music()
	GlobalNode.answer_revealed.emit(current_question)
	
	enable_buzzers_btn.disabled = false
	disable_buzzers_btn.disabled = true
	
	show_points_btn.disabled = false
	show_question_btn.disabled = false
	show_awnser_btn.disabled=true
	
func _on_show_question_pressed() -> void:
	GlobalNode.buzzers_enabled.emit(current_question)
	
	start_music_on_position(null)
	
	show_points_btn.disabled = false
	show_question_btn.disabled = true
	show_awnser_btn.disabled=false


func _on_show_points_pressed() -> void:
	GlobalNode.question_selected.emit(current_question)
	
	show_points_btn.disabled = true
	show_question_btn.disabled = false
	show_awnser_btn.disabled=false
