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
var patron = "entrando"
var nivel = 1
var dead = false
var t = 0.0
var estado = "bajando"
var tiempo_rayo = 0.0
var con_nave = false
var sonido_rayo
var lado = 1

# formación
var map
var slot = -1
var slot_pos = Vector2.ZERO
var espera = 8.0
var es_captor = false
var ang = PI / 2        # rumbo actual (hacia abajo)
var giro_lado = 1
var t_ataque = 0.0
var y_giro = randf_range(500, 640)   # altura donde la abeja da la vuelta

@onready var sprite = $AnimatedSprite2D

#se crea el enemigo aleatorio
func _ready():
	if tipo == "mariposa":
		points = 80
	elif tipo == "jefe":
		points = 150
		max_hp *= 2
	sprite.play(tipo)
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

	speed += 20 * (nivel - 1)
	$Weapon.reload_time = max(1.2, 2.5 - 0.15 * (nivel - 1))
	if tipo == "jefe":
		$Weapon.queue_free()   # el jefe no dispara, solo captura

	patron = "entrando"
	es_captor = tipo == "jefe"
	espera = max(2.0, randf_range(4.0, 12.0) - nivel)


func _physics_process(delta):
	t += delta

	var dir = direction
	var mult = 1.0
	match patron:
		"entrando", "volviendo":
			var destino = slot_pos + Vector2(map.sway, 0)
			var d = destino - global_position
			if d.length() < 8:
				patron = "formacion"
			if d.length() < 60:
				ang = d.angle()               # ya cerca: apunta directo
			else:
				girar_hacia(d.angle(), 5.0, delta)
			dir = Vector2.from_angle(ang)
			mult = 2.5
		"ataque":
			t_ataque += delta
			if t_ataque < 1.4:
				# bucle inicial hacia afuera
				ang += giro_lado * 3.0 * delta
			else:
				# curva hacia el jugador, siempre hacia abajo
				var objetivo = Vector2.DOWN.angle()
				var player = get_tree().get_first_node_in_group("player")
				if player:
					objetivo = (Vector2(player.global_position.x, global_position.y + 300) - global_position).angle()
				if tipo == "mariposa":
					objetivo += sin(t * 4) * 0.8      # serpentea
					girar_hacia(objetivo, 3.0, delta)
				else:
					girar_hacia(objetivo, 2.0, delta)
					if global_position.y > y_giro:
						patron = "volviendo"       # giro en U
			dir = Vector2.from_angle(ang)
			mult = 1.8
		"formacion":
			global_position = slot_pos + Vector2(map.sway, 0)
			rotation = 0
			espera -= delta
			if espera <= 0:
				salir_de_formacion()
			return
		"captor":
			dir = actualizar_captor(delta)

	velocity = dir.normalized() * speed * mult
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


func salir_de_formacion():
	estado = "bajando"
	if es_captor:
		patron = "captor"
		return
	patron = "ataque"
	t_ataque = 0.0
	ang = -PI / 2                                      # empieza subiendo
	giro_lado = -1 if global_position.x < 300 else 1   # el bucle sale hacia afuera


# al salir por abajo reaparece arriba y vuelve a su casilla
func volver_arriba():
	global_position = Vector2(slot_pos.x, -40)
	patron = "volviendo"
	estado = "bajando"
	ang = PI / 2
	tiempo_rayo = 0.0
	espera = max(2.0, randf_range(4.0, 12.0) - nivel)


# gira el rumbo hacia un ángulo con una velocidad máxima de giro
func girar_hacia(objetivo, max_giro, delta):
	var diff = angle_difference(ang, objetivo)
	ang += clamp(diff, -max_giro * delta, max_giro * delta)


func _exit_tree():
	if slot != -1 and is_instance_valid(map):
		map.liberar(slot)

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
	hide()
	queue_free()   # se borra aunque algo más abajo falle
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


# solo dispara mientras ataca en picada (no en formación ni en el bucle)
func puede_disparar():
	return patron == "ataque" and t_ataque > 1.4
