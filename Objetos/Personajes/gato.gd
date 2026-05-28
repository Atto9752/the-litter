class_name Gato extends CharacterBody2D

@export var data : PersonajeData
@onready var animation: AnimatedSprite2D = $Animation
@onready var componente_salud: Node = $ComponenteSalud
@onready var efecto_estado = $EfectoEstado
@onready var icono_debuff_izq = $IconoDebuffIzq
@onready var icono_debuff_der = $IconoDebuffDer

signal accion_terminada

const VELOCIDAD = 400.0

# variables animacion
var atacando : bool = false
var posicion_inicial : Vector2
var regresar_posicion : bool = false

# icono correcto que usara cada gato en particular
var icono_debuff_actual : Sprite2D 

# variables personaje
var gato_objetivo
var defendiendo : bool = false

# variables grunido
var turnos_grunido : int = 0
var penalizacion_defensa : float = 0.0

# variables bufido
var turnos_bufido : int = 0
var penalizacion_evasion : float = 0.0
var evasion_actual : float = 0.2
# Variables para la huida narrativa al final de la pelea
var huyendo : bool = false
var destino_huida : Vector2 = Vector2.ZERO



# ------------------------------------------------------------------------------------------ #
# ACCIONES QUE SE ACTIVAN APENAS SE ABRE EL JUEGO
# ------------------------------------------------------------------------------------------ #

func _ready():
	
	# --- RESETEAR VARIABLES DE VISIBILIDAD PARA NUEVAS BATALLAS ---
	visible = true # Nos aseguramos de que el gato sea completamente visible
	set_physics_process(true) # Forzamos a que el código de movimiento funcione
	huyendo = false # Apagamos el estado de huida de la batalla anterior
	atacando = false
	regresar_posicion = false
	gato_objetivo = null
	# --------------------------------------------------------------
	
	# valores iniciales
	evasion_actual = data.evasion
	
	# Asignar animaciones personalizadas desde el Resource antes de reproducir
	if data and data.animaciones_gato:
		animation.sprite_frames = data.animaciones_gato
	
	animation.animation_finished.connect(_on_animation_finished)
	animation.play("idle")
	posicion_inicial = global_position
	
	componente_salud.salud_maxima = data.salud_maxima
	componente_salud.salud_actual = data.salud_maxima
	componente_salud.defensa = data.defensa
	componente_salud.update_progress_bar()
	
	# conexiones generales para todos los gatitos
	Manager.connect("ataque_iniciado", ocultar_aliado_seleccionado)
	Manager.connect("ataque_iniciado", ocultar_enemigo_seleccionado)
	
	Manager.registrar_gato(self)
	
	if data.jugador == false:
		add_to_group("Enemigos")
		animation.flip_h = true
		Manager.connect("seleccion_enemigo", mostrar_enemigo_seleccionado)
		icono_debuff_actual = icono_debuff_der
	else:
		# para q los aliados escuchen la indicacion de apagar su indicador verde
		add_to_group("Aliados")
		Manager.connect("ocultar_indicadores_aliados", ocultar_aliado_seleccionado)
		icono_debuff_actual = icono_debuff_izq


# PARA ABRIR PANEL DE MENU
func _on_panel_gui_input(event: InputEvent):
	if componente_salud.sin_salud or Manager.batalla_finalizada: return
	
	if data.jugador:
		if (Input.is_action_just_pressed("click_izquierdo") or event.is_action_pressed("ui_accept")) and Manager.puede_abrir_menu and Manager.turno_jugador:
			if not Manager.aliados_que_ya_eligieron.has(self):
				$Acciones.abrir_menu()
				Manager.seleccion_gato_equipo(self)
	else:
		if (Input.is_action_just_pressed("click_izquierdo") or event.is_action_pressed("ui_accept")) and $Seleccion_enemigo.visible and Manager.seleccionando_objetivo:
			Manager.seleccion_gato_enemigo(self)
			Manager.iniciar_ataque()


