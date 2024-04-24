extends Node2D

func _ready():
	# FIXME main menu here?
	get_tree().get_root().size_changed.connect(_on_window_size_changed)


func _on_window_size_changed():
	%ColorRect.material.set_shader_parameter("resolution", get_tree().get_root().size)
	
