extends Object

class_name QuestionId

var round: int
var category: int
var question: int

func _init(_round, _category, _question):
	round = _round
	category = _category
	question = _question

func _to_string() -> String:
	return "%d/%d/%d"%[round, category, question]
