extends Interface
class_name PlayTakI

const url = "playtak.com:9999"

@export var menu: TabMenu
@export var loginMenu: LoginMenu
@export var seekMenu: SeekList
@export var watchMenu: WatchList


var socket: WebSocketPeer = WebSocketPeer.new()
var active: bool = false
var activeUsername: String = ""

var activeGame: String
var pingtime: float = 0

signal addSeek(seek: SeekData, id: int)
signal removeSeek(id: int)

signal addGame(game: GameData, id: int)
signal removeGame(id: int)



func signInGuest() -> bool:
	return await signIn("Guest", "")


func signIn(username: String, password: String) -> bool:
	if active: return false #already active
	
	socket.supported_protocols = PackedStringArray(["binary"])
	
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		return false
	
	var packet: String = await awaitPacket() #should be welcome packet
	packet = await awaitPacket() #should be login request
	
	socket.send_text("Login %s %s" % [username, password])
	packet = await awaitPacket() #confirmation or rejection
	
	if packet.begins_with("Welcome"):
		active = true
		activeUsername = packet.substr(8, packet.length()-9)
		
		Chat.rooms["Global"] = Chat.new(self, "Global", Chat.GLOBAL)
		menu.addNode(Chat.rooms["Global"], "Chat: Global", false)
		
		print("successfully logged in as %s" % activeUsername)
		return true
	
	print("failed to login")
	socket.close()
	return false


func logout():
	active = false
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()
		while socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
			await get_tree().create_timer(.1).timeout
			socket.poll()
	
	seekMenu.clear()
	watchMenu.clear()
	for chat in Chat.rooms:
		Chat.rooms[chat].remove()
	Chat.rooms.clear()
	
	activeUsername = ""
	activeGame = ""
	


func awaitPacket() -> String:
	while socket.get_available_packet_count() < 1:
		await get_tree().create_timer(.1).timeout
		socket.poll()
	return getPacket()


func getPacket() -> String:
	return socket.get_packet().get_string_from_utf8().rstrip("\n")


