extends Node2D

# Recurso editable con los valores del sistema de equilibrio.
@export var configuracion: ConfiguracionEquilibrio

# Señales utilizadas para actualizar el HUD y comunicar eventos.
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
@onready var visual_jinete: Node2D = $escenario/Toro/movimiento/Puntomontura/Jinete/visual
@onready var gestor_qte: Node = $GestorQTE
@onready var qte_prompt: Control = $HUB/QTEPrompt
@onready var temporizador_qte: Timer = $GestorQTE/TemporizadorQTE

# Reproductores de sonido.
@onready var sonido_qte_correcto: AudioStreamPlayer = $SonidoQTECorrecto
@onready var sonido_qte_fallido: AudioStreamPlayer = $SonidoQTEFallido

# Rectángulos utilizados para los destellos visuales.
@onready var efecto_acierto: ColorRect = $HUB/EfectoAcierto
@onready var efecto_fallo: ColorRect = $HUB/EfectoFallo

# Cámara del escenario.
@onready var camara: Camera2D = buscar_camara()

# Variables del sistema de equilibrio.
var equilibrio_actual: float = 100.0
var partida_activa: bool = true
var tiempo_entre_qte: float = 0.0

# Variables de tiempo y dificultad.
var tiempo_partida: float = 0.0
var nivel_furia: int = 1
var intervalo_qte: float = 1.8

# Variables de puntuación y combo.
var combo_actual: int = 0
var puntuacion_actual: int = 0
var ultimo_segundo: int = 0

# Variables del sistema Turbo.
var carga_turbo: float = 0.0
var turbo_activo: bool = false
var tiempo_turbo_restante: float = 0.0
var ultimo_segundo_turbo: int = -1

# Variables para las animaciones del jinete.
var tiempo_retorno_jinete: float = 0.0
var animacion_jinete_temporal: bool = false

# Control de la inclinación previa al aviso de compensación.
var qte_direccion_activo: bool = false
var esperando_aviso_compensacion: bool = false

var rotacion_original_jinete: float = 0.0
var rotacion_original_visual: float = 0.0

# Tweens utilizados para los efectos visuales.
var tween_efecto_acierto: Tween
var tween_efecto_fallo: Tween
var tween_rebote: Tween
var tween_camara: Tween

# Posiciones originales.
var posicion_original_jinete: Vector2 = Vector2.ZERO
var posicion_original_camara: Vector2 = Vector2.ZERO

# Configuración del sistema Turbo.
const CARGA_TURBO_MAXIMA: float = 100.0
const CARGA_POR_PERFECTO: float = 15.0
const PENALIZACION_CARGA_TURBO: float = 30.0
const DURACION_TURBO: float = 5.0
const PENALIZACION_FALLO_EN_TURBO: float = 30.0

# Multiplicadores del Turbo.
const MULTIPLICADOR_PUNTOS_TURBO: int = 2
const MULTIPLICADOR_FRECUENCIA_TURBO: float = 1.4

# Valores de puntuación.
const PUNTOS_POR_SEGUNDO: int = 10
const PUNTOS_POR_COMBO: int = 10

# Configuración de dificultad.
const NIVEL_FURIA_MAXIMO: int = 5
const SEGUNDOS_POR_NIVEL: float = 10.0

# Duración de las inclinaciones del jinete.
const DURACION_INCLINACION_JINETE: float = 0.35

# Configuración de los destellos.
const DURACION_DESTELLO: float = 0.25
const INTENSIDAD_DESTELLO: float = 0.45

# Configuración del rebote del jinete.
const ALTURA_REBOTE: float = 12.0
const DURACION_REBOTE: float = 0.20

# Configuración de la sacudida de cámara.
const INTENSIDAD_SACUDIDA: float = 10.0
const DURACION_SACUDIDA: float = 0.30
const INTERVALO_SACUDIDA: float = 0.04


# Busca una cámara dentro de la escena.
func buscar_camara() -> Camera2D:
	var camaras: Array[Node] = find_children(
		"*",
		"Camera2D",
		true,
		false
	)

	if camaras.is_empty():
		return null

	return camaras[0] as Camera2D


