class_name QuestionLabel

extends Label

var disappearing = false
var question
var points: String
var orig_pos: Vector2
var orig_size: Vector2
var max_size: Vector2
var small_scale: Vector2

var points_settings = LabelSettings.new()
var question_settings = LabelSettings.new()	
var answer_settings = LabelSettings.new()

var normal_font = load("res://assets/fonts/LilitaOne-Regular.ttf")
var pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")

func _init(question, points, orig_pos: Vector2, orig_size: Vector2, max_size: Vector2):
	self.question = question
	self.points = str(points)
	self.orig_pos = orig_pos
	self.orig_size = orig_size
	self.max_size = max_size
	self.small_scale = Vector2(orig_size.x / max_size.x, orig_size.y / max_size.y)
	
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0,0,1)
	add_theme_stylebox_override("normal", box)
	
	points_settings.font = pixel_font
	points_settings.font_color = Color(1,1,0)
	points_settings.font_size = 60
	
	question_settings.font = normal_font
	question_settings.font_color = Color(1,1,1)
	question_settings.font_size = 52

	answer_settings.font = normal_font
	answer_settings.font_color = Color(1,1,1)
	answer_settings.font_size = 52
	
func _ready() -> void:
	position = orig_pos
	size = max_size
	scale = small_scale
	
	label_settings = points_settings

	text = points
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD
	
	GlobalNode.question_deselected.connect(_on_question_deselected)
	GlobalNode.question_completed.connect(_on_question_completed)
	GlobalNode.question_answered_correctly.connect(show_answer)
	GlobalNode.answer_revealed.connect(show_answer)
	GlobalNode.buzzers_enabled.connect(reveal_question)
	
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(0,0), 0.7)
	tween.parallel().tween_property(self, "scale", Vector2(1,1), 0.7)

func _on_question_deselected():
	disappear()
	
func _on_question_completed():
	disappear()
	
func reveal_question(question_id):
	if "image" in question:
		var color_rect = ColorRect.new()
		color_rect.color = Color(1, 1, 1, .8)
		color_rect.size = max_size

		var rect = TextureRect.new()
		rect.texture = ImageTexture.create_from_image(Image.load_from_file("../" + question["image"]))
		rect.ignore_texture_size = true
		rect.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		rect.size_flags_horizontal = Control.SIZE_EXPAND
		rect.size_flags_vertical = Control.SIZE_EXPAND
		rect.size = max_size
		
		color_rect.add_child(rect)
		add_child(color_rect)
	else:
		label_settings = question_settings
		text = question["q"]
	
func show_answer(question_id: QuestionId):
	if "image" in question:
		for c in get_children():
			c.queue_free()
	
	label_settings = answer_settings
	text = question["a"]

func disappear():
	if disappearing:
		return

	var tween = create_tween()
	tween.tween_property(self, "position", orig_pos, 0.7)
	tween.parallel().tween_property(self, "scale", small_scale, 0.7)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	pass
