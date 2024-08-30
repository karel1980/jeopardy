extends HBoxContainer

var scores = [ 0, 0, 0 ]
var data
var teams

var current_team = -1
var highlight_none = Color(1, 1, 1, 1)
var highlight_color = Color(1, 1, 0.5, 1)

@onready var widgets = [ $"team 1/name", $"team 2/name", $"team 3/name" ]

func select_random_team():
	current_team = randi_range(0, 2)
	print("randomly chosen team: ", current_team)

	var t = create_tween()

	if current_team == -1: # nobody selected, just highlight team 0
		t.tween_property(widgets[0], "modulate", highlight_none, 0.2)
	elif current_team == 0: # 0 already selected
		pass
	else:
		t.tween_property(widgets[current_team], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[0], "modulate", highlight_color, 0.2)

	# TODO: play 'bloop bloop' sound
	for i in range(3):
		t.tween_property(widgets[0], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[1], "modulate", highlight_color, 0.2)
		
		t.tween_property(widgets[1], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[2], "modulate", highlight_color, 0.2)

		t.tween_property(widgets[2], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[0], "modulate", highlight_color, 0.2)
		
	# after 10 iterations team 0 is highlighted
	# we must modulate a bit more until we hit the selected team
	
	if current_team > 0:
		t.tween_property(widgets[0], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[1], "modulate", highlight_color, 0.2)

	if current_team > 1:
		t.tween_property(widgets[1], "modulate", highlight_none, 0.2)
		t.parallel().tween_property(widgets[2], "modulate", highlight_color, 0.2)
		
		
func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func init_game(game_data):
	data = game_data
	teams = data["teams"]

	for i in range(3):
		widgets[i].text = teams[i]

func set_current_team(team_idx):
	# TODO: add some code to avoid running 2 tweens in parallel (basically disable the button until done)
	var t = create_tween()
	if team_idx != current_team:
		t.tween_property(widgets[current_team], "modulate", highlight_none, 0.2)
		current_team = team_idx
		t.tween_property(widgets[team_idx], "modulate", highlight_color, 0.2)
	
