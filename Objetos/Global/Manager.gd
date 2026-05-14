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
var aliados = []
var turno_enemigo : int = 0

var batalla_finalizada : bool = false


func registrar_gato(gato):
	if gato.data.jugador:
		aliados.append(gato)
	else:
		enemigos.append(gato)


func obtener_personajes():
	enemigos = get_tree().get_nodes_in_group("Enemigos")
	aliados = get_tree().get_nodes_in_group("Aliados")
	
	if enemigos.size() == 0:
		print("¡Has ganado!")
		batalla_finalizada = true
	elif aliados.size() == 0:
		print("Has perdido")
		batalla_finalizada = true


# para ir cambiando entre el turno del jugador y la ia
func cambiar_turno():
	turno_jugador = !turno_jugador
	
	if turno_jugador:
		puede_abrir_menu = true
		print("Turno del jugador")
		# para quitar la defensa luego del turno del enemigo
		for i in aliados:
			i.quitar_defensa()
	else:
		puede_abrir_menu = false
		await get_tree().create_timer(1.5).timeout # pequeña pausa
		if batalla_finalizada: return
		print("Turno del enemigo")
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
	puede_abrir_menu = false
	gato_equipo.atacar_enemigo(gato_objetivo)


func defender_gato():
	gato_equipo.defenderse()


func iniciar_turno_enemigo():
	
	if turno_enemigo >= enemigos.size():
		turno_enemigo=0
	
	if enemigos.is_empty() or aliados.is_empty(): return # por seguridad
	
	var enemigo_actual = enemigos[turno_enemigo]
	var objetivo = aliados.pick_random()
	
	# para que el ataque sea mas frecuente que la defensa
	if (randf_range(0,100) < 0.75):
		# atacar
		seleccion_gato_equipo(enemigo_actual)
		seleccion_gato_enemigo(objetivo)
		iniciar_ataque()
		
	else:
		# defender
		seleccion_gato_equipo(enemigo_actual)
		defender_gato()
	
	turno_enemigo = turno_enemigo+1
