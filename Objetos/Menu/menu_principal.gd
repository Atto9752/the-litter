extends Control


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Objetos/Mundo/mundo_demo.tscn") 


func _on_button_3_pressed() -> void:
	get_tree().quit() 
