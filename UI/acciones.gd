extends Control

func _ready():
	cerrar_menu()

func abrir_menu():
	for i in get_tree().get_nodes_in_group("Aliados"):
		i.get_node("Acciones").cerrar_menu()
	visible = true

	$PanelContainer/MarginContainer/VBoxContainer/boton_atacar.grab_focus() # para que el menu se abra con el primer botón seleccionado

func cerrar_menu():
	visible = false
	

func _on_boton_atacar_button_down() -> void:
	cerrar_menu()
	Manager.tipo_accion = "attack"
	Manager.mostrar_selec_gato_enemigo()
	print("ATACAR")

func _on_boton_defender_button_down() -> void:
	cerrar_menu()
	Manager.defender_gato()
	print("DEFENDER")

func _on_boton_grunido_button_down() -> void:
	cerrar_menu()
	Manager.tipo_accion = "grunido"
	Manager.mostrar_selec_gato_enemigo()
	print("GRUÑIDO")

func _on_boton_bufido_button_down() -> void:
	cerrar_menu()
	print("BUFIDO")

func _on_boton_cerrar_button_down() -> void:
	cerrar_menu()
	Manager.emit_signal("ocultar_indicadores_aliados")
