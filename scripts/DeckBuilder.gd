## Builds 15-card decks from CardsData.
## Uses generate_filler_cards() when fewer than 15 unique cards exist.
class_name DeckBuilder
extends RefCounted

static func build_deck() -> Array:
	var all_design_cards := CardsData.get_all_cards()
	var deck := []
	if all_design_cards.size() >= GameConfig.DECK_SIZE:
		all_design_cards.shuffle()
		deck = all_design_cards.slice(0, GameConfig.DECK_SIZE)
	else:
		deck = all_design_cards.duplicate()
		var filler_needed := GameConfig.DECK_SIZE - deck.size()
		var fillers := CardsData.generate_filler_cards(filler_needed)
		deck.append_array(fillers)
	deck.shuffle()
	return deck

static func create_card_instances(side: String) -> Array:
	var deck_data := build_deck()
	var instances := []
	for data in deck_data:
		var card := Card.new()
		card.setup(data, side)
		instances.append(card)
	return instances
