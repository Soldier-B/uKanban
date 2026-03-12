@tool
extends Control
class_name UKColumnHeader

signal text_changed(new_text: String)
signal new_card_requested
signal delete_requested
signal move_left_requested
signal move_right_requested
signal edit_cancelled

enum UKColumnHeaderState {
	IDLE,
	HOVERED,
	PRESSED,
	EDITING
}

@onready var line_edit := $VBoxContainer/LineEdit
@onready var label := $VBoxContainer/Label

var _state : UKColumnHeaderState
var _menu: UKMenu
var remove_on_cancel : bool = false

var text : String:
	get:
		return text
	set(value):
		var changed := text != value

		text = value

		if line_edit:
			line_edit.text = value
		if label:
			label.text = value

		if changed:
			text_changed.emit(value)
				
var prev_text : String


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	#size_flags_horizontal = Control.SIZE_FILL
	#size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	mouse_entered.connect(_on_mouse_hovered)
	mouse_exited.connect(_on_mouse_exited)

	line_edit.gui_input.connect(_handle_editing)
	line_edit.focus_exited.connect(_on_focus_exited)
	
	line_edit.visible = false
	line_edit.text = text

	label.visible = false
	label.text = text
	
	_enter_state(UKColumnHeaderState.IDLE)

func _get_minimum_size() -> Vector2:
	var min_size = Vector2.ZERO
	
	for child in get_children():
		if child is Control and child.visible:
			var child_min = child.get_combined_minimum_size()
			min_size.x = max(min_size.x, child_min.x)
			min_size.y += child_min.y
			
	return min_size

func _on_mouse_hovered() -> void:
	if _state == UKColumnHeaderState.IDLE:
		_set_state(UKColumnHeaderState.HOVERED)

func _on_mouse_exited() -> void:
	if _state == UKColumnHeaderState.HOVERED or _state == UKColumnHeaderState.PRESSED:
		_set_state(UKColumnHeaderState.IDLE)


func _gui_input(event: InputEvent) -> void:
	match _state:
		UKColumnHeaderState.IDLE:
			_handle_idle(event)
		UKColumnHeaderState.HOVERED:
			_handle_hovered(event)
		UKColumnHeaderState.PRESSED:
			_handle_pressed(event)

func _handle_idle(event : InputEvent) -> void:
	pass

func _handle_hovered(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		_set_state(UKColumnHeaderState.PRESSED)

func _handle_pressed(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and not event.pressed:
		_set_state(UKColumnHeaderState.EDITING)

func _handle_editing(event : InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			if remove_on_cancel:
				edit_cancelled.emit()
				line_edit.release_focus.call_deferred()
				return
			text = prev_text
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			text = line_edit.text
		else:
			return

		line_edit.release_focus.call_deferred()

func _on_focus_exited() -> void:
	text = line_edit.text
	if remove_on_cancel and text.is_empty():
		edit_cancelled.emit()
		return
	_set_state(UKColumnHeaderState.IDLE)

func _set_state(state : UKColumnHeaderState) -> void:
	if _state == state:
		return

	_exit_state(_state)
	_state = state
	_enter_state(_state)

func _enter_state(state : UKColumnHeaderState) -> void:
	match state:
		UKColumnHeaderState.IDLE:
			label.visible = true
			if get_global_rect().has_point(get_global_mouse_position()):
				_set_state.call_deferred(UKColumnHeaderState.HOVERED)
		UKColumnHeaderState.HOVERED:
			UKEvents.instance.show_menu.emit(self)
			# Menu reparents itself to self when show_menu is emitted
			_menu = UKMenu.find_in(self)
			if _menu:
				if not _menu.add_pressed.is_connected(_on_menu_add_pressed):
					_menu.add_pressed.connect(_on_menu_add_pressed)
				if not _menu.delete_pressed.is_connected(_on_menu_delete_pressed):
					_menu.delete_pressed.connect(_on_menu_delete_pressed)
				if not _menu.move_left_pressed.is_connected(_on_menu_move_left_pressed):
					_menu.move_left_pressed.connect(_on_menu_move_left_pressed)
				if not _menu.move_right_pressed.is_connected(_on_menu_move_right_pressed):
					_menu.move_right_pressed.connect(_on_menu_move_right_pressed)
		UKColumnHeaderState.PRESSED:
			pass
		UKColumnHeaderState.EDITING:
			prev_text = text
			label.visible = false
			line_edit.visible = true
			line_edit.caret_column = line_edit.text.length()
			line_edit.grab_focus.call_deferred()

func _exit_state(state : UKColumnHeaderState) -> void:
	match state:
		UKColumnHeaderState.IDLE:
			pass
		UKColumnHeaderState.HOVERED:
			if _menu:
				if _menu.add_pressed.is_connected(_on_menu_add_pressed):
					_menu.add_pressed.disconnect(_on_menu_add_pressed)
				if _menu.delete_pressed.is_connected(_on_menu_delete_pressed):
					_menu.delete_pressed.disconnect(_on_menu_delete_pressed)
				if _menu.move_left_pressed.is_connected(_on_menu_move_left_pressed):
					_menu.move_left_pressed.disconnect(_on_menu_move_left_pressed)
				if _menu.move_right_pressed.is_connected(_on_menu_move_right_pressed):
					_menu.move_right_pressed.disconnect(_on_menu_move_right_pressed)
			UKEvents.instance.hide_menu.emit(self)
		UKColumnHeaderState.PRESSED:
			pass
		UKColumnHeaderState.EDITING:
			line_edit.visible = false
	pass

func _on_menu_add_pressed() -> void:
	add_card()

func _on_menu_delete_pressed() -> void:
	remove_column()

func add_card() -> void:
	new_card_requested.emit()

func remove_column() -> void:
	delete_requested.emit()

func _on_menu_move_left_pressed() -> void:
	if _menu:
		_menu.hide()
	move_left_requested.emit()

func _on_menu_move_right_pressed() -> void:
	if _menu:
		_menu.hide()
	move_right_requested.emit()

func edit(should_remove_on_cancel: bool = false) -> void:
	remove_on_cancel = should_remove_on_cancel
	_set_state(UKColumnHeaderState.EDITING)

func cleanup() -> void:
	# Disable mouse input to prevent further state changes
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Disconnect mouse signals
	mouse_entered.disconnect(_on_mouse_hovered)
	mouse_exited.disconnect(_on_mouse_exited)
	# Reset to idle state
	_set_state(UKColumnHeaderState.IDLE)
