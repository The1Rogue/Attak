extends Node

const e = "/home/fay/Projects/attak-misc/test.py"
const e2 = "/home/fay/Projects/Attak/Attak.ico"

const q = ["hello!", "world!"]

var thread: Thread
var thread2: Thread

var pipes
var pid

func _ready():
	while true:
		pipes = OS.execute_with_pipe(e2, [])
		pid = pipes["pid"]
		thread = Thread.new()
		thread.start(readPipe.bind(pipes["stdio"], "stdio: "))
		
		thread2 = Thread.new()
		thread2.start(readPipe.bind(pipes["stderr"], "stderr: "))
		
		await get_tree().create_timer(.1).timeout
		if OS.is_process_running(pid):
			for i in q:
				print("> " + i)
				pipes["stdio"].store_line(i) #THIS IS THE LINE THAT CRASHES GODOT
				await get_tree().create_timer(.1).timeout
		else:
			print("DIED")
			OS.crash("oops")
			
		OS.kill(pid)
		#pipes["stdio"].close()
		#pipes["stderr"].close()
		thread.wait_to_finish()
		thread2.wait_to_finish()

		print("=========")


func readPipe(pipe: FileAccess, pref: String):
	while pipe.is_open() and pipe.get_error() == OK:
		var s = pipe.get_line()
		if s.is_empty(): print(pref + "[empty line]")
		else: print(pref + s)
