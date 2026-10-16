extends Node2D

# Configuración editable del equilibrio.
@export var configuracion: ConfiguracionEquilibrio

signal equilibrio_cambiado(valor: float)
signal equilibrio_agotado
signal nivel_furia_cambiado(nivel: int)

@onready var hud: CanvasLayer = $HUB
@onready var toro: Node2D = $escenario/Toro
@onready var movimiento_toro: Node2D = $escenario/Toro/movimiento
@onready var jinete: Node2D = $escenario/Toro/movimiento/Puntomontura/Jinete
@onready var gestor_qte: Node = $GestorQTE
@onready var qte_prompt: Control = $HUB/QTEPrompt
@onready var temporizador_qte: Timer = $GestorQTE/TemporizadorQTE

var equilibrio_actual: float = 100.0
var partida_activa: bool = true
var tiempo_entre_qte: float = 0.0

# Sistema de furia.
var tiempo_partida: float = 0.0
var nivel_furia: int = 1
var intervalo_qte: float = 1.8

const NIVEL_FURIA_MAXIMO: int = 5
const SEGUNDOS_POR_NIVEL: float = 10.0


func _ready() -> void:
	if configuracion == null:
		push_error("Falta asignar la configuración del equilibrio.")
		return

	randomize()

	equilibrio_actual = configuracion.equilibrio_inicial

	# Conecta el equilibrio y la furia con el HUD.
	equilibrio_cambiado.connect(hud.actualizar_equilibrio)
	nivel_furia_cambiado.connect(hud.actualizar_nivel_furia)

	# Conecta la furia con el movimiento del toro.
	nivel_furia_cambiado.connect(toro.actualizar_nivel_furia)

	# Conecta las señales de los QTE.
	gestor_qte.qte_iniciado.connect(_on_qte_iniciado)
	gestor_qte.qte_acertado.connect(_on_qte_acertado)
	gestor_qte.qte_fallado.connect(_on_qte_fallado)
	gestor_qte.progreso_machacar.connect(_on_progreso_machacar)

	configurar_dificultad_furia()

	# Muestra los valores iniciales.
	equilibrio_cambiado.emit(equilibrio_actual)
	nivel_furia_cambiado.emit(nivel_furia)


func _process(delta: float) -> void:
	if configuracion == null or not partida_activa:
		return

	# Actualiza el nivel de furia.
	actualizar_furia(delta)

	# Reduce el equilibrio constantemente.
	modificar_equilibrio(
		-configuracion.perdida_por_segundo * delta
	)

	if not partida_activa:
		return

	# Actualiza el indicador de tiempo del QTE.
	if gestor_qte.qte_activo:
		qte_prompt.actualizar_tiempo(
			temporizador_qte.time_left,
			temporizador_qte.wait_time
		)
	else:
		tiempo_entre_qte += delta

		if tiempo_entre_qte >= intervalo_qte:
			iniciar_qte()


# Aumenta la furia cada 10 segundos.
func actualizar_furia(delta: float) -> void:
	tiempo_partida += delta

	var nuevo_nivel: int = mini(
		int(tiempo_partida / SEGUNDOS_POR_NIVEL) + 1,
		NIVEL_FURIA_MAXIMO
	)

	if nuevo_nivel != nivel_furia:
		nivel_furia = nuevo_nivel

		configurar_dificultad_furia()

		# Actualiza el HUD y el movimiento del toro.
		nivel_furia_cambiado.emit(nivel_furia)

		print("Nivel de furia: ", nivel_furia)


# Configura la dificultad de cada nivel.
func configurar_dificultad_furia() -> void:
	gestor_qte.configurar_tiempo_respuesta(nivel_furia)

	match nivel_furia:
		1:
			intervalo_qte = 1.8
		2:
			intervalo_qte = 1.4
		3:
			intervalo_qte = 1.1
		4:
			intervalo_qte = 0.8
		5:
			intervalo_qte = 0.6


# Selecciona los QTE disponibles según la furia.
func iniciar_qte() -> void:
	tiempo_entre_qte = 0.0

	# Cada nivel desbloquea nuevos tipos de QTE.
	var tipo_maximo: int = 1

	match nivel_furia:
		1:
			tipo_maximo = 1
		2:
			tipo_maximo = 2
		3:
			tipo_maximo = 3
		4, 5:
			tipo_maximo = 4

	var tipo_qte: int = randi_range(0, tipo_maximo)

	match tipo_qte:
		0:
			gestor_qte.iniciar_simple()
		1:
			gestor_qte.iniciar_direccion(movimiento_toro.rotation)
		2:
			gestor_qte.iniciar_mantener()
		3:
			gestor_qte.iniciar_machacar()
		4:
			gestor_qte.iniciar_secuencia()


# Recibe las teclas del jugador.
func _unhandled_input(event: InputEvent) -> void:
	if not partida_activa or not gestor_qte.qte_activo:
		return

	# QTE de mantener ESPACIO.
	if gestor_qte.qte_mantener:
		if event.is_action_pressed("accion") and not event.is_echo():
			gestor_qte.comenzar_mantener()
		elif event.is_action_released("accion"):
			gestor_qte.soltar_mantener()
		return

	# QTE de pulsaciones repetidas.
	if gestor_qte.qte_machacar:
		if event.is_action_pressed("accion") and not event.is_echo():
			gestor_qte.registrar_pulsacion()
		return

	# QTE direccionales y de secuencia.
	var acciones: Array[String] = [
		"qte_izq",
		"qte_derecha",
		"qte_arriba",
		"qte_abajo"
	]

	for accion in acciones:
		if event.is_action_pressed(accion) and not event.is_echo():
			if gestor_qte.qte_secuencia:
				gestor_qte.comprobar_secuencia(accion)
			else:
				gestor_qte.comprobar_respuesta(accion)
			return


# Muestra las instrucciones del QTE.
func _on_qte_iniciado(
	_accion: String, tecla: String, es_direccion: bool
) -> void:
	qte_prompt.mostrar_qte(tecla, es_direccion)


# Actualiza el progreso de las pulsaciones.
func _on_progreso_machacar(
	pulsaciones: int, necesarias: int
) -> void:
	qte_prompt.actualizar_progreso(
		pulsaciones,
		necesarias
	)


# Recupera equilibrio al acertar.
func _on_qte_acertado() -> void:
	qte_prompt.mostrar_resultado(true)
	modificar_equilibrio(configuracion.recuperacion_qte)


# Pierde equilibrio al fallar.
func _on_qte_fallado() -> void:
	qte_prompt.mostrar_resultado(false)
	modificar_equilibrio(-configuracion.penalizacion_fallo)


# Actualiza el equilibrio y notifica al HUD.
func modificar_equilibrio(cantidad: float) -> void:
	equilibrio_actual = clampf(
		equilibrio_actual + cantidad,
		0.0,
		configuracion.equilibrio_maximo
	)

	equilibrio_cambiado.emit(equilibrio_actual)

	if equilibrio_actual <= 0.0 and partida_activa:
		terminar_partida()


# Reproduce la caída antes de GAME OVER.
func terminar_partida() -> void:
	partida_activa = false

	gestor_qte.detener()
	qte_prompt.ocultar_qte()

	equilibrio_agotado.emit()

	hud.actualizar_equilibrio(0.0)

	jinete.caer()

	await jinete.caida_terminada

	get_tree().change_scene_to_file(
		"res://Scenes/ui/fin_juego.tscn"
	)
