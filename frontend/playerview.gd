extends Node2D

@onready var intro_screen = $VBoxContainer/intro_screen
@onready var questionboard = $VBoxContainer/questionboard
@onready var scoreboard = $VBoxContainer/scoreboard
@onready var camera := $Camera2D

var game
var categories

var scores = [ 0, 0, 0 ]
var category_buttons = []

var margin = 10

var question_points = [ 100, 200, 300, 400, 500 ]

var cat_tween = null
var cat_tween2 = null
var cat_button = null

func _ready() -> void:
	intro_screen.show()
	questionboard.hide()
	scoreboard.hide()
	
func _process(delta: float) -> void:
	pass

func init_game(game_data):
	
	game = game_data
	categories = game["categories"]
	scoreboard.init_game(game_data)
	
	intro_screen.hide()
	questionboard.show()
	scoreboard.show()
	
	init_category_buttons()
	init_question_buttons()
	
func reveal_category(cat_idx):
	var sz = get_window().size

	if cat_tween2:
		# still cleaning up
		return
		
	if cat_tween:
		var cleanup = func():
			cat_tween = null
			cat_tween2 = null
			cat_button.queue_free()
		cat_tween2 = create_tween()
		cat_tween2.tween_property(cat_button, "position", Vector2(-sz.x, 0), 0.7)
		cat_tween2.tween_callback(cleanup)
		return
		
	cat_button = get_category_button(cat_idx).duplicate()
	cat_button.position = Vector2(sz.x, 0)
	cat_button.text = categories[cat_idx].name
	cat_button.size = sz
	cat_button.add_theme_font_size_override("font_size",50)
	
	add_child(cat_button)
	
	var set_category_name = func():
		get_category_button(cat_idx).text = categories[cat_idx].name
		
	cat_tween = create_tween()
	cat_tween.tween_property(cat_button, "position", Vector2(0, 0), 0.7)
	cat_tween.tween_callback(set_category_name)
	
func init_category_buttons():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)

	for cat_i in len(categories):
		var cat = categories[cat_i]

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
			var handle_click = func _do_question_clicked():
				display_question(cat_i, point_i)
			var btn = get_question_button(cat_i, point_i)
			btn.text = str(question_points[point_i])
			btn.pressed.connect(handle_click)
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

func display_question(cat_idx, points_idx):
	var orig_btn = get_question_button(cat_idx, points_idx)
	var btn = orig_btn.duplicate()
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.move_to_front()
	fixate_button_color(btn, Color(1,1,1))

	btn.text = categories[cat_idx]["questions"][points_idx]["q"]
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	tween.parallel().tween_property(btn, "scale", Vector2(1, 1), 0.7)
	
	var state = [0]
	var update_button = func():
		if state[0] == 0:
			btn.text = categories[cat_idx]["questions"][points_idx]["a"]
		if state[0] == 1:
			btn.queue_free()
			orig_btn.text = ""
			clear_category_if_complete(cat_idx)
		state[0] += 1
	btn.pressed.connect(update_button)
	
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
