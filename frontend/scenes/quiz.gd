extends Panel

@onready var categories_slider := $categories_slider
@onready var question_holder := $main_view/question_holder
@onready var main_view := $main_view
@onready var questionboard = $main_view/questionboard
@onready var scoreboard = $main_view/scoreboard

var normal_font = load("res://assets/fonts/LilitaOne-Regular.ttf")

var game = GlobalNode.game
var game_state = GlobalNode.game_state

var next_view: String

var scores = [ 0, 0, 0 ]
var category_buttons = []

var shown_question = []
var question_btn
var orig_question_btn

var margin = 10

var question_points = [ 100, 200, 300, 400, 500 ]

var cat_tween = null
var cat_tween2 = null
var cat_button = null

func _ready() -> void:
	init_category_buttons()
	init_question_buttons()
	
	GlobalNode.round_started.connect(start_round)
	GlobalNode.category_revealed.connect(reveal_category)
	GlobalNode.question_selected.connect(show_question)
	GlobalNode.question_deselected.connect(hide_question)
	GlobalNode.question_completed.connect(hide_and_clear_question)
	GlobalNode.question_answered_correctly.connect(show_answer)
	GlobalNode.answer_revealed.connect(show_answer)
	
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
	categories_slider.size = Vector2(sz.x * 5, sz.y)
	categories_slider.get_node("hbox").size = Vector2(sz.x * 5, sz.y)
	for cat_idx in range(len(categories)):
		categories_slider.get_node("hbox").get_child(cat_idx).text = categories[cat_idx]["name"]
	categories_slider.position = Vector2(sz.x, 0)
	categories_slider.show()

func position_categories_slider(category_idx):
	var sz = get_viewport().get_size()
	categories_slider.position = Vector2(-category_idx * sz.x, 0)
	categories_slider.size = Vector2(sz.x * 5, sz.y)
	
func start_round(_round_idx):
	hide_question()
	init_category_buttons()
	init_question_buttons()
	categories_slider.hide()
	# why show question holder?
	question_holder.show()
	
	# Clear all questions that are already completed
	for q in game_state.get_current_round_questions():
		get_question_label(q).text = ""

func reveal_category(previous_cat_idx, cat_idx):
	init_categories_slider()

	if previous_cat_idx >= 0 and previous_cat_idx < 5:
		get_category_button(previous_cat_idx).text = game["rounds"][game_state.current_round]["categories"][previous_cat_idx]["name"]
	var sz = main_view.size
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
		category_buttons.append(btn)
		
func init_question_buttons():
	var categories = game["rounds"][game_state.current_round]["categories"]
	for point_i in len(question_points):
		for cat_i in len(categories):
			var btn = get_question_label(QuestionId.new(game_state.current_round, cat_i, point_i))
			btn.text = str(question_points[point_i])

func get_category_button(cat_idx) -> Label:
	return questionboard.get_child(cat_idx).get_node("MarginContainer/Button")

func get_question_label(question_id: QuestionId):
	return questionboard.get_child(question_id.category).get_child(question_id.question + 1)

func fixate_button_color(btn, color):
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_pressed_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_pressed_color", color)

func hide_question():
	if question_btn:
		var free_when_done = func():
			if question_btn:
				question_btn.queue_free()
				question_btn = null
		var t = create_tween()
		t.tween_property(question_btn, "scale", Vector2(orig_question_btn.get_global_rect().size.x / question_btn.size.x, orig_question_btn.get_global_rect().size.y / question_btn.size.y), 0.7)
		t.parallel().tween_property(question_btn, "position", orig_question_btn.get_global_position(), 0.7)
		t.tween_callback(free_when_done)
		
func hide_and_clear_question(question_id: QuestionId):
	hide_question()
	get_question_label(question_id).text = ""
		
func show_question(question_id: QuestionId):
	if question_btn:
		question_btn.free()
		question_btn = null
	
	var points_idx = question_id.question
	var cat_idx = question_id.category
	var categories = game["rounds"][game_state.current_round]["categories"]
	var question = categories[cat_idx]["questions"][points_idx]
	var orig_btn = get_question_label(question_id)
	var btn
	if "image" in question:
		btn = TextureButton.new()
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		btn.size_flags_vertical = Control.SIZE_EXPAND
		btn.texture_normal = ImageTexture.create_from_image(Image.load_from_file("../" + question["image"]))
		
		var color_rect = ColorRect.new()
		color_rect.color = Color(1, 1, 1, .8)  # Set to your desired background color (e.g., red)
		color_rect.size = questionboard.get_global_rect().size
		color_rect.show_behind_parent = true
		btn.add_child(color_rect)
	else:
		btn = orig_btn.duplicate()
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.text = str(question_points[points_idx])
		btn.label_settings = LabelSettings.new()
		btn.label_settings.font_size = 52

	question_btn = btn
	orig_question_btn = orig_btn
	shown_question = [cat_idx, points_idx]
	fixate_button_color(btn, Color(1,1,1))
	btn.position = orig_btn.get_global_position()
	btn.size = questionboard.size
	btn.scale = Vector2(orig_btn.get_global_rect().size.x / btn.size.x, orig_btn.get_global_rect().size.y / btn.size.y)
	
	var set_question_text = func():
		if "image" not in question:
			if btn:
				btn.text = question["q"]
				btn.label_settings.font = normal_font

	question_holder.add_child(btn)
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	tween.parallel().tween_property(btn, "scale", Vector2(1,1), 0.7)
	tween.tween_interval(1)
	tween.tween_callback(set_question_text)
	
func show_answer(question_id: QuestionId):
	if question_btn:
		if question_btn is TextureButton:
			question_btn.free()
			question_btn = get_question_label(question_id).duplicate()
			question_btn.position = Vector2(0, 0)
			question_btn.size = questionboard.get_rect().size
			question_btn.label_settings = LabelSettings.new()
			question_btn.label_settings.font = normal_font
			question_btn.label_settings.font_size = 52
			question_holder.get_children().clear()
			question_holder.add_child(question_btn)
		question_btn.text = game.rounds[question_id.round]["categories"][question_id.category]["questions"][question_id.question]["a"]

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
