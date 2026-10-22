extends CharacterBody2D
#aqui manejamos el movimiento, el disparo, las vidas y los powerups

signal health_changed(current, maximum)   # ahora reporta las vidas
signal player_died

@export var speed: float = 400
@export var explosion: PackedScene

const VIDAS_INICIALES = 3
const VIDAS_MAX = 5
const POS_INICIAL = Vector2(300, 720)

var vidas = VIDAS_INICIALES
var dead = false
var doble = false
var capturado = false
var escudo = false
var invencible = false
var tween_escudo
var id_rapido = 0
var id_escudo = 0

@onready var current_weapon = $Weapon


func _ready() -> void:
	current_weapon.max_bullets = 2
	$Weapon2.max_bullets = 2
	health_changed.emit(vidas, VIDAS_MAX)


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
	var dir = Input.get_axis("left", "right")
	velocity = Vector2(dir * speed, 0)
	move_and_slide()
	global_position.x = clamp(global_position.x, 30, 570)


# cualquier golpe: con nave doble pierdes una nave, si no pierdes una vida
func take_damage(_damage):
	if escudo or invencible or dead:
		return
	if doble:
		perder_doble()
		return
	die()


# pierde una vida; reaparece si quedan, si no es game over
func die():
	if dead:
		return
	vidas -= 1
	health_changed.emit(vidas, VIDAS_MAX)
	Global.play_sfx("explosion")
	var e = explosion.instantiate()
	e.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", e)
	if vidas <= 0:
		dead = true
		player_died.emit()
		queue_free()
		return
	reaparecer()


func reaparecer():
	capturado = false
	$Nave.rotation = 0
	global_position = POS_INICIAL
	invencible = true
	var t = create_tween().set_loops(8)
	t.tween_property(self, "modulate:a", 0.3, 0.125)
	t.tween_property(self, "modulate:a", 1.0, 0.125)
	t.finished.connect(fin_invencible)


func fin_invencible():
	invencible = false
	modulate = Color.WHITE


# jefe llama esta funcion para el rayo que captura nave
func capture():
	if capturado or escudo or invencible or doble or dead:
		return false
	capturado = true
	Global.play_sfx("fighter_captured")
	var t = create_tween()
	t.tween_property($Nave, "rotation", TAU * 3, 2.0)
	t.finished.connect(soltar)
	return true


# la nave capturada se pierde: cuesta una vida
func soltar():
	$Nave.rotation = 0
	capturado = false
	die()


# si muere jefe se activa doble nave
func make_double():
	if doble or dead:
		return
	doble = true
	Global.play_sfx("fighter_rescued")
	$Nave2.show()
	$CollisionShape2D2.set_deferred("disabled", false)


# explosion si hay golpe y vuelve a una sola nave
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
		# una vida extra
		"vida":
			vidas = min(VIDAS_MAX, vidas + 1)
			health_changed.emit(vidas, VIDAS_MAX)
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
