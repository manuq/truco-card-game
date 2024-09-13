extends Node

const _ROTATE_TABLE_STEP = 0.01
const _SKEW_TABLE_STEP = 0.01
var table_rotation = _ROTATE_TABLE_STEP * -10
var table_skew = _SKEW_TABLE_STEP * -10
signal table_changed


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(_event):
	if Input.is_action_just_released("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_pressed("pause-resume"):
		get_tree().paused = not get_tree().paused
	elif Input.is_action_pressed("restart"):
		Game.restart()
	elif Input.is_action_pressed("rotate-table-less"):
		table_rotation += _ROTATE_TABLE_STEP
		table_skew += _SKEW_TABLE_STEP
		table_changed.emit()
	elif Input.is_action_pressed("rotate-table-more"):
		table_rotation -= _ROTATE_TABLE_STEP
		table_skew -= _SKEW_TABLE_STEP
		table_changed.emit()
	elif Input.is_action_just_released("toggle-debug"):
		Game.toggle_debug()
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
