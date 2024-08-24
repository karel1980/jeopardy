extends GridContainer

var categories = [ "Cat one", "Cat 2", "cats", "dogs", "doodas" ]
var question_points = [ 100, 200, 300, 400, 500 ]

func _ready() -> void:
	#custom_minimum_size = get_window().size
	add_categories()
	add_question_buttons()
	
func add_categories():
	for cat in categories:
		var btn = Button.new()
		btn.text = cat
		btn.custom_minimum_size = Vector2(size.x / 5, size.y / 6)
		add_child(btn)

func add_question_buttons():
	for point_i in len(question_points):
		for cat_i in len(categories):
			var display = "TODO: display {category} for {points}".format({ "category": categories[cat_i], "points": question_points[point_i]})
			var handle_click = func _do_question_clicked():
				print(display)
			var btn = Button.new()
			btn.text = str(question_points[point_i])
			btn.pressed.connect(handle_click)
			btn.custom_minimum_size = Vector2(size.x / 5, size.y / 6)
			add_child(btn)

func _process(delta: float) -> void:
	pass
