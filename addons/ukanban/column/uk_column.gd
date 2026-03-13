@tool
extends Control
class_name UKColumn

@onready var cards_layout = $ColumnLayout/CardsContainer/CardsPadding/CardsLayout
@onready var header := $ColumnLayout/Header
@onready var scroll := $ColumnLayout/CardsContainer

var prev_text : String
var remove_on_cancel : bool = false

var text : String:
	get:
		return text
	set(value):
		if text != value:
			text = value
			if header:
				header.text = text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	header.text = text

	# Connect directly to header's signals
	header.text_changed.connect(_on_header_text_changed)
	header.new_card_requested.connect(_on_header_new_card_requested)
	header.delete_requested.connect(_on_header_delete_requested)
	header.move_left_requested.connect(_on_header_move_left_requested)
	header.move_right_requested.connect(_on_header_move_right_requested)
	header.edit_cancelled.connect(_on_header_edit_cancelled)

	UKEvents.instance.column_new_card_sibling.connect(_on_column_new_card_sibling)

func _on_header_text_changed(new_text: String) -> void:
	text = new_text
	# Only save if this isn't a new column being cancelled, or text has actually changed
	if not remove_on_cancel or text != prev_text:
		UKEvents.instance.column_updated.emit(self)
	remove_on_cancel = false

func _on_header_new_card_requested() -> void:
	var card = UKCard.new()
	add_card(card)
	_scroll_to_end.call_deferred()
	card.edit.call_deferred()

func _on_header_delete_requested() -> void:
	_remove_vseparator()

	# Reparent menu immediately to prevent it from being stuck with deleted column
	var menu = UKMenu.find_in(header)
	if menu:
		menu.return_to_default_parent()

	# Defer the rest to avoid orphaned column responding to events
	_cleanup_and_delete.call_deferred()
	UKEvents.instance.column_updated.emit(self)
	queue_free()

func _on_header_edit_cancelled() -> void:
	if remove_on_cancel:
		_remove_vseparator()
		# Reparent menu immediately
		var menu = UKMenu.find_in(header)
		if menu:
			menu.return_to_default_parent()
		# Defer cleanup to prevent orphaned column from responding to events
		_cleanup_and_delete.call_deferred()
		queue_free()

func _cleanup_and_delete() -> void:
	# Cleanup header to prevent orphaned signals
	if header:
		header.cleanup()

	# Remove from tree before deletion so it's not included in saved data
	get_parent().remove_child(self)

func _remove_vseparator() -> void:
	# Remove the VSeparator that follows this column
	var parent = get_parent()
	var next_index = get_index() + 1
	if next_index < parent.get_child_count():
		var next_sibling = parent.get_child(next_index)
		if next_sibling is VSeparator:
			next_sibling.queue_free()

func _on_column_new_card_sibling(_card : UKCard, offset : int) -> void:
	if not is_ancestor_of(_card):
		return

	var card = UKCard.new()
	add_card(card)
	cards_layout.move_child(card, _card.get_index() + offset)
	_scroll_to_end.call_deferred()
	card.edit.call_deferred()

func _on_header_move_left_requested() -> void:
	UKEvents.instance.column_move_left_requested.emit(self)

func _on_header_move_right_requested() -> void:
	UKEvents.instance.column_move_right_requested.emit(self)

func edit() -> void:
	remove_on_cancel = true
	prev_text = text
	header.edit(true)

func get_card_container() -> VBoxContainer:
	return cards_layout

func add_card(card : UKCard) -> void:
	cards_layout.add_child(card)

func _scroll_to_end() -> void:
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
