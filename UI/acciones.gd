extends Control

func _ready():
	cerrar_menu()

func abrir_menu():
	visible = true

func cerrar_menu():
	visible = false

func _on_boton_atacar_button_down() -> void:
	cerrar_menu()
	Manager.mostrar_selec_gato_enemigo()
	print("ATACAR")

func _on_boton_defender_button_down() -> void:
	cerrar_menu()
	print("DEFENDER")

func _on_boton_grunido_button_down() -> void:
	cerrar_menu()
	print("GRUÑIDO")

func _on_boton_bufido_button_down() -> void:
	cerrar_menu()
	print("BUFIDO")

func _on_boton_cerrar_button_down() -> void:
	cerrar_menu()
