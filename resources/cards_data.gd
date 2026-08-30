## Static card database — 14 unique cards + filler card generator.
## Each card is a Dictionary with: id, name, base_pw, keywords, effect_type, effect_params, description.
class_name CardsData
extends RefCounted

static func get_all_cards() -> Array:
	return [
		{"id": "athos", "name": "三劍客-阿多斯", "base_pw": 2, "keywords": ["三劍客"], "effect_type": "musketeer_link", "effect_params": {}, "description": "與相鄰三劍客連接時+1 pw"},
		{"id": "porthos", "name": "三劍客-波爾多斯", "base_pw": 2, "keywords": ["三劍客"], "effect_type": "musketeer_link", "effect_params": {}, "description": "與相鄰三劍客連接時+1 pw"},
		{"id": "aramis", "name": "三劍客-阿拉密斯", "base_pw": 2, "keywords": ["三劍客"], "effect_type": "musketeer_link", "effect_params": {}, "description": "與相鄰三劍客連接時+1 pw"},
		{"id": "swamp_mage", "name": "沼澤法師", "base_pw": 0, "keywords": ["法師"], "effect_type": "timer", "effect_params": {"trigger_turns": 3, "effect": "enemy_all_permanent_minus_1"}, "description": "3回合後敵方全體永久-1 pw"},
		{"id": "mage_assassin", "name": "法師刺客", "base_pw": 2, "keywords": ["刺客"], "effect_type": "on_enter", "effect_params": {"action": "kill_zero_pw_mage", "self_bonus": 1}, "description": "消滅敵方最前排0 pw法師，成功則+1永久"},
		{"id": "fireball_mage", "name": "火球法師", "base_pw": 0, "keywords": ["法師"], "effect_type": "on_enter", "effect_params": {"action": "opposing_temp_minus_4"}, "description": "對位敵方臨時-4 pw"},
		{"id": "armor_merchant", "name": "護身武器商人", "base_pw": 0, "keywords": ["商人"], "effect_type": "aura", "effect_params": {"condition": "ally_zero_pw", "bonus": 1}, "description": "我方0 pw卡臨時+1"},
		{"id": "cannon_commander", "name": "火砲指揮官", "base_pw": 0, "keywords": ["槍手"], "effect_type": "on_enter", "effect_params": {"action": "damage_by_right_ally"}, "description": "造成右方友軍pw的傷害"},
		{"id": "mercenary_leader", "name": "僱傭兵領隊", "base_pw": 2, "keywords": ["僱傭兵", "戰士"], "effect_type": "on_enter", "effect_params": {"action": "summon_mercenary"}, "description": "召喚一個1 pw僱傭兵隊員"},
		{"id": "bronze_assassin", "name": "銅牌刺客", "base_pw": 1, "keywords": ["刺客"], "effect_type": "on_enter", "effect_params": {"action": "temp_plus_1_and_kill_left_1", "fail_penalty": -1}, "description": "我方臨時+1，消滅敵方最前排≤1 pw卡"},
		{"id": "gladiator", "name": "角鬥士", "base_pw": 1, "keywords": ["戰士"], "effect_type": "trigger", "effect_params": {"trigger": "enemy_card_destroyed", "bonus": 1, "max": 6}, "description": "敵方卡被消滅時永久+1（最大6）"},
		{"id": "prayer_warrior", "name": "祝禱戰士", "base_pw": 1, "keywords": ["戰士"], "effect_type": "on_enter", "effect_params": {"action": "cleanse_last_ally", "cost": -2}, "description": "消除最後友軍負面效果，我方臨時-2"},
		{"id": "mind_eater", "name": "噬心巫師", "base_pw": 0, "keywords": ["巫師"], "effect_type": "on_enter", "effect_params": {"action": "attach_mind_eat"}, "description": "附加噬心效果到敵方最前排"},
		{"id": "time_mage", "name": "時光法師", "base_pw": 0, "keywords": ["法師"], "effect_type": "timer", "effect_params": {"trigger_turns": 5, "effect": "self_permanent_plus_1_each_turn"}, "description": "5回合後每回合永久+1"},
	]

static func get_card_data(card_id: String) -> Dictionary:
	for card in get_all_cards():
		if card["id"] == card_id:
			return card
	return {}

static func generate_filler_cards(count: int) -> Array:
	var result := []
	var filler_names := ["傭兵A", "傭兵B", "傭兵C", "傭兵D", "傭兵E", "傭兵F", "傭兵G", "傭兵H", "傭兵I", "傭兵J", "傭兵K", "傭兵L", "傭兵M", "傭兵N", "傭兵O", "傭兵P", "傭兵Q", "傭兵R", "傭兵S", "傭兵T", "傭兵U", "傭兵V", "傭兵W", "傭兵X", "傭兵Y", "傭兵Z"]
	for i in range(count):
		var name_index := i % filler_names.size()
		result.append({
			"id": "filler_%d" % i,
			"name": filler_names[name_index],
			"base_pw": 3,
			"keywords": ["傭兵", "戰士"],
			"effect_type": "none",
			"effect_params": {},
			"description": "基礎作戰單位"
		})
	return result
