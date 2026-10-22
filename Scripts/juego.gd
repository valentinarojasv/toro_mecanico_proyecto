extends Node2D

# Configuración editable del equilibrio.
@export var configuracion: ConfiguracionEquilibrio

signal equilibrio_cambiado(valor: float)
signal equilibrio_agotado
signal nivel_furia_cambiado(nivel: int)
signal combo_cambiado(combo: int)
signal puntuacion_cambiada(puntos: int)
signal tiempo_cambiado(segundos: int)
signal turbo_cambiado(carga: float)


# Referencias a los nodos principales.
@onready var hud: CanvasLayer = $HUB
@onready var toro: Node2D = $escenario/Toro
@onready var movimiento_toro: Node2D = $escenario/Toro/movimiento
@onready var jinete: Node2D = $escenario/Toro/movimiento/Puntomontura/Jinete
@onready var gestor_qte: Node = $GestorQTE
@onready var qte_prompt: Control = $HUB/QTEPrompt
@onready var temporizador_qte: Timer = $GestorQTE/TemporizadorQTE

# Efecto visual del Turbo.
@onready var efecto_turbo: ColorRect = $HUB/EfectoTurbo


# Recursos de audio en formato OGG.
const AUDIO_QTE_CORRECTO = preload("res://Audio/success.ogg")
const AUDIO_QTE_PERFECTO = preload("res://Audio/perfect.ogg")
const AUDIO_QTE_FALLIDO = preload("res://Audio/fallo.ogg")
const AUDIO_TURBO = preload("res://Audio/turbo.ogg")
const AUDIO_TURBO_FINALIZADO = preload("res://Audio/perdidaturbo.ogg")
const AUDIO_CAIDA = preload("res://Audio/caidajinete.ogg")
const AUDIO_MUSICA = preload("res://Audio/game.ogg")


# Estado general de la partida.
var equilibrio_actual: float = 100.0
var partida_activa: bool = true
var tiempo_entre_qte: float = 0.0


# Sistema de furia.
var tiempo_partida: float = 0.0
var nivel_furia: int = 1
var intervalo_qte: float = 1.8


# Sistema de combos.
var combo_actual: int = 0


# Sistema de puntuación.
var puntuacion_actual: int = 0
var ultimo_segundo: int = 0


# Sistema Turbo.
var carga_turbo: float = 0.0
var turbo_activo: bool = false
var tiempo_turbo_restante: float = 0.0
var ultimo_segundo_turbo: int = -1


# Control del destello visual.
var animacion_efecto_turbo: Tween


# Configuración definitiva del Turbo.
const CARGA_TURBO_MAXIMA: float = 100.0
const CARGA_POR_PERFECTO: float = 15.0
const PENALIZACION_CARGA_TURBO: float = 30.0
const DURACION_TURBO: float = 5.0


# Penalización de equilibrio durante el Turbo.
const PENALIZACION_FALLO_EN_TURBO: float = 30.0


# Efectos del Turbo.
const MULTIPLICADOR_PUNTOS_TURBO: int = 2
const MULTIPLICADOR_FRECUENCIA_TURBO: float = 1.4


# Puntuación.
const PUNTOS_POR_SEGUNDO: int = 10
const PUNTOS_POR_COMBO: int = 10


# Niveles de furia.
const NIVEL_FURIA_MAXIMO: int = 5
const SEGUNDOS_POR_NIVEL: float = 10.0


# Configuración de la música.
const AUMENTO_MUSICA_POR_FURIA: float = 0.08
const AUMENTO_MUSICA_TURBO: float = 0.20


# Tiempo adicional para apreciar la caída.
const ESPERA_DESPUES_CAIDA: float = 2.0


