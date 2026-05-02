extends Node

signal salud_cero()

@export var progress_bar: ProgressBar

var salud_maxima : float
var salud_actual : float

func recibir_danio(cantidad: float):
	salud_actual = salud_actual - cantidad
	
	print("Daño recibido: ", cantidad)
	update_progress_bar()
	
	if (salud_actual <=0):
		emit_signal("salud_cero")


func update_progress_bar():
	if progress_bar:
		progress_bar.value = salud_actual/salud_maxima
