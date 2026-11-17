extends Control
class_name Menu

## Base for menus. Put the layout (e.g. a VBoxContainer) inside it.
## Focuses first_button whenever the menu appears, so keyboard and gamepad
## always start on a button.

## Emitted by close(), so whoever opened the menu can take focus back.
signal menu_closed

## Gets focus whenever this menu becomes visible.
@export var first_button : Control
## What is hidden while a sub-menu is open (see open_sub_menu). Leave empty to
## hide this whole menu; set it to the panel when sub-menus are children of
## this menu, otherwise they would be hidden too.
@export var content : Control

## The sub-menu that is open right now, if any.
var current_sub_menu : Menu


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if is_visible_in_tree():
		focus_first_button.call_deferred()


func focus_first_button() -> void:
	if first_button and first_button.is_visible_in_tree():
		first_button.grab_focus()


## Hides the menu and tells whoever opened it.
func close() -> void:
	hide()
	menu_closed.emit()


## Opens a sub-menu (options, quit confirmation...) in place of this one, so
## only one is visible at a time. When the sub-menu closes, this menu comes
## back with its first button focused.
func open_sub_menu(sub_menu : Menu) -> void:
	close_sub_menu()
	current_sub_menu = sub_menu
	sub_menu.menu_closed.connect(_on_sub_menu_closed, CONNECT_ONE_SHOT)
	_get_content().hide()
	sub_menu.show()


## Closes the open sub-menu without it emitting menu_closed, e.g. when the
## whole menu is reset, and shows this menu again.
func close_sub_menu() -> void:
	if current_sub_menu:
		if current_sub_menu.menu_closed.is_connected(_on_sub_menu_closed):
			current_sub_menu.menu_closed.disconnect(_on_sub_menu_closed)
		current_sub_menu.hide()
		current_sub_menu = null
	_get_content().show()


## Goes back one step: closes the deepest open sub-menu. Returns false when
## no sub-menu is open, so the caller can decide what Esc does then.
func back() -> bool:
	if not current_sub_menu:
		return false
	if not current_sub_menu.back():
		current_sub_menu.close()
	return true


## Esc goes back to the previous menu while a sub-menu is open.
func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("esc") and is_visible_in_tree() and back():
		get_viewport().set_input_as_handled()


func _on_sub_menu_closed() -> void:
	current_sub_menu = null
	_get_content().show()
	focus_first_button()


func _get_content() -> Control:
	return content if content else self


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		# Deferred so children that are shown in the same frame are visible
		# (and focusable) by the time we grab focus.
		focus_first_button.call_deferred()
