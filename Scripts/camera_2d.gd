extends Camera2D

# Arraste o seu personagem para esta variável no painel Inspector
@export var target: Node2D 

# Define a velocidade com que a câmera alcança o personagem
@export var smooth_speed: float = 5.0 

func _physics_process(delta: float) -> void:
	if target:
		# Interpola a posição da câmera em direção à posição do alvo
		global_position = global_position.lerp(target.global_position, smooth_speed * delta)
