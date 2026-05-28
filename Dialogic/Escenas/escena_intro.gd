extends Node2D

func _ready() -> void:
	# 1. Conectamos la señal para saber cuándo termina la conversación
	Dialogic.timeline_ended.connect(_al_terminar_timeline)
	
	# 2. Iniciamos la introducción inmediatamente al cargar la escena
	# Reemplaza "intro_juego" por el nombre exacto de tu Timeline
	Dialogic.start("Intro")

func _al_terminar_timeline():
	# 3. Desconectamos la señal por seguridad
	Dialogic.timeline_ended.disconnect(_al_terminar_timeline)
	
	# 4. Ahora sí, cambiamos la escena por completo hacia la batalla de garras
	get_tree().change_scene_to_file("res://Objetos/Mundo/mundo_demo.tscn")
