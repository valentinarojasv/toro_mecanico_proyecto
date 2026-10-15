extends Control

@onready var boton_jugar: Button = $BotonJugar

func _ready() -> void:
	boton_jugar.pressed.connect(iniciar_juego)

func iniciar_juego() -> void:
	get_tree().change_scene_to_file("res://Scenes/game/juego.tscn")
