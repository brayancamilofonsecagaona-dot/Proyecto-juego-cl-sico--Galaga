extends Area2D

const TEXTURAS = {
	"vida": preload("res://Assets/Galaga/power_vida.png"),
	"rapido": preload("res://Assets/Galaga/power_rapido.png"),
	"escudo": preload("res://Assets/Galaga/power_escudo.png"),
}

@export var velocidad: float = 120

var tipo = ""


func _ready():
	if tipo == "":
		tipo = TEXTURAS.keys().pick_random()
	$Sprite2D.texture = TEXTURAS[tipo]
	var t = create_tween().set_loops()
	t.tween_property($Sprite2D, "modulate:a", 0.4, 0.25)
	t.tween_property($Sprite2D, "modulate:a", 1.0, 0.25)


func _physics_process(delta):
	position.y += velocidad * delta
	if position.y > 850:
		queue_free()


func _on_body_entered(body):
	if body.has_method("apply_powerup"):
		body.apply_powerup(tipo)
		Global.play_sfx("extend")
		queue_free()