# Inicializa las variables, señales y efectos.
func _ready() -> void:
	if configuracion == null:
		push_error("Falta asignar la configuración del equilibrio.")
		return

	randomize()

	equilibrio_actual = configuracion.equilibrio_inicial

	posicion_original_jinete = jinete.position
	rotacion_original_jinete = jinete.rotation
	rotacion_original_visual = visual_jinete.rotation

	if camara != null:
		posicion_original_camara = camara.offset

	efecto_acierto.visible = false
	efecto_fallo.visible = false

	efecto_acierto.modulate.a = 0.0
	efecto_fallo.modulate.a = 0.0

	efecto_acierto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	efecto_fallo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Conecta las señales del HUD.
	equilibrio_cambiado.connect(hud.actualizar_equilibrio)
	nivel_furia_cambiado.connect(hud.actualizar_nivel_furia)
	combo_cambiado.connect(hud.actualizar_combo)
	puntuacion_cambiada.connect(hud.actualizar_puntuacion)
	tiempo_cambiado.connect(hud.actualizar_tiempo)
	turbo_cambiado.connect(hud.actualizar_turbo)

	# Comunica la furia al toro.
	nivel_furia_cambiado.connect(toro.actualizar_nivel_furia)

	# Conecta los eventos QTE.
	gestor_qte.qte_iniciado.connect(_on_qte_iniciado)
	gestor_qte.qte_acertado.connect(_on_qte_acertado)
	gestor_qte.qte_perfecto.connect(_on_qte_perfecto)
	gestor_qte.qte_fallado.connect(_on_qte_fallado)
	gestor_qte.progreso_machacar.connect(_on_progreso_machacar)

	configurar_dificultad_furia()

	# El jinete comienza en reposo.
	jinete.reposo()

	equilibrio_cambiado.emit(equilibrio_actual)
	nivel_furia_cambiado.emit(nivel_furia)
	combo_cambiado.emit(combo_actual)
	puntuacion_cambiada.emit(puntuacion_actual)
	tiempo_cambiado.emit(0)
	turbo_cambiado.emit(carga_turbo)


# Actualiza las mecánicas principales.
func _process(delta: float) -> void:
	if configuracion == null or not partida_activa:
		return

	# No genera inclinaciones automáticas.
	actualizar_animacion_jinete(delta)

	if turbo_activo:
		tiempo_turbo_restante -= delta

		if tiempo_turbo_restante <= 0.0:
			desactivar_turbo()
		else:
			actualizar_contador_turbo()

	actualizar_furia(delta)
	actualizar_puntuacion_tiempo()

	if not turbo_activo:
		modificar_equilibrio(
			-configuracion.perdida_por_segundo * delta
		)

	if not partida_activa:
		return

	if gestor_qte.qte_activo:
		# Durante la inclinación previa todavía no se muestra
		# la barra de respuesta.
		if not esperando_aviso_compensacion:
			qte_prompt.actualizar_tiempo(
				temporizador_qte.time_left,
				temporizador_qte.wait_time
			)
	else:
		tiempo_entre_qte += delta

		if tiempo_entre_qte >= obtener_intervalo_qte():
			iniciar_qte()


# Muestra el destello de acierto.
func mostrar_efecto_acierto() -> void:
	if tween_efecto_acierto != null:
		if tween_efecto_acierto.is_running():
			tween_efecto_acierto.kill()

	efecto_acierto.visible = true
	efecto_acierto.modulate.a = INTENSIDAD_DESTELLO

	tween_efecto_acierto = create_tween()

	tween_efecto_acierto.tween_property(
		efecto_acierto,
		"modulate:a",
		0.0,
		DURACION_DESTELLO
	)

	tween_efecto_acierto.tween_callback(
		func() -> void:
			efecto_acierto.visible = false
	)


# Muestra el destello de fallo.
func mostrar_efecto_fallo() -> void:
	if tween_efecto_fallo != null:
		if tween_efecto_fallo.is_running():
			tween_efecto_fallo.kill()

	efecto_fallo.visible = true
	efecto_fallo.modulate.a = INTENSIDAD_DESTELLO

	tween_efecto_fallo = create_tween()

	tween_efecto_fallo.tween_property(
		efecto_fallo,
		"modulate:a",
		0.0,
		DURACION_DESTELLO
	)

	tween_efecto_fallo.tween_callback(
		func() -> void:
			efecto_fallo.visible = false
	)


