extends Node

# Señales de los QTE.
signal qte_iniciado(accion: String, tecla: String, es_direccion: bool)
signal qte_acertado
signal qte_fallado
signal progreso_machacar(pulsaciones: int, necesarias: int)

@onready var temporizador: Timer = $TemporizadorQTE

# Acciones de los QTE existentes.
var acciones_qte: Array[String] = [
	"qte_izq", "qte_derecha", "qte_arriba", "qte_abajo"
]

var teclas_qte: Array[String] = ["A", "D", "W", "S"]

var qte_activo: bool = false
var accion_correcta: String = ""

# Tiempo de respuesta según el nivel de furia.
var tiempo_respuesta: float = 1.6

# Configuración del QTE de mantener.
@export var duracion_mantener: float = 1.0

var qte_mantener: bool = false
var manteniendo_tecla: bool = false
var tiempo_mantenido: float = 0.0

# Configuración del QTE de pulsaciones repetidas.
@export_range(1, 20, 1) var pulsaciones_necesarias: int = 5

var qte_machacar: bool = false
var pulsaciones_actuales: int = 0

# Configuración del QTE de secuencia.
@export_range(3, 4, 1) var longitud_secuencia: int = 3
@export var duracion_secuencia: float = 4.0

var qte_secuencia: bool = false
var secuencia_acciones: Array[String] = []
var secuencia_teclas: Array[String] = []
var posicion_secuencia: int = 0


func _ready() -> void:
	temporizador.timeout.connect(fallar_qte)


func _process(delta: float) -> void:
	if not qte_activo or not qte_mantener:
		return

	if manteniendo_tecla:
		tiempo_mantenido += delta

		if tiempo_mantenido >= duracion_mantener:
			acertar_qte()


# Configura el tiempo de respuesta del nivel actual.
func configurar_tiempo_respuesta(nivel_furia: int) -> void:
	match nivel_furia:
		1:
			tiempo_respuesta = 1.6
		2:
			tiempo_respuesta = 1.3
		3:
			tiempo_respuesta = 1.0
		4:
			tiempo_respuesta = 0.8
		5:
			tiempo_respuesta = 0.6


# Inicia un QTE simple.
func iniciar_simple() -> void:
	preparar_qte_normal()

	var indice: int = randi_range(0, acciones_qte.size() - 1)

	accion_correcta = acciones_qte[indice]
	qte_activo = true

	temporizador.start(tiempo_respuesta)
	qte_iniciado.emit(accion_correcta, teclas_qte[indice], false)


# Inicia un QTE direccional.
func iniciar_direccion(inclinacion: float) -> void:
	preparar_qte_normal()

	var tecla: String = ""

	if inclinacion < 0.0:
		accion_correcta = "qte_derecha"
		tecla = "D"
	else:
		accion_correcta = "qte_izq"
		tecla = "A"

	qte_activo = true

	temporizador.start(tiempo_respuesta)
	qte_iniciado.emit(accion_correcta, tecla, true)


# Inicia un QTE de mantener ESPACIO.
func iniciar_mantener() -> void:
	preparar_qte_normal()

	qte_mantener = true
	accion_correcta = "accion"
	qte_activo = true

	# Conserva el tiempo necesario para mantener la tecla.
	var tiempo_mantener_qte: float = maxf(
		tiempo_respuesta,
		duracion_mantener + 0.5
	)

	temporizador.start(tiempo_mantener_qte)
	qte_iniciado.emit(accion_correcta, "ESPACIO", false)


# Inicia un QTE de pulsaciones repetidas.
func iniciar_machacar() -> void:
	preparar_qte_normal()

	qte_machacar = true
	pulsaciones_actuales = 0
	accion_correcta = "accion"
	qte_activo = true

	temporizador.start(tiempo_respuesta)
	qte_iniciado.emit(accion_correcta, "REPETIR ESPACIO", false)


# Inicia un QTE de secuencia.
func iniciar_secuencia() -> void:
	preparar_qte_normal()

	qte_secuencia = true
	posicion_secuencia = 0

	for i in range(longitud_secuencia):
		var indice: int = randi_range(0, acciones_qte.size() - 1)

		secuencia_acciones.append(acciones_qte[indice])
		secuencia_teclas.append(teclas_qte[indice])

	qte_activo = true

	# Conserva el tiempo específico de las secuencias.
	temporizador.start(duracion_secuencia)

	qte_iniciado.emit(
		"secuencia",
		"SECUENCIA: " + obtener_texto_secuencia(),
		false
	)


# Construye el texto de la secuencia.
func obtener_texto_secuencia() -> String:
	var texto: String = ""

	for i in range(secuencia_teclas.size()):
		if i > 0:
			texto += " → "

		texto += secuencia_teclas[i]

	return texto


# Comprueba cada tecla de la secuencia.
func comprobar_secuencia(accion: String) -> void:
	if not qte_activo or not qte_secuencia:
		return

	if accion != secuencia_acciones[posicion_secuencia]:
		fallar_qte()
		return

	posicion_secuencia += 1

	if posicion_secuencia >= secuencia_acciones.size():
		acertar_qte()


# Restablece los estados de los QTE.
func preparar_qte_normal() -> void:
	qte_mantener = false
	manteniendo_tecla = false
	tiempo_mantenido = 0.0

	qte_machacar = false
	pulsaciones_actuales = 0

	qte_secuencia = false
	secuencia_acciones.clear()
	secuencia_teclas.clear()
	posicion_secuencia = 0


# Comprueba los QTE simples y direccionales.
func comprobar_respuesta(accion: String) -> void:
	if not qte_activo:
		return

	if qte_mantener or qte_machacar or qte_secuencia:
		return

	if accion == accion_correcta:
		acertar_qte()
	else:
		fallar_qte()


# Comienza a contar el tiempo mantenido.
func comenzar_mantener() -> void:
	if not qte_activo or not qte_mantener:
		return

	manteniendo_tecla = true


# Falla si se suelta ESPACIO antes de tiempo.
func soltar_mantener() -> void:
	if not qte_activo or not qte_mantener:
		return

	if manteniendo_tecla:
		fallar_qte()


# Registra cada pulsación de ESPACIO.
func registrar_pulsacion() -> void:
	if not qte_activo or not qte_machacar:
		return

	pulsaciones_actuales += 1

	# Actualiza el indicador de progreso.
	progreso_machacar.emit(
		pulsaciones_actuales,
		pulsaciones_necesarias
	)

	if pulsaciones_actuales >= pulsaciones_necesarias:
		acertar_qte()


# Registra un acierto.
func acertar_qte() -> void:
	qte_activo = false
	preparar_qte_normal()

	temporizador.stop()
	qte_acertado.emit()


# Registra un fallo.
func fallar_qte() -> void:
	if not qte_activo:
		return

	qte_activo = false
	preparar_qte_normal()

	temporizador.stop()
	qte_fallado.emit()


# Detiene todos los QTE.
func detener() -> void:
	qte_activo = false
	preparar_qte_normal()

	temporizador.stop()
