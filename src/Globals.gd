extends Node


const rPTN = "^([FCS])?([A-Ha-h][1-8])$|^([1-8])?([A-Ha-h][1-8])([<>+-])([1-8]*)(\\*)?$"
const rPlayTak = "^P ([A-Ha-h][1-8]) ?([CW])?$|^M ([A-Ha-h][1-8]) ([A-Ha-h][1-8])((?: [1-8])+)$"
var ptnRegex: RegEx = RegEx.new()
var playTakRegex: RegEx = RegEx.new()

func _ready():
	ptnRegex.compile(rPTN)
	playTakRegex.compile(rPlayTak)

func isMobile():
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
