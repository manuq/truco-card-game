extends Node

var DEBUG = false # or true
const DEBUG_SPEED = 3.0

enum PlayerKinds {Human, Bot}
enum PlayerPositions {RIGHT, TOP, LEFT, BOTTOM}
enum Teams {TeamA, TeamB}
enum Players {TeamAP1, TeamBP1, TeamAP2, TeamBP2}
const PLAYERS_PER_TEAM = {
	Teams.TeamA: [Players.TeamAP1, Players.TeamAP2],
	Teams.TeamB: [Players.TeamBP1, Players.TeamBP2],
}
var positions_by_player = {
	# This gets updated so that my_player always matches BOTTOM
	Players.TeamBP1: PlayerPositions.RIGHT,
	Players.TeamAP2: PlayerPositions.TOP,
	Players.TeamBP2: PlayerPositions.LEFT,
	Players.TeamAP1: PlayerPositions.BOTTOM,
}
const TOTAL_ROUNDS = 3
const ROUNDS_TO_WIN = 2
var my_player: Players = Players.TeamAP1
var _current_player: Players
signal player_changed
signal start_the_game

var current_round = 0
var cardsinfo_played = [{}, {}, {}]
var _rounds_won = []
const _INITIAL_RANK = 999
var _min_rank_this_round = _INITIAL_RANK
var _deck: Array[Dictionary]
var _cardsinfo_in_hand = {
	Game.Players.TeamAP1: [],
	Game.Players.TeamBP1: [],
	Game.Players.TeamAP2: [],
	Game.Players.TeamBP2: [],
}
signal play_npc_card
signal play_my_card
signal card_played
signal cards_in_hand_changed
signal rounds_won_changed
signal winner_changed
signal winning_player_changed

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
	_current_player = Players.TeamBP1
	player_changed.emit(_current_player)


func _setup_cards():
	_shuffle_deck_and_give_cards()
	for peer in Multiplayer.player_by_peer.keys():
		var player = Multiplayer.player_by_peer[peer]
		_update_cards_in_hand.rpc_id(peer, _cardsinfo_in_hand[player])
	_play_rounds()


func _pick_npc_card(player: Players):
	# FIXME not a very smart NPC
	return _cardsinfo_in_hand[player].pop_back()


func _get_player_kind(player: Players):
	if player not in Multiplayer.player_by_peer.values():
		return PlayerKinds.Bot
	else:
		return PlayerKinds.Human


func _play_rounds():
	while _get_winner() == null:
		for player in [Players.TeamBP1, Players.TeamAP2, Players.TeamBP2, Players.TeamAP1]:
			_set_current_player.rpc(player)
			var player_kind = _get_player_kind(player)
			if player_kind == PlayerKinds.Bot:
				if not DEBUG:
					await get_tree().create_timer(2).timeout
				var card_info = _pick_npc_card(player)
				cardsinfo_played[current_round][player] = card_info
				_send_play_card.rpc(player, card_info)
			elif player_kind == PlayerKinds.Human:
				var peer
				for p in Multiplayer.player_by_peer.keys():
					if Multiplayer.player_by_peer[p] == player:
						peer = p
				_ask_peer_card.rpc_id(peer)
			await card_played
			# prints(multiplayer.get_unique_id(), cardsinfo_played, current_round, player)
			if player in cardsinfo_played[current_round].keys():
				var card_info = cardsinfo_played[current_round][player]
				if card_info["rank"] < _min_rank_this_round:
					_min_rank_this_round = card_info["rank"]
					_send_winning_player(player)
				elif card_info["rank"] == _min_rank_this_round:
					_send_winning_player(null)
				# FIXME early check winner with the cards already played

		_update_rounds_won()
		_send_rounds_won_label()
		var winner = _get_winner()
		if winner != null:
			_send_winner_changed.rpc(winner)
			break
		_next_round()


func _update_rounds_won():
	var players_with_min_rank: Array = _check_min_rank(cardsinfo_played[current_round])
	var teams_with_min_rank = players_with_min_rank.map(_team_for_player).reduce(_unique_teams, [])
	if teams_with_min_rank.size() == 2:
		_rounds_won.append(null)
	else:
		if teams_with_min_rank[0] == Teams.TeamA:
			_rounds_won.append(Teams.TeamA)
		else:
			_rounds_won.append(Teams.TeamB)


@rpc("authority", "call_local", "reliable")
func start_game():
	start_the_game.emit()
	if multiplayer.is_server():
		_setup_cards()


func restart():
	Multiplayer.restart()
	current_round = 0
	cardsinfo_played = [{}, {}, {}]
	_rounds_won = []
	#get_tree().reload_current_scene()


@rpc("authority", "call_local", "reliable")
func _set_current_player(player: Players):
	_current_player = player
	player_changed.emit(_current_player)