func _ready() -> void:
	if configuracion == null:
		push_error("Falta asignar la configuración del equilibrio.")
		return

	randomize()

	equilibrio_actual = configuracion.equilibrio_inicial

	# Detiene cualquier audio anterior antes de iniciar.
	AudioManager.detener_todo()

	# Prepara el efecto visual del Turbo.
	efecto_turbo.visible = false
	efecto_turbo.modulate.a = 0.0
	efecto_turbo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Conecta los indicadores con el HUD.
	equilibrio_cambiado.connect(hud.actualizar_equilibrio)
	nivel_furia_cambiado.connect(hud.actualizar_nivel_furia)
	combo_cambiado.connect(hud.actualizar_combo)
	puntuacion_cambiada.connect(hud.actualizar_puntuacion)
	tiempo_cambiado.connect(hud.actualizar_tiempo)
	turbo_cambiado.connect(hud.actualizar_turbo)

	# Conecta la furia con el movimiento del toro.
	nivel_furia_cambiado.connect(toro.actualizar_nivel_furia)

	# Conecta las señales de los QTE.
	gestor_qte.qte_iniciado.connect(_on_qte_iniciado)
	gestor_qte.qte_acertado.connect(_on_qte_acertado)
	gestor_qte.qte_perfecto.connect(_on_qte_perfecto)
	gestor_qte.qte_fallado.connect(_on_qte_fallado)
	gestor_qte.progreso_machacar.connect(_on_progreso_machacar)

	# Configura la dificultad inicial.
	configurar_dificultad_furia()

	# Inicia la música mediante AudioManager.
	AudioManager.reproducir_musica(AUDIO_MUSICA)

	# Muestra los valores iniciales.
	equilibrio_cambiado.emit(equilibrio_actual)
	nivel_furia_cambiado.emit(nivel_furia)
	combo_cambiado.emit(combo_actual)
	puntuacion_cambiada.emit(puntuacion_actual)
	tiempo_cambiado.emit(0)
	turbo_cambiado.emit(carga_turbo)


func _process(delta: float) -> void:
	if configuracion == null or not partida_activa:
		return

	# Actualiza el tiempo restante del Turbo.
	if turbo_activo:
		tiempo_turbo_restante -= delta

		if tiempo_turbo_restante <= 0.0:
			desactivar_turbo()
		else:
			actualizar_contador_turbo()

	# Actualiza el tiempo, la puntuación y la furia.
	actualizar_furia(delta)
	actualizar_puntuacion_tiempo()

	# El Turbo detiene la pérdida automática de equilibrio.
	if not turbo_activo:
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

		if tiempo_entre_qte >= obtener_intervalo_qte():
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

		nivel_furia_cambiado.emit(nivel_furia)

		print("Nivel de furia: ", nivel_furia)


# Devuelve el multiplicador actual de puntos.
func obtener_multiplicador_puntos() -> int:
	if turbo_activo:
		return MULTIPLICADOR_PUNTOS_TURBO

	return 1


# Calcula el intervalo entre QTE según el Turbo.
func obtener_intervalo_qte() -> float:
	if turbo_activo:
		return intervalo_qte / MULTIPLICADOR_FRECUENCIA_TURBO

	return intervalo_qte


# Suma puntos por cada segundo sobrevivido.
func actualizar_puntuacion_tiempo() -> void:
	var segundos_actuales: int = int(tiempo_partida)

	if segundos_actuales > ultimo_segundo:
		var segundos_ganados: int = (
			segundos_actuales - ultimo_segundo
		)

		ultimo_segundo = segundos_actuales

		var puntos_ganados: int = (
			segundos_ganados
			* PUNTOS_POR_SEGUNDO
			* obtener_multiplicador_puntos()
		)

		puntuacion_actual += puntos_ganados

		tiempo_cambiado.emit(segundos_actuales)
		puntuacion_cambiada.emit(puntuacion_actual)

		print(
			"Tiempo: ", segundos_actuales,
			" s | Puntos ganados: +", puntos_ganados,
			" | Puntuación: ", puntuacion_actual
		)


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

	# Ajusta la música al nivel de furia.
	actualizar_musica()


# Ajusta la música según la furia y el Turbo.
func actualizar_musica() -> void:
	var velocidad_musica: float = (
		1.0
		+ float(nivel_furia - 1) * AUMENTO_MUSICA_POR_FURIA
	)

	# Durante el Turbo la música se acelera.
	if turbo_activo:
		velocidad_musica += AUMENTO_MUSICA_TURBO

	AudioManager.ajustar_velocidad_musica(velocidad_musica)


