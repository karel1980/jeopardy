extends Object

class_name QuestionId

var round: int
var category: int
var question: int

func _init(round, category, question):
	self.round = round
	self.category = category
	self.question = question

func _to_string() -> String:
	return "%d/%d/%d"%[round, category, question]
