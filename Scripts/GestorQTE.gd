extends Node

# Avisa cuando comienza un QTE.
signal qte_iniciado(accion: String, tecla: String, es_direccion: bool)

# Avisa cuando el jugador acierta.
signal qte_acertado

# Avisa cuando el jugador falla.
signal qte_fallado

# Temporizador del QTE.
@onready var temporizador: Timer = $TemporizadorQTE

# Acciones disponibles.
var acciones_qte: Array[String] = [
	"qte_izq",
	"qte_derecha",
	"qte_arriba",
	"qte_abajo"
]

var teclas_qte: Array[String] = [
	"A",
	"D",
	"W",
	"S"
]

# Estado del QTE.
var qte_activo: bool = false
var accion_correcta: String = ""


# Prepara el temporizador.
func _ready() -> void:
	temporizador.timeout.connect(fallar_qte)


# Inicia un QTE de pulsación simple.
func iniciar_simple() -> void:
	var indice: int = randi_range(0, acciones_qte.size() - 1)

	accion_correcta = acciones_qte[indice]
	qte_activo = true

	temporizador.start()

	qte_iniciado.emit(
		accion_correcta,
		teclas_qte[indice],
		false
	)


# Inicia un QTE de dirección.
func iniciar_direccion(inclinacion: float) -> void:
	var tecla: String = ""

	if inclinacion < 0.0:
		accion_correcta = "qte_derecha"
		tecla = "D"
	else:
		accion_correcta = "qte_izq"
		tecla = "A"

	qte_activo = true

	temporizador.start()

	qte_iniciado.emit(
		accion_correcta,
		tecla,
		true
	)


# Comprueba la respuesta del jugador.
func comprobar_respuesta(accion: String) -> void:
	if not qte_activo:
		return

	if accion == accion_correcta:
		acertar_qte()
	else:
		fallar_qte()

func acertar_qte() -> void:
	qte_activo = false
	temporizador.stop()
	qte_acertado.emit()

func fallar_qte() -> void:
	if not qte_activo:
		return

	qte_activo = false
	temporizador.stop()
	qte_fallado.emit()


# Detiene cualquier QTE activo.
func detener() -> void:
	qte_activo = false
	temporizador.stop()
