extends Node2D

var enter_scene = preload("res://scenes/enter.tscn")
var player_selection_scene = preload("res://scenes/player_selection.tscn")
var board_scene = preload("res://scenes/board.tscn")
# var board_scene = preload("res://scenes/test.tscn")

var _grid_velocity_for_position = {
	Game.PlayerPositions.RIGHT: Vector2(0.03, 0.0),
	Game.PlayerPositions.TOP: Vector2(0.0, -0.03),
	Game.PlayerPositions.LEFT: Vector2(-0.03, 0.0),
	Game.PlayerPositions.BOTTOM: Vector2(0.0, 0.03),
}

func _ready():
	get_tree().get_root().size_changed.connect(_on_window_size_changed)
	%SubViewport.add_child(enter_scene.instantiate())
	Game.start_the_game.connect(_on_start_game)
	Game.player_changed.connect(_on_player_changed)
	GlobalInput.table_changed.connect(_on_table_changed)
	_on_table_changed()
	Multiplayer.connected_as_server.connect(_on_connected)
	Multiplayer.connected_as_client.connect(_on_connected)
	Multiplayer.any_disconnected.connect(_on_game_ended)

	%NetworkGateway.webrtc_multiplayerpeer_set.connect(Multiplayer._on_network_gateway_webrtc_multiplayerpeer_set)

func _on_window_size_changed():
	%ColorRect.material.set_shader_parameter("resolution", get_tree().get_root().size)


func _on_player_changed(player):
	var player_position: Game.PlayerPositions = Game.positions_by_player[player]
	var velocity = _grid_velocity_for_position[player_position]
	%ColorRect.material.set_shader_parameter("velocity", velocity)


func _on_table_changed():
	%ColorRect.material.set_shader_parameter("rotation", GlobalInput.table_rotation)
	%ColorRect.material.set_shader_parameter("skew", GlobalInput.table_skew)


func _go_to_scene(scene: PackedScene):
	for c in %SubViewport.get_children():
		if c.name == "Enter":
			c.visible = (scene == null)
		else:
			c.queue_free()
	if scene:
		%SubViewport.add_child(scene.instantiate())
	

func _on_connected():
	_go_to_scene(player_selection_scene)

func _on_game_ended():
	_go_to_scene(null)


func _on_start_game():
	_go_to_scene(board_scene)
