extends Node

signal game_paused
signal game_over
signal round_started(round_number)
signal random_team_selection_requested
signal round_finished
signal category_revealed
signal question_selected
signal buzzers_enabled
signal answer_revealed
signal question_answered_correctly
signal question_deselected
signal question_completed
signal buzzer_accepted
signal team_deselected

var game_location = "../jeopardy.json"
var game = JSON.parse_string(FileAccess.open(game_location, FileAccess.READ).get_as_text())
var game_state: GameState = restore_game_state()

func _ready() -> void:
	pass
	
func restore_game_state():
	var result = GameState.new(zeros(len(game.teams)), [])
	result.load(game_location + ".state")
	return result


func zeros(n):
	var result: Array[int] = []
	result.resize(n)
	result.fill(0)
	return result


func save_state() -> void:
	game_state.save(game_location + ".state")
