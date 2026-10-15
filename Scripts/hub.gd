extends CanvasLayer

@onready var barra_equilibrio: ProgressBar = $barraequilibrio
@export var color_equilibrio_alto: Color = Color.GREEN
@export var color_equilibrio_medio: Color = Color.YELLOW
@export var color_equilibrio_bajo: Color = Color.RED

# Límites configurables.
@export_range(0.0, 100.0) var limite_alto: float = 60.0
@export_range(0.0, 100.0) var limite_medio: float = 30.0


# Prepara la barra al iniciar.
func _ready() -> void:
	barra_equilibrio.min_value = 0.0
	barra_equilibrio.max_value = 100.0
	barra_equilibrio.value = 100.0

	actualizar_color(100.0)


# Actualiza el equilibrio y su color.
func actualizar_equilibrio(valor: float) -> void:
	barra_equilibrio.value = valor
	actualizar_color(valor)


# Cambia el color según el equilibrio.
func actualizar_color(valor: float) -> void:
	var estilo: StyleBoxFlat = barra_equilibrio.get_theme_stylebox("fill") as StyleBoxFlat

	if estilo == null:
		return

	if valor > limite_alto:
		estilo.bg_color = color_equilibrio_alto
	elif valor > limite_medio:
		estilo.bg_color = color_equilibrio_medio
	else:
		estilo.bg_color = color_equilibrio_bajo


# Recibe la señal enviada por Juego.
func _on_juego_equilibrio_cambiado(valor: float) -> void:
	actualizar_equilibrio(valor)
