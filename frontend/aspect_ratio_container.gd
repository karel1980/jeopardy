extends Control


var scores = [ 0, 0, 0 ]
var buttons = []
var category_buttons = []

var margin = 10

var data = JSON.parse_string(FileAccess.open("../jeopardy.json", FileAccess.READ).get_as_text())
var categories = data["categories"]
var question_points = [ 100, 200, 300, 400, 500 ]

var w = (size.x - 6*margin) / 5
var h = (size.y - 7*margin) / 6

func _ready() -> void:
	add_categories()
	add_question_buttons()
	
func add_categories():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)

	for cat_i in len(categories):
		var cat = categories[cat_i]

		var btn = Button.new()
		btn.text = cat["name"]
		btn.custom_minimum_size = Vector2(w, h)
		btn.position = Vector2(margin + cat_i*(w + margin), margin)
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		btn.add_theme_stylebox_override("normal", style_box)
		btn.add_theme_stylebox_override("hover", style_box)
		btn.add_theme_stylebox_override("pressed", style_box)

		category_buttons.append(btn)
		add_child(btn)

func add_question_buttons():	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(.2, .2, 1)
	
	for point_i in len(question_points):
		buttons.append([])
		for cat_i in len(categories):
			var handle_click = func _do_question_clicked():
				display_question(cat_i, point_i)
			var btn = Button.new()
			btn.text = str(question_points[point_i])
			btn.pressed.connect(handle_click)
			btn.position = Vector2(margin +  + cat_i * (w+margin), margin + (point_i + 1) * (h+margin))
			btn.custom_minimum_size = Vector2(w, h)
			btn.add_theme_font_size_override("font_size", 40)
			fixate_button_color(btn, Color(1,1,0))
			btn.add_theme_stylebox_override("normal", style_box)
			btn.add_theme_stylebox_override("hover", style_box)
			btn.add_theme_stylebox_override("pressed", style_box)
			btn.add_theme_stylebox_override("clicked", style_box)

			buttons[-1].append(btn)
			add_child(btn)
			
func fixate_button_color(btn, color):
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_pressed_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_color_override("font_pressed_color", color)


func display_question(cat_idx, points_idx):
	var orig_btn = buttons[points_idx][cat_idx]	
	var btn = orig_btn.duplicate()
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.move_to_front()
	fixate_button_color(btn, Color(1,1,1))

	btn.scale = Vector2(w / size.x, h / size.y)
	btn.size = size
	btn.text = data["categories"][cat_idx]["questions"][points_idx]["q"]
	add_child(btn)
	
	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(1,1), 0.7)
	tween.parallel().tween_property(btn, "scale", Vector2(1, 1), 0.7)
	
	var state = [0]
	var update_button = func():
		if state[0] == 0:
			btn.text = data["categories"][cat_idx]["questions"][points_idx]["a"]
		if state[0] == 1:
			btn.queue_free()
			orig_btn.text = ""
			clear_category_if_complete(cat_idx)
		state[0] += 1
	btn.pressed.connect(update_button)
	
func clear_category_if_complete(cat_idx):
	var btn = category_buttons[cat_idx]
	for row in buttons:
		if row[cat_idx].text != "":
			return
	var tween = create_tween()
	var scaler = func(font_color):
		fixate_button_color(btn, font_color)
	
	tween.tween_method(scaler, Color(1,1,1), Color(.2,.2,1), 1)
	
func update_score(team_idx, score):
	scores[team_idx] += score
	get_node('scoreboard/team 1 score').text = "{score}".format({"score": scores[team_idx]})
	
func _process(_delta: float) -> void:
	pass
