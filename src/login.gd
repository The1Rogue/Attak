extends Resource
class_name Login

@export var user: String
@export var password: String

func _init(user: String = "", password: String = ""):
	self.user = user
	self.password = password
