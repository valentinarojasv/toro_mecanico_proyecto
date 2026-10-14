extends Node2D

# Configuración editable del toro.
@export var configuracion: ConfiguracionToro

# Nodo que contiene las partes móviles.
@onready var movimiento: Node2D = $movimiento

# Tiempo acumulado del movimiento.
var tiempo: float = 0.0


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
	)
