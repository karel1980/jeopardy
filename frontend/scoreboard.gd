extends HBoxContainer

var scores = [ 0, 0, 0 ]
var data
var teams

@onready var widgets = [ $"team 1/name", $"team 2/name", $"team 3/name" ]

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func init_game(game_data):
	data = game_data
	teams = data["teams"]

	for i in range(3):
		widgets[i].text = teams[i]
	set_current_team(0)

func set_current_team(team_idx):
	var default_team = StyleBoxFlat.new()
	var active_team = StyleBoxFlat.new()
	active_team.bg_color = Color(.4,.4,1)

	for w in range(len(widgets)):
		if w == team_idx:
			widgets[w].add_theme_stylebox_override("normal", active_team)
		else:
			widgets[w].add_theme_stylebox_override("normal", default_team)
		
	
