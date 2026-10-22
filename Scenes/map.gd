extends Node2D
#fabricar los enemigos arriba y borrarlos abajo
signal enemy_spawned(enemy)

@export var enemy_to_spawn: PackedScene

var nivel = 1

@onready var shapeSize = $SpawnArea/CollisionShape2D.shape.extents
@onready var origin = $SpawnArea/CollisionShape2D.global_position
@onready var spawnStart = origin - shapeSize
@onready var spawnEnd = origin + shapeSize


func start():
	$SpawnTimer.start()

# se acelera el reloj de spawn de los enemigos
# crea eneimigo cada 1s , restando en cada nivel 0.12s
func set_level(n):
	nivel = n
	$SpawnTimer.wait_time = max(0.35, 1.0 - 0.12 * (n - 1))

# se crea un enemigo nuevo y se spawnea en una coordenada
func _on_spawn_timer_timeout():
	var x = randf_range(spawnStart.x, spawnEnd.x)
	var y = randf_range(spawnStart.y, spawnEnd.y)
	
	var e = enemy_to_spawn.instantiate()
	e.position = Vector2(x,y)
	e.nivel = nivel
	#se agrega al juego
	call_deferred("add_child", e)
	enemy_spawned.emit(e)

# se borra los enemigos que lleguen hasta abajo y  que  el jugador no mato
func _on_remove_area_body_entered(body):
	body.queue_free()
