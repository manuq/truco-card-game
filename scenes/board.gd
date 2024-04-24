extends Node2D
var card_scene = preload("res://scenes/card.tscn")

var turn = 0
var deck: Array[Dictionary]


func _ready():
	deck = Global.GoldenDeck.duplicate()
	randomize()
	deck.shuffle()
	_give_player_cards()
	_play_npc_turn()


func _give_player_cards():
	for marker in [%MarkerCard1, %MarkerCard2, %MarkerCard3]:
		var card: Card = _pick_random_card()
		card.cancel.connect(_on_card_cancel)
		card.play.connect(_on_card_play)
		add_child(card)
		card.initial_position_mark = marker
		card.position = marker.global_position


func _pick_random_card():
	var card: Card = card_scene.instantiate()
	var card_info = deck.pop_back()
	card.suit = card_info["suit"]
	card.rank = card_info["rank"]
	card.points = card_info["points"]
	return card


func _play_npc_turn():
	_play_npc_card(%MarkerCardRight, %MarkerRight)
	await get_tree().create_timer(2).timeout
	_play_npc_card(%MarkerCardTop, %MarkerTop)
	await get_tree().create_timer(2).timeout
	_play_npc_card(%MarkerCardLeft, %MarkerLeft)


func _play_npc_card(from: Marker2D, to: Marker2D):
	var card: Card = _pick_random_card()
	add_child(card)
	card.position = from.global_position
	_animate_card(card, to)

func _card_on_table(card):
	card.z_index = Global.CardIndex["on_table"] + turn
	
func _animate_card(card: Card, marker: Marker2D):
	%PlayArea.modulate = Color(%PlayArea.modulate, 0.5)
	var final_position = marker.global_position + Vector2(20, 25) * turn
	var tween = get_tree().create_tween()
	card.z_index = Global.CardIndex["dragging"]
	tween.tween_property(card, "position", %MarkerCenter.global_position, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "scale", Vector2(1.6, 1.6), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.chain()
	tween.tween_property(card, "scale", Vector2(0.7, 0.7), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "position", final_position, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(card, "rotation", -0.1, 0.5)
	tween.parallel()
	tween.tween_property(card, "skew", -0.1, 0.5)
	tween.tween_callback(_card_on_table.bind(card))
	await tween.finished


func _on_card_play(card: Card):
	await _animate_card(card, %MarkerBottom)
	turn += 1
	if turn < 3:
		_play_npc_turn()


func _on_card_cancel(card):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", card.initial_position_mark.position, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	card.z_index = Global.CardIndex["on_table"]


func _on_area_2d_area_entered(area):
	area.owner.in_play_area = true
	%PlayArea.modulate = Color(%PlayArea.modulate, 0.8)


func _on_area_2d_area_exited(area):
	area.owner.in_play_area = false
	%PlayArea.modulate = Color(%PlayArea.modulate, 0.5)
