@tool
extends Panel
class_name UKMenu

signal delete_pressed
signal add_pressed
signal move_left_pressed
signal move_right_pressed

@onready var container : HBoxContainer = $HBoxContainer
@onready var handle : Button = $HBoxContainer/Handle
@onready var add : Button = $HBoxContainer/Add
@onready var delete : Button = $HBoxContainer/Delete
@onready var move_left : Button = $HBoxContainer/MoveLeft
@onready var move_right : Button = $HBoxContainer/MoveRight

var _default_parent : Node
var _current_target : Node

func _ready() -> void:
	_default_parent = get_parent()
	
	if Engine.is_editor_hint():
		visible = false
		
		var theme := EditorInterface.get_editor_theme()

		handle.icon = theme.get_icon("GuiTabMenuHl", "EditorIcons")
		add.icon = theme.get_icon("Add", "EditorIcons")
		delete.icon = theme.get_icon("Remove", "EditorIcons")
		move_left.icon = theme.get_icon("PagePrevious", "EditorIcons")
		move_right.icon = theme.get_icon("PageNext", "EditorIcons")
	
	UKEvents.instance.show_menu.connect(_on_show_menu)
	UKEvents.instance.hide_menu.connect(_on_hide_menu)
	
	delete.pressed.connect(_on_delete_pressed)
	add.pressed.connect(_on_add_pressed)
	move_left.pressed.connect(_on_move_left_pressed)
	move_right.pressed.connect(_on_move_right_pressed)
	
	handle.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if container.get_global_rect().has_point(event.global_position):
			accept_event()

func _on_show_menu(target : Node) -> void:
	_current_target = target

	# Show/hide buttons based on target type
	var is_card = target is UKCard
	add.visible = not is_card
	delete.visible = true
	move_left.visible = not is_card
	move_right.visible = not is_card

	# Disable move buttons based on column position
	if target is UKColumnHeader:
		var column = _get_column_from_header(target)
		if column:
			var columns_container = column.get_parent()
			if columns_container:
				var column_index = _get_column_index(column, columns_container)
				var column_count = _count_columns(columns_container)
				move_left.disabled = column_index == 0
				move_right.disabled = column_index == column_count - 1
				# Disable delete if only one column remains
				delete.disabled = column_count == 1

	size = container.get_combined_minimum_size()
	container.position = Vector2(size.x - container.size.x, 0)
	reparent(target)

	position = Vector2(target.size.x - size.x, 0)
	z_index = 100

	visible = true

func _on_hide_menu(target : Control) -> void:
	# if the control trying to hide the menu isn't currently active then ignore it
	if get_parent() != target:
		return
	# hide the menu and reparent if back to it's original
	visible = false
	reparent(_default_parent)

func _on_delete_pressed() -> void:
	delete_pressed.emit()

func _on_add_pressed() -> void:
	add_pressed.emit()

func _on_move_left_pressed() -> void:
	move_left_pressed.emit()

func _on_move_right_pressed() -> void:
	move_right_pressed.emit()

static func find_in(node: Node) -> UKMenu:
	for child in node.get_children():
		if child is UKMenu:
			return child
	return null

func return_to_default_parent() -> void:
	if _default_parent:
		reparent(_default_parent)
		visible = false

func _get_column_from_header(header: UKColumnHeader) -> UKColumn:
	# Header is at: ColumnLayout/Header, so Header's parent's parent is the Column
	var column_layout = header.get_parent()
	if column_layout:
		return column_layout.get_parent() as UKColumn
	return null

func _get_column_index(column: UKColumn, columns_container: Control) -> int:
	var index = 0
	for child in columns_container.get_children():
		if child is UKColumn:
			if child == column:
				return index
			index += 1
	return -1

func _count_columns(columns_container: Control) -> int:
	var count = 0
	for child in columns_container.get_children():
		if child is UKColumn:
			count += 1
	return count
