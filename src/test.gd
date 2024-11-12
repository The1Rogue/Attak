@tool
extends EditorScript

func _run():
	print(not "2".to_int() in [1,2])
