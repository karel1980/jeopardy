extends Node2D

@onready var intro_screen = $intro_screen
@onready var categories_slider := $categories_slider
@onready var question_holder := $question_holder
@onready var main_view := $main_view
@onready var questionboard = $main_view/questionboard
@onready var scoreboard = $main_view/scoreboard
@onready var camera := $Camera2D

var game
var game_state
var current_category_slider_idx = -1

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
	init_categories_slider()
	init_question_buttons()

	pause_game()
	
	var hostview = get_tree().root.get_node("SceneRoot")
	hostview.round_started.connect(Callable(self, "start_round"))
	hostview.question_selected.connect(Callable(self, "show_question"))
	hostview.game_started.connect(Callable(self, "start_game"))
	hostview.game_paused.connect(Callable(self, "pause_game"))

	scoreboard.init_game(game, game_state)
	
func _process(_delta: float) -> void:
	pass
	
func init_game(game_data, _game_state):
	game = game_data
	game_state = _game_state
	
	game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	
func _on_game_state_loaded():
	for q in game_state.questions:
		if q.round == game_state.current_round:
			get_question_button(q).text = ""

func init_categories_slider():
	current_category_slider_idx = -1
	for btn in categories_slider.get_children():
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(.2, .2, 1)
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_font_size_override("font_size", 40)
	
	var categories = game["rounds"][game_state.current_round]["categories"]
	for cat_idx in range(len(categories)):
		categories_slider.get_child(cat_idx).text = categories[cat_idx]["name"]

	position_categories_slider()

# TODO: sliding left and right is a bit wonky. Passing from/to could make things easier here
func position_categories_slider():
	var sz = main_view.get_rect().size
	categories_slider.position = Vector2(-current_category_slider_idx * sz.x, 0)
	categories_slider.size = Vector2(sz.x * 5, sz.y)

	
func start_game():	
	intro_screen.hide()
	main_view.show()
	question_holder.show()
		
func start_round(round_idx):
	hide_question()
	var round = game["rounds"][round_idx]
	init_category_buttons()
	init_categories_slider()
	init_question_buttons()
	
	# TODO: this filtered for loop is written many times. Create GameState.get_current_round_questions()
	for q in game_state.questions:
		if q.round == game_state.current_round:
			get_question_button(q).text = ""
		
func pause_game():	
	intro_screen.show()
	main_view.hide()
	question_holder.hide()
		
func reveal_category(cat_idx):
	current_category_slider_idx = cat_idx
	position_categories_slider()
	categories_slider.show()
	var tween = create_tween()

	var sz = main_view.get_rect().size
	tween.tween_property(categories_slider, "position", Vector2(sz.x * (-cat_idx), 0), 0.3)	

func hide_categories_slider():
	var tween = create_tween()
	var sz = main_view.get_rect().size
	tween.tween_property(categories_slider, "position", Vector2(sz.x * -6, 0), 0.3)	

func show_category_names():
	var categories = game["rounds"][game_state.current_round]["categories"]
	for cat_idx in range(len(categories)):
		questionboard.get_child(cat_idx).get_child(0).text = categories[cat_idx]["name"]
		
func init_category_buttons():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)

	#TODO: Merge game and game_state? I'd like a get_current_round_categories()
	var categories = game["rounds"][game_state.current_round]["categories"]
	for cat_i in len(categories):
		var btn = get_category_button(cat_i)
		btn.text = "???"
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_stylebox_override("focus", style_box)
		btn.add_theme_stylebox_override("hover", style_box)
		btn.add_theme_stylebox_override("pressed", style_box)

		category_buttons.append(btn)
		
func init_question_buttons():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)
	
	var categories = game["rounds"][game_state.current_round]["categories"]
	for point_i in len(question_points):
		for cat_i in len(categories):
			var btn = get_question_button(QuestionId.new(game_state.current_round, cat_i, point_i))
			btn.text = str(question_points[point_i])
			btn.add_theme_font_size_override("font_size", 40)
			fixate_button_color(btn, Color(1,1,0))
			btn.add_theme_stylebox_override("normal", style_box)
			btn.add_theme_stylebox_override("hover", style_box)
			btn.add_theme_stylebox_override("pressed", style_box)
			btn.add_theme_stylebox_override("clicked", style_box)

func get_category_button(cat_idx) -> Label:
	return questionboard.get_child(cat_idx).get_child(0)

func get_question_button(question_id: QuestionId):
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
		
func show_question(question_id: QuestionId):
	if question_btn:
		question_btn.free()
		question_btn = null
	
	var points_idx = question_id.question
	var cat_idx = question_id.category
	var categories = game["rounds"][game_state.current_round]["categories"]
	var question = categories[cat_idx]["questions"][points_idx]
	var orig_btn = get_question_button(question_id)
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

	question_holder.add_child(btn)
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	tween.parallel().tween_property(btn, "scale", Vector2(1,1), 0.7)
	tween.tween_interval(1)
	tween.tween_callback(set_question_text)

func mark_question_completed(question_id: QuestionId):
	get_question_button(question_id).text = ""
	
func clear_category_if_complete(cat_idx):
	var btn = category_buttons[cat_idx]
	for row in range(5):
		if get_question_button(QuestionId.new(game_state.current_round, cat_idx, row)).text != "":
			return
	var tween = create_tween()
	var scaler = func(font_color):
		fixate_button_color(btn, font_color)
	
	tween.tween_method(scaler, Color(1,1,1), Color(.2,.2,1), 1)
	
func update_score(team_idx, score):
	scores[team_idx] += score
	get_node('scoreboard/team 1 score').text = "{score}".format({"score": scores[team_idx]})

func select_random_team():
	scoreboard.select_random_team()
