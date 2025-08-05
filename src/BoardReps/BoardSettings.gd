extends Resource
class_name BoardSettings

signal update

static func loadOrNew(cls) -> BoardSettings:
	var data
	if ResourceLoader.exists(cls.path):
		ResourceLoader.load_threaded_request(cls.path, "", true)
		data = ResourceLoader.load_threaded_get(cls.path)
		if data != null: # data couldnt load correctly
			data.check()
			return data
	
	data = cls.new()
	data.check()
	data.save()
	return data


func save():
	ResourceSaver.save(self, self.path)


func check():
	pass


static func loadImg(path: String) -> Image:
	var img
	if path.begins_with("res://"):
		img = load(path).get_image()
	else:
		img = Image.load_from_file(path)
	
	if img == null: return null
	if img.is_compressed():
		if img.decompress() != OK:
			return null
	img.fix_alpha_edges()
	return img
