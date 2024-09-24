extends Node2D

var game
var game_state

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func init_game(_game, _game_state):
	self.game = _game
	self.game_state = _game_state
	
	self.game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	self.game_state.connect("scores_updated", Callable(self, "update_scores"))

func _on_game_state_loaded():
	update_scores(self.game_state.scores, self.game_state.score_times)
	$BoxContainer/TextureRect/team1_name/label.text = "[center]" + game["teams"][0] + "[/center]"
	$BoxContainer/TextureRect/team2_name/label.text = "[center]" + game["teams"][1] + "[/center]"
	$BoxContainer/TextureRect/team3_name/label.text = "[center]" + game["teams"][2] + "[/center]"
	
func update_scores(scores, _score_times):
	$BoxContainer/TextureRect/team1_score/score.text = str(game_state.scores[0])
	$BoxContainer/TextureRect/team2_score/score.text = str(game_state.scores[1])
	$BoxContainer/TextureRect/team3_score/score.text = str(game_state.scores[2])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
