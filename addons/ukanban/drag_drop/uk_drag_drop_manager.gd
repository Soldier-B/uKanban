@tool
extends Node
class_name UKDragDropManager

var board: UKBoard

var placeholder: Panel
var drag_target: UKCard

func _input(event: InputEvent) -> void:
	if drag_target != null and event is InputEventMouseMotion:
		drag_target.position += event.relative
		UKEvents.instance.card_drag_moved.emit(drag_target, event.global_position)

func start_drag(card: UKCard) -> void:
	var card_parent := card.get_parent()
	# create placeholder
	placeholder = Panel.new()
	placeholder.custom_minimum_size = card.size
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_parent.add_child(placeholder)
	card_parent.move_child(placeholder, card.get_index())
	# reparent card so layout doesn't break and card is on top
	card.reparent(get_tree().root, true)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	# store reference to card
	drag_target = card

func move_drag(card: UKCard, global_pos: Vector2) -> void:
	var target_column = _get_target_column(global_pos)

	if target_column == null:
		return

	var target_container := target_column.get_card_container()
	var insert_index := _compute_insert_index(target_container, global_pos.y)

	_move_placeholder_if_needed(target_container, insert_index)

func end_drag(card: UKCard) -> void:
	if placeholder == null:
		return
	var card_parent = placeholder.get_parent()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	# place card in new home
	card.reparent(card_parent)
	card_parent.move_child(card, placeholder.get_index())
	# remove placeholder
	placeholder.queue_free()
	placeholder = null
	drag_target = null

func _get_target_column(global_pos: Vector2) -> UKColumn:
	for column in board.column_container.get_children():
		if column is UKColumn and column.get_global_rect().has_point(global_pos):
			return column
	return null

func _compute_insert_index(container: Control, mouse_y: float) -> int:
	var insert_index := container.get_child_count()

	for i in container.get_child_count():
		var child : Control = container.get_child(i)

		if child == placeholder:
			continue

		var rect := child.get_global_rect()
		var midpoint := rect.position.y + rect.size.y * 0.5

		if mouse_y < midpoint:
			insert_index = i
			break

	return insert_index

func _move_placeholder_if_needed(container: Control, insert_index: int) -> void:
	var current_index := -1

	if placeholder.get_parent() == container:
		current_index = placeholder.get_index()

		if current_index < insert_index:
			insert_index -= 1
	else:
		placeholder.reparent(container)

	if current_index != insert_index:
		container.move_child(placeholder, insert_index)
