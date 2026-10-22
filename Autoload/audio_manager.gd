extends Node

# Administrador global de música y efectos de sonido.

# Reproductor principal de música.
var reproductor_musica: AudioStreamPlayer

# Reproductores independientes para efectos.
var reproductores_efectos: Array[AudioStreamPlayer] = []

# Cantidad máxima de efectos simultáneos.
const MAX_EFECTOS_SIMULTANEOS: int = 8


func _ready() -> void:
	# Crear el reproductor de música.
	reproductor_musica = AudioStreamPlayer.new()
	reproductor_musica.name = "ReproductorMusica"
	add_child(reproductor_musica)

	# Crear reproductores independientes para efectos.
	for i in range(MAX_EFECTOS_SIMULTANEOS):
		var reproductor: AudioStreamPlayer = AudioStreamPlayer.new()
		reproductor.name = "ReproductorEfecto" + str(i + 1)

		add_child(reproductor)
		reproductores_efectos.append(reproductor)


# Reproduce una pista musical.
func reproducir_musica(audio: AudioStream) -> void:
	if audio == null:
		return

	# Evita reiniciar la misma música si ya está sonando.
	if reproductor_musica.stream == audio and reproductor_musica.playing:
		return

	reproductor_musica.stream = audio
	reproductor_musica.play()


# Detiene la música.
func detener_musica() -> void:
	reproductor_musica.stop()


# Reproduce un efecto sin interrumpir los demás.
func reproducir_efecto(audio: AudioStream) -> void:
	if audio == null:
		return

	for reproductor in reproductores_efectos:
		if not reproductor.playing:
			reproductor.stream = audio
			reproductor.play()
			return

	# Si todos los reproductores están ocupados,
	# no interrumpe ningún sonido activo.
	print("AudioManager: límite de efectos simultáneos alcanzado.")


# Ajusta la velocidad de reproducción de la música.
func ajustar_velocidad_musica(velocidad: float) -> void:
	reproductor_musica.pitch_scale = maxf(velocidad, 0.01)


# Detiene todos los efectos de sonido.
func detener_efectos() -> void:
	for reproductor in reproductores_efectos:
		reproductor.stop()


# Detiene toda la reproducción de audio.
func detener_todo() -> void:
	detener_musica()
	detener_efectos()
