class_name Gato extends CharacterBody2D

@export var data : PersonajeData
@onready var animation: AnimatedSprite2D = $Animation
@onready var componente_salud: Node = $ComponenteSalud
@onready var efecto_estado = $EfectoEstado
@onready var icono_debuff_izq = $IconoDebuffIzq
@onready var icono_debuff_der = $IconoDebuffDer

const VELOCIDAD = 400.0

#variables animacion
var atacando : bool = false
var posicion_inicial : Vector2
var regresar_posicion : bool = false

# Esta variable guardará el ícono correcto que usará este gato en particular
var icono_debuff_actual : Sprite2D 

#variables personaje
var gato_objetivo
var defendiendo : bool = false

var turnos_grunido : int = 0
var penalizacion_defensa : float = 0.0

# ACCIONES QUE SE ACTIVAN APENAS SE ABRE EL JUEGO
func _ready():
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
		if Input.is_action_just_pressed("click_izquierdo") or event.is_action_pressed("ui_accept")and Manager.puede_abrir_menu and Manager.turno_jugador:
			$Acciones.abrir_menu()
			Manager.seleccion_gato_equipo(self)
	else:
		if Input.is_action_just_pressed("click_izquierdo") or event.is_action_pressed("ui_accept") and $Seleccion_enemigo.visible:
			Manager.seleccion_gato_enemigo(self)
			Manager.iniciar_ataque()


# ANIMACION para que el gato se acerque a atacar al otro
func _physics_process(delta):
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
			animation.play("idle")
			Manager.cambiar_turno()
			
			# RECORDAR QUITAR LUEGOOOOOOOOOOOOOOOOOOOO CTMMM
			Manager.puede_abrir_menu = true


### FUNCIONES GENERALES ###

func atacar_enemigo(target):
	gato_objetivo = target

func defenderse():
	componente_salud.defensa = (data.defensa + penalizacion_defensa)/2 
	defendiendo = true
	Manager.cambiar_turno()
	Manager.puede_abrir_menu = true


func quitar_defensa():
	componente_salud.defensa = data.defensa + penalizacion_defensa 

func usar_grunido(target):
	gato_objetivo = target
	atacando = true 
	animation.play("grunido")

func recibir_grunido():
	turnos_grunido = 2
	penalizacion_defensa = 0.4
	quitar_defensa() 
	print("¡Defensa vulnerada por 2 turnos!")
	animation.play("def_down") 

	efecto_estado.visible = true 
	if data.jugador:
		efecto_estado.play("anim_def_down")
	else:
		efecto_estado.play("anim_def_down_enemy")

	if icono_debuff_actual:
		icono_debuff_actual.visible = true

func procesar_turnos_estado():
	if turnos_grunido > 0:
		turnos_grunido -= 1 
		if turnos_grunido <= 0:
			penalizacion_defensa = 0.0
			quitar_defensa() 
			if icono_debuff_actual:
				icono_debuff_actual.visible = false
			print("El efecto de gruñido desapareció. Defensa normalizada.")


### FUNCIONES DEL MARCADOR ###
func mostrar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = true

func ocultar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = false

func mostrar_aliado_seleccionado():
	$Seleccion_aliado.visible = true

func ocultar_aliado_seleccionado():
	$Seleccion_aliado.visible = false



# FUNCIONES VISUALES

func _on_animation_finished():
	if animation.animation == "attack":
		if gato_objetivo and gato_objetivo.has_node("ComponenteSalud"):
			gato_objetivo.componente_salud.recibir_danio(data.danio, data.prob_critico, data.multip_danio)
			print("Hacer daño al personaje")
		
		gato_objetivo = null
		atacando = false
		regresar_posicion = true
		Manager.puede_abrir_menu = true

	elif animation.animation == "grunido":
		if gato_objetivo:
			gato_objetivo.recibir_grunido() 
			
		gato_objetivo = null
		atacando = false
		animation.play("idle")
		Manager.cambiar_turno()	
		
	elif animation.animation == "hurt" or animation.animation == "def_down":
		animation.play("idle")
		


func _on_componente_salud_danio_recibido() -> void:
	animation.play("hurt")
	defendiendo = false
	quitar_defensa()


func _on_componente_salud_salud_cero() -> void:
	animation.play("dead")
	$Salud.visible = false
	
	if data.jugador:
		remove_from_group("Aliados")
	else:
		remove_from_group("Enemigos")
	
	Manager.obtener_personajes()


func _on_efecto_estado_animation_finished() -> void:
	efecto_estado.visible = false 
