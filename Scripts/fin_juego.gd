extends Control

# Referencia al botón REINTENTAR.
@onready var boton_reintentar: Button = $BotonReintentar

# Prepara la pantalla de derrota.
func _ready() -> void:
	boton_reintentar.pressed.connect(reiniciar_juego)

# Reinicia la partida desde el principio.
func reiniciar_juego() -> void:
	get_tree().change_scene_to_file("res://Scenes/game/juego.tscn")
