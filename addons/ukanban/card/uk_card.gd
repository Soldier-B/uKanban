@tool
extends TextEdit
class_name UKCard

enum UKCardState {
	IDLE,
	HOVERED,
	PRESSED,
	CLICK,
	EDITING,
	DRAGGING
}

const DRAG_HOLD_TIME := 0.5  # seconds before a held press initiates drag

var _state : UKCardState
var _press_timer : float = 0.0
var prev_text : String
var remove_on_cancel : bool = false
var _menu: UKMenu

func _ready() -> void:
	# configure text edit properties
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	scroll_fit_content_height = true
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_theme_constant_override("line_spacing", 0)
	add_theme_constant_override("wrap_offset", 0)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_exited.connect(_on_focus_exited)
	
	_enter_state(UKCardState.IDLE)


func _gui_input(event: InputEvent) -> void:
	match _state:
		UKCardState.IDLE:
			pass
		UKCardState.HOVERED:
			_handle_hovered(event)
		UKCardState.PRESSED:
			_handle_pressed(event)
		UKCardState.CLICK:
			_handle_click(event)
		UKCardState.EDITING:
			_handle_editing(event)
		UKCardState.DRAGGING:
			_handle_dragging(event)

func _on_mouse_entered() -> void:
	if _state == UKCardState.IDLE:
		_set_state(UKCardState.HOVERED)

func _on_mouse_exited() -> void:
	if _state == UKCardState.HOVERED or _state == UKCardState.PRESSED:
		_set_state(UKCardState.IDLE)

func _on_focus_exited() -> void:
	if text != prev_text:
		UKEvents.instance.card_updated.emit(self)
	elif remove_on_cancel:
		queue_free()
		return
		
	_set_state(UKCardState.IDLE)

func _process(delta: float) -> void:
	if _state == UKCardState.PRESSED:
		_press_timer += delta
		if _press_timer >= DRAG_HOLD_TIME:
			_set_state(UKCardState.DRAGGING)

func _set_state(state : UKCardState) -> void:
	if _state == state:
		return
	
	_exit_state(_state)
	_state = state
	_enter_state(_state)

func _enter_state(state : UKCardState) -> void: 
	#text = UKCardState.find_key(state)
	match state:
		UKCardState.IDLE:
			focus_mode = Control.FOCUS_NONE
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			selecting_enabled = false
			context_menu_enabled = false
			if get_global_rect().has_point(get_global_mouse_position()):
				_set_state.call_deferred(UKCardState.HOVERED)
		UKCardState.HOVERED:
			_press_timer = 0.0
			UKEvents.instance.show_menu.emit(self)
			# Menu reparents itself to self when show_menu is emitted
			_menu = UKMenu.find_in(self)
			if _menu:
				if not _menu.delete_pressed.is_connected(_on_menu_delete_pressed):
					_menu.delete_pressed.connect(_on_menu_delete_pressed)
			
		UKCardState.PRESSED:
			pass
			
		UKCardState.CLICK:
			pass
			
		UKCardState.EDITING:
			focus_mode = Control.FOCUS_ALL
			prev_text = text
			selecting_enabled = true
			context_menu_enabled = true
			mouse_default_cursor_shape = Control.CURSOR_IBEAM
			_set_caret_to_end()
			grab_focus.call_deferred()
			
		UKCardState.DRAGGING:
			UKEvents.instance.card_drag_started.emit(self)
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			modulate = get_theme_color("accent_color", "Editor")

func _exit_state(state : UKCardState) -> void:
	match state:
		UKCardState.IDLE:
			pass
			
		UKCardState.HOVERED:
			if _menu:
				if _menu.delete_pressed.is_connected(_on_menu_delete_pressed):
					_menu.delete_pressed.disconnect(_on_menu_delete_pressed)
			UKEvents.instance.hide_menu.emit(self)
			
		UKCardState.PRESSED:
			pass
			
		UKCardState.CLICK:
			pass
			
		UKCardState.EDITING:
			pass
			
		UKCardState.DRAGGING:
			modulate = Color.WHITE

func _handle_hovered(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == 1 and e.pressed:
			accept_event()
			_set_state(UKCardState.DRAGGING if e.alt_pressed else UKCardState.PRESSED)

func _handle_pressed(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == 1 and not e.pressed:
			_set_state(UKCardState.CLICK if _press_timer < DRAG_HOLD_TIME else UKCardState.DRAGGING)

func _handle_click(event : InputEvent) -> void:
	_set_state(UKCardState.EDITING)

func _handle_editing(event : InputEvent) -> void:
	if event is InputEventKey:
		var e:= event as InputEventKey
		 
		if e.keycode == KEY_ESCAPE:
			if remove_on_cancel:
				queue_free()
				return
			text = prev_text
		elif e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
			if e.ctrl_pressed or e.shift_pressed:
				if e.pressed:
					accept_event()
					return
				if e.ctrl_pressed:
					# todo: create new card above or below in column
					UKEvents.instance.column_new_card_sibling.emit(self, 0 if e.shift_pressed else 1)
			else:
				return
		elif e.keycode == KEY_TAB:
			# todo: focus next or previous card
			if e.pressed:
				accept_event()
				return
			
			var parent = get_parent()
			var next_index = get_index() + (-1 if e.shift_pressed else 1)
			
			if next_index < 0 or next_index >= parent.get_child_count():
				accept_event()
				return
			
			var next := parent.get_child(next_index) as UKCard
			
			next.edit()
		else: 
			return

		remove_on_cancel = false
		accept_event()
		_set_state(UKCardState.IDLE)
		
		if text != prev_text:
			UKEvents.instance.card_updated.emit(self)

func _handle_dragging(event : InputEvent) -> void:
	if event.button_mask & 1 == 0:
		UKEvents.instance.card_drag_ended.emit(self)
		UKEvents.instance.card_updated.emit(self)
		_set_state(UKCardState.IDLE)

func edit() -> void:
	remove_on_cancel = true
	_set_state(UKCardState.EDITING)
	

func _on_menu_delete_pressed() -> void:
	remove_card()

func remove_card() -> void:
	UKEvents.instance.card_updated.emit(self)
	queue_free()

func _set_caret_to_end() -> void:
	var last_line = get_line_count() - 1
	var line_length = get_line(last_line).length()
	set_caret_line(last_line)
	set_caret_column(line_length)
	center_viewport_to_caret()
