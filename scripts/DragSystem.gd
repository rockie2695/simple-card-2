class_name DraggableCard
extends PanelContainer

var card: Card
var turn_manager: TurnManager
var is_dragging: bool = false
var original_position: Vector2
var original_parent: Node
var original_index: int = -1
var drag_layer: CanvasLayer
var tooltip_layer: CanvasLayer
var tooltip_visual: Control
var _last_mouse_pos: Vector2  # Updated from InputEventMouse.position

func setup(c: Card, tm: TurnManager) -> void:
	card = c
	turn_manager = tm

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# Apply hand scale — need 2 deferred frames because HBoxContainer
	# layout resets scale on the first frame after add_child
	call_deferred("_apply_hand_scale_deferred")

func _apply_hand_scale_deferred() -> void:
	# Wait one more frame for HBoxContainer layout to finish
	await get_tree().process_frame
	scale = Vector2(GameConfig.HAND_SCALE, GameConfig.HAND_SCALE)
	pivot_offset = Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)

func _input(event: InputEvent) -> void:
	# Use _input for ALL drag phases — gui_input won't fire after
	# reparenting to CanvasLayer mid-press, and synthetic mouse events
	# (e.g. from MCP debugger bridge) don't trigger gui_input at all.
	if not card or not turn_manager:
		return
	# Always update stored mouse position from events — get_global_mouse_position()
	# may not be updated from synthetic events
	if event is InputEventMouse:
		_last_mouse_pos = event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var rect := get_global_rect()
		if event.pressed:
			# Only start drag if mouse is over this card's rect
			if not is_dragging and turn_manager.current_side == "player" and turn_manager.can_play_card():
				if rect.has_point(event.position):
					_start_drag()
					get_viewport().set_input_as_handled()
		else:
			# Release — end drag
			if is_dragging:
				_end_drag()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if is_dragging:
			_update_drag()

func _on_gui_input(event: InputEvent) -> void:
	if not card or not turn_manager:
		return
	if turn_manager.current_side != "player":
		return
	if not turn_manager.can_play_card():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag()
			get_viewport().set_input_as_handled()

func _start_drag() -> void:
	is_dragging = true
	original_position = global_position
	original_parent = get_parent()
	original_index = original_parent.get_children().find(self) if original_parent else -1
	# Remove tooltip while dragging
	_hide_tooltip()
	drag_layer = CanvasLayer.new()
	drag_layer.layer = 100
	get_tree().root.add_child(drag_layer)
	original_parent.remove_child(self)
	drag_layer.add_child(self)
	scale = Vector2(1.0, 1.0)
	pivot_offset = Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)
	position = _last_mouse_pos - Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)

func _update_drag() -> void:
	if not is_dragging:
		return
	position = _last_mouse_pos - Vector2(GameConfig.CARD_WIDTH * 0.5, GameConfig.CARD_HEIGHT * 0.5)

func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	var drop_pos := _last_mouse_pos
	var battlefield_hit := false
	var main_node = get_tree().current_scene
	if main_node:
		var bf_label = main_node.get_node_or_null("%PlayerBattlefieldLabel")
		if bf_label:
			var label_y = bf_label.global_position.y
			var label_bottom = label_y + 250.0  # 150px scaled card + padding
			if drop_pos.y >= label_y and drop_pos.y <= label_bottom:
				battlefield_hit = true
		else:
			var bf = main_node.get_node_or_null("%PlayerBattlefieldContainer")
			if bf:
				var bf_rect = Rect2(bf.global_position, Vector2(maxf(bf.size.x, 1240.0), maxf(bf.size.y, 400.0)))
				if bf_rect.has_point(drop_pos):
					battlefield_hit = true
	if battlefield_hit:
		# Cache root reference BEFORE remove_child (which removes from tree)
		var root = get_tree().root
		if drag_layer:
			drag_layer.remove_child(self)
			drag_layer.queue_free()
			drag_layer = null
		root.add_child(self)
		position = Vector2(-9999, -9999)
		var success := turn_manager.play_card_from_hand(card)
		if success:
			queue_free()
			return
		else:
			var orig_parent = original_parent
			var orig_idx = original_index
			if orig_parent:
				orig_parent.add_child(self)
				if orig_idx >= 0 and orig_idx < orig_parent.get_child_count():
					orig_parent.move_child(self, orig_idx)
			scale = Vector2(GameConfig.HAND_SCALE, GameConfig.HAND_SCALE)
			global_position = original_position
			return
	_return_to_original()

func _return_to_original() -> void:
	if drag_layer:
		drag_layer.remove_child(self)
		drag_layer.queue_free()
		drag_layer = null
	if original_parent:
		original_parent.add_child(self)
		if original_index >= 0 and original_index < original_parent.get_child_count():
			original_parent.move_child(self, original_index)
	scale = Vector2(GameConfig.HAND_SCALE, GameConfig.HAND_SCALE)
	global_position = original_position

