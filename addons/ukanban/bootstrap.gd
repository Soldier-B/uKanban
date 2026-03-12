@tool
extends EditorPlugin

var uk_board : UKBoard
var _events : UKEvents

func _enter_tree() -> void:
	_events = UKEvents.new()
	UKEvents.instance = _events

	uk_board = preload("res://addons/ukanban/board/uk_board.tscn").instantiate()

	EditorInterface.get_editor_main_screen().add_child(uk_board)

	uk_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	uk_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	uk_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	uk_board.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	uk_board.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	uk_board.hide()

	add_tool_menu_item("µKanban Help", _on_help_pressed)

func _exit_tree() -> void:
	remove_tool_menu_item("µKanban Help")
	if uk_board:
		uk_board.queue_free()
	UKEvents.instance = null
	if _events:
		_events.free()

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "µKanban"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Panels2Alt", "EditorIcons")

func _make_visible(visible: bool) -> void:
	if uk_board:
		uk_board.visible = visible

func _on_help_pressed() -> void:
	if uk_board:
		uk_board.show_help()
