extends Control

# Texto que muestra la tecla solicitada.
@onready var texto_qte: Label = $TextoQTE

# Anillo que muestra el tiempo restante.
@onready var anillo_tiempo: TextureProgressBar = $AnilloTiempo


# Prepara el indicador.
func _ready() -> void:
	hide()
	anillo_tiempo.min_value = 0.0
	anillo_tiempo.max_value = 100.0
	anillo_tiempo.value = 100.0


# Muestra el desafío y reinicia el anillo.
func mostrar_qte(tecla: String, es_direccion: bool) -> void:
	if es_direccion:
		texto_qte.text = "COMPENSA CON " + tecla
	else:
		texto_qte.text = "PRESIONA " + tecla

	anillo_tiempo.value = 100.0
	show()


# Actualiza el tiempo visible.
func actualizar_tiempo(restante: float, duracion: float) -> void:
	if duracion <= 0.0:
		return

	anillo_tiempo.value = clampf(
		(restante / duracion) * 100.0,
		0.0,
		100.0
	)


# Oculta el indicador al terminar el QTE.
func ocultar_qte() -> void:
	hide()
