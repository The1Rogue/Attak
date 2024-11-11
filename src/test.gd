@tool
extends EditorScript

func _run():
	var m = 2**32
	var t = "Sometimes, you need to run code just one time to automate a certain task that is not available in the editor out of the box. Some examples might be:"
	for i in t.split(" "):
		var h = i.hash()
		print(h, "      ",  h / (m as float))
		
	print(m, "      ", m as float)
