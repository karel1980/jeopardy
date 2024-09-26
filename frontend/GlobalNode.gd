extends Node

signal game_paused
signal game_over
signal round_started(round_number)
signal round_finished
signal category_revealed
signal question_selected
signal question_deselected
signal buzzer_accepted

var game_location = "../jeopardy.json"
var game = JSON.parse_string(FileAccess.open(game_location, FileAccess.READ).get_as_text())
var game_state: GameState = restore_game_state()

func _ready() -> void:
	pass
	
func restore_game_state():
	var result = GameState.new()
	result.load(game_location + ".state")
	return result


func save_state() -> void:
	game_state.save(game_location + ".state")
