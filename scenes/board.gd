extends Node2D
var card_scene = preload("res://scenes/card.tscn")
var highlight_scene = preload("res://scenes/card_highlight.tscn")

var _card_highlight
var _player_cards_in_hand = []
var _player_cards_on_table = []


@onready var starting_marks = {
	Game.PlayerPositions.RIGHT: %MarkerCardRight,
	Game.PlayerPositions.TOP: %MarkerCardTop,
	Game.PlayerPositions.LEFT: %MarkerCardLeft,
}

@onready var table_marks = {
	Game.PlayerPositions.RIGHT: %MarkerRight,
	Game.PlayerPositions.BOTTOM: %MarkerBottom,
	Game.PlayerPositions.TOP: %MarkerTop,
	Game.PlayerPositions.LEFT: %MarkerLeft,
}


func _ready():
	_update_rounds_label("")
	_update_winner_label(null)
	_update_restart_button(null)
	Game.cards_in_hand_changed.connect(_instantiate_player_cards)
	Game.winning_player_changed.connect(_on_winning_player_changed)
	Game.rounds_won_changed.connect(_update_rounds_label)
	Game.winner_changed.connect(_on_winner_changed)
	Game.play_npc_card.connect(_on_play_npc_card)
	Game.play_my_card.connect(_on_play_my_card)
	GlobalInput.table_changed.connect(_on_table_changed)
	_on_table_changed()
	_card_highlight = highlight_scene.instantiate()
	%MarkerCenter.add_child(_card_highlight)
	_card_highlight.scale = Vector2(0.7, 0.7)
	_card_highlight.visible = false


func _on_table_changed():
	%MarkerCenter.rotation = GlobalInput.table_rotation
	%MarkerCenter.skew = GlobalInput.table_skew


func _instantiate_player_cards(cardsinfo_in_my_hand):
	%PlayerLabel.text = Game.Players.keys()[Game.my_player]
	var player_markers = [%MarkerCardBottom1, %MarkerCardBottom2, %MarkerCardBottom3]
	for i in player_markers.size():
		var marker = player_markers[i]
		var card_info = cardsinfo_in_my_hand[i]
		var card: Card = _instantiate_card_from_info(card_info)
		_player_cards_in_hand.append(card)
		card.cancel.connect(_on_card_cancel)
		card.play.connect(_on_card_play)
		add_child(card)
		card.initial_position_mark = marker
		card.is_player_card = true
		card.position = marker.global_position


func _instantiate_card_from_info(card_info: Dictionary):
	var card: Card = card_scene.instantiate()
	card.suit = card_info["suit"]
	card.rank = card_info["rank"]
	card.points = card_info["points"]
	return card


func _on_play_npc_card(player: Game.Players, card_info):
	var card: Card = _instantiate_card_from_info(card_info)
	var player_position: Game.PlayerPositions = Game.positions_by_player[player]
	var from: Marker2D = starting_marks[player_position]
	var to: Marker2D = table_marks[player_position]
	add_child(card)
	card.position = from.global_position
	_animate_card(player, card, to)


func _on_play_my_card():
	for card in _player_cards_in_hand:
		card.is_drag_enabled = true
	

func _card_on_table(player: Game.Players, card: Card):
	card.reparent(%MarkerCenter)
	card.set_card_z_index(Game.CardIndex["on_table"] + Game.current_round)
	var is_bot = Game._get_player_kind(player) == Game.PlayerKinds.Bot
	if multiplayer.is_server() and (player == Game.my_player or is_bot):
		prints("server playing card", card, "is bot:", is_bot)
		Game.play_card()
	elif player == Game.my_player:
		prints("peer", multiplayer.get_unique_id(), "playing card", card)
		Game.play_card.rpc_id(1)


func _animate_card(player: Game.Players, card: Card, marker: Marker2D):
	%PlayArea.modulate = Color(%PlayArea.modulate, 0.5)
	# FIXME apply table transform to the Vector2 being added
	var final_position = marker.global_position + Vector2(20, 25) * Game.current_round
	var tween = card.create_tween()
	if Game.DEBUG:
		tween.set_speed_scale(Game.DEBUG_SPEED)
	card.set_card_z_index(Game.CardIndex["dragging"])
	tween.tween_property(card, "position", %MarkerCenter.global_position, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "scale", Vector2(1.6, 1.6), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.chain()
	tween.tween_property(card, "scale", Vector2(0.7, 0.7), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "position", final_position, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "rotation", GlobalInput.table_rotation, 0.5)
	tween.parallel()
	tween.tween_property(card, "skew", GlobalInput.table_skew, 0.5)
	tween.tween_callback(_card_on_table.bind(player, card))
	await tween.finished

func _on_winning_player_changed(player):
	if player == null:
		_card_highlight.visible = false
		return
	_card_highlight.visible = true
	var _position = Game.positions_by_player[player]
	_card_highlight.position = table_marks[_position].position
	

func _update_rounds_label(text):
	%RoundsLabel.text = text
	DampedOscillator.animate(%RoundsLabel, "scale", 200.0, 10.0, 15.0, 0.75)


func _update_winner_label(winner):
	if winner == null:
		%WinnerLabel.text = ""
		return
	if Game.my_player in Game.PLAYERS_PER_TEAM[winner]:
		%WinnerLabel.text = "You win!"
	else:
		%WinnerLabel.text = "You lose!"
	DampedOscillator.animate(%WinnerLabel, "scale", 200.0, 10.0, 15.0, 0.75)


func _update_restart_button(winner):
	%RestartButton.disabled = winner == null
	%RestartButton.visible = winner != null
	if %RestartButton.visible:
		DampedOscillator.animate(%RestartButton, "rotation_degrees", 200.0, 10.0, 15.0, 100.0)


func _on_winner_changed(winner):
	_update_winner_label(winner)
	_update_restart_button(winner)


func _on_card_play(card: Card):
	for c in _player_cards_in_hand:
		c.is_drag_enabled = false
	_player_cards_in_hand.erase(card)

	var card_info = {
		"suit": card.suit,
		"rank": card.rank,
		"points": card.points,
	}
	# FIXME this is animating the card in other peers,
	# but also introducing bugs!
	if multiplayer.is_server():
		Game.update_card_info(card_info)
	else:
		Game.update_card_info.rpc_id(1, card_info)

	var player_position = Game.positions_by_player[Game.my_player]
	await _animate_card(Game.my_player, card, table_marks[player_position])
	_player_cards_on_table.append(card)


func _on_card_cancel(card):
	var tween = get_tree().create_tween()
	if Game.DEBUG:
		tween.set_speed_scale(Game.DEBUG_SPEED)
	tween.tween_property(card, "position", card.initial_position_mark.position, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	card.set_card_z_index(Game.CardIndex["on_table"])


func _on_area_2d_area_entered(area):
	area.owner.in_play_area = true
	# %PlayArea.modulate = Color(%PlayArea.modulate, 0.8)


func _on_area_2d_area_exited(area):
	area.owner.in_play_area = false
	# %PlayArea.modulate = Color(%PlayArea.modulate, 0.5)


func _on_restart_button_pressed():
	Game.restart()
