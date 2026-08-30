extends Node2D

@onready var player_hand_container: HBoxContainer = %PlayerHandContainer
@onready var ai_hand_container: HBoxContainer = %AIHandContainer
@onready var player_battlefield_container: HBoxContainer = %PlayerBattlefieldContainer
@onready var ai_battlefield_container: HBoxContainer = %AIBattlefieldContainer
@onready var info_label: Label = %InfoLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var game_over_dialog: AcceptDialog = %GameOverDialog
@onready var background: ColorRect = $Background
@onready var ai_hand_label: Label = $AIHandLabel
@onready var ai_hand_scroll: ScrollContainer = $AIHandScroll
@onready var ai_bf_label: Label = $AIBattlefieldLabel
@onready var ai_bf_container: HBoxContainer = $AIBattlefieldContainer
@onready var player_bf_label: Label = $PlayerBattlefieldLabel
@onready var player_bf_container: HBoxContainer = $PlayerBattlefieldContainer
@onready var player_hand_label: Label = $PlayerHandLabel
@onready var player_hand_scroll: ScrollContainer = $PlayerHandScroll

var battlefield: Battlefield
var hand_manager: HandManager
var turn_manager: TurnManager
var ui_manager: UIManager

func _ready() -> void:
	battlefield = Battlefield.new()
	hand_manager = HandManager.new()
	turn_manager = TurnManager.new()
	ui_manager = UIManager.new()
	add_child(ui_manager)
	turn_manager.setup(battlefield, hand_manager)
	ui_manager.setup(battlefield, hand_manager, turn_manager)
	ui_manager.player_hand_container = player_hand_container
	ui_manager.ai_hand_container = ai_hand_container
	ui_manager.player_battlefield_container = player_battlefield_container
	ui_manager.ai_battlefield_container = ai_battlefield_container
	ui_manager.info_label = info_label
	ui_manager.end_turn_button = end_turn_button
	ui_manager.game_over_dialog = game_over_dialog
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	game_over_dialog.confirmed.connect(_on_game_over_confirmed)
	get_viewport().size_changed.connect(_on_resize)
	_apply_layout()
	turn_manager.start_game()
	ui_manager.refresh_all()

func _on_resize() -> void:
	_apply_layout()

func _apply_layout() -> void:
	var vp := get_viewport_rect().size
	var margin := GameConfig.SCENE_MARGIN
	var content_w := vp.x - margin * 2.0
	# Background
	background.size = vp
	# Layout rows as proportions of viewport height
	var row_h := vp.y
	# AI Hand: 5% - 12%
	var ai_hand_top := row_h * 0.05
	var ai_hand_h := row_h * 0.07
	ai_hand_label.position = Vector2(margin, ai_hand_top)
	ai_hand_label.size = Vector2(200, GameConfig.LABEL_HEIGHT)
	ai_hand_scroll.position = Vector2(margin, ai_hand_top + 25)
	ai_hand_scroll.size = Vector2(content_w, ai_hand_h)
	# AI Battlefield: 14% - 37%
	var ai_bf_top := row_h * 0.14
	var ai_bf_h := row_h * 0.23
	ai_bf_label.position = Vector2(margin, ai_bf_top)
	ai_bf_label.size = Vector2(200, GameConfig.LABEL_HEIGHT)
	ai_bf_container.position = Vector2(margin, ai_bf_top + 25)
	ai_bf_container.size = Vector2(content_w, ai_bf_h)
	# Player Battlefield: 53% - 76%
	var pl_bf_top := row_h * 0.53
	var pl_bf_h := row_h * 0.23
	player_bf_label.position = Vector2(margin, pl_bf_top)
	player_bf_label.size = Vector2(200, GameConfig.LABEL_HEIGHT)
	player_bf_container.position = Vector2(margin, pl_bf_top + 25)
	player_bf_container.size = Vector2(content_w, pl_bf_h)
	# Player Hand: 78% - 92%
	var pl_hand_top := row_h * 0.78
	var pl_hand_h := row_h * 0.14
	player_hand_label.position = Vector2(margin, pl_hand_top)
	player_hand_label.size = Vector2(200, GameConfig.LABEL_HEIGHT)
	player_hand_scroll.position = Vector2(margin, pl_hand_top + 25)
	player_hand_scroll.size = Vector2(content_w, pl_hand_h)
	# Info label: bottom-right
	var info_w := 240.0
	var info_h := 80.0
	info_label.position = Vector2(vp.x - info_w - margin, vp.y * 0.78)
	info_label.size = Vector2(info_w, info_h)
	# End turn button: below info
	var btn_w := 200.0
	var btn_h := 40.0
	end_turn_button.position = Vector2(vp.x - btn_w - margin - 20, vp.y - btn_h - margin)
	end_turn_button.size = Vector2(btn_w, btn_h)

func _on_end_turn_pressed() -> void:
	if turn_manager.current_side == "player":
		turn_manager.end_turn()
		ui_manager.refresh_all()

func _on_game_over_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/Home.tscn")
