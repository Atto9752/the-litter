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
var numero_batalla : int = 1  # Comenzamos en la Batalla 1

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
	# Filtramos usando el componente de salud para saber quiénes siguen activos físicamente
	enemigos = get_tree().get_nodes_in_group("Enemigos").filter(func(e): return !e.componente_salud.sin_salud)
	aliados = get_tree().get_nodes_in_group("Aliados").filter(func(a): return !a.componente_salud.sin_salud)
	
	# Conseguimos la lista TOTAL de nodos gato en la escena (vivos y no vivos)
	var todos_los_gatos = get_tree().get_nodes_in_group("Aliados") + get_tree().get_nodes_in_group("Enemigos")
	
	if enemigos.size() == 0:
		print("¡Has ganado!")
		batalla_finalizada = true
		puede_abrir_menu = false
		
		for gato in todos_los_gatos:
			gato.ejecutar_fin_batalla(true) # true = Ganó el jugador
		
		await get_tree().create_timer(2.5).timeout
		
		var carteles_victoria = get_tree().get_nodes_in_group("mensaje_victoria")
		
		if carteles_victoria.size() > 0:
			carteles_victoria[0].visible = true
			carteles_victoria[0].play("aparecer_victoria")
			# --- NUEVA EVALUACIÓN SEGÚN LA BATALLA ---
			if numero_batalla == 1:
				if not carteles_victoria[0].animation_finished.is_connected(_al_terminar_animacion_victoria):
					carteles_victoria[0].animation_finished.connect(_al_terminar_animacion_victoria)
			elif numero_batalla == 2:
				if not carteles_victoria[0].animation_finished.is_connected(_al_terminar_animacion_batalla_2):
					carteles_victoria[0].animation_finished.connect(_al_terminar_animacion_batalla_2)
		
		
	elif aliados.size() == 0:
		print("Has perdido")
		batalla_finalizada = true
		puede_abrir_menu = false
		
		for gato in todos_los_gatos:
			gato.ejecutar_fin_batalla(false) # false = Perdió el jugador
		
		await get_tree().create_timer(2.5).timeout
		
		var carteles_derrota = get_tree().get_nodes_in_group("mensaje_derrota")
		
		if carteles_derrota.size() > 0:
			carteles_derrota[0].visible = true
			carteles_derrota[0].play("aparecer_derrota")
			# Si quieres que al perder también pase algo en la historia, puedes conectar su señal aquí
	
	# --- CONFIGURACIÓN DINÁMICA DE VECINOS PARA EL MANDO ---
	# Si hay al menos dos enemigos vivos en la arena, los enlazamos para la cruceta
	if enemigos.size() >= 2:
		for i in range(enemigos.size()):
			var panel_actual = enemigos[i].get_node("Panel")
			
			# Calculamos quién está a la izquierda y derecha de forma circular
			var indice_izq = (i - 1 + enemigos.size()) % enemigos.size()
			var indice_der = (i + 1) % enemigos.size()
			
			var panel_izq = enemigos[indice_izq].get_node("Panel")
			var panel_der = enemigos[indice_der].get_node("Panel")
			
			# Le asignamos los vecinos del foco explícitamente para el mando
			panel_actual.focus_neighbor_left = panel_izq.get_path()
			panel_actual.focus_neighbor_right = panel_der.get_path()


# Nueva función para Dialogic al ganar
func _al_terminar_animacion_victoria():
	# Desconectamos para evitar duplicados
	var carteles_victoria = get_tree().get_nodes_in_group("mensaje_victoria")
	if carteles_victoria.size() > 0 and carteles_victoria[0].animation_finished.is_connected(_al_terminar_animacion_victoria):
		carteles_victoria[0].animation_finished.disconnect(_al_terminar_animacion_victoria)
	
	# Ocultamos el cartel para que no tape los diálogos
	carteles_victoria[0].visible = false
	
	# --- NUEVA LÓGICA PARA APAGAR LA MÚSICA ---
	# Buscamos el nodo de música en la escena actual usando el árbol principal
	var nodo_musica = get_tree().current_scene.get_node_or_null("MusicaBatallaTutorial")
	if nodo_musica and nodo_musica is AudioStreamPlayer:
		nodo_musica.stop() # Apaga la canción de la primera pelea inmediatamente
		print("Música de la primera batalla detenida para los diálogos.")
	
	Dialogic.timeline_ended.connect(_al_terminar_timeline_guarida)
	Dialogic.start("Guarida")

