extends Node
signal seleccion_enemigo()
signal seleccion_aliado()
signal ataque_iniciado()
signal ocultar_indicadores_aliados()

var turno_jugador : bool = true
var puede_abrir_menu : bool = true

var gato_equipo
var gato_objetivo

var enemigos = []
var jugadores = []
var turno_enemigo : int = 0

func _ready():
	enemigos = get_tree().get_nodes_in_group("Enemigos")
	jugadores = get_tree().get_nodes_in_group("Jugadores")

# para ir cambiando entre el turno del jugador y la ia
func cambiar_turno():
	turno_jugador = !turno_jugador
	
	if turno_jugador == false:
		iniciar_turno_enemigo()


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

func iniciar_turno_enemigo():
	var enemigo_actual = enemigos[turno_enemigo]
	seleccion_gato_equipo(enemigo_actual)
	seleccion_gato_enemigo(jugadores.pick_random())
	iniciar_ataque()
