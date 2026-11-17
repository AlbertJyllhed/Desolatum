extends Button

@export_group("Focus Cursor")
## Draws a blinking block right after the text while the button has focus,
## like a terminal cursor. Buttons without text never show it.
@export var cursor_enabled : bool = true
## Seconds the cursor stays on, and then off.
@export var cursor_blink_time : float = 0.5
## Extra empty pixels before the cursor, on top of the font's normal spacing
## between letters (at 0 it sits where the next letter would go).
@export var cursor_gap : int = 0
## Cursor width in pixels. 0 = the width of an "M" in the button's font.
@export var cursor_width : int = 0
## Cursor height in pixels. 0 = the height of an "M" in the button's font.
@export var cursor_height : int = 0

var _blink_elapsed : float = 0.0
var _cursor_on : bool = true


func _ready():
	mouse_entered.connect(on_mouse_entered)
	focus_entered.connect(_on_focus_changed)
	focus_exited.connect(_on_focus_changed)
	set_process(false)


func on_mouse_entered():
	grab_focus()


## Restart the blink fully visible whenever focus arrives, so you always see
## where you are. Only process while focused.
func _on_focus_changed() -> void:
	_blink_elapsed = 0.0
	_cursor_on = true
	set_process(has_focus() and cursor_enabled)
	queue_redraw()


func _process(delta : float) -> void:
	_blink_elapsed += delta
	var on : bool = fmod(_blink_elapsed, cursor_blink_time * 2.0) < cursor_blink_time
	if on != _cursor_on:
		_cursor_on = on
		queue_redraw()


func _draw() -> void:
	if not cursor_enabled or not _cursor_on or not has_focus() or text.is_empty():
		return

	var font : Font = get_theme_font(&"font")
	var font_size : int = get_theme_font_size(&"font_size")
	var text_width : float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var style : StyleBox = get_theme_stylebox(&"normal")
	var left : float = style.get_margin(SIDE_LEFT)
	var right : float = style.get_margin(SIDE_RIGHT)

	# Where the text starts, following the button's alignment.
	var text_x : float = left
	match alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			text_x = left + (size.x - left - right - text_width) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			text_x = size.x - right - text_width

	# Button centers the text line vertically; the cursor sits on its baseline.
	var ascent : float = font.get_ascent(font_size)
	var line_height : float = ascent + font.get_descent(font_size)
	var baseline : float = (size.y - line_height) / 2.0 + ascent

	# Default size: the drawn "M" glyph, so the block matches the capitals.
	var capital : Vector2 = _get_capital_size(font, font_size)
	var width : float = cursor_width if cursor_width > 0 else capital.x
	var height : float = cursor_height if cursor_height > 0 else capital.y

	var rect := Rect2(
		roundf(text_x + text_width + cursor_gap),
		roundf(baseline - height),
		roundf(width),
		roundf(height))
	draw_rect(rect, _get_current_font_color())


## Pixel size of a capital "M" in this font (its visible glyph, not the line
## height, which in pixel fonts is often much taller than the letters).
func _get_capital_size(font : Font, font_size : int) -> Vector2:
	var rids : Array[RID] = font.get_rids()
	if not rids.is_empty():
		var server : TextServer = TextServerManager.get_primary_interface()
		var size_key := Vector2i(font_size, 0)
		var glyph : int = server.font_get_glyph_index(rids[0], font_size, "M".unicode_at(0), 0)
		var glyph_size : Vector2 = server.font_get_glyph_size(rids[0], size_key, glyph)
		# The glyph's texture has 1 px of padding on every side.
		glyph_size -= Vector2(2.0, 2.0)
		if glyph_size.x > 0.0 and glyph_size.y > 0.0:
			return glyph_size
	# Fallback: the advance width and the ascent.
	return Vector2(font.get_char_size("M".unicode_at(0), font_size).x, font.get_ascent(font_size))


## The color the button is drawing its text in right now.
func _get_current_font_color() -> Color:
	match get_draw_mode():
		DRAW_HOVER:
			return get_theme_color(&"font_hover_color")
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			return get_theme_color(&"font_pressed_color")
		DRAW_DISABLED:
			return get_theme_color(&"font_disabled_color")
	return get_theme_color(&"font_focus_color")
