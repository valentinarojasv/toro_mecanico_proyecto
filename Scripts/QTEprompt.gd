extends Control

@onready var texto_qte: Label = $TextoQTE
@onready var anillo_tiempo: TextureProgressBar = $AnilloTiempo

var numero_resultado: int = 0
var mostrando_progreso: bool = false


func _ready() -> void:
	hide()
	anillo_tiempo.min_value = 0.0
	anillo_tiempo.max_value = 100.0
	anillo_tiempo.value = 100.0


# Muestra las instrucciones del QTE.
func mostrar_qte(tecla: String, es_direccion: bool) -> void:
	numero_resultado += 1
	mostrando_progreso = false

	if es_direccion:
		texto_qte.text = "COMPENSA CON " + tecla
	elif tecla.begins_with("SECUENCIA:"):
		texto_qte.text = tecla
	elif tecla == "ESPACIO":
		texto_qte.text = "MANTÉN ESPACIO"
	elif tecla == "REPETIR ESPACIO":
		texto_qte.text = "PULSA ESPACIO
		 REPETIDAMENTE"
		mostrando_progreso = true
	else:
		texto_qte.text = "PRESIONA " + tecla

	anillo_tiempo.show()

	if mostrando_progreso:
		anillo_tiempo.value = 0.0
	else:
		anillo_tiempo.value = 100.0

	show()


# Actualiza el tiempo restante.
func actualizar_tiempo(restante: float, duracion: float) -> void:
	if duracion <= 0.0 or mostrando_progreso:
		return

	anillo_tiempo.value = clampf(
		(restante / duracion) * 100.0,
		0.0,
		100.0
	)


# Actualiza el progreso de las pulsaciones.
func actualizar_progreso(pulsaciones: int, necesarias: int) -> void:
	if not mostrando_progreso or necesarias <= 0:
		return

	anillo_tiempo.value = clampf(
		(float(pulsaciones) / float(necesarias)) * 100.0,
		0.0,
		100.0
	)


# Muestra CORRECTO o FALLASTE.
func mostrar_resultado(correcto: bool) -> void:
	numero_resultado += 1
	var resultado_actual: int = numero_resultado

	mostrando_progreso = false

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
	mostrando_progreso = false
	hide()
