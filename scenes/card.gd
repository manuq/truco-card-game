@tool
class_name Card
extends Node2D

signal play
signal cancel
var _played = false
var _dragging = false
var _original_position: Vector2

var in_play_area = false

@export var show_in_editor: bool = false:
	set = _set_show_in_editor

@export_range(0, 14, 1) var rank: int = 0:
	set = _set_rank

@export_range(0, 33, 1) var points: int = 0:
	set = _set_points

@export var suit: Global.Suits = Global.Suits.ESPADA:
	set = _set_suit

@export var initial_position_mark: Marker2D


func _set_show_in_editor(_show):
	show_in_editor = _show
	%RankLabel.text = str(rank)
	%PointsLabel.text = str(points)
	_update_suit(suit)


func _set_rank(_rank):
	rank = _rank
	if %RankLabel:
		%RankLabel.text = str(rank)


func _set_points(_points):
	points = _points
	if %PointsLabel:
		%PointsLabel.text = str(points)
	# FIXME change graphic


func _update_suit(_suit):
	if _suit == Global.Suits.ESPADA:
		%Assets.modulate = Color(0, 1, 1, 1)
	elif _suit == Global.Suits.BASTO:
		%Assets.modulate = Color(0, 1, 0, 1)
	elif _suit == Global.Suits.ORO:
		%Assets.modulate = Color(1, 1, 0, 1)
	elif _suit == Global.Suits.COPA:
		%Assets.modulate = Color(1, 0, 1, 1)
	else:
		%Assets.modulate = Color(1, 1, 1, 1)
	

func _set_suit(_suit):
	suit = _suit
	_update_suit(_suit)


func _ready():
	%RankLabel.text = str(rank)
	%PointsLabel.text = str(points)
	_original_position = position


func _process(_delta):
	if _played:
		return
	if _dragging:
		position = get_global_mouse_position()


func _on_touch_screen_button_pressed():
	if _played:
		return
	z_index = Global.CardIndex["dragging"]
	_dragging = true


func _on_touch_screen_button_released():
	if _played:
		return
	if in_play_area:
		confirm_play()
	else:
		cancel_play()


func confirm_play():
	_dragging = false
	_played = true
	play.emit(self)
	
func cancel_play():
	_dragging = false
	cancel.emit(self)
