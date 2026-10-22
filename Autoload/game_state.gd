extends Node

# Archivo donde se guarda el récord.
const RUTA_RECORD: String = "user://record.dat"

# Puntuaciones.
var puntuacion_record: int = 0
var puntuacion_final: int = 0

# Tiempo sobrevivido durante la última partida.
var tiempo_final: int = 0


# Carga el récord al iniciar.
func _ready() -> void:
	cargar_record()


# Recupera el récord guardado.
func cargar_record() -> void:
	if not FileAccess.file_exists(RUTA_RECORD):
		puntuacion_record = 0
		return

	var archivo: FileAccess = FileAccess.open(
		RUTA_RECORD, FileAccess.READ
	)

	if archivo == null:
		push_warning("No se pudo leer el récord.")
		return

	puntuacion_record = maxi(archivo.get_32(), 0)
	archivo.close()


# Guarda la puntuación final y actualiza el récord.
func guardar_record(puntuacion: int) -> void:
	puntuacion_final = puntuacion

	if puntuacion <= puntuacion_record:
		return

	var archivo: FileAccess = FileAccess.open(
		RUTA_RECORD, FileAccess.WRITE
	)

	if archivo == null:
		push_error("No se pudo guardar el récord.")
		return

	archivo.store_32(puntuacion)
	archivo.close()

	puntuacion_record = puntuacion
	print("Nuevo récord: ", puntuacion_record)


# Guarda el tiempo sobrevivido durante la partida.
func guardar_tiempo_final(segundos: int) -> void:
	tiempo_final = maxi(segundos, 0)
