extends Control

var iniciando = false


func _ready():
	$Record.text = "HI-SCORE   %06d" % Global.record
	var t = create_tween().set_loops()
	t.tween_property($Start, "modulate:a", 0.15, 0.5)
	t.tween_property($Start, "modulate:a", 1.0, 0.5)


func _unhandled_input(event):
	if iniciando or not (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		return
	iniciando = true
	$Musica.stop()
	Global.play_sfx("credit")
	get_tree().create_timer(0.6).timeout.connect(empezar)


func empezar():
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
