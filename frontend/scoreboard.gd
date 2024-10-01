extends HBoxContainer

var game = GlobalNode.game
var game_state := GlobalNode.game_state

var current_team = -1

var current_scores: Array[int] = [0,0,0]
var target_scores: Array[int] = [0,0,0]

var score_positive_style: StyleBoxFlat
var score_neutral_style: StyleBoxFlat
var score_negative_style: StyleBoxFlat

var highlight_color = Color(1, 1, 0.5, 1)
var mod_color_none = Color(1,1,1,1)

@onready var teams_ui = [ $"team 1", $"team 2", $"team 3"]
@onready var team_names = [ $"team 1/name", $"team 2/name", $"team 3/name" ]
@onready var score_labels = [ $"team 1/score", $"team 2/score", $"team 3/score" ]

func _ready() -> void:
	score_neutral_style = score_labels[0].get_theme_stylebox("normal")
	score_positive_style = score_neutral_style.duplicate()
	score_positive_style.border_color = Color(.5,1,.5)
	score_negative_style = score_neutral_style.duplicate()
	score_negative_style.border_color = Color(1,.2,.2)
	
	GlobalNode.random_team_selection_requested.connect(select_random_team)
	GlobalNode.buzzer_accepted.connect(_on_buzzer_accepted)
	GlobalNode.team_deselected.connect(deselect_team)
	GlobalNode.game_state.scores_updated.connect(update_scores)
	
	target_scores = game_state.scores.duplicate()
	current_scores = game_state.scores.duplicate()
	for team_idx in range(len(current_scores)):
		update_score_label(team_idx)
	
	for i in range(3):
		team_names[i].text = game.teams[i]
	
func _process(_delta: float) -> void:
	for team_idx in range(len(current_scores)):
		var score_diff = target_scores[team_idx] - current_scores[team_idx]
		if score_diff == 0:
			continue
		current_scores[team_idx] += sign(score_diff) * 2
		update_score_label(team_idx)

func update_score_label(team_idx):
	score_labels[team_idx].text = str(current_scores[team_idx])
	update_score_color(team_idx, current_scores[team_idx])

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
		t.tween_property(team_names[0], "modulate", mod_color_none, 0.2)
	elif current_team == 0: # 0 already selected
		pass
	else:
		t.tween_property(team_names[current_team], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[0], "modulate", highlight_color, 0.2)

	# TODO: play 'bloop bloop' sound
	for i in range(3):
		t.tween_property(team_names[0], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[1], "modulate", highlight_color, 0.2)
		
		t.tween_property(team_names[1], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[2], "modulate", highlight_color, 0.2)

		t.tween_property(team_names[2], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[0], "modulate", highlight_color, 0.2)
		
	# after 10 iterations team 0 is highlighted
	# we must modulate a bit more until we hit the selected team
	
	# TODO: for humorous effect, make the last transition after a longish delay
	
	if current_team > 0:
		t.tween_property(team_names[0], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[1], "modulate", highlight_color, 0.2)

	if current_team > 1:
		t.tween_property(team_names[1], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[2], "modulate", highlight_color, 0.2)
		
func _on_buzzer_accepted(team_idx):
	_buzzer_animation(team_idx)
	highlight_team(team_idx)

func highlight_team(team_idx):
	var t = create_tween()

	if current_team != -1 and current_team != team_idx:
		t.tween_property(team_names[current_team], "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(team_names[team_idx], "modulate", highlight_color, 0.2)
		current_team = team_idx
	else:
		t.tween_property(team_names[team_idx], "modulate", highlight_color, 0.2)

func deselect_team():
	current_team = -1
	team_names[0].modulate = mod_color_none
	team_names[1].modulate = mod_color_none
	team_names[2].modulate = mod_color_none
	
func set_current_team(team_idx):
	# TODO: add some code to avoid running 2 tweens in parallel (basically disable the button until done)
	var t = create_tween()
	if team_idx != current_team:
		t.tween_property(team_names[current_team], "modulate", mod_color_none, 0.2)
		current_team = team_idx
		t.tween_property(team_names[team_idx], "modulate", highlight_color, 0.2)
	
func update_scores(scores, _score_times):
	target_scores = scores
		
func update_score_color(team_idx, value):
	if value == 0:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_neutral_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(1,1,1,1))
	elif value < 0:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_negative_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(1,1,1,1))
	else:
		score_labels[team_idx].add_theme_stylebox_override("normal", score_positive_style)
		score_labels[team_idx].add_theme_color_override("font_color", Color(1,1,1,1))
