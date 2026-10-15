extends Node2D

# Configuración editable del equilibrio.
@export var configuracion: ConfiguracionEquilibrio

signal equilibrio_cambiado(valor: float)
signal equilibrio_agotado

@onready var hud: CanvasLayer = $HUB
@onready var movimiento_toro: Node2D = $escenario/Toro/movimiento
@onready var gestor_qte: Node = $GestorQTE
@onready var qte_prompt: Control = $HUB/QTEPrompt
@onready var temporizador_qte: Timer = $GestorQTE/TemporizadorQTE

var equilibrio_actual: float = 100.0
var partida_activa: bool = true
var tiempo_entre_qte: float = 0.0

@export var intervalo_qte: float = 5.0


func _ready() -> void:
	if configuracion == null:
		push_error("Falta asignar la configuración del equilibrio.")
		return

	randomize()
	equilibrio_actual = configuracion.equilibrio_inicial

	gestor_qte.qte_iniciado.connect(_on_qte_iniciado)
	gestor_qte.qte_acertado.connect(_on_qte_acertado)
	gestor_qte.qte_fallado.connect(_on_qte_fallado)

	equilibrio_cambiado.emit(equilibrio_actual)


func _process(delta: float) -> void:
	if configuracion == null or not partida_activa:
		return

	modificar_equilibrio(-configuracion.perdida_por_segundo * delta)

	if not partida_activa:
		return

	if gestor_qte.qte_activo:
		qte_prompt.actualizar_tiempo(
			temporizador_qte.time_left,
			temporizador_qte.wait_time
		)
	else:
		tiempo_entre_qte += delta

		if tiempo_entre_qte >= intervalo_qte:
			iniciar_qte()


func iniciar_qte() -> void:
	tiempo_entre_qte = 0.0

	var tipo_qte: int = randi_range(0, 1)

	if tipo_qte == 0:
		gestor_qte.iniciar_simple()
	else:
		gestor_qte.iniciar_direccion(movimiento_toro.rotation)


func _unhandled_input(event: InputEvent) -> void:
	if not partida_activa or not gestor_qte.qte_activo:
		return

	var acciones: Array[String] = [
		"qte_izq",
		"qte_derecha",
		"qte_arriba",
        "qte_abajo"
	]

	for accion in acciones:
		if event.is_action_pressed(accion):
			gestor_qte.comprobar_respuesta(accion)
			return


func _on_qte_iniciado(
	_accion: String, tecla: String, es_direccion: bool
) -> void:
	qte_prompt.mostrar_qte(tecla, es_direccion)


# Muestra CORRECTO y recupera equilibrio.
func _on_qte_acertado() -> void:
	qte_prompt.mostrar_resultado(true)
	modificar_equilibrio(configuracion.recuperacion_qte)


# Muestra FALLASTE y penaliza el equilibrio.
func _on_qte_fallado() -> void:
	qte_prompt.mostrar_resultado(false)
	modificar_equilibrio(-configuracion.penalizacion_fallo)


func modificar_equilibrio(cantidad: float) -> void:
	equilibrio_actual = clampf(
		equilibrio_actual + cantidad,
		0.0,
		configuracion.equilibrio_maximo
	)

	equilibrio_cambiado.emit(equilibrio_actual)

	if equilibrio_actual <= 0.0 and partida_activa:
		terminar_partida()


# Termina la partida y abre la pantalla de derrota.
func terminar_partida() -> void:
	partida_activa = false
	gestor_qte.detener()
	qte_prompt.ocultar_qte()
	equilibrio_agotado.emit()

	get_tree().change_scene_to_file(
        "res://Scenes/ui/fin_juego.tscn"
	)
