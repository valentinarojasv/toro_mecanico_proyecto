extends Control

@onready var texto_qte: Label = $TextoQTE
@onready var anillo_tiempo: TextureProgressBar = $AnilloTiempo

var numero_resultado: int = 0
var mostrando_progreso: bool = false

# Colores de los resultados.
const COLOR_NORMAL: Color = Color.WHITE
const COLOR_CORRECTO: Color = Color.GREEN
const COLOR_PERFECTO: Color = Color.GOLD
const COLOR_FALLASTE: Color = Color.RED


func _ready() -> void:
	hide()
	anillo_tiempo.min_value = 0.0
	anillo_tiempo.max_value = 100.0
	anillo_tiempo.value = 100.0


# Convierte las letras del teclado en flechas.
# Solo modifica el texto mostrado, no las acciones del jugador.
func convertir_direccion(tecla: String) -> String:
	match tecla.to_upper():
		"W":
			return "↑"
		"A":
			return "←"
		"S":
			return "↓"
		"D":
			return "→"
		_:
			return tecla


# Convierte las letras de los QTE de secuencia.
func convertir_secuencia(secuencia: String) -> String:
	var texto_convertido: String = secuencia

	# Reemplaza las letras individuales de la secuencia.
	# Se utiliza una expresión regular para evitar modificar
	# letras que formen parte de otras palabras.
	var expresion: RegEx = RegEx.new()
	expresion.compile("\\b[WASD]\\b")

	var coincidencias: Array[RegExMatch] = expresion.search_all(
		texto_convertido
	)

	# Recorre las coincidencias en orden inverso para conservar
	# las posiciones originales durante los reemplazos.
	for i in range(coincidencias.size() - 1, -1, -1):
		var coincidencia: RegExMatch = coincidencias[i]

		var letra: String = coincidencia.get_string()
		var direccion: String = convertir_direccion(letra)

		var inicio: int = coincidencia.get_start()
		var final: int = coincidencia.get_end()

		texto_convertido = (
			texto_convertido.substr(0, inicio)
			+ direccion
			+ texto_convertido.substr(final)
		)

	return texto_convertido


# Muestra las instrucciones del QTE.
func mostrar_qte(tecla: String, es_direccion: bool) -> void:
	numero_resultado += 1
	mostrando_progreso = false

	# Recupera el color normal.
	texto_qte.add_theme_color_override(
		"font_color",
		COLOR_NORMAL
	)

	if es_direccion:
		texto_qte.text = (
			"COMPENSA "
			+ convertir_direccion(tecla)
		)

	elif tecla.begins_with("SECUENCIA:"):
		texto_qte.text = convertir_secuencia(tecla)

	elif tecla == "ESPACIO":
		texto_qte.text = "MANTÉN ESPACIO"

	elif tecla == "REPETIR ESPACIO":
		texto_qte.text = "PULSA ESPACIO\nREPETIDAMENTE"
		mostrando_progreso = true

	else:
		texto_qte.text = (
			"PRESIONA "
			+ convertir_direccion(tecla)
		)

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


# Muestra el resultado del QTE.
func mostrar_resultado(
	correcto: bool,
	perfecto: bool = false
) -> void:
	numero_resultado += 1
	var resultado_actual: int = numero_resultado

	mostrando_progreso = false

	if perfecto:
		texto_qte.text = "¡PERFECTO!"
		texto_qte.add_theme_color_override(
			"font_color",
			COLOR_PERFECTO
		)

	elif correcto:
		texto_qte.text = "¡CORRECTO!"
		texto_qte.add_theme_color_override(
			"font_color",
			COLOR_CORRECTO
		)

	else:
		texto_qte.text = "¡FALLASTE!"
		texto_qte.add_theme_color_override(
			"font_color",
			COLOR_FALLASTE
		)

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
