extends Control

# Referencias a los elementos de Game Over.
@onready var boton_reintentar: Button = $BotonReintentar
@onready var puntuacion_final_label: Label = $PuntuacionFinalLabel
@onready var record_label: Label = $RecordLabel


# Prepara la pantalla de derrota.
func _ready() -> void:
	boton_reintentar.pressed.connect(reiniciar_juego)

	# Muestra los resultados de la partida.
	puntuacion_final_label.text = (
		"PUNTUACIÓN FINAL: " + str(Record.puntuacion_final)
	)

	record_label.text = (
		"RÉCORD: " + str(Record.puntuacion_record)
	)


# Reinicia la partida desde el principio.
func reiniciar_juego() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/game/juego.tscn"
	)