# ANIMACION para que el gato se acerque a atacar al otro
func _physics_process(delta):
	
	if Manager.batalla_finalizada and not huyendo: 
		velocity = Vector2.ZERO
		return
	
	if huyendo:
		var distancia = global_position.distance_to(destino_huida)
		if distancia > 10.0:
			var direccion = (destino_huida - global_position).normalized()
			velocity = VELOCIDAD * direccion
			move_and_slide()
			if animation.animation != "walk":
				animation.play("walk")
		else:
			# Ya salió de la pantalla, lo hacemos invisible y apagamos su procesamiento
			velocity = Vector2.ZERO
			visible = false
			set_physics_process(false)
		return # Cortamos la ejecución para que no haga nada del combate antiguo
	
	if componente_salud.sin_salud or Manager.batalla_finalizada: return
	
	# IR HACIA EL ENEMIGO
	if gato_objetivo != null and not atacando and not regresar_posicion:
		
		var distancia := global_position.distance_to(gato_objetivo.global_position)
		
		# ANIMACION PARA ACERCARSE
		if distancia > 100.0:
			
			var direccion = (gato_objetivo.global_position - global_position).normalized()
			velocity = VELOCIDAD * direccion
			move_and_slide()
			if animation.animation != "walk":
				animation.play("walk")
			
		else:
			
			# LLEGA AL ENEMIGO Y LO ATACA
			velocity = Vector2.ZERO
			atacando = true
			animation.play("attack")
	
	# PARA REGRESAR A LA POSICION INICIAL
	elif regresar_posicion:
		
		var distancia = global_position.distance_to(posicion_inicial)
		
		# ANIMACION PARA REGRESAR
		if distancia > 5.0:
			
			var direccion = (posicion_inicial - global_position).normalized()
			velocity = VELOCIDAD * direccion
			move_and_slide()
			if animation.animation != "walk":
				animation.play("walk")
			
		else:
			
			#ANIMACION AL REGRESAR A LA POSICION INICIAL
			global_position = posicion_inicial
			velocity = Vector2.ZERO
			regresar_posicion = false
			gato_objetivo = null
			animation.play("idle")
			accion_terminada.emit()
			Manager.puede_abrir_menu = true



# ------------------------------------------------------------------------------------------ #
### FUNCIONES GENERALES ###
# ------------------------------------------------------------------------------------------ #

func atacar_enemigo(target):
	gato_objetivo = target

func defenderse():
	componente_salud.defensa = (data.defensa + penalizacion_defensa)/2 
	defendiendo = true

func actualizar_defensa_actual():
	componente_salud.defensa = data.defensa + penalizacion_defensa 

func usar_grunido(target):
	gato_objetivo = target
	atacando = true 
	animation.play("grunido")

func recibir_grunido():
	turnos_grunido = 2
	penalizacion_defensa = 0.4
	actualizar_defensa_actual()
	
	print("¡Defensa vulnerada por 2 turnos!")
	animation.play("def_down") 
	efecto_estado.visible = true 
	
	if data.jugador:
		efecto_estado.play("anim_def_down")
	else:
		efecto_estado.play("anim_def_down_enemy")
	
	if icono_debuff_actual:
		icono_debuff_actual.visible = true

func usar_bufido(target):
	gato_objetivo = target
	atacando = true
	animation.play("bufido")

func recibir_bufido():
	turnos_bufido = 2
	penalizacion_evasion = 0.15
	evasion_actual = clamp(data.evasion - penalizacion_evasion, 0.0, 1.0)
	print("¡Evasión reducida por 2 turnos!")
	# ANIMACIONES DE PARTICULAS O ICONOS DEBUFF PARA CUANDO TENGAMOS

func procesar_turnos_estado():
	
	# para gruñido
	if turnos_grunido > 0:
		turnos_grunido -= 1 
		if turnos_grunido <= 0:
			penalizacion_defensa = 0.0
			actualizar_defensa_actual()
			if icono_debuff_actual: icono_debuff_actual.visible = false
			print("El efecto de gruñido desapareció. Defensa normalizada.")
	
	#para bufido
	if turnos_bufido > 0:
		turnos_bufido -= 1
		if turnos_bufido <= 0:
			penalizacion_evasion = 0.0
			evasion_actual = data.evasion
			print("El efecto de bufido desapareció. Evasión normalizada.")


