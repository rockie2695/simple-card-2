## One-shot deferred scaling helper.
## Waits 1 process_frame for HBoxContainer layout to settle,
## then sets parent to GameConfig.HAND_SCALE and self-destructs.
## Required because HBoxContainer resets child scale on add_child.
extends Node

## Adds itself as a child of a Control node, waits one frame for
## HBoxContainer layout to settle, then sets the parent to 0.5x scale
## and self-destructs. Avoids Godot 4's Object-arg call_deferred issue.

func _ready() -> void:
	await get_tree().process_frame
	var parent = get_parent()
	if parent and parent is Control:
		parent.scale = Vector2(GameConfig.HAND_SCALE, GameConfig.HAND_SCALE)
	queue_free()
