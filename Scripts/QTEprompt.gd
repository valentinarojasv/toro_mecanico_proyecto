extends Control

@onready var texto_qte: Label = $TextoQTE
@onready var anillo_tiempo: TextureProgressBar = $AnilloTiempo

var numero_resultado: int = 0


func _ready() -> void:
	hide()
	anillo_tiempo.min_value = 0.0
	anillo_tiempo.max_value = 100.0
	anillo_tiempo.value = 100.0


# Muestra la tecla que debe presionar el jugador.
func mostrar_qte(tecla: String, es_direccion: bool) -> void:
	numero_resultado += 1

	if es_direccion:
		texto_qte.text = "COMPENSA CON " + tecla
	else:
		texto_qte.text = "PRESIONA " + tecla

	anillo_tiempo.show()
	anillo_tiempo.value = 100.0
	show()


# Actualiza el tiempo disponible.
func actualizar_tiempo(restante: float, duracion: float) -> void:
	if duracion <= 0.0:
		return

	anillo_tiempo.value = clampf(
		(restante / duracion) * 100.0,
		0.0,
		100.0
	)


# Muestra el resultado en el mismo texto.
func mostrar_resultado(correcto: bool) -> void:
	numero_resultado += 1
	var resultado_actual: int = numero_resultado

	if correcto:
		texto_qte.text = "¡CORRECTO!"
	else:
		texto_qte.text = "¡FALLASTE!"

	anillo_tiempo.hide()
	show()

	await get_tree().create_timer(0.8).timeout

	if resultado_actual == numero_resultado:
		hide()


# Oculta el indicador.
func ocultar_qte() -> void:
	numero_resultado += 1
	hide()
