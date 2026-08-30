## Home screen — main menu with Start, Select, Shop, Settings, Quit buttons.
## Applies saved resolution on startup. Dynamic centered layout.
extends Node2D

@onready var start_button: Button = %StartButton
@onready var select_button: Button = %SelectButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var dialog: AcceptDialog = %Dialog
@onready var background: ColorRect = $Background
@onready var title: Label = $Title
@onready var button_container: VBoxContainer = $ButtonContainer

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	select_button.pressed.connect(_on_select_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	get_viewport().size_changed.connect(_on_resize)
	_apply_saved_settings()
	_apply_layout()

func _apply_saved_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	var w: int = int(config.get_value("display", "width", 1600))
	var h: int = int(config.get_value("display", "height", 900))
	var fullscreen: bool = config.get_value("display", "fullscreen", false)
	DisplayServer.window_set_size(Vector2i(w, h))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_resize() -> void:
	_apply_layout()

func _apply_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	# Background fills entire viewport
	background.size = vp_size
	# Title centered horizontally, 8% from top
	var title_w := 600.0
	var title_h := 80.0
	title.position = Vector2((vp_size.x - title_w) / 2.0, vp_size.y * 0.08)
	title.size = Vector2(title_w, title_h)
	# Button container centered horizontally, 30% from top
	var btn_w := 400.0
	var btn_h := button_container.size.y if button_container.size.y > 0 else 380.0
	button_container.position = Vector2((vp_size.x - btn_w) / 2.0, vp_size.y * 0.30)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_select_pressed() -> void:
	dialog.dialog_text = "功能開發中..."
	dialog.popup_centered()

func _on_shop_pressed() -> void:
	dialog.dialog_text = "功能開發中..."
	dialog.popup_centered()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
