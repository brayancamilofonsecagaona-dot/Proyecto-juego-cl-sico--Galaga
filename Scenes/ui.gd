extends Control

var id_mensaje = 0


const TEX_NAVE = preload("res://Assets/Galaga/nave.png")
var caja = HBoxContainer.new()


func _ready():
	caja.position = Vector2(15, 760)
	add_child(caja)


# muestra las naves de reserva abajo a la izquierda
func update_lives(vidas):
	for c in caja.get_children():
		c.queue_free()
	for i in max(0, vidas - 1):
		var r = TextureRect.new()
		r.texture = TEX_NAVE
		r.custom_minimum_size = Vector2(32, 32)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caja.add_child(r)


func update_points(points):
	$PointsLabel.text = "%06d" % points


func update_record(record):
	$HiScoreLabel.text = "%06d" % record


func show_message(texto, duracion):
	id_mensaje += 1
	$StageLabel.text = texto
	$StageLabel.show()
	get_tree().create_timer(duracion).timeout.connect(ocultar_mensaje.bind(id_mensaje))


func ocultar_mensaje(mi_id):
	if mi_id == id_mensaje:
		$StageLabel.hide()


func show_player_died(nuevo_record):
	$StageLabel.hide()
	if nuevo_record:
		$PlayerDied.text = "GAME OVER\n¡NUEVO RÉCORD!\n\nENTER  reiniciar\nESC  menú"
	$PlayerDied.show()
