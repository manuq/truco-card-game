extends Control


func _on_button_pressed():
	Multiplayer.host_or_join_game($LineEdit.text)
