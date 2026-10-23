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
@onready var gestor_qte: Node = $GestorQTE
@onready var qte_prompt: Control = $HUB/QTEPrompt
@onready var temporizador_qte: Timer = $GestorQTE/TemporizadorQTE

# Reproductores de sonido.
@onready var sonido_qte_correcto: AudioStreamPlayer = $SonidoQTECorrecto
@onready var sonido_qte_fallido: AudioStreamPlayer = $SonidoQTEFallido

# Rectángulos utilizados para los destellos visuales.
@onready var efecto_acierto: ColorRect = $HUB/EfectoAcierto
@onready var efecto_fallo: ColorRect = $HUB/EfectoFallo

# Cámara del escenario. Se busca sin exigir una ruta específica.
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

# Variables para las animaciones independientes del jinete.
var tiempo_retorno_jinete: float = 0.0
var animacion_jinete_temporal: bool = false

# Tweens utilizados para los efectos visuales.
var tween_efecto_acierto: Tween
var tween_efecto_fallo: Tween
var tween_rebote: Tween
var tween_camara: Tween

# Posiciones originales de los elementos animados.
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


# Busca una cámara dentro de la escena del juego.
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


# Inicializa las variables, señales y efectos visuales.
func _ready() -> void:
	if configuracion == null:
		push_error("Falta asignar la configuración del equilibrio.")
		return

	randomize()

	# Obtiene el equilibrio inicial desde el Resource.
	equilibrio_actual = configuracion.equilibrio_inicial

	# Guarda las posiciones originales de los elementos.
	posicion_original_jinete = jinete.position

	if camara != null:
		posicion_original_camara = camara.offset

	# Oculta los efectos al comenzar la partida.
	efecto_acierto.visible = false
	efecto_fallo.visible = false

	efecto_acierto.modulate.a = 0.0
	efecto_fallo.modulate.a = 0.0

	# Evita que los destellos bloqueen los controles táctiles.
	efecto_acierto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	efecto_fallo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Conecta las señales con el HUD.
	equilibrio_cambiado.connect(hud.actualizar_equilibrio)
	nivel_furia_cambiado.connect(hud.actualizar_nivel_furia)
	combo_cambiado.connect(hud.actualizar_combo)
	puntuacion_cambiada.connect(hud.actualizar_puntuacion)
	tiempo_cambiado.connect(hud.actualizar_tiempo)
	turbo_cambiado.connect(hud.actualizar_turbo)

	# Comunica el nivel de furia al toro.
	nivel_furia_cambiado.connect(toro.actualizar_nivel_furia)

	# Conecta los eventos del gestor QTE.
	gestor_qte.qte_iniciado.connect(_on_qte_iniciado)
	gestor_qte.qte_acertado.connect(_on_qte_acertado)
	gestor_qte.qte_perfecto.connect(_on_qte_perfecto)
	gestor_qte.qte_fallado.connect(_on_qte_fallado)
	gestor_qte.progreso_machacar.connect(_on_progreso_machacar)

	# Configura la dificultad inicial.
	configurar_dificultad_furia()

	# Inicia al jinete en reposo.
	jinete.reposo()

	# Envía los valores iniciales al HUD.
	equilibrio_cambiado.emit(equilibrio_actual)
	nivel_furia_cambiado.emit(nivel_furia)
	combo_cambiado.emit(combo_actual)
	puntuacion_cambiada.emit(puntuacion_actual)
	tiempo_cambiado.emit(0)
	turbo_cambiado.emit(carga_turbo)


# Actualiza las mecánicas principales del juego.
func _process(delta: float) -> void:
	if configuracion == null or not partida_activa:
		return

	# Actualiza el movimiento independiente del jinete.
	actualizar_animacion_jinete(delta)

	# Controla la duración del Turbo.
	if turbo_activo:
		tiempo_turbo_restante -= delta

		if tiempo_turbo_restante <= 0.0:
			desactivar_turbo()
		else:
			actualizar_contador_turbo()

	# Actualiza la dificultad y la puntuación.
	actualizar_furia(delta)
	actualizar_puntuacion_tiempo()

	# Reduce el equilibrio cuando el Turbo no está activo.
	if not turbo_activo:
		modificar_equilibrio(
			-configuracion.perdida_por_segundo * delta
		)

	if not partida_activa:
		return

	# Actualiza el tiempo disponible del QTE.
	if gestor_qte.qte_activo:
		qte_prompt.actualizar_tiempo(
			temporizador_qte.time_left,
			temporizador_qte.wait_time
		)
	else:
		# Controla el intervalo antes del siguiente QTE.
		tiempo_entre_qte += delta

		if tiempo_entre_qte >= obtener_intervalo_qte():
			iniciar_qte()


