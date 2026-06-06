extends AnimatedSprite2D

#animção do gato (código do levi)
@onready var gato = $"."

func _physics_process(_delta):
	gato.play()
