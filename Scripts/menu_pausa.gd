extends Control

const RUTA_MENU_PRINCIPAL: String = "res://Scenes/ui/menu_principal.tscn"

@onready var boton_continuar: Button = $BotonContinuar
@onready var boton_menu_principal: Button = $BotonMenuPrincipal
@onready var boton_pausa: Button = $"../BotonPausa"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	boton_continuar.pressed.connect(continuar_partida)
	boton_menu_principal.pressed.connect(regresar_menu_principal)
	boton_pausa.pressed.connect(pausar_partida)

	hide()


# Detecta la tecla ESC.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			if get_tree().paused:
				continuar_partida()
			else:
				pausar_partida()

			get_viewport().set_input_as_handled()


# Pausa la partida.
func pausar_partida() -> void:
	boton_pausa.hide()
	show()
	get_tree().paused = true


# Continúa la partida.
func continuar_partida() -> void:
	get_tree().paused = false
	hide()
	boton_pausa.show()


# Regresa al menú principal.
func regresar_menu_principal() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(RUTA_MENU_PRINCIPAL)
