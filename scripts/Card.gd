class_name Card
extends RefCounted

var id: String = ""
var card_name: String = ""
var base_pw: int = 0
var temp_pw: int = 0
var permanent_pw: int = 0
var keywords: Array = []
var effect_type: String = "none"
var effect_params: Dictionary = {}
var description: String = ""
var timer_counter: int = 0
var owner_side: String = "player"
var is_summoned: bool = false
var attached_effects: Array = []

func setup(data: Dictionary, side: String) -> void:
	id = data.get("id", "")
	card_name = data.get("name", "")
	base_pw = data.get("base_pw", 0)
	keywords = data.get("keywords", [])
	effect_type = data.get("effect_type", "none")
	effect_params = data.get("effect_params", {})
	description = data.get("description", "")
	owner_side = side

func get_current_pw() -> int:
	var total := base_pw + temp_pw + permanent_pw
	if total < 0:
		total = 0
	return total

func add_temp(amount: int) -> void:
	temp_pw += amount

func add_permanent(amount: int) -> void:
	permanent_pw += amount

func reset_temp() -> void:
	temp_pw = 0

func has_keyword(kw: String) -> bool:
	return kw in keywords

func get_display_name() -> String:
	return card_name

func get_effect_text() -> String:
	return description

func get_keywords_text() -> String:
	return ", ".join(keywords) if keywords.size() > 0 else ""

func is_enemy(other: Card) -> bool:
	return owner_side != other.owner_side

func is_ally(other: Card) -> bool:
	return owner_side == other.owner_side
