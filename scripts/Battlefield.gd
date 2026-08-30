class_name Battlefield
extends RefCounted

signal pw_changed(side: String, total_pw: int)
signal card_destroyed(side: String, card: Card, index: int)

var player_cards: Array = []
var ai_cards: Array = []

func play_card(card: Card, side: String) -> void:
	if side == "player":
		player_cards.append(card)
	else:
		ai_cards.append(card)
	recalculate_all_pw()

func remove_card(index: int, side: String) -> Card:
	var card: Card = null
	if side == "player" and index >= 0 and index < player_cards.size():
		card = player_cards[index]
		player_cards.remove_at(index)
	elif side == "ai" and index >= 0 and index < ai_cards.size():
		card = ai_cards[index]
		ai_cards.remove_at(index)
	if card:
		card_destroyed.emit(side, card, index)
		recalculate_all_pw()
	return card

func get_cards(side: String) -> Array:
	return player_cards if side == "player" else ai_cards

func get_front_card(side: String) -> Card:
	var cards := get_cards(side)
	return cards[0] if cards.size() > 0 else null

func get_last_card(side: String) -> Card:
	var cards := get_cards(side)
	return cards[cards.size() - 1] if cards.size() > 0 else null

func get_card_at(index: int, side: String) -> Card:
	var cards := get_cards(side)
	if index >= 0 and index < cards.size():
		return cards[index]
	return null

func get_card_index(card: Card, side: String) -> int:
	var cards := get_cards(side)
	return cards.find(card)

func get_total_pw(side: String) -> int:
	var total := 0
	var cards := get_cards(side)
	for card in cards:
		total += card.get_current_pw()
	return total

func get_enemy_side(side: String) -> String:
	return "ai" if side == "player" else "player"

func recalculate_all_pw() -> void:
	for card in player_cards:
		card.reset_temp()
	for card in ai_cards:
		card.reset_temp()
	_apply_musketeer_link(player_cards)
	_apply_musketeer_link(ai_cards)
	_apply_aura_effects(player_cards, "player")
	_apply_aura_effects(ai_cards, "ai")
	pw_changed.emit("player", get_total_pw("player"))
	pw_changed.emit("ai", get_total_pw("ai"))

func _apply_musketeer_link(cards: Array) -> void:
	for i in range(cards.size()):
		var card: Card = cards[i]
		if not card.has_keyword("三劍客"):
			continue
		if i > 0 and cards[i - 1].has_keyword("三劍客"):
			card.add_temp(1)
		if i < cards.size() - 1 and cards[i + 1].has_keyword("三劍客"):
			card.add_temp(1)

func _apply_aura_effects(cards: Array, side: String) -> void:
	for card in cards:
		if card.effect_type == "aura" and card.effect_params.get("condition") == "ally_zero_pw":
			for other in cards:
				if other != card and other.get_current_pw() == 0:
					other.add_temp(card.effect_params.get("bonus", 1))

func find_zero_pw_mage(side: String) -> Card:
	var cards := get_cards(side)
	for card in cards:
		if card.has_keyword("法師") and card.get_current_pw() == 0:
			return card
	return null

func find_leftmost_with_pw_limit(side: String, max_pw: int) -> Card:
	var cards := get_cards(side)
	for card in cards:
		if card.get_current_pw() <= max_pw:
			return card
	return null
