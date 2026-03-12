@tool
extends Node
class_name UKFile

const FILE_PATH = "res://.kanban"
const DEFAULT_DATA : Variant = [ { "name": "Todos", "cards": []}]

var save_timer : Timer
var _pending_columns: Array[UKColumn] = []

func _ready() -> void:
	save_timer = Timer.new()
	save_timer.wait_time = 0.2
	save_timer.one_shot = true
	save_timer.timeout.connect(_save)

	add_child(save_timer)

func queue_save(columns: Array[UKColumn]) -> void:
	_pending_columns = columns
	save_timer.stop()
	save_timer.start()

func _save() -> void:
	if _pending_columns.is_empty():
		return
	var data = _read_data(_pending_columns)
	save_data(data)

func save_data(data: Variant) -> void:
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)

	if f == null:
		push_error("Kanban: cannot write %s" % FILE_PATH)
		return

	f.store_string(JSON.stringify(data))
	f.close()

func load() -> Variant:
	if not FileAccess.file_exists(FILE_PATH):
		save_data(DEFAULT_DATA)
	
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	
	if f == null:
		push_error("Kanban: cannot read %s" % FILE_PATH)
		return DEFAULT_DATA
	
	var data = JSON.parse_string(f.get_as_text())
	
	if data == null:
		data = DEFAULT_DATA
		
	return data

func _read_data(columns: Array[UKColumn]) -> Variant:
	var data = []

	for column in columns:
		# Skip invalid/freed columns
		if not is_instance_valid(column):
			continue

		var cards = column.get_card_container().get_children()
		var card_data : Array[String] = []

		for card in cards:
			card_data.append(card.text)

		data.append({ "name": column.text, "cards": card_data })

	return data
