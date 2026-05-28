extends CanvasLayer

@onready var icono = $IconoCursor

var usando_control : bool = false 

func _ready() -> void:
	icono.visible = false

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		usando_control = false
		
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
		usando_control = true

func _process(delta: float) -> void:
	var elemento_enfocado = get_viewport().gui_get_focus_owner()
	
	if elemento_enfocado != null and elemento_enfocado.is_visible_in_tree() and usando_control:
		icono.visible = true
		
		var posicion_destino = elemento_enfocado.global_position
		posicion_destino.x -= 35
		posicion_destino.y += (elemento_enfocado.size.y / 2.0)
		
		icono.global_position = icono.global_position.lerp(posicion_destino, delta * 20.0)
	else:
		icono.visible = false