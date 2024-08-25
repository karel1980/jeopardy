extends Button


var main_scene = preload('res://main.tscn')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = "Start test game"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)