# Selecciona los QTE disponibles según la furia.
func iniciar_qte() -> void:
	tiempo_entre_qte = 0.0

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
	if not partida_activa:
		return

	# Activa el Turbo con Shift cuando está cargado.
	if event.is_action_pressed("activar_turbo") and not event.is_echo():
		activar_turbo()
		return

	if not gestor_qte.qte_activo:
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


# Activa el Turbo cuando la barra está completa.
func activar_turbo() -> void:
	if turbo_activo:
		return

	if carga_turbo < CARGA_TURBO_MAXIMA:
		return

	turbo_activo = true
	tiempo_turbo_restante = DURACION_TURBO
	ultimo_segundo_turbo = -1

	# Acelera la música durante el Turbo.
	actualizar_musica()

	# Reproduce el sonido de activación.
	AudioManager.reproducir_efecto(AUDIO_TURBO)

	# Muestra el destello azul.
	mostrar_efecto_turbo()

	# Reduce el tiempo de respuesta de los QTE.
	gestor_qte.configurar_turbo(true)

	actualizar_contador_turbo()

	print("TURBO ACTIVADO: 5 segundos")
	print("MULTIPLICADOR DE PUNTOS: x2")
	print("PÉRDIDA AUTOMÁTICA DE EQUILIBRIO: DETENIDA")
	print("FRECUENCIA DE QTE: +40%")
	print("TIEMPO DE RESPUESTA QTE: -30%")


# Muestra un destello azul al activar el Turbo.
func mostrar_efecto_turbo() -> void:
	# Detiene una animación anterior.
	if animacion_efecto_turbo != null:
		if animacion_efecto_turbo.is_running():
			animacion_efecto_turbo.kill()

	# Prepara el rectángulo.
	efecto_turbo.modulate.a = 0.0
	efecto_turbo.visible = true

	# Crea el destello.
	animacion_efecto_turbo = create_tween()

	animacion_efecto_turbo.tween_property(
		efecto_turbo,
		"modulate:a",
		1.0,
		0.12
	)

	animacion_efecto_turbo.tween_property(
		efecto_turbo,
		"modulate:a",
		0.0,
		0.35
	)

	animacion_efecto_turbo.tween_callback(
		ocultar_efecto_turbo
	)


# Oculta el destello.
func ocultar_efecto_turbo() -> void:
	efecto_turbo.visible = false
	efecto_turbo.modulate.a = 0.0


# Actualiza la cuenta regresiva del Turbo.
func actualizar_contador_turbo() -> void:
	if not turbo_activo:
		return

	var segundos_visibles: int = ceili(tiempo_turbo_restante)

	if segundos_visibles != ultimo_segundo_turbo:
		ultimo_segundo_turbo = segundos_visibles
		hud.mostrar_turbo_activo(segundos_visibles)


# Finaliza el Turbo y reinicia su carga.
func desactivar_turbo() -> void:
	if not turbo_activo:
		return

	turbo_activo = false
	tiempo_turbo_restante = 0.0
	ultimo_segundo_turbo = -1
	carga_turbo = 0.0

	# Recupera la velocidad musical correspondiente a la furia.
	actualizar_musica()

	# Reproduce el sonido de finalización.
	AudioManager.reproducir_efecto(AUDIO_TURBO_FINALIZADO)

	# Recupera el tiempo de respuesta normal.
	gestor_qte.configurar_turbo(false)

	turbo_cambiado.emit(carga_turbo)
	hud.mostrar_turbo_finalizado()

	print("TURBO FINALIZADO. Carga: 0%")
	print("MULTIPLICADOR DE PUNTOS: x1")
	print("PÉRDIDA AUTOMÁTICA DE EQUILIBRIO: REACTIVADA")
	print("FRECUENCIA DE QTE: NORMAL")
	print("TIEMPO DE RESPUESTA QTE: NORMAL")


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


