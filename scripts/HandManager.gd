## Manages hands and decks for both player and AI sides.
## Handles draw, remove, deck-empty signals.
class_name HandManager
extends RefCounted

signal hand_changed(side: String)
signal deck_empty(side: String)

var player_hand: Array = []
var ai_hand: Array = []
var deck_player: Array = []
var deck_ai: Array = []

func initialize_decks() -> void:
	deck_player = DeckBuilder.create_card_instances("player")
	deck_ai = DeckBuilder.create_card_instances("ai")
	player_hand.clear()
	ai_hand.clear()

func draw_initial_hands(count: int = 3) -> void:
	for i in range(count):
		draw_card("player")
		draw_card("ai")

func draw_card(side: String) -> Card:
	var deck: Array = deck_player if side == "player" else deck_ai
	var hand: Array = player_hand if side == "player" else ai_hand
	if deck.size() == 0:
		deck_empty.emit(side)
		return null
	var card: Card = deck.pop_back()
	hand.append(card)
	hand_changed.emit(side)
	return card

func remove_card_from_hand(card: Card, side: String) -> void:
	var hand: Array = player_hand if side == "player" else ai_hand
	var index := hand.find(card)
	if index >= 0:
		hand.remove_at(index)
		hand_changed.emit(side)

func get_hand(side: String) -> Array:
	return player_hand if side == "player" else ai_hand

func get_deck_count(side: String) -> int:
	return deck_player.size() if side == "player" else deck_ai.size()

func is_hand_empty(side: String) -> bool:
	return get_hand(side).size() == 0

func get_random_card_from_hand(side: String) -> Card:
	var hand := get_hand(side)
	if hand.size() == 0:
		return null
	return hand[randi() % hand.size()]