func ejecutar_fin_batalla(gana_jugador: bool):
	# Limpiamos estados de combate por seguridad
	gato_objetivo = null
	atacando = false
	regresar_posicion = false
	$Salud.visible = false # Ocultamos barras de vida flotantes
	
	if data.jugador:
		# --- LÓGICA PARA TUS GATOS ALIADOS ---
		if componente_salud.sin_salud:
			# Si perdimos pero somos aliados, nos levantamos del knockout
			componente_salud.sin_salud = false 
			animation.play("idle")
		
		if gana_jugador:
			# Si ganamos, caminamos elegantemente de regreso a nuestra posición inicial de descanso
			global_position = posicion_inicial
			animation.play("idle")
		else:
			# Si perdimos, nos volteamos a la izquierda y huimos hacia atrás de la pantalla
			animation.flip_h = true
			destino_huida = Vector2(-200, global_position.y) # Fuera de pantalla por la izquierda
			huyendo = true
	else:
		# --- LÓGICA PARA LOS GATOS ENEMIGOS ---
		if componente_salud.sin_salud:
			# Reviven del knockout para poder escapar de la escena
			componente_salud.sin_salud = false
			animation.play("idle")
		
		if gana_jugador:
			# Si el jugador ganó, los enemigos se voltean a la derecha y huyen despavoridos
			animation.flip_h = false # Mirando a la derecha
			destino_huida = Vector2(1600, global_position.y) # Fuera de pantalla por la derecha
			huyendo = true
			animation.play("walk")
		else:
			# Si el enemigo ganó, se quedan en su posición celebrando en idle
			global_position = posicion_inicial
			animation.play("idle")




# ------------------------------------------------------------------------------------------ #
### FUNCIONES DEL MARCADOR ###
# ------------------------------------------------------------------------------------------ #

func mostrar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = true

func ocultar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = false

func mostrar_aliado_seleccionado():
	$Seleccion_aliado.visible = true

func ocultar_aliado_seleccionado():
	$Seleccion_aliado.visible = false




# ------------------------------------------------------------------------------------------ #
# FUNCIONES VISUALES
# ------------------------------------------------------------------------------------------ #

func _on_animation_finished():
	if animation.animation == "attack":
		if gato_objetivo and gato_objetivo.has_node("ComponenteSalud"):
			gato_objetivo.componente_salud.recibir_danio(
				data.danio, 
				data.prob_critico, 
				data.multip_danio, 
				gato_objetivo.evasion_actual
			)
			print("Hacer daño al personaje")
		
		atacando = false
		regresar_posicion = true
		Manager.puede_abrir_menu = true
		
	elif animation.animation == "grunido":
		if gato_objetivo:
			gato_objetivo.recibir_grunido() 
			
		gato_objetivo = null
		atacando = false
		animation.play("idle")
		accion_terminada.emit()
		
	elif animation.animation == "bufido":
		if gato_objetivo:
			gato_objetivo.recibir_bufido()
		
		gato_objetivo = null
		atacando = false
		animation.play("idle")
		accion_terminada.emit()
		
	elif animation.animation == "hurt" or animation.animation == "def_down":
		animation.play("idle")



func _on_componente_salud_danio_recibido() -> void:
	animation.play("hurt")
	defendiendo = false
	actualizar_defensa_actual()


func _on_componente_salud_salud_cero() -> void:
	animation.play("dead")
	$Salud.visible = false
	
	Manager.obtener_personajes()


func _on_efecto_estado_animation_finished() -> void:
	efecto_estado.visible = false 


func _on_panel_focus_entered() -> void:
	# Si es el turno del jugador y este gato no ha planeado su acción todavía
	if data.jugador and Manager.puede_abrir_menu and Manager.turno_jugador:
		if not Manager.aliados_que_ya_eligieron.has(self):
			# Abrimos la interfaz de ataques y le asignamos la selección global
			$Acciones.abrir_menu()
			Manager.seleccion_gato_equipo(self)
