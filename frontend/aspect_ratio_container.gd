extends Control


var scores = [ 0, 0, 0 ]
var buttons = []

var margin = 10

var data = JSON.parse_string(FileAccess.open("../jeopardy.json", FileAccess.READ).get_as_text())
var categories = data["categories"]
var question_points = [ 100, 200, 300, 400, 500 ]

func _ready() -> void:
	update_team_names(data["teams"])
	
	add_categories()
	add_question_buttons()
	
func update_team_names(teams):
	get_node('../scoreboard/team 1 name').text = teams[0]
	get_node('../scoreboard/team 2 name').text = teams[1]
	get_node('../scoreboard/team 3 name').text = teams[2]
	
func add_categories():
	var w = (size.x - 4*margin) / 5
	var h = (size.y - 5*margin) / 6

	for cat_i in len(categories):
		var cat = categories[cat_i]

		var btn = Button.new()
		btn.text = cat["name"]
		btn.custom_minimum_size = Vector2(w, h)
		btn.position = Vector2(cat_i*(w + margin), 0)
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(btn)

func add_question_buttons():
	var w = (size.x - 4*margin) / 5
	var h = (size.y - 5*margin) / 6
	
	for point_i in len(question_points):
		buttons.append([])
		for cat_i in len(categories):
			var handle_click = func _do_question_clicked():
				display_question(cat_i, point_i)
			var btn = Button.new()
			btn.text = str(question_points[point_i])
			btn.pressed.connect(handle_click)
			btn.position = Vector2(cat_i * (w+margin), (point_i + 1) * (h+margin))
			btn.custom_minimum_size = Vector2(w, h)
			btn.add_theme_font_size_override("font_size", 40)
			
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(.2, .2, 1)
			btn.add_theme_stylebox_override("normal", style_box)
			btn.add_theme_stylebox_override("hover", style_box)
			btn.add_theme_stylebox_override("pressed", style_box)

			buttons[-1].append(btn)
			add_child(btn)

func display_question(cat_idx, points_idx):
	var orig_btn = buttons[points_idx][cat_idx]	
	var btn = orig_btn.duplicate()
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(btn)
	
	var display = "TODO: display {category} for {points}".format({ "category": categories[cat_idx], "points": question_points[points_idx]})
	print(display)

	btn.move_to_front()

	var tween = create_tween()
	tween.tween_property(btn, "position", Vector2(0,0), 0.7)
	tween.parallel().tween_property(btn, "size", size, 0.7)
	
	var state = [0]
	var update_button = func():
		if state[0] == 0:
			btn.text = data["categories"][cat_idx]["questions"][points_idx]["q"]
		if state[0] == 1:
			btn.text = data["categories"][cat_idx]["questions"][points_idx]["a"]
		if state[0] == 2:
			btn.queue_free()
			orig_btn.text = "---"
		state[0] += 1
	btn.pressed.connect(update_button)
	
func update_score(team_idx, score):
	scores[team_idx] += score
	get_node('scoreboard/team 1 score').text = "{score}".format({"score": scores[team_idx]})
	
func _process(_delta: float) -> void:
	pass
