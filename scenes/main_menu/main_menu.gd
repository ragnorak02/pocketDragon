extends Control
## FF7-inspired main menu with dark ornate styling.

@onready var new_game_btn: Button = $VBoxContainer/MenuPanel/MenuButtons/NewGameBtn
@onready var continue_btn: Button = $VBoxContainer/MenuPanel/MenuButtons/ContinueBtn
@onready var bestiary_btn: Button = $VBoxContainer/MenuPanel/MenuButtons/BestiaryBtn
@onready var exit_btn: Button = $VBoxContainer/MenuPanel/MenuButtons/ExitBtn
@onready var title_label: Label = $VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/TitleContainer/SubtitleLabel
@onready var version_label: Label = $VersionLabel

var _has_save := false
var bestiary_panel: Control = null

func _ready() -> void:
	_check_save_file()
	continue_btn.disabled = not _has_save
	bestiary_btn.disabled = not _has_save

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	bestiary_btn.pressed.connect(_on_bestiary)
	exit_btn.pressed.connect(_on_exit)

	new_game_btn.grab_focus()
	_animate_title()

func _check_save_file() -> void:
	_has_save = FileAccess.file_exists("user://save_game.json")

func _on_new_game() -> void:
	GameManager.change_state(GameManager.GameState.STARTER_SELECTION)
	EventBus.scene_transition_requested.emit("starter_selection")

func _on_continue() -> void:
	# Load save data
	var file := FileAccess.open("user://save_game.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		file.close()
		if err == OK:
			PartyManager.load_save_data(json.data)
			GameManager.change_state(GameManager.GameState.OVERWORLD)
			EventBus.scene_transition_requested.emit("overworld")

func _on_bestiary() -> void:
	if bestiary_panel == null:
		var BestiaryScript = load("res://ui/widgets/bestiary.gd")
		bestiary_panel = Control.new()
		bestiary_panel.set_script(BestiaryScript)
		bestiary_panel.closed.connect(func(): bestiary_panel.visible = false)
		add_child(bestiary_panel)
	bestiary_panel.show_bestiary()

func _on_exit() -> void:
	get_tree().quit()

func _animate_title() -> void:
	if title_label:
		var tween := create_tween().set_loops()
		tween.tween_property(title_label, "modulate:a", 0.7, 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(title_label, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