# Recupera equilibrio al acertar normalmente.
func _on_qte_acertado() -> void:
	qte_prompt.mostrar_resultado(true)

	# Sonido de acierto normal.
	AudioManager.reproducir_efecto(AUDIO_QTE_CORRECTO)

	modificar_equilibrio(configuracion.recuperacion_qte)
	aumentar_combo()


# Recupera equilibrio y carga Turbo por un QTE perfecto.
func _on_qte_perfecto() -> void:
	# Muestra PERFECTO en dorado.
	qte_prompt.mostrar_resultado(true, true)

	# Sonido exclusivo de QTE perfecto.
	AudioManager.reproducir_efecto(AUDIO_QTE_PERFECTO)

	modificar_equilibrio(configuracion.recuperacion_perfecta)
	aumentar_combo()

	# Acumula 15 % por PERFECTO.
	if not turbo_activo:
		carga_turbo = clampf(
			carga_turbo + CARGA_POR_PERFECTO,
			0.0,
			CARGA_TURBO_MAXIMA
		)

		turbo_cambiado.emit(carga_turbo)

	print("QTE PERFECTO: +", configuracion.recuperacion_perfecta)
	print("Carga Turbo: ", carga_turbo, "%")


# Pierde equilibrio y carga Turbo al fallar.
func _on_qte_fallado() -> void:
	qte_prompt.mostrar_resultado(false)

	# Reproduce el sonido de fallo.
	AudioManager.reproducir_efecto(AUDIO_QTE_FALLIDO)

	# Penalización normal o durante Turbo.
	var penalizacion: float = configuracion.penalizacion_fallo

	if turbo_activo:
		penalizacion = PENALIZACION_FALLO_EN_TURBO

	modificar_equilibrio(-penalizacion)
	reiniciar_combo()

	# Reduce la carga cuando Turbo está inactivo.
	if not turbo_activo:
		carga_turbo = clampf(
			carga_turbo - PENALIZACION_CARGA_TURBO,
			0.0,
			CARGA_TURBO_MAXIMA
		)

		turbo_cambiado.emit(carga_turbo)

	print(
		"QTE FALLADO. Equilibrio: -", penalizacion,
		" | Carga Turbo: ", carga_turbo, "%"
	)


# Aumenta el combo y otorga puntos adicionales.
func aumentar_combo() -> void:
	combo_actual += 1
	combo_cambiado.emit(combo_actual)

	var bonificacion: int = (
		combo_actual
		* PUNTOS_POR_COMBO
		* obtener_multiplicador_puntos()
	)

	puntuacion_actual += bonificacion
	puntuacion_cambiada.emit(puntuacion_actual)

	print(
		"Combo: ", combo_actual,
		" | Bonificación: +", bonificacion,
		" | Puntuación: ", puntuacion_actual
	)


# Reinicia el combo cuando se falla.
func reiniciar_combo() -> void:
	combo_actual = 0
	combo_cambiado.emit(combo_actual)

	print("Combo reiniciado: ", combo_actual)


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


# Guarda el récord, el tiempo final y reproduce la caída.
func terminar_partida() -> void:
	if not partida_activa:
		return

	partida_activa = false

	gestor_qte.detener()
	qte_prompt.ocultar_qte()

	# Guarda los resultados.
	GameState.guardar_record(puntuacion_actual)
	GameState.guardar_tiempo_final(int(tiempo_partida))

	print("Puntuación final: ", puntuacion_actual)
	print("Récord actual: ", GameState.puntuacion_record)
	print("Tiempo final: ", GameState.tiempo_final, " segundos")

	equilibrio_agotado.emit()
	hud.actualizar_equilibrio(0.0)

	# Detiene la música y los efectos anteriores.
	AudioManager.detener_todo()

	# Reproduce la caída.
	AudioManager.reproducir_efecto(AUDIO_CAIDA)
	jinete.caer()

	# Espera a que termine la animación.
	await jinete.caida_terminada

	# Mantiene visible la caída durante 2 segundos.
	await get_tree().create_timer(
		ESPERA_DESPUES_CAIDA
	).timeout

	# Abre la pantalla Game Over.
	get_tree().change_scene_to_file(
		"res://Scenes/ui/fin_juego.tscn"
	)
