extends Control

const SETTINGS_FILE = "user://settings.cfg"

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var back_button: Button = %BackButton
@onready var apply_button: Button = %ApplyButton
@onready var fullscreen_check: CheckButton = %FullscreenCheck

var resolutions: Array = [
	{"label": "1280 x 720 (HD)", "width": 1280, "height": 720},
	{"label": "1600 x 900 (\u9810\u8a2d)", "width": 1600, "height": 900},
	{"label": "1920 x 1080 (FHD)", "width": 1920, "height": 1080},
	{"label": "2560 x 1440 (QHD)", "width": 2560, "height": 1440},
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_populate_resolutions()
	_load_settings()

func _populate_resolutions() -> void:
	resolution_option.clear()
	for r in resolutions:
		resolution_option.add_item(r["label"])

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _on_apply_pressed() -> void:
	var idx: int = resolution_option.get_selected()
	if idx < 0 or idx >= resolutions.size():
		return
	var r: Dictionary = resolutions[idx]
	var w: int = int(r["width"])
	var h: int = int(r["height"])
	DisplayServer.window_set_size(Vector2i(w, h))
	# Center the window
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var centered_pos: Vector2i = Vector2i(
		(screen_size.x - w) / 2,
		(screen_size.y - h) / 2
	)
	DisplayServer.window_set_position(centered_pos)
	_save_settings(w, h, fullscreen_check.button_pressed)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings(width_val: int, height_val: int, fullscreen_val: bool) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "width", width_val)
	config.set_value("display", "height", height_val)
	config.set_value("display", "fullscreen", fullscreen_val)
	config.save(SETTINGS_FILE)

func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		resolution_option.select(1)
		return
	var width_val: int = int(config.get_value("display", "width", 1600))
	var height_val: int = int(config.get_value("display", "height", 900))
	var fullscreen_val: bool = config.get_value("display", "fullscreen", false)
	for i: int in range(resolutions.size()):
		var r: Dictionary = resolutions[i]
		if int(r["width"]) == width_val and int(r["height"]) == height_val:
			resolution_option.select(i)
			break
	fullscreen_check.button_pressed = fullscreen_val
	if fullscreen_val:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
