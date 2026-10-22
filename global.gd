extends Node

const RUTA_RECORD = "user://record.save"
const CARPETA_SFX = "res://Assets/Audio/sfx/"

var record: int = 0
var sonidos = {}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in ["fire", "zako_destroy", "goei_destroy", "boss_damage", "boss_destroy", "explosion",
			"credit", "start", "tractor_beam", "fighter_captured", "fighter_rescued", "extend",
			"challenging_stage_start", "name_entry"]:
		sonidos[nombre] = load(CARPETA_SFX + nombre + ".wav")
	if FileAccess.file_exists(RUTA_RECORD):
		var f = FileAccess.open(RUTA_RECORD, FileAccess.READ)
		record = f.get_32()


func play_sfx(nombre, volumen = 0.0):
	var p = AudioStreamPlayer.new()
	p.stream = sonidos[nombre]
	p.volume_db = volumen
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p


func stop_all():
	for p in get_children():
		p.queue_free()


func save_record(puntos):
	if puntos <= record:
		return false
	record = puntos
	var f = FileAccess.open(RUTA_RECORD, FileAccess.WRITE)
	f.store_32(record)
	return true
