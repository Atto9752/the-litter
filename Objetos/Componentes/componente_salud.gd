extends Node

signal salud_cero()
signal danio_recibido()

@export var progress_bar: ProgressBar

var salud_maxima : float
var salud_actual : float
var sin_salud : bool = false

func recibir_danio(cantidad: float):
	if sin_salud: return
	
	salud_actual = salud_actual - cantidad
	salud_actual = clamp(salud_actual, 0 , salud_maxima) # para evitar salud negativa
	
	update_progress_bar()
	
	if salud_actual <= 0:
		salud_cero.emit()  # = emit_signal("salud_cero")
		sin_salud = true
	else:
		danio_recibido.emit()


func update_progress_bar():
	if progress_bar:
		progress_bar.value = salud_actual/salud_maxima
