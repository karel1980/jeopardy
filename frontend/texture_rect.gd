extends TextureRect

var main_scene = preload('res://main.tscn')

func _ready() -> void:
	self.size = get_window().size

func _process(_delta: float) -> void:
	pass

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_tree().change_scene_to_packed(main_scene)
