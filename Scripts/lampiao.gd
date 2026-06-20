extends CharacterBody2D

# ==========================================
# CONFIGURAÇÕES DO LAMPIÃO
# ==========================================
const SPEED = 50.0
const CHASE_SPEED = 100.0 
var direction = -1 
var damage = 20 

var is_attacking = false
var is_chasing = false 
var player_in_range = false 
var target_player = null 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# ==========================================
# SISTEMA DE VIDA DO INIMIGO
# ==========================================
var max_health: int = 60
var current_health: int = 60

# ==========================================
# REFERÊNCIAS DOS NÓS
# ==========================================
@onready var animated_sprite = $AnimatedSprite2D
@onready var detector_chao = $DetectorChao 
@onready var hitbox = $Hitbox
@onready var area_visao = $AreaVisao 

func _ready():
	add_to_group("Inimigos")
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)
	
	if area_visao:
		area_visao.body_entered.connect(_on_area_visao_body_entered)
		area_visao.body_exited.connect(_on_area_visao_body_exited)
		
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# ==========================================
	# MÁQUINA DE ESTADOS
	# ==========================================
	if is_attacking:
		velocity.x = 0 
		
	elif is_chasing and target_player:
		var direcao_para_alvo = sign(target_player.global_position.x - global_position.x)
		
		if direcao_para_alvo != 0 and direcao_para_alvo != direction:
			direction = direcao_para_alvo
			aplicar_direcao()
			
		if is_on_wall() or not detector_chao.is_colliding():
			velocity.x = 0
			animated_sprite.play("IDLE")
		else:
			velocity.x = direction * CHASE_SPEED
			if animated_sprite.animation != "RUN":
				animated_sprite.play("RUN")
				
	else:
		if is_on_wall() or not detector_chao.is_colliding():
			virar()
		
		velocity.x = direction * SPEED
		if animated_sprite.animation != "WALK":
			animated_sprite.play("WALK")

	move_and_slide()

# ==========================================
# MOVIMENTO E VIRADA
# ==========================================
func virar():
	direction *= -1
	aplicar_direcao()

func aplicar_direcao():
	if direction > 0:
		animated_sprite.flip_h = false
		detector_chao.position.x = abs(detector_chao.position.x) 
		hitbox.scale.x = 1 
	else:
		animated_sprite.flip_h = true
		detector_chao.position.x = -abs(detector_chao.position.x) 
		hitbox.scale.x = -1 

# ==========================================
# SISTEMA DE VISÃO (PERSEGUIÇÃO)
# ==========================================
func _on_area_visao_body_entered(body):
	# CORREÇÃO: Só persegue se for o Jogador!
	if body.is_in_group("Jogador"):
		is_chasing = true
		target_player = body 

func _on_area_visao_body_exited(body):
	if body == target_player:
		is_chasing = false 

# ==========================================
# COMBATE E ATAQUE
# ==========================================
func _on_hitbox_body_entered(body):
	# CORREÇÃO: Só ataca se for o Jogador!
	if body.is_in_group("Jogador"):
		player_in_range = true
		target_player = body
		if not is_attacking:
			iniciar_ataque()

func _on_hitbox_body_exited(body):
	if body == target_player:
		player_in_range = false

func iniciar_ataque():
	is_attacking = true
	animated_sprite.play("ATACK")
	
	if target_player:
		target_player.receber_dano(damage)

func _on_animation_finished():
	if animated_sprite.animation == "ATACK":
		if player_in_range:
			animated_sprite.play("ATACK") 
			if target_player:
				target_player.receber_dano(damage)
		else:
			is_attacking = false 

# ==========================================
# SISTEMA DE DANO SOFRIDO E MORTE
# ==========================================
func receber_dano(quantidade: int):
	current_health -= quantidade
	
	animated_sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(animated_sprite):
		animated_sprite.modulate = Color(1, 1, 1)

	if current_health <= 0:
		morrer()

func morrer():
	remove_from_group("Inimigos")
	
	var jogadores = get_tree().get_nodes_in_group("Jogador")
	if jogadores.size() > 0:
		jogadores[0].curar(30) 
	
	var inimigos_restantes = get_tree().get_nodes_in_group("Inimigos").size()
	print("Lampião derrotado! Restam: ", inimigos_restantes)
	
	if inimigos_restantes == 0:
		print("VITÓRIA! A Revolta do CearenCE foi um sucesso!")
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): get_tree().reload_current_scene())
		
	queue_free()
