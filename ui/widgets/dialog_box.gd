extends Control
## Typewriter dialog box displayed at the bottom of the screen.
## Press E or Space to advance/skip. Closes after last line.

signal dialog_closed()

var _speaker: String = ""
var _lines: PackedStringArray = []
var _current_line_index: int = 0
var _displayed_chars: int = 0
var _chars_per_second: float = 30.0
var _char_timer: float = 0.0
var _line_complete := false
var _active := false

var _panel: PanelContainer
var _speaker_label: Label
var _text_label: Label
var _advance_hint: Label

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Full-screen transparent overlay to block clicks
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Panel at bottom of screen
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -160
	_panel.offset_bottom = -20
	_panel.offset_left = 100
	_panel.offset_right = -100

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style.border_color = Color(0.4, 0.35, 0.6, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Speaker name
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 18)
	_speaker_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	vbox.add_child(_speaker_label)

	# Dialog text
	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 20)
	_text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_text_label)

	# Advance hint
	_advance_hint = Label.new()
	_advance_hint.add_theme_font_size_override("font_size", 14)
	_advance_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.7))
	_advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_hint.text = "[E] / [Space] to continue"
	vbox.add_child(_advance_hint)

	_panel.add_child(vbox)
	add_child(_panel)

func start_dialog(speaker: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return

	_speaker = speaker
	_lines = lines
	_current_line_index = 0
	_active = true
	visible = true

	_speaker_label.text = _speaker
	_start_line()

	# Freeze player movement
	GameManager.change_state(GameManager.GameState.CUTSCENE)

func _start_line() -> void:
	_displayed_chars = 0
	_char_timer = 0.0
	_line_complete = false
	_text_label.text = ""
	_advance_hint.visible = false

func _process(delta: float) -> void:
	if not _active:
		return

	if _line_complete:
		return

	var full_text: String = _lines[_current_line_index]
	_char_timer += delta * _chars_per_second
	var new_chars := int(_char_timer)
	if new_chars > _displayed_chars:
		_displayed_chars = mini(new_chars, full_text.length())
		_text_label.text = full_text.substr(0, _displayed_chars)

	if _displayed_chars >= full_text.length():
		_line_complete = true
		_advance_hint.visible = true

func _input(event: InputEvent) -> void:
	if not _active:
		return

	var advance := event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not advance:
		return

	get_viewport().set_input_as_handled()

	if not _line_complete:
		# Skip to end of current line
		var full_text: String = _lines[_current_line_index]
		_displayed_chars = full_text.length()
		_text_label.text = full_text
		_line_complete = true
		_advance_hint.visible = true
		return

	# Advance to next line
	_current_line_index += 1
	if _current_line_index >= _lines.size():
		_close_dialog()
		return

	_start_line()

func _close_dialog() -> void:
	_active = false
	visible = false
	_text_label.text = ""
	_speaker_label.text = ""

	# Restore gameplay
	GameManager.change_state(GameManager.GameState.OVERWORLD)
	dialog_closed.emit()
	EventBus.dialog_finished.emit()