# --- Hover tooltip ---

func _on_mouse_entered() -> void:
	if is_dragging:
		return
	if not card:
		return
	_show_tooltip()

func _on_mouse_exited() -> void:
	_hide_tooltip()

func _show_tooltip() -> void:
	if tooltip_layer:
		return
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 50
	get_tree().root.add_child(tooltip_layer)
	tooltip_visual = _build_full_card()
	# Smart positioning: avoid tooltip going off-screen
	var vp_size := get_viewport_rect().size
	var gap := GameConfig.TOOLTIP_GAP
	var mx := _last_mouse_pos.x
	var my := _last_mouse_pos.y
	var tx: float
	var ty: float
	# Horizontal: left or right of mouse
	if mx + gap + GameConfig.CARD_WIDTH <= vp_size.x:
		tx = mx + gap
	else:
		tx = mx - gap - GameConfig.CARD_WIDTH
	# Vertical: above or below mouse
	if my + gap + GameConfig.CARD_HEIGHT <= vp_size.y:
		ty = my + gap
	else:
		ty = my - gap - GameConfig.CARD_HEIGHT
	tooltip_visual.position = Vector2(tx, ty)
	tooltip_layer.add_child(tooltip_visual)

func _hide_tooltip() -> void:
	if tooltip_layer:
		tooltip_layer.queue_free()
		tooltip_layer = null
		tooltip_visual = null

func _build_full_card() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	wrapper.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	# Shadow
	var shadow := PanelContainer.new()
	shadow.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	shadow.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	shadow.position = Vector2(GameConfig.TOOLTIP_SHADOW_OFFSET, GameConfig.TOOLTIP_SHADOW_OFFSET)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.4)
	shadow_style.corner_radius_top_left = GameConfig.CARD_CORNER_RADIUS
	shadow_style.corner_radius_top_right = GameConfig.CARD_CORNER_RADIUS
	shadow_style.corner_radius_bottom_left = GameConfig.CARD_CORNER_RADIUS
	shadow_style.corner_radius_bottom_right = GameConfig.CARD_CORNER_RADIUS
	shadow.add_theme_stylebox_override("panel", shadow_style)
	wrapper.add_child(shadow)
	# Card panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	panel.size = Vector2(GameConfig.CARD_WIDTH, GameConfig.CARD_HEIGHT)
	panel.position = Vector2.ZERO
	var style := StyleBoxFlat.new()
	style.bg_color = _get_card_color()
	style.corner_radius_top_left = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_top_right = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_bottom_left = GameConfig.CARD_CORNER_RADIUS
	style.corner_radius_bottom_right = GameConfig.CARD_CORNER_RADIUS
	style.border_width_top = GameConfig.TOOLTIP_BORDER_WIDTH
	style.border_width_bottom = GameConfig.TOOLTIP_BORDER_WIDTH
	style.border_width_left = GameConfig.TOOLTIP_BORDER_WIDTH
	style.border_width_right = GameConfig.TOOLTIP_BORDER_WIDTH
	style.border_color = Color(1, 1, 0.6)
	style.content_margin_left = GameConfig.TOOLTIP_CONTENT_MARGIN
	style.content_margin_top = GameConfig.TOOLTIP_CONTENT_MARGIN
	style.content_margin_right = GameConfig.TOOLTIP_CONTENT_MARGIN
	style.content_margin_bottom = GameConfig.TOOLTIP_CONTENT_MARGIN
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", GameConfig.TOOLTIP_SEPARATION)
	var name_label := Label.new()
	name_label.text = card.get_display_name()
	name_label.add_theme_font_size_override("font_size", GameConfig.TOOLTIP_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)
	var pw_label := Label.new()
	pw_label.text = "PW: %d" % card.get_current_pw()
	pw_label.add_theme_font_size_override("font_size", GameConfig.TOOLTIP_PW_FONT_SIZE)
	pw_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(pw_label)
	var desc_label := Label.new()
	desc_label.text = card.get_effect_text()
	desc_label.add_theme_font_size_override("font_size", GameConfig.TOOLTIP_DESC_FONT_SIZE)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	if card.get_keywords_text() != "":
		var kw_label := Label.new()
		kw_label.text = card.get_keywords_text()
		kw_label.add_theme_font_size_override("font_size", GameConfig.TOOLTIP_KW_FONT_SIZE)
		kw_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(kw_label)
	panel.add_child(vbox)
	wrapper.add_child(panel)
	return wrapper

func _get_card_color() -> Color:
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
