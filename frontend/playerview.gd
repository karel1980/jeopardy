extends Node2D

var intro_screen = preload("res://scenes/intro.tscn")
var halfway_screen = preload("res://scenes/halfway.tscn")
var round_screen = preload("res://scenes/quiz.tscn")
var gameover_screen = preload("res://scenes/gameover.tscn")

@onready var current_screen := $current

@onready var views = {
	"round_screen": round_screen,
	"intro_screen": intro_screen,
	"halfway_screen": halfway_screen,
	"gameover_screen": gameover_screen
}

var normal_font = load("res://assets/fonts/LilitaOne-Regular.ttf")

var game = GlobalNode.game
var game_state = GlobalNode.game_state

var next_view: String = "intro_screen"

var scores = [ 0, 0, 0 ]
var category_buttons = []

var shown_question = []
var question_btn
var orig_question_btn

var margin = 10

var question_points = [ 100, 200, 300, 400, 500 ]

var cat_tween = null
var cat_tween2 = null
var cat_button = null

func _ready() -> void:
	$FadePanel.modulate = Color(0,0,0,0)
	
	GlobalNode.round_started.connect(start_round)
	GlobalNode.round_finished.connect(on_round_finished)
	GlobalNode.game_paused.connect(pause_game)
	GlobalNode.game_over.connect(on_game_over)
	
	$AnimationPlayer.animation_finished.connect(on_animation_finished)
	
	replace_view("intro_screen")
	
func _process(_delta: float) -> void:
	pass
	
func on_animation_finished(anim_name):
	if anim_name == "fade_out":
		replace_view(next_view)
		$AnimationPlayer.play("fade_in")

func replace_view(_next_view):
	if current_screen.get_child_count() > 0:
		current_screen.remove_child(current_screen.get_child(0))
	current_screen.add_child(views[_next_view].instantiate())

func transition_to_view(view_name: String):
	if next_view == view_name:
		return
	next_view = view_name
	print("Starting transition to ", view_name)
	$AnimationPlayer.play("fade_out")

# TODO: what signal is this bound to
func on_round_finished():
	# TODO: pass round number. if this was the last round, go to the next viww (halfway or final)
	transition_to_view("halfway_screen")
	
func start_round(_round_idx):
	transition_to_view("round_screen")
			
func pause_game():	
	transition_to_view("intro_screen")
	
func update_score(team_idx, score):
	scores[team_idx] += score
	get_node('scoreboard/team 1 score').text = "{score}".format({"score": scores[team_idx]})

func on_game_over():
	transition_to_view("gameover_screen")
