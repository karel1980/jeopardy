extends HBoxContainer

var game = GlobalNode.game
var game_state := GlobalNode.game_state

var current_team = -1

var current_scores: Array[int]
var target_scores: Array[int]

var score_positive_style: StyleBoxFlat
var score_neutral_style: StyleBoxFlat
var score_negative_style: StyleBoxFlat

var highlight_color = Color(1, 1, 0.5, 1)
var mod_color_none = Color(1,1,1,1)

var rotate_delay = 0.1

@onready var prototeam = $prototeam

func _ready() -> void:
	current_scores = zeros(len(game.teams))
	target_scores = zeros(len(game.teams))
	
	prototeam.hide()
	for i in range(len(game.teams)):
		var child = prototeam.duplicate()
		child.show()
		add_child(child)
	
	score_neutral_style = _team_score(0).get_theme_stylebox("normal")
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
	
	for i in range(len(game.teams)):
		_team_name(i).text = game.teams[i]
	

func _teams_ui(i):
	return get_child(i+3)
	
func _team_name(i):
	return get_child(i+3).get_child(0)
	
func _team_score(i):
	return get_child(i+3).get_child(1)
	
func zeros(n):
	var result: Array[int] = []
	result.resize(n)
	result.fill(0)
	return result

func _process(_delta: float) -> void:
	for team_idx in range(len(current_scores)):
		var score_diff = target_scores[team_idx] - current_scores[team_idx]
		if score_diff == 0:
			continue
		current_scores[team_idx] += sign(score_diff) * 2
		update_score_label(team_idx)

func update_score_label(team_idx):
	_team_score(team_idx).text = str(current_scores[team_idx])
	update_score_color(team_idx, current_scores[team_idx])

func _buzzer_animation(idx):
	var rect = _team_name(idx).get_global_rect()
	var splode = get_node("CanvasLayer/explosion")
	splode.position = rect.get_center()
	splode.emission_rect_extents = rect.size / 2
	splode.emitting = true
	
func select_random_team():
	current_team = randi_range(0, 2)
	print("randomly chosen team: ", current_team)

	var t = create_tween()
	
	if current_team == -1: # nobody selected, just highlight team 0
		t.tween_property(_team_name(0), "modulate", mod_color_none, rotate_delay)
		t.tween_callback(func(): $AudioStreamPlayer.play())
	elif current_team == 0: # 0 already selected
		pass
	else:
		bip(t, current_team, 0)

	var transitions = 10 * len(game.teams) + current_team
	for i in range(transitions - 1):
		bip(t, i%len(game.teams), (i+1)%len(game.teams))
		
	t.tween_interval(2)
	bip(t, (transitions+len(game.teams)-1)%len(game.teams), transitions%len(game.teams))
		
func _on_buzzer_accepted(team_idx):
	_buzzer_animation(team_idx)
	highlight_team(team_idx)

func highlight_team(team_idx):
	var t = create_tween()

	if current_team != -1 and current_team != team_idx:
		t.tween_property(_team_name(current_team), "modulate", mod_color_none, 0.2)
		t.parallel().tween_property(_team_name(team_idx), "modulate", highlight_color, 0.2)
		current_team = team_idx
	else:
		t.tween_property(_team_name(current_team), "modulate", highlight_color, 0.2)

func bip(tween, from_idx, to_idx):
	tween.tween_property(_team_name(from_idx), "modulate", mod_color_none, rotate_delay)
	tween.parallel().tween_property(_team_name(to_idx), "modulate", highlight_color, rotate_delay)
	tween.tween_callback(func(): $AudioStreamPlayer.play())

func deselect_team():
	current_team = -1
	for i in range(len(game.teams)):
		_team_name(i).modulate = mod_color_none
	
func set_current_team(team_idx):
	# TODO: add some code to avoid running 2 tweens in parallel (basically disable the button until done)
	var t = create_tween()
	if team_idx != current_team:
		t.tween_property(_team_name(current_team), "modulate", mod_color_none, 0.2)
		current_team = team_idx
		t.tween_property(_team_name(team_idx), "modulate", highlight_color, 0.2)
	
func update_scores(scores, _score_times):
	target_scores = scores
		
func update_score_color(team_idx, value):
	if value == 0:
		_team_score(team_idx).add_theme_stylebox_override("normal", score_neutral_style)
		_team_score(team_idx).add_theme_color_override("font_color", Color(1,1,1,1))
	elif value < 0:
		_team_score(team_idx).add_theme_stylebox_override("normal", score_negative_style)
		_team_score(team_idx).add_theme_color_override("font_color", Color(1,1,1,1))
	else:
		_team_score(team_idx).add_theme_stylebox_override("normal", score_positive_style)
		_team_score(team_idx).add_theme_color_override("font_color", Color(1,1,1,1))
