extends Node2D
# esta clase seria como el controlador principal:puntaje, sube de nivel y señales
var points: int = 0
var nivel = 1
var game_over = false

#preparar los marcadores para iniciar
func _ready():
	$UI.update_points(points)
	$UI.update_record(Global.record)
	$UI.show_message("NIVEL 1", 6.0)
	$Inicio.play()
	get_tree().create_timer($Inicio.stream.get_length()).timeout.connect(empezar)


func empezar():
	if game_over:
		return
	$Map.start()
	$Musica.play()


func _on_player_health_changed(current, maximum):
	$UI.update_health(current, maximum)


func _on_player_player_died():
	game_over = true
	$Musica.stop()
	$Inicio.stop()
	var nuevo_record = Global.save_record(points)
	$UI.show_player_died(nuevo_record)
	if nuevo_record:
		Global.play_sfx("name_entry")


func _on_map_enemy_spawned(enemy):
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.ship_rescued.connect(_on_ship_rescued)

# subir de nivel cada 1000 puntos osea nivel 2, 3...
func _on_enemy_died(value):
	if game_over:
		return
	points += value
	$UI.update_points(points)
	if points > Global.record:
		$UI.update_record(points)
	var nuevo_nivel = 1 + floori(points / 1000.0)
	if nuevo_nivel > nivel:
		nivel = nuevo_nivel
		$Map.set_level(nivel)
		$UI.show_message("NIVEL %d" % nivel, 2.0)
		Global.play_sfx("challenging_stage_start")


func _on_ship_rescued():
	var player = get_node_or_null("Player")
	if player:
		player.make_double()


func _unhandled_input(event):
	if not game_over or not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_ENTER:
		Global.stop_all()
		get_tree().reload_current_scene()
	elif event.keycode == KEY_ESCAPE:
		Global.stop_all()
		get_tree().change_scene_to_file("res://Scenes/Title.tscn")
