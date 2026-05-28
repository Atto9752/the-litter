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
var seleccionando_objetivo : bool = false

# nuevas variables para turnos tipo rpg x turnos clasico
var acciones_planificadas : Array = [] # guarda diccionarios con {gato_origen, tipo_accion, gato_objetivo} etc
var aliados_que_ya_eligieron : Array = []
var ejecutando_acciones_en_cadena : bool = false


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
			i.actualizar_defensa_actual()
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
	seleccionando_objetivo = true
	emit_signal("seleccion_enemigo")
	
	if enemigos.size() > 0:
		enemigos[0].get_node("Panel").grab_focus() # para que el menu se abra con el primer enemigo seleccionado

func mostrar_selec_gato_equipo():
	puede_abrir_menu = true
	emit_signal("seleccion_aliado")

func seleccion_gato_equipo(gato):
	if ejecutando_acciones_en_cadena: return
	
	if aliados_que_ya_eligieron.has(gato): 
		print("Este gato ya tiene un comando asignado para este turno.")
		return
	
	emit_signal("ocultar_indicadores_aliados")
	gato_equipo = gato
	gato.mostrar_aliado_seleccionado()

func seleccion_gato_enemigo(gato):
	gato_objetivo = gato


func iniciar_ataque():
	seleccionando_objetivo = false
	emit_signal("ataque_iniciado")
	emit_signal("ocultar_indicadores_aliados")
	
	# guardamos los datos de la accion del aliado actual
	var nueva_accion = {
		"origen": gato_equipo,
		"tipo": tipo_accion,
		"objetivo": gato_objetivo
	}
	
	acciones_planificadas.append(nueva_accion)
	aliados_que_ya_eligieron.append(gato_equipo)
	
	gato_equipo = null
	
	evaluar_siguiente_paso_jugador()


# ejecuta de forma asincrona una accion tras otra
func ejecutar_acciones_acumuladas():
	ejecutando_acciones_en_cadena = true
	puede_abrir_menu = false
	
	for accion in acciones_planificadas:
		var gato = accion["origen"]
		
		if not is_instance_valid(gato) or gato.componente_salud.sin_salud: 
			continue # Si el gato murio antes de su turno en la cola, saltar
		
		if accion["tipo"] == "attack":
			gato.atacar_enemigo(accion["objetivo"])
			await gato.accion_terminada # espera q el atacante vaya y vuelva
		elif accion["tipo"] == "grunido":
			gato.usar_grunido(accion["objetivo"])
			await gato.accion_terminada
		elif accion["tipo"] == "bufido":
			gato.usar_bufido(accion["objetivo"])
			await gato.accion_terminada
		elif accion["tipo"] == "defender":
			gato.defenderse()
			# la defensa es instantanea, no requiere acercarse a un enemigo
			await get_tree().create_timer(0.5).timeout
	
	
	# limpiar datos del turno actual del jugador
	acciones_planificadas.clear()
	aliados_que_ya_eligieron.clear()
	ejecutando_acciones_en_cadena = false
	
	# pasamos al turno de la ia
	turno_jugador = false
	iniciar_turno_enemigo()


# verifica si faltan aliados por elegir comando o si se ejecutan todos
func evaluar_siguiente_paso_jugador():
	# filtrar aliados vivos x si alguno muirio
	var aliados_vivos = aliados.filter(func(g): return !g.componente_salud.sin_salud)
	
	if aliados_que_ya_eligieron.size() >= aliados_vivos.size():
		# todos los gatos del jugador eligieron, se inicia la cadena de acciones
		ejecutar_acciones_acumuladas()
	else:
		# para dejar q el jugador seleccione a otro gato que no haya elegido aun
		puede_abrir_menu = true
		for aliado in aliados_vivos:
			if not aliado in aliados_que_ya_eligieron:
				gato_equipo = aliado
				aliado.get_node("Panel").grab_focus()
				break



func defender_gato():
	gato_equipo.defenderse()
	
	var nueva_accion = {
		"origen": gato_equipo,
		"tipo": "defender",
		"objetivo": null
	}
	
	acciones_planificadas.append(nueva_accion)
	aliados_que_ya_eligieron.append(gato_equipo)
	
	gato_equipo = null
	evaluar_siguiente_paso_jugador()


func iniciar_turno_enemigo():
	
	if turno_enemigo >= enemigos.size():
		turno_enemigo=0
	elif enemigos.is_empty() or aliados.is_empty(): return # por seguridad
	
	var enemigo_actual = enemigos[turno_enemigo]
	enemigo_actual.actualizar_defensa_actual()
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
