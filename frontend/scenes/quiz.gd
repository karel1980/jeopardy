extends Panel

@onready var categories_slider := $categories_slider
@onready var question_holder := $main_view/question_holder
@onready var main_view := $main_view
@onready var questionboard = $main_view/questionboard
@onready var scoreboard = $main_view/scoreboard

var normal_font = load("res://assets/fonts/LilitaOne-Regular.ttf")
var pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

var game = GlobalNode.game
var game_state = GlobalNode.game_state

var next_view: String

var scores = [ 0, 0, 0 ]
var category_buttons
var question_buttons

var shown_question = []
var question_btn
var orig_question_btn

var margin = 10
var sep = 5
var row_drop_delay = .3
var item_drop_delay = .3

var question_points = [ 100, 200, 300, 400, 500 ]

var cat_tween = null
var cat_tween2 = null
var cat_button = null

func _ready() -> void:
	if not category_buttons:
		category_buttons = create_category_buttons()
		question_buttons = create_question_buttons()
		init_category_buttons()
		init_question_buttons()
		drop_questionboard_labels()
	else:
		init_category_buttons()
		init_question_buttons()
		drop_questionboard_labels()

	GlobalNode.round_started.connect(start_round)
	GlobalNode.category_revealed.connect(reveal_category)
	GlobalNode.question_selected.connect(zoom_question)
	GlobalNode.question_deselected.connect(hide_question)
	GlobalNode.question_completed.connect(hide_and_clear_question)
	GlobalNode.question_answered_correctly.connect(show_answer)
	GlobalNode.answer_revealed.connect(show_answer)
	GlobalNode.buzzers_enabled.connect(reveal_question)
	
	for q in game_state.questions:
		if q.round == game_state.current_round:
			get_question_label(q).text = ""

	for q in game_state.questions:
		if q.round == game_state.current_round:
			get_question_label(q).text = ""

func init_categories_slider():
	for btn in categories_slider.get_node("hbox").get_children():
		btn.add_theme_font_size_override("font_size", 40)
	
	var categories = game["rounds"][game_state.current_round]["categories"]
	var sz = main_view.size
	var round_screen_size = size
	categories_slider.size = Vector2(round_screen_size.x * 5, round_screen_size.y)
	categories_slider.get_node("hbox").size = Vector2(sz.x * 5, round_screen_size.y)
	for cat_idx in range(len(categories)):
		categories_slider.get_node("hbox").get_child(cat_idx).text = categories[cat_idx]["name"]
	categories_slider.position = Vector2(sz.x, 0)
	categories_slider.show()

func position_categories_slider(category_idx):
	var sz = questionboard.size
	categories_slider.position = Vector2(-category_idx * sz.x, 0)
	
func start_round(_round_idx):
	hide_question()
	init_category_buttons()
	init_question_buttons()
	categories_slider.hide()
	# why show question holder?
	question_holder.show()

	drop_questionboard_labels()
	
	# Clear all questions that are already completed
	for q in game_state.get_current_round_questions():
		get_question_label(q).text = ""

func drop_questionboard_labels():
	drop_row(category_buttons, 0)
	for question_idx in range(5):
		var row = []
		for category_idx in range(5):
			row.append(question_buttons[category_idx][question_idx])
		drop_row(row, question_idx + 1)
	
func drop_row(labels, row_num):
	var current_row_delay = (5 - row_num) * row_drop_delay
	for i in range(len(labels)):
		var label = labels[i]
		var pos = questionboard_label_pos(i, row_num)
		label.position = Vector2(pos.x, pos.y - 1200)
		var tween = create_tween()
		tween.tween_interval(current_row_delay + item_drop_delay * i)
		tween.tween_property(label, "position", pos, 2.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func reveal_category(previous_cat_idx, cat_idx):
	init_categories_slider()

	if previous_cat_idx >= 0 and previous_cat_idx < 5:
		get_category_button(previous_cat_idx).text = game["rounds"][game_state.current_round]["categories"][previous_cat_idx]["name"]
	var sz = size
	position_categories_slider(previous_cat_idx)
	categories_slider.show()
	var tween = create_tween()
	tween.tween_property(categories_slider, "position", Vector2(sz.x * (-cat_idx), 0), 0.5)

func show_category_names():
	var categories = game["rounds"][game_state.current_round]["categories"]
	for cat_idx in range(len(categories)):
		questionboard.get_child(cat_idx).get_child(0).text = categories[cat_idx]["name"]
		
func init_category_buttons():
	#TODO: Merge game and game_state? I'd like a get_current_round_categories()
	var categories = game["rounds"][game_state.current_round]["categories"]
	for cat_i in len(categories):
		var btn = get_category_button(cat_i)
		btn.text = "???"
		
func init_question_buttons():
	var categories = game["rounds"][game_state.current_round]["categories"]
	for point_i in len(question_points):
		for cat_i in len(categories):
			var btn = get_question_label(QuestionId.new(game_state.current_round, cat_i, point_i))
			btn.text = str(question_points[point_i])

func get_category_button(cat_idx) -> Label:
	return category_buttons[cat_idx]

func get_question_label(question_id: QuestionId):
	return question_buttons[question_id.category][question_id.question]

func fixate_button_color(btn, color):
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_pressed_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_pressed_color", color)

func hide_question():
	if question_btn:
		var remove_when_done = func():
			question_btn.queue_free()
			question_holder.get_children().clear()
		var t = create_tween()
		t.tween_property(question_btn, "scale", Vector2(orig_question_btn.get_global_rect().size.x / question_btn.size.x, orig_question_btn.get_global_rect().size.y / question_btn.size.y), 0.7)
		t.parallel().tween_property(question_btn, "position", orig_question_btn.get_global_position(), 0.7)
		t.tween_callback(remove_when_done)
	
func create_category_buttons():
	var result = []
	var stylebox = StyleBoxFlat.new()
	stylebox.corner_radius_top_left = 30
	stylebox.corner_radius_top_right = 30
	stylebox.bg_color = Color(0,0,1)
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 30

	for i in range(5):
		result.append(create_category_button(i, stylebox, label_settings))
		
	return result

func create_category_button(cat_idx: int, stylebox: StyleBox, label_settings: LabelSettings):
	var result = Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER	
	result.position = questionboard_label_pos(cat_idx, 0)
	result.size = questionboard_label_size()
	result.add_theme_stylebox_override("normal", stylebox)
	result.label_settings = label_settings
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	questionboard.add_child(result)
	return result

func create_question_buttons():
	var result = []
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0,0,1)

	var stylebox2 = StyleBoxFlat.new()
	stylebox2.corner_radius_bottom_left = 30
	stylebox2.corner_radius_bottom_right = 30
	stylebox2.bg_color = Color(0,0,1)
	
	var label_settings = LabelSettings.new()
	label_settings.font = pixel_font
	label_settings.font_color = Color(1,1,0)
	
	for category_idx in range(5):
		result.append([])
		for question_idx in range(5):
			result[-1].append(create_question_button(category_idx, question_idx, stylebox if question_idx < 4 else stylebox2, label_settings))
			
	return result