# Produce un pequeño rebote al acertar.
func aplicar_rebote_jinete() -> void:
	if not partida_activa:
		return

	if tween_rebote != null:
		if tween_rebote.is_running():
			tween_rebote.kill()

	var posicion_base: Vector2 = posicion_original_jinete

	jinete.position = posicion_base

	tween_rebote = create_tween()

	tween_rebote.tween_property(
		jinete,
		"position:y",
		posicion_base.y - ALTURA_REBOTE,
		DURACION_REBOTE / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween_rebote.tween_property(
		jinete,
		"position:y",
		posicion_base.y,
		DURACION_REBOTE / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# Sacude brevemente la cámara al fallar.
func aplicar_sacudida_camara() -> void:
	if camara == null:
		return

	if tween_camara != null:
		if tween_camara.is_running():
			tween_camara.kill()

	camara.offset = posicion_original_camara

	tween_camara = create_tween()

	var cantidad_movimientos: int = maxi(
		int(DURACION_SACUDIDA / INTERVALO_SACUDIDA),
		1
	)

	for i in range(cantidad_movimientos):
		var progreso: float = float(i) / float(cantidad_movimientos)

		var intensidad_actual: float = (
			INTENSIDAD_SACUDIDA * (1.0 - progreso)
		)

		var desplazamiento: Vector2 = Vector2(
			randf_range(-intensidad_actual, intensidad_actual),
			randf_range(-intensidad_actual, intensidad_actual)
		)

		tween_camara.tween_property(
			camara,
			"offset",
			posicion_original_camara + desplazamiento,
			INTERVALO_SACUDIDA
		)

	tween_camara.tween_property(
		camara,
		"offset",
		posicion_original_camara,
		INTERVALO_SACUDIDA
	)


# Inclina al jinete a la izquierda al comenzar un QTE de compensación.
func animar_jinete_izquierda() -> void:
	if not partida_activa:
		return

	jinete.inclinar_izquierda()


# Inclina al jinete a la derecha al comenzar un QTE de compensación.
func animar_jinete_derecha() -> void:
	if not partida_activa:
		return

	jinete.inclinar_derecha()


# Devuelve al jinete a su postura normal al finalizar el QTE.
func animar_jinete_reposo() -> void:
	if not partida_activa:
		return

	jinete.reposo()

	# Las animaciones modifican visual.rotation.
	visual_jinete.rotation = rotacion_original_visual


# Las inclinaciones solo se inician desde _on_qte_iniciado.
# No se calcula ninguna animación a partir del balanceo normal del toro.
func actualizar_animacion_jinete(_delta: float) -> void:
	pass


# Incrementa el nivel de furia cada diez segundos.
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


# Configura el intervalo entre QTE según la furia.
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


# Obtiene el multiplicador de puntos.
func obtener_multiplicador_puntos() -> int:
	if turbo_activo:
		return MULTIPLICADOR_PUNTOS_TURBO

	return 1


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
			" s | Puntos: ", puntuacion_actual
		)


# Aumenta el combo y concede puntos adicionales.
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
		" | Bonificación: +", bonificacion
	)


# Reinicia el combo después de fallar.
func reiniciar_combo() -> void:
	combo_actual = 0

	combo_cambiado.emit(combo_actual)

	print("Combo reiniciado")


# Calcula el intervalo entre QTE.
func obtener_intervalo_qte() -> float:
	if turbo_activo:
		return intervalo_qte / MULTIPLICADOR_FRECUENCIA_TURBO

	return intervalo_qte


# Inicia un QTE aleatorio según la furia.
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
			# El gestor calcula la dirección contraria
			# a la inclinación del toro.
			gestor_qte.iniciar_direccion(
				movimiento_toro.rotation
			)

		2:
			gestor_qte.iniciar_mantener()

		3:
			gestor_qte.iniciar_machacar()

		4:
			gestor_qte.iniciar_secuencia()


