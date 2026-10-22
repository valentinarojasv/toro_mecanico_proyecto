extends Control

# Referencias a los elementos de Game Over.
@onready var boton_reintentar: Button = $BotonReintentar
@onready var boton_menu: Button = $BotonMenuP
@onready var puntuacion_final_label: Label = $PuntuacionFinalLabel
@onready var record_label: Label = $RecordLabel
@onready var tiempo_final_label: Label = $TiempoFinal


# Prepara la pantalla de derrota.
func _ready() -> void:
	boton_reintentar.pressed.connect(reiniciar_juego)
	boton_menu.pressed.connect(volver_menu_principal)

	# Muestra los resultados de la partida.
	puntuacion_final_label.text = (
		"PUNTUACIÓN FINAL: " + str(GameState.puntuacion_final)
	)

	record_label.text = (
		"RÉCORD: " + str(GameState.puntuacion_record)
	)

	tiempo_final_label.text = (
		"TIEMPO FINAL: " + str(GameState.tiempo_final) + " s"
	)


# Reinicia la partida desde el principio.
func reiniciar_juego() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/game/juego.tscn"
	)


# Regresa al menú principal.
func volver_menu_principal() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/ui/menu_principal.tscn"
	)
