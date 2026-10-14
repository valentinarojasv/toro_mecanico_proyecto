extends CanvasLayer

# Referencia a la barra de equilibrio.
@onready var barra_equilibrio: ProgressBar = $barraequilibrio

# Referencia al indicador QTE.
@onready var indicador_qte: Label = $IndicadorQTE


# Prepara el HUD al iniciar el juego.
func _ready() -> void:
	barra_equilibrio.min_value = 0.0
	barra_equilibrio.max_value = 100.0
	barra_equilibrio.value = 100.0

	indicador_qte.hide()


# Actualiza la barra con el equilibrio del jinete.
func actualizar_equilibrio(valor: float) -> void:
	barra_equilibrio.value = valor


# Muestra la tecla que debe presionar el jugador.
func mostrar_qte(tecla: String) -> void:
	indicador_qte.text = "PRESIONA " + tecla
	indicador_qte.show()


# Oculta el indicador cuando termina el QTE.
func ocultar_qte() -> void:
	indicador_qte.hide()


# Recibe la señal de equilibrio enviada por Juego.
func _on_juego_equilibrio_cambiado(valor: float) -> void:
	actualizar_equilibrio(valor)
