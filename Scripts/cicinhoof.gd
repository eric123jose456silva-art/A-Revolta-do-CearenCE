extends CharacterBody2D

# ==========================================
# CONFIGURAÇÕES DE MOVIMENTO E COMBATE
# ==========================================
const WALK_SPEED = 150.0
const RUN_SPEED = 250.0
const JUMP_VELOCITY = -400.0

var is_attacking: bool = false
var attack_damage: int = 30 # Dano que o Cicinho causa no inimigo

# ==========================================
# STATUS DO JOGADOR
# ==========================================
var max_health: int = 100
var current_health: int = 100

var max_stamina: float = 50.0
var current_stamina: float = 50.0
var run_stamina_cost: float = 15.0 
var double_jump_cost: float = 15.0 
var stamina_regen_rate: float = 10.0 

var can_double_jump: bool = false

# ==========================================
# REFERÊNCIAS DE NÓS
# ==========================================
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D 
@onready var ataque_hitbox = $AtaqueHitbox

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Adiciona o Cicinho ao grupo Jogador para ser achado e curado pelos inimigos
	add_to_group("Jogador")
	
	# Configura os limites da câmera
	if camera:
		camera.limit_top = 102
		camera.limit_bottom = 690
	
	# Conecta o sinal de fim de animação para liberar o movimento após o golpe
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	var is_running = false

	# 1. GRAVIDADE E PULO DUPLO
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		can_double_jump = true

	# Se estiver atacando, trava o movimento
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	# 2. SISTEMA DE ATAQUE
	if Input.is_action_just_pressed("ATAQUE") and is_on_floor():
		iniciar_ataque()
		return 

	# 3. SISTEMA DE PULO
	if Input.is_action_just_pressed("JUMP"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif can_double_jump and current_stamina >= double_jump_cost:
			velocity.y = JUMP_VELOCITY
			current_stamina -= double_jump_cost
			can_double_jump = false

	# 4. DIREÇÃO E CORRIDA (Usa "RIGTH" do seu mapa)
	var direction = Input.get_axis("LEFT", "RIGTH")
	var current_speed = WALK_SPEED
	
	if Input.is_action_pressed("RUNNING") and direction != 0 and current_stamina > 0 and is_on_floor():
		current_speed = RUN_SPEED
		is_running = true
		current_stamina -= run_stamina_cost * delta
		current_stamina = max(current_stamina, 0.0) 
	
	if not is_running and current_stamina < max_stamina:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(current_stamina, max_stamina) 

	# 5. MOVIMENTO HORIZONTAL
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	# 6. ANIMAÇÕES E INVERSÃO DO PERSONAGEM/ATAQUE
	if direction > 0:
		animated_sprite.flip_h = false
		if ataque_hitbox: ataque_hitbox.scale.x = 1 
	elif direction < 0:
		animated_sprite.flip_h = true
		if ataque_hitbox: ataque_hitbox.scale.x = -1 

	if not is_on_floor():
		animated_sprite.play("jump")
	else:
		if direction != 0:
			animated_sprite.play("walk")
			animated_sprite.speed_scale = 1.5 if is_running else 1.0
		else:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0

	move_and_slide()

# ==========================================
# FUNÇÕES DE COMBATE (DAR DANO)
# ==========================================
func iniciar_ataque():
	is_attacking = true
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("ataque") 
	
	if ataque_hitbox:
		var corpos_na_area = ataque_hitbox.get_overlapping_bodies()
		for corpo in corpos_na_area:
			if corpo.has_method("receber_dano") and corpo != self:
				corpo.receber_dano(attack_damage)

func _on_animation_finished():
	if animated_sprite.animation == "ataque":
		is_attacking = false

# ==========================================
# SISTEMA DE DANO E CURA
# ==========================================
func receber_dano(quantidade: int):
	current_health -= quantidade
	print("Cicinho sofreu dano! Vida: ", current_health)
	
	animated_sprite.modulate = Color(1, 0, 0) 
	await get_tree().create_timer(0.2).timeout
	animated_sprite.modulate = Color(1, 1, 1) 

	if current_health <= 0:
		morrer()

func curar(quantidade: int):
	current_health += quantidade
	if current_health > max_health:
		current_health = max_health
		
	print("Cicinho recuperou vida! Vida atual: ", current_health)
	
	animated_sprite.modulate = Color(0, 1, 0) # Pisca Verde
	await get_tree().create_timer(0.2).timeout
	animated_sprite.modulate = Color(1, 1, 1) 

func morrer():
	print("Fim de Jogo!")
	get_tree().reload_current_scene()
