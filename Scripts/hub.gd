extends CanvasLayer

@onready var barra_equilibrio: ProgressBar = $barraequilibrio
@onready var barra_turbo: ProgressBar = $BarraTurbo
@onready var estado_turbo_label: Label = $EstadoTurboLabel

@onready var nivel_furia: Label = $NivelFuria
@onready var combo_label: Label = $ComboLabel
@onready var puntuacion_label: Label = $PuntuacionLabel
@onready var tiempo_label: Label = $TiempoLabel

@export var color_equilibrio_alto: Color = Color.GREEN
@export var color_equilibrio_medio: Color = Color.YELLOW
@export var color_equilibrio_bajo: Color = Color.RED

# Límites configurables.
@export_range(0.0, 100.0) var limite_alto: float = 60.0
@export_range(0.0, 100.0) var limite_medio: float = 30.0

# Control del mensaje de finalización.
var tiempo_mensaje_finalizado: float = 0.0


func _ready() -> void:
	barra_equilibrio.min_value = 0.0
	barra_equilibrio.max_value = 100.0
	barra_equilibrio.value = 100.0

	barra_turbo.min_value = 0.0
	barra_turbo.max_value = 100.0
	barra_turbo.value = 0.0

	actualizar_color(100.0)
	actualizar_nivel_furia(1)
	actualizar_combo(0)
	actualizar_puntuacion(0)
	actualizar_tiempo(0)
	actualizar_turbo(0.0)


func _process(delta: float) -> void:
	# Mantiene visible brevemente el mensaje final.
	if tiempo_mensaje_finalizado > 0.0:
		tiempo_mensaje_finalizado -= delta

		if tiempo_mensaje_finalizado <= 0.0:
			actualizar_turbo(barra_turbo.value)


# Actualiza el equilibrio y su color.
func actualizar_equilibrio(valor: float) -> void:
	barra_equilibrio.value = valor
	actualizar_color(valor)


# Cambia el color según el equilibrio.
func actualizar_color(valor: float) -> void:
	var estilo: StyleBoxFlat = (
		barra_equilibrio.get_theme_stylebox("fill") as StyleBoxFlat
	)

	if estilo == null:
		return

	if valor > limite_alto:
		estilo.bg_color = color_equilibrio_alto
	elif valor > limite_medio:
		estilo.bg_color = color_equilibrio_medio
	else:
		estilo.bg_color = color_equilibrio_bajo


# Actualiza el texto del nivel de furia.
func actualizar_nivel_furia(nivel: int) -> void:
	nivel_furia.text = "FURIA: NIVEL " + str(nivel)


# Actualiza el indicador visual del combo.
func actualizar_combo(combo: int) -> void:
	combo_label.text = "COMBO: " + str(combo)


# Actualiza los puntos de la partida.
func actualizar_puntuacion(puntos: int) -> void:
	puntuacion_label.text = "PUNTUACIÓN: " + str(puntos)


# Actualiza el tiempo de supervivencia.
func actualizar_tiempo(segundos: int) -> void:
	tiempo_label.text = "TIEMPO: " + str(segundos) + " s"


# Actualiza la barra y el estado del Turbo.
func actualizar_turbo(carga: float) -> void:
	barra_turbo.value = carga

	if tiempo_mensaje_finalizado > 0.0:
		return

	if carga >= 100.0:
		estado_turbo_label.text = "TURBO LISTO - PRESIONA SHIFT"
	else:
		estado_turbo_label.text = "TURBO NO DISPONIBLE"


# Muestra el tiempo restante del Turbo activo.
func mostrar_turbo_activo(segundos: int) -> void:
	tiempo_mensaje_finalizado = 0.0

	estado_turbo_label.text = (
		"TURBO ACTIVO: " + str(segundos) + " s"
	)


# Muestra el aviso cuando termina el Turbo.
func mostrar_turbo_finalizado() -> void:
	estado_turbo_label.text = "TURBO FINALIZADO"

	# Mantiene el aviso durante un segundo.
	tiempo_mensaje_finalizado = 1.0
