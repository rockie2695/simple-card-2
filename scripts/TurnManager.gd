class_name TurnManager
extends RefCounted

signal turn_started(side: String)
signal turn_ended(side: String)
signal game_over(winner: String, reason: String)
signal card_played(side: String, card: Card)
signal effect_triggered(side: String, card: Card, effect: String)

var current_side: String = "player"
var turn_count: int = 0
var cards_played_this_turn: int = 0
var battlefield: Battlefield
var hand_manager: HandManager

func setup(bf: Battlefield, hm: HandManager) -> void:
	battlefield = bf
	hand_manager = hm

func start_game() -> void:
	turn_count = 0
	current_side = "player"
	hand_manager.initialize_decks()
	hand_manager.draw_initial_hands(3)
	start_turn()

func start_turn() -> void:
	turn_count += 1
	cards_played_this_turn = 0
	hand_manager.draw_card(current_side)
	_trigger_turn_start_effects()
	battlefield.recalculate_all_pw()
	if check_win():
		return
	turn_started.emit(current_side)
	if current_side == "ai":
		_do_ai_turn.call_deferred()

func end_turn() -> void:
	_trigger_turn_end_effects()
	if check_win():
		return
	turn_ended.emit(current_side)
	current_side = "ai" if current_side == "player" else "player"
	start_turn()

func play_card_from_hand(card: Card) -> bool:
	if cards_played_this_turn > 0:
		return false
	hand_manager.remove_card_from_hand(card, current_side)
	battlefield.play_card(card, current_side)
	cards_played_this_turn = 1
	_apply_enter_effects(card)
	battlefield.recalculate_all_pw()
	if check_win():
		return true
	card_played.emit(current_side, card)
	return true

func check_win() -> bool:
	var player_pw := battlefield.get_total_pw("player")
	var ai_pw := battlefield.get_total_pw("ai")
	if player_pw >= 20:
		game_over.emit("player", "玩家勝利！總 pw 達到 %d" % player_pw)
		return true
	if ai_pw >= 20:
		game_over.emit("ai", "AI 勝利！總 pw 達到 %d" % ai_pw)
		return true
	return false

func can_play_card() -> bool:
	return cards_played_this_turn == 0

func _do_ai_turn() -> void:
	await Engine.get_main_loop().create_timer(1.0).timeout
	var hand := hand_manager.get_hand("ai")
	if hand.size() > 0 and cards_played_this_turn == 0:
		var card_to_play := hand_manager.get_random_card_from_hand("ai")
		if card_to_play:
			play_card_from_hand(card_to_play)
	end_turn()

func _trigger_turn_start_effects() -> void:
	var cards := battlefield.get_cards(current_side)
	for card in cards:
		if card.effect_type == "timer":
			card.timer_counter += 1
			var trigger_turns: int = card.effect_params.get("trigger_turns", 3)
			if card.timer_counter >= trigger_turns:
				_apply_timer_effect(card, current_side)
		for effect in card.attached_effects:
			if effect.get("type") == "mind_eat":
				var my_cards := battlefield.get_cards(current_side)
				for mc in my_cards:
					mc.add_temp(-1)

func _trigger_turn_end_effects() -> void:
	pass

func _apply_enter_effects(card: Card) -> void:
	match card.effect_type:
		"on_enter":
			_apply_on_enter_effect(card)
		_:
			pass

