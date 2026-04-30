extends Node
signal seleccion_enemigo()
signal seleccion_aliado()
signal ataque_iniciado()
signal ocultar_indicadores_aliados()


var turno_jugador : bool = true
var puede_abrir_menu : bool = true

var gato_equipo
var gato_objetivo

# para ir cambiando entre el turno del jugador y la ia
func cambio_turnos():
	turno_jugador = !turno_jugador


func mostrar_selec_gato_enemigo():
	puede_abrir_menu = false
	emit_signal("seleccion_enemigo")

func mostrar_selec_gato_equipo():
	puede_abrir_menu = true
	emit_signal("seleccion_aliado")

func seleccion_gato_equipo(gato):
	emit_signal("ocultar_indicadores_aliados")
	gato_equipo = gato
	gato.mostrar_aliado_seleccionado()

func seleccion_gato_enemigo(gato):
	gato_objetivo = gato

func iniciar_ataque():
	emit_signal("ataque_iniciado")
	emit_signal("ocultar_indicadores_aliados")
	gato_equipo.atacar_enemigo(gato_objetivo)
