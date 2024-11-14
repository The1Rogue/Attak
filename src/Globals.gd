extends Node


const rPTN = "^([FCS])?([A-Ha-h][1-8])$|^([1-8])?([A-Ha-h][1-8])([<>+-])([1-8]*)(\\*)?$"
const rPlayTak = "^P ([A-Ha-h][1-8]) ?([CW])?$|^M ([A-Ha-h][1-8]) ([A-Ha-h][1-8])((?: [1-8])+)$"
var ptnRegex: RegEx = RegEx.new()
var playTakRegex: RegEx = RegEx.new()

var gameUI: GameUI

func _ready():
	ptnRegex.compile(rPTN)
	playTakRegex.compile(rPlayTak)
