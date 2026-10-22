extends CharacterBody2D
#señales
signal health_changed(current, maximum)
signal enemy_died(points)
signal ship_rescued

@export var speed: float = 100
@export var direction: Vector2 = Vector2.DOWN
@export var max_hp: float = 2
@export var collision_damage: float = 5
@export var explosion: PackedScene
@export var powerup: PackedScene
#probabilidad de soltar un premio.
@export var probabilidad_powerup: float = 0.12

var current_hp: float
var points = 50
var tipo = "abeja"
var patron = "recto"
var nivel = 1
var dead = false
var t = 0.0
var estado = "bajando"
var tiempo_rayo = 0.0
var con_nave = false
var sonido_rayo
var lado = 1

@onready var sprite = $AnimatedSprite2D

#se crea el enemigo aleatorio
func _ready():
	tipo = ["abeja", "abeja", "mariposa", "jefe"].pick_random()
	if tipo == "mariposa":
		points = 80
	elif tipo == "jefe":
		points = 150
		max_hp *= 2
	sprite.play(tipo)
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

	speed += 20 * (nivel - 1)
	$Weapon.reload_time = max(0.6, 1.5 - 0.15 * (nivel - 1))
  #movimiento del enemigo
	var patrones = ["recto", "recto", "zigzag"]
	#Nueva posibilidad de movimiento en picada 
	if nivel >= 2:
		patrones.append("picada")
	patron = patrones.pick_random()
	#si es jefe tiene posibilidad de nuevo patron
	if tipo == "jefe" and randf() < 0.4:
		patron = "captor"


func _physics_process(delta):
	t += delta

	#direction o patron  de  movimiento
	var dir = direction
	match patron:
		#de izquierda a derecha usamos la funcion del coseno
		"zigzag":
			dir = Vector2(cos(t * 3) * 1.2, 1)
			#se lanza contra jugador luego de pixel 150
		"picada":
			if estado == "bajando" and global_position.y > 150:
				estado = "picando"
				var player = get_tree().get_first_node_in_group("player")
				if player:
					direction = (player.global_position - global_position).normalized()
					direction.y = max(direction.y, 0.4)
			dir = direction
		"captor":
			dir = actualizar_captor(delta)

	velocity = dir.normalized() * speed
	if estado == "saliendo":
		velocity *= 1.8

	if velocity.length() > 0 and estado != "regresando" and estado != "patrulla":
		#mira hacia el movimiento
		look_at(position + velocity)
		rotation += PI / 2

	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body.has_method("take_damage"):
			body.take_damage(collision_damage)
			die()

#jefe captor
func actualizar_captor(delta):
	#el jefe bajaria hasta abajo de la pantalla
	if estado == "bajando" and global_position.y >= 460:
		estado = "rayo"
		#muestra el rayo
		$Rayo.show()
		$Rayo/Sprite.play()
		#manda un sonido
		sonido_rayo = Global.play_sfx("tractor_beam")
	if estado == "rayo":
		tiempo_rayo += delta
		for body in $Rayo/Area.get_overlapping_bodies():
			#secuestra la nave y regresa
			intentar_captura(body)
		if tiempo_rayo > 4 and estado == "rayo":
			terminar_rayo()
		return Vector2.ZERO
	if estado == "regresando":
		if global_position.y <= 150:
			estado = "patrulla"
			tiempo_rayo = 0
		return Vector2.UP
		#si no atrapa nada se va y apaga el rayo
		# rebota en los bordes esperando que jugador la rescate
	if estado == "patrulla":
		tiempo_rayo += delta
		if global_position.x < 60:
			lado = 1
		elif global_position.x > 540:
			lado = -1
		if tiempo_rayo > 10:
			estado = "saliendo"
		return Vector2(lado, 0)
	return Vector2.DOWN


func terminar_rayo():
	estado = "saliendo"
	$Rayo.hide()
	if is_instance_valid(sonido_rayo):
		sonido_rayo.queue_free()


func intentar_captura(body):
	if estado == "rayo" and body.has_method("capture") and body.capture():
		con_nave = true
		$NaveCapturada.show()
		terminar_rayo()
		estado = "regresando"

#para el daño 
func take_damage(damage):
	current_hp -= damage
	current_hp = clamp(current_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if tipo == "jefe" and current_hp > 0:
		sprite.play("jefe_herido")
		Global.play_sfx("boss_damage")
	if current_hp <= 0:
		die()

#para el eatdod de muerte
func die():
	if dead:
		return
	dead = true
	match tipo:
		"abeja":
			Global.play_sfx("zako_destroy")
		"mariposa":
			Global.play_sfx("goei_destroy")
		"jefe":
			Global.play_sfx("boss_destroy")
	if is_instance_valid(sonido_rayo):
		sonido_rayo.queue_free()
	if con_nave:
		ship_rescued.emit()

	var e = explosion.instantiate()
	e.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", e)

	if randf() < probabilidad_powerup:
		var p = powerup.instantiate()
		p.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", p)

	enemy_died.emit(points)
	queue_free()