@rpc("authority", "call_local", "reliable")
func _send_winner_changed(winner):
	winner_changed.emit(winner)


@rpc("authority", "call_local", "reliable")
func _update_cards_in_hand(cardsinfo_in_my_hand):
	cards_in_hand_changed.emit(cardsinfo_in_my_hand)


@rpc("authority", "call_local", "reliable")
func _ask_peer_card():
	play_my_card.emit()


@rpc("authority", "call_local", "reliable")
func _send_play_card(player, card_info):
	if player != my_player:
		play_npc_card.emit(player, card_info)


@rpc("authority", "call_local", "reliable")
func _update_rounds_won_label(text):
	rounds_won_changed.emit(text)


@rpc("authority", "call_remote", "reliable")
func _send_round(_round):
	current_round = _round


@rpc("authority", "call_local", "reliable")
func _update_winning_player(player):
	winning_player_changed.emit(player)


@rpc("any_peer", "call_remote", "reliable")
func update_card_info(card_info):
	# prints("update_card_info", multiplayer.get_unique_id(), multiplayer.get_remote_sender_id())
	cardsinfo_played[current_round][_current_player] = card_info
	if multiplayer.is_server():
		_send_play_card.rpc(_current_player, card_info)


@rpc("any_peer", "call_remote", "reliable")
func play_card(): # card_info):
	var is_bot = _get_player_kind(_current_player) == PlayerKinds.Bot
	if multiplayer.get_remote_sender_id() != 0:
		card_played.emit()
	else:
		if _current_player == my_player:
			card_played.emit()
		elif is_bot:
			card_played.emit()


func _send_rounds_won_label():
	var characters = []
	for r in Game._rounds_won:
		if r == Game.Teams.TeamA:
			characters.append('A')
		elif r == Game.Teams.TeamB:
			characters.append('B')
		else:
			characters.append('-')
	var text = "".join(characters)
	_update_rounds_won_label.rpc(text)


func _next_round():
	if current_round >= TOTAL_ROUNDS:
		return

	current_round += 1
	_send_round.rpc(current_round)
	_min_rank_this_round = _INITIAL_RANK


func _send_winning_player(player):
	_update_winning_player.rpc(player)


func toggle_debug():
	DEBUG = not DEBUG


func _shuffle_deck_and_give_cards():
	_deck = GoldenDeck.duplicate()
	randomize()
	_deck.shuffle()
	for player in _cardsinfo_in_hand.keys():
		for i in range(3):
			var card_info = _deck.pop_back()
			_cardsinfo_in_hand[player].append(card_info)


func _check_min_rank(cards_info: Dictionary):
	var min_rank = _INITIAL_RANK
	var players_with_min_rank = []
	for player in cards_info.keys():
		if cards_info[player]["rank"] < min_rank:
			min_rank = cards_info[player]["rank"]
			players_with_min_rank = [player]
		elif cards_info[player]["rank"] == min_rank:
			players_with_min_rank.append(player)
	return players_with_min_rank


func _get_winner():
	var team_a_rounds = _rounds_won.count(Game.Teams.TeamA)
	var team_b_rounds = _rounds_won.count(Game.Teams.TeamB)
	var draw_rounds = _rounds_won.count(null)

	if _rounds_won.size() < 2:
		# can't tell yet
		return null
	elif _rounds_won.size() == 2:
		if draw_rounds == 2 or team_a_rounds == team_b_rounds:
			# can't tell yet
			return null
		elif team_a_rounds > team_b_rounds:
			return Game.Teams.TeamA
		else:
			return Game.Teams.TeamB
	elif _rounds_won.size() == 3:
		if draw_rounds == 3:
			# FIXME return the hand, currently hardcoded
			return Game.Teams.TeamB
		elif team_a_rounds > team_b_rounds:
			return Game.Teams.TeamA
		else:
			return Game.Teams.TeamB
	else:
		# shouldn't reach this, 3 rounds max
		return null


func _team_for_player(player: Players):
	if player in PLAYERS_PER_TEAM[Teams.TeamA]:
		return Teams.TeamA
	elif player in PLAYERS_PER_TEAM[Teams.TeamB]:
		return Teams.TeamB


func _unique_teams(accum, player):
	if player in accum:
		return accum
	else:
		accum.append(player)
		return accum


func set_my_player(player: Players):
	my_player = player
	var new_positions = [PlayerPositions.BOTTOM, PlayerPositions.RIGHT, PlayerPositions.TOP, PlayerPositions.LEFT]
	# This rotates positions_by_player so that my_player is at the bottom:
	for i in range(int(my_player)):
		var position = new_positions.pop_back()
		new_positions.push_front(position)
	positions_by_player = {}
	for each_player in [Players.TeamAP1, Players.TeamBP1, Players.TeamAP2, Players.TeamBP2]:
		positions_by_player[each_player] = new_positions[int(each_player)]
