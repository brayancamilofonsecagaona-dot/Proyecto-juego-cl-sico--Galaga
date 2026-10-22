extends Node2D
#fabricar los enemigos arriba y mantenerlos en formación
signal enemy_spawned(enemy)

@export var enemy_to_spawn: PackedScene

const LAYOUT = [
	"...JJJJ...",
	".MMMMMMMM.",
	".MMMMMMMM.",
	"AAAAAAAAAA",
	"AAAAAAAAAA",
]

var nivel = 1
var slots = []       # cada casilla: {pos, tipo}
var ocupados = []
var tiempo = 0.0
var sway = 0.0


@onready var shapeSize = $SpawnArea/CollisionShape2D.shape.extents
@onready var origin = $SpawnArea/CollisionShape2D.global_position
@onready var spawnStart = origin - shapeSize
@onready var spawnEnd = origin + shapeSize


func _ready():
	var tipos = {"J": "jefe", "M": "mariposa", "A": "abeja"}
	for f in LAYOUT.size():
		for c in LAYOUT[f].length():
			var ch = LAYOUT[f][c]
			if ch == ".":
				continue
			slots.append({"pos": Vector2(70 + c * 50, 80 + f * 45), "tipo": tipos[ch]})
	ocupados.resize(slots.size())
	ocupados.fill(false)


func _process(delta):
	tiempo += delta
	sway = sin(tiempo * 0.8) * 40


func start():
	$SpawnTimer.start()


func set_level(n):
	nivel = n
	$SpawnTimer.wait_time = max(0.35, 1.0 - 0.12 * (n - 1))


func liberar(i):
	ocupados[i] = false


# se crea un enemigo nuevo y se le asigna una casilla libre
func _on_spawn_timer_timeout():
	var libres = []
	for i in ocupados.size():
		if not ocupados[i]:
			libres.append(i)
	if libres.is_empty():
		return
	var i = libres.pick_random()
	ocupados[i] = true

	var e = enemy_to_spawn.instantiate()
	e.position = Vector2(randf_range(spawnStart.x, spawnEnd.x), randf_range(spawnStart.y, spawnEnd.y))
	e.nivel = nivel
	e.map = self
	e.slot = i
	e.slot_pos = slots[i].pos
	e.tipo = slots[i].tipo
	call_deferred("add_child", e)
	enemy_spawned.emit(e)


# los enemigos que llegan abajo reaparecen arriba; lo demás se borra
func _on_remove_area_body_entered(body):
	if body.has_method("volver_arriba"):
		body.volver_arriba()
	else:
		body.queue_free()