func create_question_button(category_idx: int, question_idx: int, stylebox: StyleBox, label_settings: LabelSettings):
	var result = Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER	
	result.position = questionboard_label_pos(category_idx, question_idx + 1)
	result.size = questionboard_label_size()
	result.add_theme_stylebox_override("normal", stylebox)
	result.label_settings = label_settings
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.text = "???"
	questionboard.add_child(result)
	return result

func questionboard_label_pos(col: int, row: int):
	var sz = questionboard_label_size()
	return Vector2(margin + (sep+sz.x) * col, margin + (sep+sz.y) * row)
	
func questionboard_label_size():
	var sz = questionboard.size
	return Vector2((sz.x -2*margin - 4*sep) / 5, (sz.y - 2*margin - 5*sep) / 6)
	
func hide_and_clear_question(question_id: QuestionId):
	hide_question()
	get_question_label(question_id).text = ""
		
func zoom_question(question_id: QuestionId):
	question_holder.get_children().clear()
	
	var points_idx = question_id.question
	var cat_idx = question_id.category
	var categories = game["rounds"][game_state.current_round]["categories"]
	var question = categories[cat_idx]["questions"][points_idx]
	var orig_btn = get_question_label(question_id)
	var btn

	btn = orig_btn.duplicate()
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.text = str(question_points[points_idx])
	btn.label_settings = LabelSettings.new()
	btn.label_settings.font_size = 52
	fixate_button_color(btn, Color(1,1,1))

	var ls = LabelSettings.new()
	ls.font_size = 60
	ls.font = pixel_font
	btn.label_settings = ls
	shown_question = [cat_idx, points_idx]
	btn.position = orig_btn.get_global_position()
	btn.size = questionboard.size
	btn.scale = Vector2(orig_btn.get_global_rect().size.x / btn.size.x, orig_btn.get_global_rect().size.y / btn.size.y)
	
	question_holder.add_child(btn)
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	tween.parallel().tween_property(btn, "scale", Vector2(1,1), 0.7)
	tween.tween_interval(1)
	question_btn = btn
	orig_question_btn = orig_btn

func reveal_question(question_id):
	if not question_btn:
		return
		
	var question = get_question(question_id)
	
	if "image" in question:
		question_btn.queue_free()
		var btn  = TextureRect.new()
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		btn.size_flags_vertical = Control.SIZE_EXPAND
		btn.texture = ImageTexture.create_from_image(Image.load_from_file("../" + question["image"]))
		btn.size = questionboard.get_global_rect().size
		
		var color_rect = ColorRect.new()
		color_rect.color = Color(1, 1, 1, .8)
		color_rect.size = questionboard.get_global_rect().size
		color_rect.show_behind_parent = true
		btn.add_child(color_rect)

		question_holder.get_children().clear()
		question_holder.add_child(btn)
		question_btn = btn
	else:
		question_btn.label_settings.font = normal_font
		question_btn.text = question["q"]

func show_answer(question_id: QuestionId):
	if question_btn:
		question_btn.queue_free()
		question_btn = get_question_label(question_id).duplicate()
		question_btn.position = Vector2(0, 0)
		question_btn.size = questionboard.get_rect().size
		question_btn.label_settings = LabelSettings.new()
		question_btn.label_settings.font = normal_font
		question_btn.label_settings.font_size = 52
		question_btn.text = get_question(question_id)["a"]
		question_holder.get_children().clear()
		question_holder.add_child(question_btn)

func get_question(question_id: QuestionId):
	return game.rounds[question_id.round]["categories"][question_id.category]["questions"][question_id.question]
	
func mark_question_completed(question_id: QuestionId):
	get_question_label(question_id).text = ""
	
func clear_category_if_complete(cat_idx):
	var btn = category_buttons[cat_idx]
	for row in range(5):
		if get_question_label(QuestionId.new(game_state.current_round, cat_idx, row)).text != "":
			return
	var tween = create_tween()
	var scaler = func(font_color):
		fixate_button_color(btn, font_color)
	
	tween.tween_method(scaler, Color(1,1,1), Color(.2,.2,1), 1)
	
func update_score(team_idx, score):
	scores[team_idx] += score
	get_node('scoreboard/team 1 score').text = "{score}".format({"score": scores[team_idx]})
