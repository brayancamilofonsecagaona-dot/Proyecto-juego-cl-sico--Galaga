extends Node2D

@export var reload_time: float = 0.2
@export var bullet: PackedScene
@export var damage: float = 1
@export var bullet_speed: float = 1000
@export var enemy_weapon: bool = false

var reloaded = true
var max_bullets = 0   # 0 = sin límite (los enemigos)
var activas = 0

@onready var reload_timer = $ReloadTimer


func _ready():
	reload_timer.wait_time = reload_time
	if enemy_weapon:
		reload_timer.start(randf_range(0.3, reload_time))


func _on_reload_timer_timeout():
	reloaded = true
	if enemy_weapon:
		if get_parent().puede_disparar():
			shoot()
		else:
			reload_timer.start(0.3)   # vuelve a revisar en un momento


func shoot():
	if not reloaded:
		return false
	if max_bullets > 0 and activas >= max_bullets:
		return false
	var b = bullet.instantiate()
	b.bullet_damage = damage
	b.bullet_speed = bullet_speed
	if enemy_weapon:
		# siempre hacia abajo, sin importar cómo esté girado el enemigo
		b.global_position = get_parent().global_position + Vector2(0, 22)
		b.rotation = PI
	else:
		b.global_transform = global_transform
	activas += 1
	b.tree_exited.connect(_on_bullet_gone)
	get_tree().current_scene.call_deferred("add_child", b)
	reloaded = false
	reload_timer.start(reload_time)
	return true


func _on_bullet_gone():
	activas -= 1
