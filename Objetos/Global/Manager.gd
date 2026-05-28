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

var tipo_accion : String = ""

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

		var carteles_victoria = get_tree().get_nodes_in_group("mensaje_victoria")
		if carteles_victoria.size() > 0:
			var cartel_animado = carteles_victoria[0]
			cartel_animado.visible = true
			cartel_animado.play("aparecer_victoria") 

	elif aliados.size() == 0:
		print("Has perdido")
		batalla_finalizada = true

		var carteles_derrota = get_tree().get_nodes_in_group("mensaje_derrota")
		if carteles_derrota.size() > 0:
			var cartel_animado = carteles_derrota[0]
			cartel_animado.visible = true
			cartel_animado.play("aparecer_derrota") 

# para ir cambiando entre el turno del jugador y la ia
func cambiar_turno():
	turno_jugador = !turno_jugador
	
	if turno_jugador:
		puede_abrir_menu = true
		print("Turno del jugador")
		# para quitar la defensa luego del turno del enemigo
		for i in aliados:
			i.quitar_defensa()
		if aliados.size() > 0:
			aliados[0].get_node("Panel").grab_focus() # para que el menu se abra con el primer gato del equipo seleccionado

	else:
		puede_abrir_menu = false
		await get_tree().create_timer(1.5).timeout # pequeña pausa
		if batalla_finalizada: return
		print("Turno del enemigo")
		iniciar_turno_enemigo()


func mostrar_selec_gato_enemigo():
	puede_abrir_menu = false
	emit_signal("seleccion_enemigo")
	
	if enemigos.size() > 0:
		enemigos[0].get_node("Panel").grab_focus() # para que el menu se abra con el primer enemigo seleccionado

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
	
	if tipo_accion == "attack":
		gato_equipo.atacar_enemigo(gato_objetivo)
		
	elif tipo_accion == "grunido":
		gato_equipo.usar_grunido(gato_objetivo)
		
	elif tipo_accion == "bufido":
		gato_equipo.usar_bufido(gato_objetivo)


func defender_gato():
	gato_equipo.defenderse()


func iniciar_turno_enemigo():
	
	if turno_enemigo >= enemigos.size():
		turno_enemigo=0
	elif enemigos.is_empty() or aliados.is_empty(): return # por seguridad
	
	var enemigo_actual = enemigos[turno_enemigo]
	enemigo_actual.quitar_defensa()
	enemigo_actual.procesar_turnos_estado()
	
	var objetivo = aliados.pick_random()
	var dado = randf_range(0, 100) # se genera un numero del 0 al 100
	seleccion_gato_equipo(enemigo_actual) # El "gato_equipo" pasa a ser el enemigo activo
	
	if dado < 65:
		# 65% de probabilidad: ATACAR
		tipo_accion = "attack"
		seleccion_gato_enemigo(objetivo)
		iniciar_ataque()
	elif dado < 80:
		# 15% de Probabilidad (De 65 a 80): DEFENDER
		defender_gato()
	elif dado < 90:
		# 10% de Probabilidad (De 80 a 90): GRUÑIDO
		tipo_accion = "grunido"
		seleccion_gato_enemigo(objetivo)
		iniciar_ataque()
	else:
		# 10% de Probabilidad (De 90 a 100): BUFIDO
		tipo_accion = "bufido"
		seleccion_gato_enemigo(objetivo)
		iniciar_ataque()
	
	turno_enemigo = turno_enemigo+1
