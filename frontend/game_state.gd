extends Object

class_name GameState

signal scores_updated

static var score_increments = 200
static var no_of_questions = 5
static var question_values = range(score_increments,(no_of_questions+1)*score_increments,score_increments)


var scores: Array[int]
var score_times: Array[int]

var questions: Array[QuestionId] = []
var current_round: int = 0

var current_team_idx: int = -1

func _init(_scores: Array[int], _questions: Array[QuestionId], _current_round: int = 0):
	self.scores = _scores
	self.score_times = zeros(len(_scores))
	self.questions = _questions
	self.current_round = _current_round
	self.current_team_idx = -1

func zeros(n):
	var result: Array[int] = []
	result.resize(n)
	result.fill(0)
	return result

func mark_correct(team_idx: int, question_id: QuestionId):
	update_score(team_idx, question_values[question_id.question])
	current_team_idx = team_idx
	print("selected team for correctness ", team_idx)
	GlobalNode.team_selected.emit()
	

func mark_wrong(team_idx: int, question_id: QuestionId):
	update_score(team_idx, -question_values[question_id.question])

func mark_question_complete(question_id: QuestionId):
	# TODO: this if isn't working, identical questions_ids can occur multiple times. how to implement equals in Godot?
	if question_id not in questions:
		questions.append(question_id)

func is_question_answered_correctly(question_id: QuestionId):
	return question_id in questions
	
func increment_score(team_idx: int, score: int):
	update_score(team_idx, score)
	
func decrement_score(team_idx: int, score: int):
	update_score(team_idx, -score)
	
func update_score(team_idx: int, score: int):
	scores[team_idx] += score
	score_times[team_idx] = score_times.max() + 1
	print("emitting new scores", scores)
	scores_updated.emit(scores, score_times)
	
func load(path: String):
	if FileAccess.file_exists(path):
		var game_state_file = FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(game_state_file.get_as_text())
		game_state_file.close()
		scores.assign(data["scores"])
		if "score_times" in data:
			score_times.assign(data["score_times"])
		questions.clear()
		for d in data["questions"]:
			questions.append(QuestionId.new(int(d[0]), int(d[1]), int(d[2])))

		current_round = int(data["round"])
		if "current_team_index" in data:
			current_team_idx = data["current_team_index"]

func save(path: String):
	var game_state_file = FileAccess.open(path, FileAccess.WRITE)
	var questions_serialized = []
	for q in questions:
		questions_serialized.append([q.round, q.category, q.question])
	
	game_state_file.store_string(JSON.stringify({
		"scores": scores,
		"score_times": score_times,
		"questions": questions_serialized,
		"round": current_round,
		"current_team_index": current_team_idx
	}))
	game_state_file.close()

func get_current_round_questions():
	return questions.filter(func(q): return q.round == current_round)
