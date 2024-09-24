extends Node2D

var game
var game_state

func _ready() -> void:
	pass
	
func init_game(game, game_state):
	self.game = game
	self.game_state = game_state
	
	self.game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	print("connecting shizzle")
	self.game_state.connect("scores_updated", Callable(self, "update_scores"))

func _on_game_state_loaded():
	update_winner()
	
func update_scores(scores, score_times):
	update_winner()
	
func update_winner():
	var highest_score = game_state.scores.max()
	var highest_scoring = []
	for team_idx in range(len(game_state.scores)):
		if game_state.scores[team_idx] == highest_score:
			highest_scoring.append(team_idx)

	var winner = highest_scoring[0]
	
	if len(highest_scoring) > 1:
		var earliest = game_state.score_times.max()
		for team_idx in highest_scoring:
			if game_state.score_times[team_idx] < earliest:
				winner = team_idx
				earliest = game_state.score_times[team_idx]
	
	var text = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]"%[game.teams[winner]]
	$winner/name.text = text
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
