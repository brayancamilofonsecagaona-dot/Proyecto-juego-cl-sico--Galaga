extends CharacterBody2D

#Variables
@export var speed: float = 400

@onready var current_weapon = $Weapon


# Called when the node enters the scene tree for the first time.
func _ready():	
	pass 
	
func _process(delta):
	if Input.is_action_pressed("Disparo"):
		current_weapon.shoot()


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	move_and_slide()
	