# Procesa las entradas del teclado.
func _unhandled_input(event: InputEvent) -> void:
	if not partida_activa:
		return

	# Activa el Turbo.
	if event.is_action_pressed("activar_turbo") and not event.is_echo():
		activar_turbo()
		return

	if not gestor_qte.qte_activo:
		return

	# Impide responder antes de que aparezca la tecla.
	if esperando_aviso_compensacion:
		return

	# QTE de mantener presionado.
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

	# Reconoce las acciones direccionales.
	var acciones: Array[String] = [
		"qte_izq",
		"qte_derecha",
		"qte_arriba",
		"qte_abajo"
	]

	for accion in acciones:
		if event.is_action_pressed(accion) and not event.is_echo():
			# La inclinación ya ocurrió antes del aviso.
			# Aquí solamente se comprueba la respuesta.
			if gestor_qte.qte_secuencia:
				gestor_qte.comprobar_secuencia(accion)
			else:
				gestor_qte.comprobar_respuesta(accion)

			return


# Cuando inicia un QTE de dirección:
# 1. El jinete se inclina hacia el lado de compensación.
# 2. Se espera a que la inclinación sea visible.
# 3. Aparece la tecla correspondiente.
func _on_qte_iniciado(
	_accion: String,
	tecla: String,
	es_direccion: bool
) -> void:
	qte_direccion_activo = es_direccion

	# Los demás QTE funcionan normalmente.
	if not es_direccion:
		qte_prompt.mostrar_qte(tecla, false)
		return

	# Evita que el jugador responda antes del aviso.
	esperando_aviso_compensacion = true

	# Pausa el tiempo de respuesta mientras se inclina.
	temporizador_qte.paused = true

	# Oculta el aviso durante la inclinación inicial.
	qte_prompt.ocultar_qte()

	# CORRECCIÓN:
	# Si la tecla es D, el jinete se inclina a la derecha.
	# Si la tecla es A, el jinete se inclina a la izquierda.
	#
	# La dirección indicada corresponde a la compensación
	# del equilibrio del toro.

	if gestor_qte.accion_correcta == "qte_derecha":
		animar_jinete_derecha()
	else:
		animar_jinete_izquierda()

	# Espera a que la inclinación sea visible.
	await get_tree().create_timer(
		DURACION_INCLINACION_JINETE
	).timeout

	# Evita continuar si terminó la partida.
	if not is_inside_tree() or not partida_activa:
		return

	# Evita mostrar un aviso de un QTE cancelado.
	if not gestor_qte.qte_activo or not qte_direccion_activo:
		return

	# Ahora aparece la tecla de compensación.
	qte_prompt.mostrar_qte(tecla, true)

	# Permite responder.
	esperando_aviso_compensacion = false

	# El tiempo de respuesta comienza ahora.
	temporizador_qte.paused = false


# Actualiza el progreso del QTE de machacar.
func _on_progreso_machacar(
	pulsaciones: int,
	necesarias: int
) -> void:
	qte_prompt.actualizar_progreso(
		pulsaciones,
		necesarias
	)


# Procesa un QTE acertado.
func _on_qte_acertado() -> void:
	# Si era una compensación, el jinete vuelve a reposo.
	if qte_direccion_activo:
		animar_jinete_reposo()

	qte_direccion_activo = false
	esperando_aviso_compensacion = false
	temporizador_qte.paused = false

	qte_prompt.mostrar_resultado(true)

	sonido_qte_correcto.play()

	mostrar_efecto_acierto()
	aplicar_rebote_jinete()

	modificar_equilibrio(
		configuracion.recuperacion_qte
	)

	aumentar_combo()


# Procesa un QTE perfecto.
func _on_qte_perfecto() -> void:
	# Si era una compensación, el jinete vuelve a reposo.
	if qte_direccion_activo:
		animar_jinete_reposo()

	qte_direccion_activo = false
	esperando_aviso_compensacion = false
	temporizador_qte.paused = false

	qte_prompt.mostrar_resultado(true, true)

	sonido_qte_correcto.play()

	mostrar_efecto_acierto()
	aplicar_rebote_jinete()

	modificar_equilibrio(
		configuracion.recuperacion_perfecta
	)

	aumentar_combo()

	# Cada PERFECTO carga un 15 % del Turbo.
	if not turbo_activo:
		carga_turbo = clampf(
			carga_turbo + CARGA_POR_PERFECTO,
			0.0,
			CARGA_TURBO_MAXIMA
		)

		turbo_cambiado.emit(carga_turbo)

	print(
		"QTE PERFECTO | Turbo: ",
		carga_turbo,
		"%"
	)


