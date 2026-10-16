extends Node2D

# Configuración editable del toro.
@export var configuracion: ConfiguracionToro

# Nodo que contiene las partes móviles.
@onready var movimiento: Node2D = $movimiento

# Tiempo acumulado del movimiento.
var tiempo: float = 0.0

# Nivel de furia actual.
var nivel_furia: int = 1

# Multiplicador de intensidad del movimiento.
var multiplicador_furia: float = 1.0


# Actualiza el movimiento del toro.
func _process(delta: float) -> void:
	if configuracion == null:
		return

	tiempo += delta
	balancear_toro()


# Inclina el toro de forma alternada.
func balancear_toro() -> void:
	var inclinacion: float = sin(
		tiempo * configuracion.frecuencia_galope
	)

	movimiento.rotation = (
		inclinacion
		* configuracion.fuerza_galope
		* configuracion.amplitud_inclinacion
		* multiplicador_furia
	)


# Actualiza la intensidad según la furia.
func actualizar_nivel_furia(nivel: int) -> void:
	nivel_furia = clampi(nivel, 1, 5)

	match nivel_furia:
		1:
			multiplicador_furia = 1.0
		2:
			multiplicador_furia = 1.25
		3:
			multiplicador_furia = 1.5
		4:
			multiplicador_furia = 1.75
		5:
			multiplicador_furia = 2.0
