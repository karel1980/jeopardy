extends Node2D

var base_dir

func _ready() -> void:
	base_dir = DirAccess.open('..').get_current_dir()
	$Panel/Label.text = base_dir

func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	GlobalNode.load_game(base_dir, "jeopardy.json", "jeopardy.json.state")
	var main = preload("res://scenes/main.tscn")
	get_tree().change_scene_to_packed(main)
