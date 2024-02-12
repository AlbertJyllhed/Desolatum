extends Node

signal dialogue_finished

var text_box_scene = preload("res://ui/text_box.tscn")

var dialogue_lines : Array[String] = []
var current_line_index : int = 0

var text_box : TextBox
var text_box_position : Vector2

var is_dialogue_active : bool = false
var can_advance_line : bool = false


func start_dialogue(position : Vector2, lines : Array[String]):
	if is_dialogue_active:
		return
	
	dialogue_lines = lines
	text_box_position = position
	show_text_box()
	
	is_dialogue_active = true


func show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished.connect(on_text_box_finished)
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	foreground_layer.add_child(text_box)
	text_box.global_position = text_box_position
	text_box.display_text(dialogue_lines[current_line_index])
	can_advance_line = false


func on_text_box_finished():
	can_advance_line = true


func _unhandled_input(event):
	if event.is_action_pressed("attack") and is_dialogue_active and can_advance_line:
		text_box.queue_free()
		current_line_index += 1
		if current_line_index >= dialogue_lines.size():
			is_dialogue_active = false
			current_line_index = 0
			dialogue_finished.emit()
			return
		
		show_text_box()
