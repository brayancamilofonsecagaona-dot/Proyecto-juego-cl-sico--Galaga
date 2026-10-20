extends Node2D

@export var enemy_to_spawn: PackedScene

@onready var shapeSize = $SpawnArea/CollisionShape2D.shape.extents
@onready var origin = $SpawnArea/CollisionShape2D.global_position
@onready var spawnStart = origin - shapeSize
@onready var spawnEnd = origin + shapeSize


func _ready():
	pass


func _process(delta):
	pass


func _on_spawn_timer_timeout():
	var x = randf_range(spawnStart.x, spawnEnd.x)
	var y = randf_range(spawnStart.y, spawnEnd.y)
	
	var e = enemy_to_spawn.instantiate()
	e.position = Vector2(x,y)
	call_deferred("add_child", e)


func _on_remove_area_body_entered(body):
	print("Enemy left play area and was removed: " + str(body))
	body.queue_free()
