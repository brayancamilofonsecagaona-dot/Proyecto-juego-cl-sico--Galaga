extends Control

var id_mensaje = 0


func update_health(current, maximum):
	$HealthBar.max_value = maximum
	$HealthBar.value = current


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
