@tool
extends Node
class_name UKEvents

static var instance: UKEvents

# UI state
signal show_menu(control : Control)
signal hide_menu(control : Control)

# Data persistence triggers
signal column_updated(column : UKColumn)
signal card_updated(card : UKCard)

# Card drag/drop
signal card_drag_started(card : UKCard)
signal card_drag_moved(card : UKCard, global_pos : Vector2)
signal card_drag_ended(card : UKCard)

# Column-card communication
signal column_new_card_sibling(card : UKCard, offset : int)

# Column management
signal column_move_left_requested(column : UKColumn)
signal column_move_right_requested(column : UKColumn)
