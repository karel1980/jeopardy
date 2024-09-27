extends Node2D

var game = GlobalNode.game
var game_state = GlobalNode.game_state

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoxContainer/TextureRect/team1_name/label.text = "[center]" + game["teams"][0] + "[/center]"
	$BoxContainer/TextureRect/team2_name/label.text = "[center]" + game["teams"][1] + "[/center]"
	$BoxContainer/TextureRect/team3_name/label.text = "[center]" + game["teams"][2] + "[/center]"

	GlobalNode.game_state.scores_updated.connect(update_scores)
	update_scores(game_state.scores, game_state.score_times)
	
func update_scores(scores, _score_times):
	$BoxContainer/TextureRect/team1_score/score.text = str(game_state.scores[0])
	$BoxContainer/TextureRect/team2_score/score.text = str(game_state.scores[1])
	$BoxContainer/TextureRect/team3_score/score.text = str(game_state.scores[2])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
