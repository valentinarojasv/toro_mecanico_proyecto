extends Node2D
signal caida_terminada

@onready var anim_reposo: AnimationPlayer = $reposo
@onready var anim_izquierda: AnimationPlayer = $"inclinacion izq"
@onready var anim_derecha: AnimationPlayer = $"inclinacion der"
@onready var anim_caida: AnimationPlayer = $Caida

# Detiene las animaciones para evitar problemas
func detener_animaciones() -> void:
	anim_reposo.stop()
	anim_izquierda.stop()
	anim_derecha.stop()
	anim_caida.stop()


# Coloca al jinete en su posición normal.
func reposo() -> void:
	detener_animaciones()
	anim_reposo.play("Reposo")

# Inclina al jinete hacia la izquierda.
func inclinar_izquierda() -> void:
	detener_animaciones()
	anim_izquierda.play("inclinacion_izq")


# Inclina al jinete hacia la derecha.
func inclinar_derecha() -> void:
	detener_animaciones()
	anim_derecha.play("inclinacion_derecha")


# Reproduce la caída del jinete.
func caer() -> void:
	detener_animaciones()
	anim_caida.play("caida")


# Avisa cuando termina la animación de caída.
func _on_caida_terminada(nombre: StringName) -> void:
	if nombre == &"caida":
		caida_terminada.emit()


# Conecta la señal de caída.
func _ready() -> void:
	anim_caida.animation_finished.connect(_on_caida_terminada)
