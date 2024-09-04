extends Object

class_name GameState

signal scores_updated

static var question_values = [ 100, 200, 300, 400, 500 ]

var scores: Array[int] = [ 0, 0, 0 ]
var questions: Array[QuestionId] = []
var current_round: int = 0

func _init(scores: Array[int] = [0,0,0], questions: Array[QuestionId] = [], current_round: int = 0):
	self.scores = scores
	self.questions = questions
	self.current_round = current_round
	
# TODO: make team_id the first argument for consistency
func mark_correct(question_id: QuestionId, team_idx: int):
	scores[team_idx] += question_values[question_id.question]
	scores_updated.emit(scores)

# TODO: make team_id the first argument for consistency
func mark_wrong(question_id: QuestionId, team_idx: int):
	scores[team_idx] -= question_values[question_id.question]
	scores_updated.emit(scores)

func mark_question_complete(question_id: QuestionId):
	questions.append(question_id)

func increment_score(team_idx: int, score: int):
	scores[team_idx] += score
	scores_updated.emit(scores)
	
func decrement_score(team_idx: int, score: int):
	scores[team_idx] -= score
	scores_updated.emit(scores)
	
func load(path: String):
	var game_state_file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(game_state_file.get_as_text())
	game_state_file.close()
	scores.assign(data["scores"])
	questions.clear()
	for d in data["questions"]:
		questions.append(QuestionId.new(int(d[0]), int(d[1]), int(d[2])))

	current_round = int(data["round"])

func save(path: String):
	var game_state_file = FileAccess.open(path, FileAccess.WRITE)
	var questions_serialized = []
	for q in questions:
		questions_serialized.append([q.round, q.category, q.question])
	
	game_state_file.store_string(JSON.stringify({
		"scores": scores,
		"questions": questions_serialized,
		"round": current_round
	}))
	game_state_file.close()