func _process(delta: float):
	if not active: return
	
	pingtime += delta
	if pingtime >= 30:
		socket.send_text("PING")
		pingtime -= 30
	
	socket.poll()
	var state = socket.get_ready_state()
	if state != WebSocketPeer.STATE_OPEN:
		print("websocket isnt open while it should be")
		Globals.gameUI.notify("Disconnected Unexpectedly!")
		loginMenu.logout()
		return
	
	var packet
	while socket.get_available_packet_count():
		packet = await getPacket()
		var data = packet.replace("#", " ").split(" ")
		match Array(data):
			["GameList", "Add", var id, var pw, var pb, var size, var time, var inc, var komi, var flats, var caps, var unrated, var tournament, var triggerMove, var triggerAmount]:
				var game = GameData.new(
					size.to_int(),
					self, self, pw, pb, 
					time.to_int(), inc.to_int(), triggerMove.to_int(), triggerAmount.to_int(),
					komi.to_int(), flats.to_int(), caps.to_int()
				)
				addGame.emit(game, id.to_int())
			
			["GameList", "Remove", var id, ..]:
				removeGame.emit(id.to_int())
			
			["Observe", var id, var pw, var pb, var size, var time, var inc, var komi, var flats, var caps, var unrated, var tournament, var triggerMove, var triggerAmount]:
				activeGame = id
				var g = GameData.new(
					size.to_int(), self, self, pw, pb, time.to_int(), inc.to_int(), triggerMove.to_int(), triggerAmount.to_int(), komi.to_int(), flats.to_int(), caps.to_int()
				)
				Globals.board.setup(g)

			["Game", "Start", var id, ..]:
				Globals.board.setup(makeGame(data))
				activeGame = id
			
			["Game", var id, "P", var sq, ..] when id == activeGame:
				var type = Place.TYPE.FLAT if data.size() == 4 else Place.TYPE.WALL if data[4] == "W" else Place.TYPE.CAP
				onMove.emit(self, Place.new(Ply.getTile(sq), type))
				
			["Game", var id, "M", var sq1, var sq2, ..] when id == activeGame:
				var tile1 = Ply.getTile(sq1)
				var tile2 = Ply.getTile(sq2)
				var smash = false
				var dir
				if tile2.x == tile1.x:
					dir = Spread.DIRECTION.UP if tile2.y > tile1.y else Spread.DIRECTION.DOWN
				else:
					dir = Spread.DIRECTION.RIGHT if tile2.x > tile1.x else Spread.DIRECTION.LEFT
				var drops: Array[int] = []
				for i in data.slice(5):
					drops.append(i.to_int())
				onMove.emit(self, Spread.new(tile1, dir, drops, smash))
			
			["Game", var id, "Time", var timeW, var timeB] when id == activeGame:
				timeSync.emit(timeW.to_int() * 1000, timeB.to_int() * 1000)
			
			["Game", var id, "Timems", var timeW, var timeB] when id == activeGame:
				timeSync.emit(timeW.to_int(), timeB.to_int())
			
			["Game", var id, "Over", var result] when id == activeGame:
				Globals.board.end("Game Ended " + result)
			
			["Game", var id, "OfferDraw"] when id == activeGame:
				Globals.board.GUI.notify("Your opponent offers a draw!")
			
			["Game", var id, "RemoveDraw"] when id == activeGame:
				Globals.board.GUI.notify("Your opponent retracts their draw offer.")
			
			["Game", var id, "RequestUndo"] when id == activeGame:
				Globals.board.GUI.notify("Your opponent requests an undo!")
			
			["Game", var id, "RemoveUndo"] when id == activeGame:
				Globals.board.GUI.notify("Your opponent retracts their undo request.")
			
			["Game", var id, "Undo"] when id == activeGame:
				Globals.board.undo()
			
			["Game", var id, "Abandoned.", var player, "quit"] when id == activeGame:
				Globals.board.end("Game ended because " + player + " abandoned." )
			
			["Seek", "new", var id, ..]:
				addSeek.emit(makeSeek(data), id.to_int())
			
			["Seek", "remove", var id, ..]:
				removeSeek.emit(id.to_int())
			
			["Shout", var user, ..]:
				Chat.rooms["Global"].add_message(user.lstrip("<").rstrip(">"), " ".join(data.slice(2)))
				
			["Joined", "room", var room]:
				Chat.new(self, room, Chat.ROOM)
				menu.addNode(Chat.rooms[room], "Chat: " + room)
			
			["Left", "room", var room]:
				pass #not sure if this even ever happens, playtak doesnt seem to handle it
			
			["ShoutRoom", var room, var user, ..]:
				if not room in Chat.rooms:
					Chat.new(self, room, Chat.ROOM)
					menu.addNode(Chat.rooms[room], "Chat: " + room)
				Chat.rooms[room].add_message(user.lstrip("<").rstrip(">"), " ".join(data.slice(3)))
				
			["Tell", var user, ..]:
				var u = user.lstrip("<").rstrip(">")
				if not u in Chat.rooms:
					Chat.new(self, u, Chat.PRIVATE)
					menu.addNode(Chat.rooms[u], "Chat: " + user)
				Chat.rooms[u].add_message(u, " ".join(data.slice(2)))
			
			["NOK"]:
				error.emit("NOK")
			
			["OK"]:
				pass
			
			_:
				print("Unparsed Message:")
				print(packet)
				print(data)


func sendMove(ply: Ply):
	var t = ply.toPlayTak()
	socket.send_text("Game#" + activeGame + " " + ply.toPlayTak().to_upper())


func sendToGame(msg: String):
	socket.send_text("Game#" + activeGame + " " + msg)


func sendSeek(seek: SeekData):
	socket.send_text(
		"Seek %d %d %d %s %d %d %d %d %d %d %d %s" % [seek.size, seek.time, seek.increment, ["A","W","B"][seek.color], seek.komi, seek.flats, seek.caps, 
		1 if seek.rated == SeekData.UNRATED else 0, 1 if seek.rated == SeekData.TOURNAMENT else 0, seek.triggerMove, seek.triggerTime, seek.playerName])


func acceptSeek(seek: int):
	socket.send_text("Accept " + str(seek))


func makeSeek(data: PackedStringArray) -> SeekData:
	return SeekData.new(
		data[3], #player
		self,
		data[4].to_int(), # size
		data[5].to_int(), # time
		data[6].to_int(), # inc
		data[13].to_int(),# triggermove
		data[14].to_int(),# triggeramount
		data[7], # color
		data[8].to_int(), # komi
		data[9].to_int(), # flats
		data[10].to_int(),# caps
		SeekData.TOURNAMENT if data[12] == "1" else SeekData.UNRATED if data[11] == "1" else SeekData.RATED
	)


func makeGame(data: PackedStringArray) -> GameData:
	var pWhite = self if data[7] == "black" else null
	var pBlack = self if data[7] == "white" else null
	
	return GameData.new(
		data[3].to_int(), #size 
		pWhite,
		pBlack,
		data[4], #pw
		data[6], #pb
		data[8].to_int(), #time
		0, #TODO is this not supposed to be here?????
		data[12].to_int(), #triggermove
		data[13].to_int(), #triggertime
		data[9].to_int(),  #komi
		data[10].to_int(), #flats
		data[11].to_int()) #caps
