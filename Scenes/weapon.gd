extends Node2D

@export var reload_time: float = 0.2
@export var bullet: PackedScene
@export var damage: float = 1
@export var bullet_speed: float = 1000
@export var enemy_weapon: bool = false

var reloaded = true

@onready var reload_timer = $ReloadTimer


func _ready():
	reload_timer.wait_time = reload_time
	if enemy_weapon:
		reload_timer.start(randf_range(0.3, reload_time))


func _on_reload_timer_timeout():
	reloaded = true
	if enemy_weapon:
		shoot()


func shoot():
	if not reloaded:
		return false
	var b = bullet.instantiate()
	b.bullet_damage = damage
	b.bullet_speed = bullet_speed
	b.global_transform = global_transform
	get_tree().current_scene.call_deferred("add_child", b)
	reloaded = false
	reload_timer.start(reload_time)
	return true
