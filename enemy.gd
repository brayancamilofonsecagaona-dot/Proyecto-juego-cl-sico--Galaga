extends CharacterBody2D 

@export var speed: float = 100
@export var direction: Vector2 = Vector2.DOWN


func _ready():
	pass 



func _process(delta):
	pass


func _physics_process(delta):
	#direction  de  movimiento
	velocity = direction.normalized() * speed
	

	look_at(position + velocity)
	rotation += PI / 2
	
	
	move_and_collide(velocity * delta)
