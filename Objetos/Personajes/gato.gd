class_name Gato extends CharacterBody2D

@export var data : PersonajeData
@onready var animation: AnimatedSprite2D = $Animation
@onready var componente_salud: Node = $ComponenteSalud


const VELOCIDAD = 400.0

#variables animacion
var atacando : bool = false
var posicion_inicial : Vector2
var regresar_posicion : bool = false

#variables personaje
var gato_objetivo


# ACCIONES QUE SE ACTIVAN APENAS SE ABRE EL JUEGO
func _ready():
	animation.animation_finished.connect(_on_animation_finished)
	animation.play("idle")
	posicion_inicial = global_position
	
	componente_salud.salud_maxima = data.salud_maxima
	componente_salud.salud_actual = data.salud_maxima
	componente_salud.update_progress_bar()
	
	# conexiones generales para todos los gatitos
	Manager.connect("ataque_iniciado", ocultar_aliado_seleccionado)
	Manager.connect("ataque_iniciado", ocultar_enemigo_seleccionado)
	
	Manager.registrar_gato(self)
	
	if data.jugador == false:
		add_to_group("Enemigos")
		animation.flip_h = true
		Manager.connect("seleccion_enemigo", mostrar_enemigo_seleccionado)
	else:
		# para q los aliados escuchen la indicacion de apagar su indicador verde
		add_to_group("Aliados")
		Manager.connect("ocultar_indicadores_aliados", ocultar_aliado_seleccionado)


func _on_panel_gui_input(event: InputEvent):
	if data.jugador:
		if Input.is_action_just_pressed("click_izquierdo") and Manager.puede_abrir_menu and Manager.turno_jugador:
			$Acciones.abrir_menu()
			Manager.seleccion_gato_equipo(self)
	else:
		if Input.is_action_just_pressed("click_izquierdo") and $Seleccion_enemigo.visible:
			Manager.seleccion_gato_enemigo(self)
			Manager.iniciar_ataque()


# ANIMACION para que el gato se acerque a atacar al otro
func _physics_process(delta):
	
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





### FUNCIONES DEL MARCADOR ###
func mostrar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = true

func ocultar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = false

func mostrar_aliado_seleccionado():
	$Seleccion_aliado.visible = true

func ocultar_aliado_seleccionado():
	$Seleccion_aliado.visible = false



func _on_animation_finished():
	if animation.animation == "attack":
		if gato_objetivo and gato_objetivo.has_node("ComponenteSalud"):
			gato_objetivo.componente_salud.recibir_danio(data.danio)
			print("Hacer daño al personaje")
		
		gato_objetivo = null
		atacando = false
		regresar_posicion = true
		Manager.puede_abrir_menu = true