func _al_terminar_timeline_guarida():
	# Desconectamos por seguridad
	Dialogic.timeline_ended.disconnect(_al_terminar_timeline_guarida)
	
	# RECOLECTAR PERSONAJES Y LIMPIAR EL MANAGER ANTES DEL VIAJE
	acciones_planificadas.clear()
	aliados_que_ya_eligieron.clear()
	enemigos.clear()
	aliados.clear()
	batalla_finalizada = false
	turno_enemigo = 0
	
	# --- ¡AQUÍ AÑADIMOS EL REINICIO DE TURNOS PARA EL JUGADOR! ---
	turno_jugador = true        # Le devolvemos el turno al jugador humano
	puede_abrir_menu = true     # Desbloqueamos los clics y el botón A del mando
	ejecutando_acciones_en_cadena = false
	
	# --- NUEVA LÍNEA: Cambiamos oficialmente el indicador a la segunda batalla ---
	numero_batalla = 2
	
	# 4. Cambiamos a la segunda escena de combate
	# REEMPLAZA esta ruta por la ruta exacta de tu archivo Batalla2.tscn
	get_tree().change_scene_to_file("res://Objetos/Mundo/batalla_2.tscn")

func _al_terminar_animacion_batalla_2():
	# Desconectamos la señal de la Batalla 2
	var carteles_victoria = get_tree().get_nodes_in_group("mensaje_victoria")
	if carteles_victoria.size() > 0 and carteles_victoria[0].animation_finished.is_connected(_al_terminar_animacion_batalla_2):
		carteles_victoria[0].animation_finished.disconnect(_al_terminar_animacion_batalla_2)
	
	carteles_victoria[0].visible = false
	
	# Opcional: Si tienes música en el mapa 2, apágala igual que en la batalla 1
	var nodo_musica = get_tree().current_scene.get_node_or_null("Witch-cat")
	if nodo_musica and nodo_musica is AudioStreamPlayer:
		nodo_musica.stop()
	
	# Ejemplo B: Si de momento quieres que vuelva directamente al Menú de Inicio:
	get_tree().change_scene_to_file("res://Objetos/Menu/menu_principal.tscn") 
	
	# Recuerda resetear el contador si vuelves al menú de inicio por si vuelven a jugar
	numero_batalla = 1


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
	
	
	if gato.data.jugador and aliados_que_ya_eligieron.has(gato): 
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
		
		# --- NUEVA VALIDACIÓN DE OBJETIVO VIVO ---
		# Si la acción requiere un objetivo y ese objetivo ya está muerto/knockout, nos saltamos la acción
		var objetivo = accion["objetivo"]
		if objetivo != null and (not is_instance_valid(objetivo) or objetivo.componente_salud.sin_salud):
			print("El objetivo ya fue derrotado. ¡Acción cancelada para " + gato.name + "!")
			continue # Se salta este ataque y el bucle pasa al siguiente de inmediato
		
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
	
	if batalla_finalizada: return
	
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
				aliado.get_node("Acciones").abrir_menu()
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
	if batalla_finalizada: return
	puede_abrir_menu = false
	
	# filtramos los enemigos vivos
	var enemigos_vivos = enemigos.filter(func(e): return !e.componente_salud.sin_salud)
	var aliados_vivos = aliados.filter(func(a): return !a.componente_salud.sin_salud)
	
	if enemigos_vivos.is_empty() or aliados_vivos.is_empty(): 
		obtener_personajes()
		return

	# la ia procesa todos sus gatos vivos uno por uno, esperando su animacion
	for enemigo_actual in enemigos_vivos:
		if batalla_finalizada or enemigo_actual.componente_salud.sin_salud: continue
		
		enemigo_actual.actualizar_defensa_actual()
		enemigo_actual.procesar_turnos_estado()
		
		var objetivo = aliados_vivos.pick_random()
		var dado = randf_range(0, 100)
		
		# variables globales momentaneas para este ataque de la ia
		gato_equipo = enemigo_actual
		gato_objetivo = objetivo
		
		if dado < 65:
			# 65% ATACAR
			tipo_accion = "attack"
			enemigo_actual.atacar_enemigo(objetivo)
			await enemigo_actual.accion_terminada # espera q el enemigo vaya y vuelva
		elif dado < 80:
			# 15% DEFENDER
			enemigo_actual.defenderse()
			await get_tree().create_timer(0.5).timeout
		elif dado < 90:
			# 10% GRUÑIDO
			tipo_accion = "grunido"
			enemigo_actual.usar_grunido(objetivo)
			await enemigo_actual.accion_terminada
		else:
			# 10% BUFIDO
			tipo_accion = "bufido"
			enemigo_actual.usar_bufido(objetivo)
			await enemigo_actual.accion_terminada
			
	# Una vez que TODOS los enemigos terminaron sus turnos físicos individuales:
	# Reiniciamos el ciclo y devolvemos el control al jugador humano
	turno_jugador = true
	puede_abrir_menu = true
	print("--- ¡Turno del Jugador! ---")
	
	# Limpieza post-turno enemigo
	for i in aliados:
		if is_instance_valid(i) and !i.componente_salud.sin_salud:
			i.actualizar_defensa_actual()
			
	# Volvemos a enfocar el menú del primer aliado vivo
	var aliados_disponibles = aliados.filter(func(a): return !a.componente_salud.sin_salud)
	if aliados_disponibles.size() > 0:
		gato_equipo = aliados_disponibles[0]
		aliados_disponibles[0].get_node("Panel").grab_focus()
		aliados_disponibles[0].get_node("Acciones").abrir_menu()
