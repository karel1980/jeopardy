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

var base_dir: String
var game
var game_state: GameState
var state_path: String

func load_game(base_dir, game_json_path, state_json_path):
	game_json_path = base_dir + '/' + game_json_path
	state_path = game_json_path + '.state'
	game = JSON.parse_string(FileAccess.open(game_json_path, FileAccess.READ).get_as_text())
	game_state = restore_game_state(state_path)

func _ready() -> void:
	pass
	
func restore_game_state(path):
	var result = GameState.new(zeros(len(game.teams)), [])
	result.load(path)
	return result


func zeros(n):
	var result: Array[int] = []
	result.resize(n)
	result.fill(0)
	return result


func save_state() -> void:
	print("saving to ", state_path)
	game_state.save(state_path)
