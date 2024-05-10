@tool
class_name Card
extends Node2D

signal play
signal cancel
var _dragging = false
var _played = false
var _original_position: Vector2

var in_play_area = false
var _alpha_tween: Tween


@export_range(0, 14, 1) var rank: int = 0:
	set = _set_rank

@export_range(0, 33, 1) var points: int = 0:
	set = _set_points

@export var suit: Game.Suits = Game.Suits.ESPADA:
	set = _set_suit

@export var is_player_card: bool = false:
	set = _set_is_player_card

@export var is_drag_enabled: bool = false:
	set = _set_is_drag_enabled
	
@export var initial_position_mark: Marker2D


func _set_rank(_rank):
	rank = _rank
	if %RankLabel:
		%RankLabel.text = str(rank)


func _to_string():
	return "< suit: " + Game.Suits.keys()[suit] + ", rank: " + str(rank) + ", points: " + str(points) + " >"


func _set_points(_points):
	points = _points
	if %PointsLabel:
		%PointsLabel.text = str(points)
	# FIXME change graphic


func _update_modulate():
	if not is_player_card:
		return
	if _alpha_tween and _alpha_tween.is_running():
		_alpha_tween.kill()
	if Engine.is_editor_hint():
		return
	_alpha_tween = create_tween()
	if Game.DEBUG:
		_alpha_tween.set_speed_scale(Game.DEBUG_SPEED)
	if not is_drag_enabled and not _played:
		_alpha_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.8), 0.1)
	else:
		_alpha_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)


func _set_is_player_card(_is):
	is_player_card = _is
	%Button.disabled = not is_player_card
	_update_modulate()


func _set_is_drag_enabled(_is):
	is_drag_enabled = _is
	_update_modulate()


func _update_suit(_suit):
	if _suit == Game.Suits.ESPADA:
		%Assets.modulate = Color(0, 1, 1, 1)
	elif _suit == Game.Suits.BASTO:
		%Assets.modulate = Color(0, 1, 0, 1)
	elif _suit == Game.Suits.ORO:
		%Assets.modulate = Color(1, 1, 0, 1)
	elif _suit == Game.Suits.COPA:
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
	_update_suit(suit)
	_set_is_player_card(is_player_card)
	_set_is_drag_enabled(is_drag_enabled)
	set_process(false)


func _process(_delta):
	if _dragging:
		position = get_global_mouse_position()


func _on_touch_screen_button_pressed():
	if not is_drag_enabled:
		return
	set_process(true)
	set_card_z_index(Game.CardIndex["dragging"])
	_dragging = true


func _on_touch_screen_button_released():
	if not is_drag_enabled:
		return
	set_process(false)
	if in_play_area:
		confirm_play()
	else:
		cancel_play()


func confirm_play():
	_dragging = false
	_played = true
	_update_modulate()
	play.emit(self)
	
func cancel_play():
	_dragging = false
	cancel.emit(self)
	
func set_card_z_index(value):
	%Trail2D.set_z_index(value - 1)
	set_z_index(value)
	
