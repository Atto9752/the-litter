extends Control


func _ready() -> void:
	$Button.grab_focus()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Dialogic/Escenas/escena_intro.tscn") 

# salir del juego
func _on_button_3_pressed() -> void:
	get_tree().quit() 
