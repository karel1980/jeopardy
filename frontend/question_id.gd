extends Object

class_name QuestionId

var game
var round: int
var category: int
var question: int

func _init(game, round, category, question):
	self.game = game
	self.round = round
	self.category = category
	self.question = question
