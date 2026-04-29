class_name Gato extends CharacterBody2D

@export var data : PersonajeData
@onready var animation: AnimatedSprite2D = $Animation

const VELOCIDAD = 400.0
var gato_objetivo
var atacando : bool = false

func _ready():
	animation.play("idle")
	
	if data.jugador == false:
		Manager.connect("seleccion_enemigo", mostrar_enemigo_seleccionado)
		Manager.connect("ataque_iniciado", ocultar_enemigo_seleccionado)
		Manager.connect("seleccion_aliado", mostrar_aliado_seleccionado)
	else:
		Manager.connect("seleccion_aliado", mostrar_aliado_seleccionado)


func _on_panel_gui_input(event: InputEvent):
	if data.jugador:
		if Input.is_action_just_pressed("click_izquierdo") and Manager.puede_abrir_menu and Manager.turno_jugador:
			$Acciones.abrir_menu()
			Manager.seleccion_gato_equipo(self)
	else:
		if Input.is_action_just_pressed("click_izquierdo") and $Seleccion_enemigo.visible:
			Manager.seleccion_gato_enemigo(self)
			Manager.iniciar_ataque()

# funcion de animacion para que el gato se acerque a atacar al otro
func _physics_process(delta):
	if gato_objetivo and atacando == false:
		var distancia := global_position.distance_to(gato_objetivo.global_position)
		if distancia > 100.0:
			var direccion = (gato_objetivo.global_position - global_position).normalized()
			velocity = VELOCIDAD * direccion
			move_and_slide()
			animation.play("walk")
		else:
			atacando = true
			animation.play("attack")

func atacar_enemigo(target):
	gato_objetivo = target


func mostrar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = true

func ocultar_enemigo_seleccionado():
	$Seleccion_enemigo.visible = false

func mostrar_aliado_seleccionado():
	$Seleccion_aliado.visible = true

func ocultar_aliado_seleccionado():
	$Seleccion_aliado.visible = false