func _apply_on_enter_effect(card: Card) -> void:
	var action: String = card.effect_params.get("action", "")
	var enemy_side := battlefield.get_enemy_side(card.owner_side)
	match action:
		"kill_zero_pw_mage":
			var target := battlefield.find_zero_pw_mage(enemy_side)
			if target:
				var idx := battlefield.get_card_index(target, enemy_side)
				if idx >= 0:
					battlefield.remove_card(idx, enemy_side)
					card.add_permanent(1)
					effect_triggered.emit(card.owner_side, card, "法師刺客觸發")
		"opposing_temp_minus_4":
			var my_cards := battlefield.get_cards(card.owner_side)
			var my_index := my_cards.find(card)
			var enemy_cards := battlefield.get_cards(enemy_side)
			if my_index >= 0 and my_index < enemy_cards.size():
				enemy_cards[my_index].add_temp(-4)
				effect_triggered.emit(card.owner_side, card, "火球法師觸發")
		"damage_by_right_ally":
			var my_cards := battlefield.get_cards(card.owner_side)
			var my_index := my_cards.find(card)
			if my_index >= 0 and my_index < my_cards.size() - 1:
				var right_ally: Card = my_cards[my_index + 1]
				var damage := right_ally.get_current_pw()
				var enemy_cards := battlefield.get_cards(enemy_side)
				for ec in enemy_cards:
					ec.add_temp(-damage)
				effect_triggered.emit(card.owner_side, card, "火砲指揮官觸發")
		"summon_mercenary":
			var mercenary_data := {"id": "mercenary_%d" % Time.get_ticks_msec(), "name": "僱傭兵隊員", "base_pw": 1, "keywords": ["僱傭兵", "戰士", "召喚物"], "effect_type": "none", "effect_params": {}, "description": "召喚物"}
			var mercenary := Card.new()
			mercenary.setup(mercenary_data, card.owner_side)
			mercenary.is_summoned = true
			battlefield.play_card(mercenary, card.owner_side)
			effect_triggered.emit(card.owner_side, card, "僱傭兵領隊觸發")
		"temp_plus_1_and_kill_left_1":
			var my_cards := battlefield.get_cards(card.owner_side)
			for mc in my_cards:
				mc.add_temp(1)
			var target := battlefield.find_leftmost_with_pw_limit(enemy_side, 1)
			if target:
				var idx := battlefield.get_card_index(target, enemy_side)
				if idx >= 0:
					battlefield.remove_card(idx, enemy_side)
					effect_triggered.emit(card.owner_side, card, "銅牌刺客觸發消滅")
			else:
				card.add_permanent(-1)
				effect_triggered.emit(card.owner_side, card, "銅牌刺客觸發失敗")
		"cleanse_last_ally":
			var my_cards := battlefield.get_cards(card.owner_side)
			if my_cards.size() > 0:
				var last_ally: Card = my_cards[my_cards.size() - 1]
				if last_ally.permanent_pw < 0:
					last_ally.permanent_pw = 0
					for mc in my_cards:
						mc.add_temp(-2)
					effect_triggered.emit(card.owner_side, card, "祝禱戰士觸發")
				elif last_ally.temp_pw < 0:
					last_ally.temp_pw = 0
					for mc in my_cards:
						mc.add_temp(-2)
					effect_triggered.emit(card.owner_side, card, "祝禱戰士觸發")
		"attach_mind_eat":
			var target := battlefield.get_front_card(enemy_side)
			if target:
				target.attached_effects.append({"type": "mind_eat", "source": card})
				effect_triggered.emit(card.owner_side, card, "噬心巫師觸發")

func _apply_timer_effect(card: Card, side: String) -> void:
	var effect: String = card.effect_params.get("effect", "")
	var enemy_side := battlefield.get_enemy_side(side)
	match effect:
		"enemy_all_permanent_minus_1":
			var enemy_cards := battlefield.get_cards(enemy_side)
			for ec in enemy_cards:
				ec.add_permanent(-1)
				if ec.get_current_pw() < 0:
					ec.permanent_pw = -ec.base_pw - ec.temp_pw
			card.timer_counter = 0
			effect_triggered.emit(side, card, "沼澤法師觸發")
		"self_permanent_plus_1_each_turn":
			if card.timer_counter >= card.effect_params.get("trigger_turns", 5):
				card.add_permanent(1)
				effect_triggered.emit(side, card, "時光法師觸發")