# Muestra un destello verde al acertar un QTE.
func mostrar_efecto_acierto() -> void:
	if tween_efecto_acierto != null:
		if tween_efecto_acierto.is_running():
			tween_efecto_acierto.kill()

	# Activa el rectángulo verde.
	efecto_acierto.visible = true
	efecto_acierto.modulate.a = INTENSIDAD_DESTELLO

	# Reduce progresivamente la transparencia.
	tween_efecto_acierto = create_tween()

	tween_efecto_acierto.tween_property(
		efecto_acierto,
		"modulate:a",
		0.0,
		DURACION_DESTELLO
	)

	# Oculta el rectángulo cuando termina el destello.
	tween_efecto_acierto.tween_callback(
		func() -> void:
			efecto_acierto.visible = false
	)


# Muestra un destello rojo al fallar un QTE.
func mostrar_efecto_fallo() -> void:
	if tween_efecto_fallo != null:
		if tween_efecto_fallo.is_running():
			tween_efecto_fallo.kill()

	# Activa el rectángulo rojo.
	efecto_fallo.visible = true
	efecto_fallo.modulate.a = INTENSIDAD_DESTELLO

	# Reduce progresivamente la transparencia.
	tween_efecto_fallo = create_tween()

	tween_efecto_fallo.tween_property(
		efecto_fallo,
		"modulate:a",
		0.0,
		DURACION_DESTELLO
	)

	# Oculta el rectángulo al terminar.
	tween_efecto_fallo.tween_callback(
		func() -> void:
			efecto_fallo.visible = false
	)


# Produce un pequeño rebote del jinete al acertar.
func aplicar_rebote_jinete() -> void:
	if not partida_activa:
		return

	# Detiene el rebote anterior para evitar acumulaciones.
	if tween_rebote != null:
		if tween_rebote.is_running():
			tween_rebote.kill()

	# Guarda la posición actual antes de iniciar el rebote.
	var posicion_base: Vector2 = posicion_original_jinete

	# Restablece la posición para evitar desplazamientos acumulados.
	jinete.position = posicion_base

	# Crea una animación de subida y bajada.
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


# Sacude brevemente la cámara cuando el jugador falla.
func aplicar_sacudida_camara() -> void:
	if camara == null:
		return

	# Detiene una sacudida anterior si todavía está activa.
	if tween_camara != null:
		if tween_camara.is_running():
			tween_camara.kill()

	# Devuelve la cámara a su posición original.
	camara.offset = posicion_original_camara

	# Crea una secuencia de pequeños desplazamientos.
	tween_camara = create_tween()

	var cantidad_movimientos: int = maxi(
		int(DURACION_SACUDIDA / INTERVALO_SACUDIDA),
		1
	)

	for i in range(cantidad_movimientos):
		# La intensidad disminuye progresivamente.
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

	# Devuelve la cámara a su posición original.
	tween_camara.tween_property(
		camara,
		"offset",
		posicion_original_camara,
		INTERVALO_SACUDIDA
	)


# Activa la inclinación izquierda del jinete.
func animar_jinete_izquierda() -> void:
	if not partida_activa:
		return

	jinete.inclinar_izquierda()

	animacion_jinete_temporal = true
	tiempo_retorno_jinete = DURACION_INCLINACION_JINETE


# Activa la inclinación derecha del jinete.
func animar_jinete_derecha() -> void:
	if not partida_activa:
		return

	jinete.inclinar_derecha()

	animacion_jinete_temporal = true
	tiempo_retorno_jinete = DURACION_INCLINACION_JINETE


# Devuelve al jinete a su animación de reposo.
func animar_jinete_reposo() -> void:
	if not partida_activa:
		return

	animacion_jinete_temporal = false
	tiempo_retorno_jinete = 0.0

	jinete.reposo()


# Controla la duración de las inclinaciones del jinete.
func actualizar_animacion_jinete(delta: float) -> void:
	if not animacion_jinete_temporal:
		return

	tiempo_retorno_jinete -= delta

	if tiempo_retorno_jinete <= 0.0:
		animar_jinete_reposo()


# Selecciona la animación del jinete según la dirección.
func procesar_movimiento_jinete(accion: String) -> void:
	match accion:
		"qte_izq":
			animar_jinete_izquierda()

		"qte_derecha":
			animar_jinete_derecha()

		"qte_arriba":
			animar_jinete_reposo()

		"qte_abajo":
			animar_jinete_reposo()


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


# Devuelve el multiplicador de puntuación.
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


# Reinicia el combo después de un fallo.
func reiniciar_combo() -> void:
	combo_actual = 0

	combo_cambiado.emit(combo_actual)

	print("Combo reiniciado")


# Calcula el intervalo entre QTE.
func obtener_intervalo_qte() -> float:
	if turbo_activo:
		return intervalo_qte / MULTIPLICADOR_FRECUENCIA_TURBO

	return intervalo_qte