# Procesa un QTE fallado.
func _on_qte_fallado() -> void:
	# Finaliza la inclinación si era un QTE de dirección.
	if qte_direccion_activo:
		animar_jinete_reposo()

	qte_direccion_activo = false
	esperando_aviso_compensacion = false
	temporizador_qte.paused = false

	qte_prompt.mostrar_resultado(false)

	sonido_qte_fallido.play()

	mostrar_efecto_fallo()
	aplicar_sacudida_camara()

	var penalizacion: float = (
		configuracion.penalizacion_fallo
	)

	if turbo_activo:
		penalizacion = PENALIZACION_FALLO_EN_TURBO

	modificar_equilibrio(-penalizacion)

	reiniciar_combo()

	if not turbo_activo:
		carga_turbo = clampf(
			carga_turbo - PENALIZACION_CARGA_TURBO,
			0.0,
			CARGA_TURBO_MAXIMA
		)

		turbo_cambiado.emit(carga_turbo)

	print(
		"QTE FALLADO | Equilibrio: -",
		penalizacion
	)


# Activa el Turbo cuando la barra está completa.
func activar_turbo() -> void:
	if turbo_activo:
		return

	if carga_turbo < CARGA_TURBO_MAXIMA:
		return

	turbo_activo = true
	tiempo_turbo_restante = DURACION_TURBO
	ultimo_segundo_turbo = -1

	gestor_qte.configurar_turbo(true)

	actualizar_contador_turbo()

	print("TURBO ACTIVADO")


# Actualiza los segundos restantes del Turbo.
func actualizar_contador_turbo() -> void:
	if not turbo_activo:
		return

	var segundos_visibles: int = ceili(
		tiempo_turbo_restante
	)

	if segundos_visibles != ultimo_segundo_turbo:
		ultimo_segundo_turbo = segundos_visibles

		hud.mostrar_turbo_activo(
			segundos_visibles
		)


# Desactiva el Turbo.
func desactivar_turbo() -> void:
	if not turbo_activo:
		return

	turbo_activo = false
	tiempo_turbo_restante = 0.0
	ultimo_segundo_turbo = -1

	carga_turbo = 0.0

	gestor_qte.configurar_turbo(false)

	turbo_cambiado.emit(carga_turbo)

	hud.mostrar_turbo_finalizado()

	print("TURBO FINALIZADO")


# Modifica el equilibrio.
func modificar_equilibrio(cantidad: float) -> void:
	equilibrio_actual = clampf(
		equilibrio_actual + cantidad,
		0.0,
		configuracion.equilibrio_maximo
	)

	equilibrio_cambiado.emit(
		equilibrio_actual
	)

	if equilibrio_actual <= 0.0 and partida_activa:
		terminar_partida()


# Finaliza la partida y reproduce la caída.
func terminar_partida() -> void:
	if not partida_activa:
		return

	partida_activa = false

	gestor_qte.detener()
	qte_prompt.ocultar_qte()

	# Cancela cualquier compensación pendiente.
	qte_direccion_activo = false
	esperando_aviso_compensacion = false
	temporizador_qte.paused = false

	animacion_jinete_temporal = false
	tiempo_retorno_jinete = 0.0

	# Detiene el rebote.
	if tween_rebote != null:
		if tween_rebote.is_running():
			tween_rebote.kill()

	jinete.position = posicion_original_jinete
	jinete.rotation = rotacion_original_jinete
	visual_jinete.rotation = rotacion_original_visual

	# Restablece la cámara.
	if camara != null:
		if tween_camara != null:
			if tween_camara.is_running():
				tween_camara.kill()

		camara.offset = posicion_original_camara

	# Guarda el récord.
	GameState.guardar_record(
		puntuacion_actual
	)

	# Guarda el tiempo final.
	GameState.guardar_tiempo_final(
		int(tiempo_partida)
	)

	print(
		"Puntuación final: ",
		puntuacion_actual
	)

	print(
		"Récord actual: ",
		GameState.puntuacion_record
	)

	equilibrio_agotado.emit()

	hud.actualizar_equilibrio(0.0)

	# Ejecuta la caída.
	jinete.caer()

	await jinete.caida_terminada

	get_tree().change_scene_to_file(
		"res://Scenes/ui/fin_juego.tscn"
	)
