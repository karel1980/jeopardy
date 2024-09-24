extends HBoxContainer

#TODO: rename to game
var data
var game_state: GameState

#TODO: get team names from data?
var teams
var current_team = -1

var score_positive_style := StyleBoxFlat.new()
var score_neutral_style
var score_negative_style := StyleBoxFlat.new()

var highlight_color = Color(1, 1, 0.5, 1)
var mod_color_none = Color(1,1,1,1)

@onready var teams_ui = [ $"team 1", $"team 2", $"team 3"]
@onready var widgets = [ $"team 1/name", $"team 2/name", $"team 3/name" ]
@onready var score_labels = [ $"team 1/score", $"team 2/score", $"team 3/score" ]

func _ready() -> void:
	score_neutral_style = score_labels[0].get_theme_stylebox("normal")
	score_positive_style.bg_color = Color(0,1,0,1)
	score_negative_style.bg_color = Color(1,.2,.2,1)
	
	get_tree().get_current_scene().buzzer_accepted.connect(_buzzer_animation)
	
func _process(_delta: float) -> void:
	pass

func _buzzer_animation(idx):
	var rect = teams_ui[idx].get_node("name").get_global_rect()
	var splode = get_node("CanvasLayer/explosion")
	splode.position = rect.get_center()
	splode.emission_rect_extents = rect.size / 2
	splode.emitting = true
	
func select_random_team():
	current_team = randi_range(0, 2)
	print("randomly chosen team: ", current_team)

	var t = create_tween()

	if current_team == -1: # nobody selected, just highlight team 0
		t.tween_property(widgets[0], "modulate", mod_color_none, 0.2)
	elif current_team == 0: # 0 already selected
		pass
	else:
		t.tween_property(widgets[current_team], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[0], "modulate", highlight_color, 0.2)

	# TODO: play 'bloop bloop' sound
	for i in range(3):
		t.tween_property(widgets[0], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[1], "modulate", highlight_color, 0.2)
		
		t.tween_property(widgets[1], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[2], "modulate", highlight_color, 0.2)

		t.tween_property(widgets[2], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[0], "modulate", highlight_color, 0.2)
		
	# after 10 iterations team 0 is highlighted
	# we must modulate a bit more until we hit the selected team
	
	# TODO: for humorous effect, make the last transition after a longish delay
	
	if current_team > 0:
		t.tween_property(widgets[0], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[1], "modulate", highlight_color, 0.2)

	if current_team > 1:
		t.tween_property(widgets[1], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[2], "modulate", highlight_color, 0.2)
		
func highlight_team(team_idx):
	var t = create_tween()

	if current_team != -1 and current_team != team_idx:
		t.tween_property(widgets[current_team], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(widgets[team_idx], "modulate", highlight_color, 0.2)
		current_team = team_idx
	else:
		t.tween_property(widgets[team_idx], "modulate", highlight_color, 0.2)

func unselect_team():
	current_team = -1
	widgets[0].modulate = mod_color_none
	widgets[1].modulate = mod_color_none
	widgets[2].modulate = mod_color_none

func init_game(_game_data, _game_state):
	data = _game_data
	self.game_state = _game_state
	teams = data["teams"]
	
	self.game_state.connect("game_state_loaded", Callable(self, "_on_game_state_loaded"))
	self.game_state.connect("scores_updated", Callable(self, "update_scores"))
	
func set_current_team(team_idx):
	# TODO: add some code to avoid running 2 tweens in parallel (basically disable the button until done)
	var t = create_tween()
	if team_idx != current_team:
		t.tween_property(widgets[current_team], "modulate", mod_color_none, 0.2)
		current_team = team_idx
		t.tween_property(widgets[team_idx], "modulate", highlight_color, 0.2)
	
func _on_game_state_loaded():
	$"team 1/name".text = data["teams"][0]
	$"team 2/name".text = data["teams"][1]
	$"team 3/name".text = data["teams"][2]
	update_scores(game_state.scores, game_state.score_times)
	
func update_scores(scores, _score_times):
	for team_idx in range(len(scores)):
		score_labels[team_idx].text = str(scores[team_idx])
		update_score_color(team_idx)
		
func update_score_color(team_idx):
	if game_state.scores[team_idx] == 0:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_neutral_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(1,1,1,1))
	elif game_state.scores[team_idx] < 0:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_negative_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(1,1,1,1))
	else:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_positive_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(0,0,0,1))
