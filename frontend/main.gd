extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_go_to_main_scene()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	_go_to_main_scene()


func _go_to_main_scene():
	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
		get_tree().change_scene_to_file("res://main.tscn")
