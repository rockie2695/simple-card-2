class_name UIManager
extends Node

var battlefield: Battlefield
var hand_manager: HandManager
var turn_manager: TurnManager

var player_hand_container: HBoxContainer
var ai_hand_container: HBoxContainer
var player_battlefield_container: HBoxContainer
var ai_battlefield_container: HBoxContainer
var info_label: Label
var end_turn_button: Button
var game_over_dialog: AcceptDialog

func setup(bf: Battlefield, hm: HandManager, tm: TurnManager) -> void:
	battlefield = bf
	hand_manager = hm
	turn_manager = tm
	battlefield.pw_changed.connect(_on_pw_changed)
	hand_manager.hand_changed.connect(_on_hand_changed)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.game_over.connect(_on_game_over)
	turn_manager.card_played.connect(_on_card_played)

func refresh_all() -> void:
	refresh_battlefield("player")
	refresh_battlefield("ai")
	refresh_hand("player")
	refresh_hand("ai")
	update_info_label()

func _deferred_scale_node(node: Control) -> void:
	# Add a ScaleHelper child that sets scale after layout, then self-destructs
	var helper = Node.new()
	helper.set_script(load("res://scripts/ScaleHelper.gd"))
	node.add_child(helper)

func refresh_battlefield(side: String) -> void:
	var container: HBoxContainer
	if side == "player":
		container = player_battlefield_container
	else:
		container = ai_battlefield_container
	if not container:
		return
	for child in container.get_children():
		child.queue_free()
	var cards := battlefield.get_cards(side)
	for i in range(cards.size()):
		var card: Card = cards[i]
		var card_node := _create_card_visual(card)
		container.add_child(card_node)
		card_node.pivot_offset = Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)
		_deferred_scale_node(card_node)

func refresh_hand(side: String) -> void:
	var container: HBoxContainer
	if side == "player":
		container = player_hand_container
	else:
		container = ai_hand_container
	if not container:
		return
	for child in container.get_children():
		child.queue_free()
	var cards := hand_manager.get_hand(side)
	for card in cards:
		if side == "player":
			var card_node := DraggableCard.new()
			card_node.setup(card, turn_manager)
			_style_card(card_node, card)
			container.add_child(card_node)
			card_node.call_deferred("_apply_hand_scale_deferred")
		else:
			var card_node := _create_card_visual(card)
			container.add_child(card_node)
			card_node.pivot_offset = Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)
			_deferred_scale_node(card_node)

func _create_card_visual(card: Card) -> Control:
	# Shadow layer for 2.5D depth
	var shadow := PanelContainer.new()
	shadow.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	shadow.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	shadow.position = Vector2(4, 4)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.35)
	shadow_style.corner_radius_top_left = 8
	shadow_style.corner_radius_top_right = 8
	shadow_style.corner_radius_bottom_left = 8
	shadow_style.corner_radius_bottom_right = 8
	shadow.add_theme_stylebox_override("panel", shadow_style)
	# Wrap card in a Control so shadow + card move together
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	wrapper.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	wrapper.add_child(shadow)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	panel.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	panel.position = Vector2.ZERO
	_style_card(panel, card)
	wrapper.add_child(panel)
	return wrapper

func _style_card(panel: Control, card: Card) -> void:
	panel.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	panel.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	var style := StyleBoxFlat.new()
	style.bg_color = _get_card_color(card)
	style.corner_radius_top_left = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_top_right = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_bottom_left = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_bottom_right = GameConfig.CARD_CORNER_RADIUS
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.content_margin_left = GameConfig.CARD_CONTENT_MARGIN
	style.content_margin_top = GameConfig.CARD_CONTENT_MARGIN
	style.content_margin_right = GameConfig.CARD_CONTENT_MARGIN
	style.content_margin_bottom = GameConfig.CARD_CONTENT_MARGIN
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GameConfig.CARD_INNER_SEPARATION)
	var name_label := Label.new()
	name_label.text = card.get_display_name()
	name_label.add_theme_font_size_override("font_size", GameConfig.CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	var pw_label := Label.new()
	pw_label.text = "PW: %d" % card.get_current_pw()
	pw_label.add_theme_font_size_override("font_size", GameConfig.CARD_PW_FONT_SIZE)
	pw_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(pw_label)
	var desc_label := Label.new()
	desc_label.text = card.get_effect_text()
	desc_label.add_theme_font_size_override("font_size", GameConfig.CARD_DESC_FONT_SIZE)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	if card.get_keywords_text() != "":
		var kw_label := Label.new()
		kw_label.text = card.get_keywords_text()
		kw_label.add_theme_font_size_override("font_size", GameConfig.CARD_KW_FONT_SIZE)
		kw_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(kw_label)
	panel.add_child(vbox)

func _get_card_color(card: Card) -> Color:
	if card.has_keyword("三劍客"):
		return Color(0.7, 0.2, 0.2)
	elif card.has_keyword("法師"):
		return Color(0.2, 0.3, 0.7)
	elif card.has_keyword("刺客"):
		return Color(0.3, 0.3, 0.4)
	elif card.has_keyword("戰士"):
		return Color(0.5, 0.4, 0.1)
	elif card.has_keyword("商人"):
		return Color(0.2, 0.6, 0.3)
	elif card.has_keyword("槍手"):
		return Color(0.6, 0.5, 0.1)
	elif card.has_keyword("巫師"):
		return Color(0.5, 0.2, 0.6)
	elif card.is_summoned:
		return Color(0.4, 0.4, 0.5)
	else:
		return Color(0.35, 0.45, 0.35)

func update_info_label() -> void:
	if not info_label:
		return
	var player_pw := battlefield.get_total_pw("player")
	var ai_pw := battlefield.get_total_pw("ai")
	info_label.text = "回合 %d | %s 回合\n玩家 PW: %d | AI PW: %d" % [turn_manager.turn_count, "玩家" if turn_manager.current_side == "player" else "AI", player_pw, ai_pw]

func _on_pw_changed(side: String, total_pw: int) -> void:
	update_info_label()

func _on_hand_changed(side: String) -> void:
	refresh_hand(side)

func _on_turn_started(side: String) -> void:
	update_info_label()
	if end_turn_button:
		end_turn_button.disabled = (side != "player")

func _on_turn_ended(side: String) -> void:
	update_info_label()

func _on_card_played(side: String, card: Card) -> void:
	refresh_battlefield(side)
	refresh_hand(side)
	update_info_label()

func _on_game_over(winner: String, reason: String) -> void:
	if game_over_dialog:
		game_over_dialog.dialog_text = reason
		game_over_dialog.popup_centered()
