class_name PersonajeData extends Resource

# para saber si es un personaje controlado por el jugador:
@export var jugador : bool = true

# PARA ANIMACIONES PERSONALIZADAS POR PERSONAJES
@export var animaciones_gato : SpriteFrames


# valores del personaje durante la batalla por turnos:

#estadisticas
@export var salud_maxima : float = 100.0
@export var defensa : float = 1.0   # lo que va a bloquear de daño al ejecutar accion de DEFENDER
@export var evasion : float = 0.2   # probabilidad de evadir un ataque

#daño
@export var danio : float = 10.0  # daño base
@export var multip_danio : float = 1.2  # multiplicador si se da un golpe critico 
@export var prob_critico : float = 0.1  # probabilidad de dar un golpe critico
