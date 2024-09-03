extends Node2D

@onready var intro_screen = $intro_screen
@onready var categories_slider := $categories_slider
@onready var question_holder := $question_holder
@onready var main_view := $main_view
@onready var questionboard = $main_view/questionboard
@onready var scoreboard = $main_view/scoreboard
@onready var camera := $Camera2D

var game
var categories
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
	print("playerview ready")

	init_category_buttons()
	init_categories_slider()
	init_question_buttons()

	scoreboard.init_game(game)

	pause_game()
	
	get_viewport().connect("screen_resized", on_resize)
	
func on_resize():
	print("yolo")
	
func _process(_delta: float) -> void:
	pass
	
func init_game(game_data):
	game = game_data
	categories = game["rounds"][0]["categories"]
	
func init_categories_slider():
	current_category_slider_idx = -1
	for btn in categories_slider.get_children():
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(.2, .2, 1)
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_font_size_override("font_size", 40)
	
	for cat_idx in range(len(categories)):
		categories_slider.get_child(cat_idx).text = categories[cat_idx]["name"]

	position_categories_slider(current_category_slider_idx)

func position_categories_slider(cat_idx):
	var sz = main_view.get_rect().size
	categories_slider.position = Vector2(-current_category_slider_idx * sz.x, 0)
	categories_slider.size = Vector2(sz.x * 5, sz.y)

	
func start_game():	
	intro_screen.hide()
	main_view.show()
	question_holder.show()
		
func start_round(round_idx):
	var round = game["rounds"][round_idx]
	categories = round["categories"]
	init_category_buttons()
	init_categories_slider()
	init_question_buttons()
		
func pause_game():	
	intro_screen.show()
	main_view.hide()
	question_holder.hide()
		
func reveal_category(cat_idx):
	position_categories_slider(cat_idx)
	current_category_slider_idx = cat_idx
	categories_slider.show()
	var tween = create_tween()

	var sz = main_view.get_rect().size
	tween.tween_property(categories_slider, "position", Vector2(sz.x * (-cat_idx), 0), 0.3)	

func hide_categories_slider():
	var tween = create_tween()
	var sz = main_view.get_rect().size
	tween.tween_property(categories_slider, "position", Vector2(sz.x * -6, 0), 0.3)	

func show_category_names():
	for cat_idx in range(len(categories)):
		questionboard.get_child(cat_idx).get_child(0).text = categories[cat_idx]["name"]
		
func init_category_buttons():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)

	for cat_i in len(categories):
		var btn = get_category_button(cat_i)
		btn.text = "???"
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_stylebox_override("hover", style_box)
		btn.add_theme_stylebox_override("pressed", style_box)

		category_buttons.append(btn)
		
func init_question_buttons():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)
	
	for point_i in len(question_points):
		for cat_i in len(categories):
			var btn = get_question_button(cat_i, point_i)
			btn.text = str(question_points[point_i])
			btn.add_theme_font_size_override("font_size", 40)
			fixate_button_color(btn, Color(1,1,0))
			btn.add_theme_stylebox_override("normal", style_box)
			btn.add_theme_stylebox_override("hover", style_box)
			btn.add_theme_stylebox_override("pressed", style_box)
			btn.add_theme_stylebox_override("clicked", style_box)

func get_category_button(cat_idx) -> Label:
	return questionboard.get_child(cat_idx).get_child(0)

func get_question_button(cat_idx, question_idx):
	return questionboard.get_child(cat_idx).get_child(question_idx + 1)

func fixate_button_color(btn, color):
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_pressed_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_pressed_color", color)

func hide_question():
	if question_btn:
		var free_when_done = func():
			question_btn.queue_free()
			question_btn = null
		var t = create_tween()
		t.tween_property(question_btn, "scale", Vector2(orig_question_btn.get_global_rect().size.x / question_btn.size.x, orig_question_btn.get_global_rect().size.y / question_btn.size.y), 0.7)
		t.parallel().tween_property(question_btn, "position", orig_question_btn.get_global_position(), 0.7)
		t.tween_callback(free_when_done)
		
func show_question(cat_idx, points_idx):
	if question_btn:
		question_btn.queue_free()
		question_btn = null
	
	var question = categories[cat_idx]["questions"][points_idx]
	var orig_btn = get_question_button(cat_idx, points_idx)
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

func mark_question_completed(cat_idx, question_idx):
	get_question_button(cat_idx, question_idx).text = ""
	
func clear_category_if_complete(cat_idx):
	var btn = category_buttons[cat_idx]
	for row in range(5):
		if get_question_button(cat_idx, row).text != "":
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
