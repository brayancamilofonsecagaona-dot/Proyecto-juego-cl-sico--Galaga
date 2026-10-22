extends CharacterBody2D
#aqui manejamos el movimiento, el disparo, los 3 powerups

signal health_changed(current, maximum)
signal player_died

#Variables
@export var speed: float = 400
@export var max_hp: float = 10
@export var explosion: PackedScene

var current_hp: float
var dead = false
var doble = false
var capturado = false
var escudo = false
var tween_escudo
var id_rapido = 0
var id_escudo = 0

@onready var current_weapon = $Weapon


func _ready() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

#disparo normal y doble
func _process(delta):
	if capturado:
		return
	if Input.is_action_pressed("shoot"):
		var disparo = current_weapon.shoot()
		if doble:
			$Weapon2.shoot()
		if disparo:
			Global.play_sfx("fire", -6.0)


func _physics_process(delta):
	if capturado:
		return
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed

	move_and_slide()

#daño y efecto visual
func take_damage(damage):
	if escudo or dead:
		return
	if doble:
		perder_doble()
	current_hp -= damage
	current_hp = clamp(current_hp, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
	if current_hp <= 0:
		die()

#muerte
func die():
	if dead:
		return
	dead = true
	Global.play_sfx("explosion")
	var e = explosion.instantiate()
	e.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", e)
	player_died.emit()
	queue_free()

# jefe llama esta funcion para el rayo que captura nave
func capture():
	if capturado or escudo or doble or dead:
		return false
	capturado = true
	Global.play_sfx("fighter_captured")
	var t = create_tween()
	t.tween_property($Nave, "rotation", TAU * 3, 2.0)
	t.finished.connect(soltar)
	return true

#devolver el control a jugador
func soltar():
	$Nave.rotation = 0
	capturado = false
	take_damage(3)

# si muere jefe se activa doble nave
func make_double():
	if doble or dead:
		return
	doble = true
	Global.play_sfx("fighter_rescued")
	$Nave2.show()
	$CollisionShape2D2.set_deferred("disabled", false)

# explosion si hay daño y vuelve a una sola nave 
func perder_doble():
	doble = false
	var e = explosion.instantiate()
	e.global_position = $Nave2.global_position
	get_tree().current_scene.call_deferred("add_child", e)
	$Nave2.hide()
	$CollisionShape2D2.set_deferred("disabled", true)

#powerups 
func apply_powerup(tipo):
	match tipo:
		# conseguir 3 puntos dde vida mas
		"vida":
			current_hp = min(max_hp, current_hp + 3)
			health_changed.emit(current_hp, max_hp)
			# menos tiempo de recarga para el arma
		"rapido":
			id_rapido += 1
			current_weapon.reload_time = 0.08
			$Weapon2.reload_time = 0.08
			get_tree().create_timer(8.0).timeout.connect(fin_rapido.bind(id_rapido))
		# activar un escudo algunos segundos
		"escudo":
			id_escudo += 1
			escudo = true
			if tween_escudo:
				tween_escudo.kill()
			tween_escudo = create_tween().set_loops()
			tween_escudo.tween_property(self, "modulate", Color(0.3, 1, 1, 0.4), 0.15)
			tween_escudo.tween_property(self, "modulate", Color.WHITE, 0.15)
			get_tree().create_timer(6.0).timeout.connect(fin_escudo.bind(id_escudo))


func fin_rapido(mi_id):
	if mi_id == id_rapido:
		current_weapon.reload_time = 0.2
		$Weapon2.reload_time = 0.2


func fin_escudo(mi_id):
	if mi_id == id_escudo:
		escudo = false
		tween_escudo.kill()
		modulate = Color.WHITE
