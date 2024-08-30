extends Node2D

var playerview_scene = preload('res://playerview.tscn')
var playerview

var data = JSON.parse_string(FileAccess.open("../jeopardy.json", FileAccess.READ).get_as_text())

func _ready() -> void:
	var win = get_window()
	win.gui_embed_subwindows = false
	
	var playerwin = Window.new()
	playerwin.size = get_tree().root.size
	playerview = playerview_scene.instantiate()
	playerwin.add_child(playerview)
	
	add_child(playerwin)
	
	playerwin.content_scale_aspect = win.content_scale_aspect
	playerwin.content_scale_mode = win.content_scale_mode
	playerwin.content_scale_size = win.content_scale_size
	playerwin.size = win.size

	playerwin.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
func _process(_delta: float) -> void:
	pass
	
func _on_start_game_pressed() -> void:
	playerview.init_game(data)

func on_reveal_category_pressed(cat_idx: int) -> void:
	playerview.reveal_category(cat_idx)


func on_random_team_pressed() -> void:
	playerview.select_random_team()
