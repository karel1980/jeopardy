extends Node2D

var game
var game_state

var highscore = -10000
var winner = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func init_game(game, game_state):
	self.game = game
	self.game_state = game_state
	
	self.game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	print("connecting shizzle")
	self.game_state.connect("scores_updated", Callable(self, "update_scores"))

func _on_game_state_loaded():
	update_winner()
	
func update_scores(scores):
	update_winner()
	
func update_winner():
	var new_highscore = game_state.scores.max()
	var winners = []
	for i in range(len(game["teams"])):
		if game_state.scores[i] == new_highscore:
			winners.append(i)
			
	if new_highscore > highscore:
		winner = winners[0]
	
	highscore = new_highscore
	var text = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]"%[game.teams[winner]]
	print("ttt", text)
	$winner/name.text = text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
