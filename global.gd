extends Node

enum Suits {ESPADA, BASTO, ORO, COPA}
var CardIndex = {"on_table": 100, "dragging": 120}
const GoldenDeck: Array[Dictionary] = [
	# extreme range (1 - 4):
	{"rank": 1, "suit": Suits.ESPADA, "points": 1},
	{"rank": 2, "suit": Suits.BASTO, "points": 1},
	{"rank": 3, "suit": Suits.ESPADA, "points": 7},
	{"rank": 4, "suit": Suits.ORO, "points": 7},
	# high range (5 - 7):
	{"rank": 5, "suit": Suits.ESPADA, "points": 3},
	{"rank": 5, "suit": Suits.BASTO, "points": 3},
	{"rank": 5, "suit": Suits.ORO, "points": 3},
	{"rank": 5, "suit": Suits.COPA, "points": 3},
	{"rank": 6, "suit": Suits.ESPADA, "points": 2},
	{"rank": 6, "suit": Suits.BASTO, "points": 2},
	{"rank": 6, "suit": Suits.ORO, "points": 2},
	{"rank": 6, "suit": Suits.COPA, "points": 2},
	{"rank": 7, "suit": Suits.ORO, "points": 1},
	{"rank": 7, "suit": Suits.COPA, "points": 1},
	# medium range (8 - 10):
	{"rank": 8, "suit": Suits.ESPADA, "points": 0},
	{"rank": 8, "suit": Suits.BASTO, "points": 0},
	{"rank": 8, "suit": Suits.ORO, "points": 0},
	{"rank": 8, "suit": Suits.COPA, "points": 0},
	{"rank": 9, "suit": Suits.ESPADA, "points": 0},
	{"rank": 9, "suit": Suits.BASTO, "points": 0},
	{"rank": 9, "suit": Suits.ORO, "points": 0},
	{"rank": 9, "suit": Suits.COPA, "points": 0},
	{"rank": 10, "suit": Suits.ESPADA, "points": 0},
	{"rank": 10, "suit": Suits.BASTO, "points": 0},
	{"rank": 10, "suit": Suits.ORO, "points": 0},
	{"rank": 10, "suit": Suits.COPA, "points": 0},
	# low range (11 - 14):
	{"rank": 11, "suit": Suits.BASTO, "points": 7},
	{"rank": 11, "suit": Suits.COPA, "points": 7},
	{"rank": 12, "suit": Suits.ESPADA, "points": 6},
	{"rank": 12, "suit": Suits.BASTO, "points": 6},
	{"rank": 12, "suit": Suits.ORO, "points": 6},
	{"rank": 12, "suit": Suits.COPA, "points": 6},
	{"rank": 13, "suit": Suits.ESPADA, "points": 5},
	{"rank": 13, "suit": Suits.BASTO, "points": 5},
	{"rank": 13, "suit": Suits.ORO, "points": 5},
	{"rank": 13, "suit": Suits.COPA, "points": 5},
	{"rank": 14, "suit": Suits.ESPADA, "points": 4},
	{"rank": 14, "suit": Suits.BASTO, "points": 4},
	{"rank": 14, "suit": Suits.ORO, "points": 4},
	{"rank": 14, "suit": Suits.COPA, "points": 4},
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Engine.max_fps = 12


func _input(_event):
	if Input.is_action_just_released("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_pressed("pause-resume"):
		get_tree().paused = not get_tree().paused
	elif Input.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_released("fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _process(_delta):
	if Input.is_action_just_pressed("next-frame"):
		if get_tree().paused:
			get_tree().paused = false
		await get_tree().process_frame
		get_tree().paused = true