# Inicia un QTE aleatorio según el nivel de furia.
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

	# Activa el Turbo mediante Shift.
	if event.is_action_pressed("activar_turbo") and not event.is_echo():
		activar_turbo()
		return

	if not gestor_qte.qte_activo:
		return

	# Gestiona el QTE de mantener presionado.
	if gestor_qte.qte_mantener:
		if event.is_action_pressed("accion") and not event.is_echo():
			gestor_qte.comenzar_mantener()

		elif event.is_action_released("accion"):
			gestor_qte.soltar_mantener()

		return

	# Gestiona el QTE de pulsaciones repetidas.
	if gestor_qte.qte_machacar:
		if event.is_action_pressed("accion") and not event.is_echo():
			gestor_qte.registrar_pulsacion()

		return

	# Procesa las acciones direccionales.
	# Cada acción reconoce WASD y las flechas.
	var acciones: Array[String] = [
		"qte_izq",
		"qte_derecha",
		"qte_arriba",
		"qte_abajo"
	]

	for accion in acciones:
		if event.is_action_pressed(accion) and not event.is_echo():
			procesar_movimiento_jinete(accion)

			if gestor_qte.qte_secuencia:
				gestor_qte.comprobar_secuencia(accion)
			else:
				gestor_qte.comprobar_respuesta(accion)

			return


# Muestra las instrucciones del QTE.
func _on_qte_iniciado(
	_accion: String,
	tecla: String,
	es_direccion: bool
) -> void:
	qte_prompt.mostrar_qte(tecla, es_direccion)


# Actualiza el progreso del QTE de pulsaciones repetidas.
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
	qte_prompt.mostrar_resultado(true)

	sonido_qte_correcto.play()

	# Muestra el destello verde.
	mostrar_efecto_acierto()

	# Produce el pequeño rebote del jinete.
	aplicar_rebote_jinete()

	# Recupera equilibrio y aumenta el combo.
	modificar_equilibrio(
		configuracion.recuperacion_qte
	)

	aumentar_combo()


# Procesa un QTE PERFECTO.
func _on_qte_perfecto() -> void:
	qte_prompt.mostrar_resultado(true, true)

	sonido_qte_correcto.play()

	# Muestra el destello verde.
	mostrar_efecto_acierto()

	# Produce el pequeño rebote del jinete.
	aplicar_rebote_jinete()

	# Recupera equilibrio y aumenta el combo.
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
	qte_prompt.mostrar_resultado(false)

	sonido_qte_fallido.play()

	# Muestra el destello rojo.
	mostrar_efecto_fallo()

	# Sacude la cámara brevemente.
	aplicar_sacudida_camara()

	# Determina la penalización de equilibrio.
	var penalizacion: float = (
		configuracion.penalizacion_fallo
	)

	if turbo_activo:
		penalizacion = PENALIZACION_FALLO_EN_TURBO

	# Reduce el equilibrio y reinicia el combo.
	modificar_equilibrio(-penalizacion)

	reiniciar_combo()

	# Reduce la carga del Turbo cuando no está activo.
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

	# Aplica la reducción del tiempo de respuesta.
	gestor_qte.configurar_turbo(true)

	# Muestra el contador del Turbo.
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


# Desactiva el Turbo y restablece los valores normales.
func desactivar_turbo() -> void:
	if not turbo_activo:
		return

	turbo_activo = false
	tiempo_turbo_restante = 0.0
	ultimo_segundo_turbo = -1

	# Vacía la barra de Turbo.
	carga_turbo = 0.0

	# Restaura los tiempos normales de respuesta.
	gestor_qte.configurar_turbo(false)

	turbo_cambiado.emit(carga_turbo)

	hud.mostrar_turbo_finalizado()

	print("TURBO FINALIZADO")


# Modifica el equilibrio y comprueba si termina la partida.
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


# Finaliza la partida y reproduce la caída del jinete.
func terminar_partida() -> void:
	if not partida_activa:
		return

	partida_activa = false

	# Detiene los QTE y oculta sus indicaciones.
	gestor_qte.detener()
	qte_prompt.ocultar_qte()

	# Detiene las animaciones temporales del jinete.
	animacion_jinete_temporal = false
	tiempo_retorno_jinete = 0.0

	# Detiene el rebote para no interferir con la caída.
	if tween_rebote != null:
		if tween_rebote.is_running():
			tween_rebote.kill()

	jinete.position = posicion_original_jinete

	# Detiene la sacudida y restablece la cámara.
	if camara != null:
		if tween_camara != null:
			if tween_camara.is_running():
				tween_camara.kill()

		camara.offset = posicion_original_camara

	# Guarda la puntuación y actualiza el récord.
	GameState.guardar_record(
		puntuacion_actual
	)

	# Guarda el tiempo sobrevivido.
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

	# Reproduce la animación de caída.
	jinete.caer()

	# Espera a que termine la caída.
	await jinete.caida_terminada

	# Cambia a la pantalla Game Over.
	get_tree().change_scene_to_file(
		"res://Scenes/ui/fin_juego.tscn"
	)
