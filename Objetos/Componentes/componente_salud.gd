extends Node

signal salud_cero()
signal danio_recibido()

@export var progress_bar: ProgressBar

var salud_maxima : float
var salud_actual : float
var sin_salud : bool = false

var defensa : float


func recibir_danio(cantidad: float, prob: float, aumento: float, evasion_gato: float = 0.0):
	if sin_salud: return
	
	# dado de probabilidad para la evasion antes de procesar daño
	if randf_range(0.0, 1.0) <= evasion_gato:
		print("¡El ataque ha sido EVADIDO!")
		# AÑADIR A FUTURO: aqui se podria disparar una señal para mostrar un texto flotante de "Miss" o "Evadido"
		return
	
	
	salud_actual -= calcular_danio(cantidad, prob, aumento)
	salud_actual = clamp(salud_actual, 0 , salud_maxima) # para evitar salud negativa
	
	update_progress_bar()
	
	if salud_actual <= 0:
		salud_cero.emit()  # = emit_signal("salud_cero")
		sin_salud = true
	else:
		danio_recibido.emit()


func calcular_danio(cantidad: float, prob: float, aumento: float) -> float:
	var resultado = cantidad
	# Calcular el daño
	if (randf_range(0,1)) <= prob:
		resultado = cantidad*aumento
		
	# Calcular defensa
	resultado = resultado * defensa
	
	return resultado


func update_progress_bar():
	if progress_bar:
		progress_bar.value = salud_actual/salud_maxima
