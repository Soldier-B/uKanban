@tool
extends ScrollContainer
class_name UKBoard

var ukcolumn_res : Resource

@onready var column_container : HBoxContainer = $Columns
@onready var add_column_button : Button = $Columns/Container/Button
@onready var file : UKFile = $File

var drag_drop_manager: UKDragDropManager
var _help_dialog: AcceptDialog

func _build_help_text() -> String:
	var a := EditorInterface.get_editor_theme().get_color("accent_color", "Editor").to_html(false)
	return """[font_size=18][b][color=#{a}]Cards[/color][/b][/font_size]
[table=2]
[cell ratio=0.45][code]Click[/code][/cell][cell]Enter edit mode[/cell]
[cell ratio=0.45][code]Escape[/code][/cell][cell]Cancel (removes card if new)[/cell]
[cell ratio=0.45][code]Shift+Enter[/code][/cell][cell]Confirm edit[/cell]
[cell ratio=0.45][code]Ctrl+Enter[/code][/cell][cell]Add card below[/cell]
[cell ratio=0.45][code]Shift+Ctrl+Enter[/code][/cell][cell]Add card above[/cell]
[cell ratio=0.45][code]Tab[/code][/cell][cell]Focus next card[/cell]
[cell ratio=0.45][code]Shift+Tab[/code][/cell][cell]Focus previous card[/cell]
[cell ratio=0.45][code]Hold + Drag[/code][/cell][cell]Reorder card[/cell]
[cell ratio=0.45][code]Alt+Click[/code][/cell][cell]Start drag immediately[/cell]
[/table]

[font_size=18][b][color=#{a}]Columns[/color][/b][/font_size]
[table=2]
[cell ratio=0.45][code]Click header[/code][/cell][cell]Rename column[/cell]
[cell ratio=0.45][code]Escape[/code][/cell][cell]Cancel (removes column if new)[/cell]
[cell ratio=0.45][code]Enter[/code][/cell][cell]Confirm rename[/cell]
[/table]

[font_size=18][b][color=#{a}]Menu[/color][/b][/font_size]
[indent]Hover over any card or column header.[/indent]
[table=2]
[cell ratio=0.45][code]+[/code][/cell][cell]Add card to column[/cell]
[cell ratio=0.45][code]×[/code][/cell][cell]Delete card or column[/cell]
[cell ratio=0.45][code]‹ / ›[/code][/cell][cell]Move column left or right[/cell]
[/table]

[i]Note: Delete is disabled when only one column remains.[/i]
""".format({"a": a})

func _ready() -> void:
	ukcolumn_res = preload("res://addons/ukanban/column/uk_column.tscn")

	# Initialize drag/drop manager
	drag_drop_manager = UKDragDropManager.new()
	add_child(drag_drop_manager)
	drag_drop_manager.board = self

	UKEvents.instance.column_updated.connect(_on_board_data_changed)
	UKEvents.instance.card_updated.connect(_on_board_data_changed)

	UKEvents.instance.card_drag_started.connect(drag_drop_manager.start_drag)
	UKEvents.instance.card_drag_moved.connect(drag_drop_manager.move_drag)
	UKEvents.instance.card_drag_ended.connect(drag_drop_manager.end_drag)

	UKEvents.instance.column_move_left_requested.connect(_on_column_move_left_requested)
	UKEvents.instance.column_move_right_requested.connect(_on_column_move_right_requested)

	add_column_button.pressed.connect(_on_add_column_pressed)

	if Engine.is_editor_hint():
		add_column_button.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")

	# Build help dialog
	_help_dialog = AcceptDialog.new()
	_help_dialog.title = "µKanban Help"
	_help_dialog.min_size = Vector2(520, 480)
	_help_dialog.exclusive = false

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = true
	label.fit_content = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.text = _build_help_text()

	margin.add_child(label)
	_help_dialog.add_child(margin)
	add_child(_help_dialog)

	_load_from_file()

func _load_from_file() -> void:
	var data = file.load()
	
	while column_container.get_child_count() > 1:
		column_container.get_child(0).queue_free()
	
	for dcolumn in data:
		var column : UKColumn = ukcolumn_res.instantiate()
		column.text = dcolumn["name"]
		_append_column(column)

		for dcard in dcolumn["cards"]:
			var card = UKCard.new()
			card.text = dcard
			column.add_card(card)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			get_viewport().gui_release_focus()

func _on_board_data_changed(_sender) -> void:
	file.queue_save(get_columns())

func get_columns() -> Array[UKColumn]:
	var children : Array[UKColumn] = []
	children.assign(column_container.find_children("*", "UKColumn", false, false))
	return children

func _on_column_move_left_requested(column: UKColumn) -> void:
	var col_idx = column.get_index()

	# Find the previous column (skip VSeps)
	var prev_col_idx = -1
	for i in range(col_idx - 1, -1, -1):
		if column_container.get_child(i) is UKColumn:
			prev_col_idx = i
			break

	if prev_col_idx >= 0:
		var prev_col = column_container.get_child(prev_col_idx)
		# Swap their positions
		column_container.move_child(column, prev_col_idx)
		column_container.move_child(prev_col, col_idx)

		UKEvents.instance.column_updated.emit(column)

func _on_column_move_right_requested(column: UKColumn) -> void:
	var col_idx = column.get_index()
	var child_count = column_container.get_child_count()

	# Find the next column (skip VSeps)
	var next_col_idx = -1
	for i in range(col_idx + 1, child_count):
		if column_container.get_child(i) is UKColumn:
			next_col_idx = i
			break

	if next_col_idx >= 0:
		var next_col = column_container.get_child(next_col_idx)
		# Swap their positions
		column_container.move_child(column, next_col_idx)
		column_container.move_child(next_col, col_idx)

		UKEvents.instance.column_updated.emit(column)

func _append_column(column: UKColumn) -> void:
	column_container.add_child(column)
	column_container.move_child(column, column_container.get_child_count() - 2)

	var vsep := VSeparator.new()
	vsep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_container.add_child(vsep)
	column_container.move_child(vsep, column.get_index() + 1)

func _on_add_column_pressed() -> void:
	var column : UKColumn = ukcolumn_res.instantiate()
	_append_column(column)
	column.edit()

func show_help() -> void:
	_help_dialog.popup_centered()
