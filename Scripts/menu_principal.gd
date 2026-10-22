extends Control

@onready var boton_jugar: Button = $BotonJugar
@onready var record_label: Label = $RecordLabel


func _ready() -> void:
	boton_jugar.pressed.connect(iniciar_juego)

	actualizar_record()


func actualizar_record() -> void:
	record_label.text = (
		"MEJOR PUNTUACION: " + str(GameState.puntuacion_record)
	)


func iniciar_juego() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/game/juego.tscn"
	)
