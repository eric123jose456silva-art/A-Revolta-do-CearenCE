extends CharacterBody2D

# Configurações de velocidade e pulo
const WALK_SPEED = 150.0
const RUN_SPEED = 250.0
const JUMP_VELOCITY = -400.0

# Obtém o valor padrão de gravidade das configurações do projeto
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referência ao nó AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# 1. APLICAÇÃO DA GRAVIDADE
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. SISTEMA DE PULO
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. VERIFICAÇÃO DE CORRIDA
	var current_speed = WALK_SPEED
	if Input.is_action_pressed("RUNNING"):
		current_speed = RUN_SPEED

	# 4. MOVIMENTAÇÃO HORIZONTAL
	# Usando "RIGTH" exatamente como está escrito no seu Mapa de Entradas
	var direction = Input.get_axis("LEFT", "RIGTH")
	
	if direction:
		velocity.x = direction * current_speed
	else:
		# Desacelera o personagem quando as teclas são soltas
		velocity.x = move_toward(velocity.x, 0, current_speed)

	# 5. CONTROLE DE ANIMAÇÕES E DIREÇÃO DO SPRITE
	# Vira o sprite para a esquerda ou direita
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Decide qual animação tocar com base no estado atual
	if not is_on_floor():
		animated_sprite.play("jump")
	else:
		if direction != 0:
			# Como não há animação "run" no seu AnimatedSprite2D, usamos "walk"
			# Mas você pode adicionar um multiplicador de velocidade na animação se estiver correndo
			animated_sprite.play("walk")
			
			# Opcional: Aumentar a velocidade da animação ao correr
			if Input.is_action_pressed("RUNNING"):
				animated_sprite.speed_scale = 1.5
			else:
				animated_sprite.speed_scale = 1.0
		else:
			animated_sprite.play("idle")

	# Move o personagem e lida com colisões
	move_and_slide()
