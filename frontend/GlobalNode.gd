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
var game_state: GameState = GameState.new()

func _ready() -> void:
	var state_file_location = game_location + ".state"
	game_state.load(state_file_location)		


func save_state() -> void:
	game_state.save(game_location + ".state")
