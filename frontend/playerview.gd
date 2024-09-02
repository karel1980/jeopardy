extends Node2D

@onready var intro_screen = $VBoxContainer/intro_screen
@onready var questionboard = $VBoxContainer/questionboard
@onready var scoreboard = $VBoxContainer/scoreboard
@onready var camera := $Camera2D

var game
var categories

var scores = [ 0, 0, 0 ]
var category_buttons = []

var shown_question = []
var question_btn

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

	intro_screen.show()
	questionboard.hide()
	scoreboard.hide()
	
func _process(_delta: float) -> void:
	pass
	
func init_game(game_data):
	game = game_data
	categories = game["categories"]
	
func init_categories_slider():
	for btn in $categories_slider.get_children():
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(.2, .2, 1)
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_font_size_override("font_size", 40)
	
	for cat_idx in range(len(categories)):
		$categories_slider.get_child(cat_idx).text = categories[cat_idx]["name"]

	$categories_slider.position = Vector2(get_viewport().size.x, 0)
	$categories_slider.size = Vector2(get_viewport().size.x * 5, get_viewport().size.y)
	
func start_game():	
	intro_screen.hide()
	questionboard.show()
	scoreboard.show()
		
func pause_game():	
	intro_screen.show()
	questionboard.hide()
	scoreboard.hide()
		
func reveal_category(cat_idx):
	$categories_slider.show()
	var tween = create_tween()
	tween.tween_property($categories_slider, "position", Vector2(get_viewport().size.x * (-cat_idx), 0), 0.3)	

func hide_categories_slider():
	var tween = create_tween()
	tween.tween_property($categories_slider, "position", Vector2(get_viewport().size.x * -6, 0), 0.3)	

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
		question_btn.queue_free()
		question_btn = null
		
func show_question(cat_idx, points_idx):
	if question_btn:
		question_btn.queue_free()
		question_btn = null
		
	var orig_btn = get_question_button(cat_idx, points_idx)
	var btn = orig_btn.duplicate()
	# TODO: create a nice animation
	question_btn = btn
	shown_question = [cat_idx, points_idx]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.move_to_front()
	add_child(btn)
	fixate_button_color(btn, Color(1,1,1))
	var sz = get_window().size

	btn.text = categories[cat_idx]["questions"][points_idx]["q"]
	
	btn.position = Vector2(1, 1)
	print(questionboard.size)
	btn.size = questionboard.size
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	
	#var state = [0]
	#var update_button = func():
		#if state[0] == 0:
			#btn.text = categories[cat_idx]["questions"][points_idx]["a"]
		#if state[0] == 1:
			#btn.queue_free()
			#orig_btn.text = ""
			#clear_category_if_complete(cat_idx)
		#state[0] += 1
	#btn.pressed.connect(update_button)
	
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
