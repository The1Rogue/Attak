extends GridContainer
class_name PtnDisplay


signal clickPly(ply: Ply)

var i = 0


func addPly(ply: Ply):
	assert(ply.ply == i, "ADDED PLY WITH WRONG INDEX!")
	if i % 2 == 0:
		var l = Label.new()
		l.text = str(i/2) + ". "
		add_child(l)
	var b = Button.new()
	b.text = ply.toPTN()
	b.pressed.connect(func(): clickPly.emit(i))
	add_child(b)
	i += 1


func removeLast():
	assert(i > 0, "CANT REMOVE IF THERES NOTHING TO REMOVE")
	remove_child(get_child(-1))
	if i % 2 == 1:
		remove_child(get_child(-1))
	i -= 1
