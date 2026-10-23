extends Node2D

signal caida_terminada

@onready var anim_reposo: AnimationPlayer = $reposo
@onready var anim_izquierda: AnimationPlayer = $"inclinacion izq"
@onready var anim_derecha: AnimationPlayer = $"inclinacion der"
@onready var anim_caida: AnimationPlayer = $Caida

# Indica si el jinete ya se separó del toro.
var jinete_desmontado: bool = false


# Detiene las animaciones para evitar problemas.
func detener_animaciones() -> void:
	anim_reposo.stop()
	anim_izquierda.stop()
	anim_derecha.stop()
	anim_caida.stop()


# Coloca al jinete en su posición normal.
func reposo() -> void:
	if jinete_desmontado:
		return

	detener_animaciones()
	anim_reposo.play("Reposo")


# Inclina al jinete hacia la izquierda.
func inclinar_izquierda() -> void:
	if jinete_desmontado:
		return

	detener_animaciones()
	anim_izquierda.play("inclinacion_izq")


# Inclina al jinete hacia la derecha.
func inclinar_derecha() -> void:
	if jinete_desmontado:
		return

	detener_animaciones()
	anim_derecha.play("inclinacion_derecha")


# Reproduce la caída del jinete.
func caer() -> void:
	if jinete_desmontado:
		return

	jinete_desmontado = true

	# Detiene las animaciones anteriores.
	detener_animaciones()

	# Separa al jinete del movimiento del toro.
	# Conserva su posición global al cambiar de padre.
	var escenario: Node = get_tree().current_scene.get_node("escenario")

	reparent(escenario, true)

	# Reproduce la animación de caída existente.
	anim_caida.play("caida")


# Avisa cuando termina la animación de caída.
func _on_caida_terminada(nombre: StringName) -> void:
	if nombre == &"caida":
		# Mantiene al jinete en la posición final.
		anim_caida.pause()

		caida_terminada.emit()


# Conecta la señal de caída.
func _ready() -> void:
	anim_caida.animation_finished.connect(_on_caida_terminada)


func _on_juego_equilibrio_agotado() -> void:
	pass # Replace with function body.
