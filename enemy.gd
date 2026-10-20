extends CharacterBody2D 

@export var speed: float = 100
@export var direction: Vector2 = Vector2.DOWN

@export var max_hp : float = 2
var current_hp: float
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
	
func take_damage(damage):
	current_hp -= damage
	
	print ("Enemy took %s damage. Current HP: %s/%s" % [damage, current_hp, max_hp])
	current_hp = clamp(current_hp, 0, max_hp)
	if current_hp <= 0:
		die()
		
func die():
	print ('Enemy Died!')
	
	queue_free()
	
