extends Control

@onready var _buttons_by_player = {
		Game.Players.TeamAP1: %TeamAP1Button,
		Game.Players.TeamBP1: %TeamBP1Button,
		Game.Players.TeamAP2: %TeamAP2Button,
		Game.Players.TeamBP2: %TeamBP2Button,
}


func _ready():
	GlobalInput.table_changed.connect(_on_table_changed)
	_on_table_changed()
	Multiplayer.player_by_peer_changed.connect(_update_player_buttons)
	_update_player_buttons()
	for player: Game.Players in _buttons_by_player.keys():
		var button: Button = _buttons_by_player[player]
		button.pressed.connect(_on_player_button_pressed.bind(player))


func _on_table_changed():
	%CenterNode.rotation = GlobalInput.table_rotation
	%CenterNode.skew = GlobalInput.table_skew


func _update_player_buttons():
	var is_server = multiplayer.is_server()
	# FIXME either start button or label depending on that
	%StartButton.visible = is_server
	%ServerLabel.visible = is_server
	%ClientLabel.visible = not is_server

	for player in _buttons_by_player.keys():
		if player not in Multiplayer.player_by_peer.values():
			var button: Button = _buttons_by_player[player]
			button.text = "BOT"
			button.disabled = false

	for peer in Multiplayer.player_by_peer.keys():
		var player = Multiplayer.player_by_peer[peer]
		var button: Button = _buttons_by_player[player]
		if peer == multiplayer.get_unique_id():
			button.text = "ME"
			%CardHighlight.visible = true
			%CardHighlight.position = button.position + button.pivot_offset
		else:
			button.text = "PLAYER"
		button.disabled = true


func _on_player_button_pressed(player: Game.Players):
	Multiplayer.request_player_change.rpc_id(1, player)


func _on_start_button_pressed():
	multiplayer.multiplayer_peer.refuse_new_connections = true
	Game.start_game.rpc()
