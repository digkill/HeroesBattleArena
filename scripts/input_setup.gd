extends Node
class_name InputSetup

static func ensure_actions() -> void:
	var actions := {
		"move_command": [ _mouse_button(MOUSE_BUTTON_RIGHT) ],
		"attack_command": [ _key_from_string("A") ],
		"stop_command": [ _key_from_string("S") ],
		"hold_position": [ _key_from_string("H") ],
		"ability_1": [ _key_from_string("Q") ],
		"ability_2": [ _key_from_string("W") ],
		"ability_3": [ _key_from_string("E") ],
		"ability_4": [ _key_from_string("R") ],
		"item_1": [ _key_from_string("1") ],
		"item_2": [ _key_from_string("2") ],
		"item_3": [ _key_from_string("3") ],
		"center_hero": [ _key_from_string("Space") ],
		"toggle_shop": [ _key_from_string("B") ],
		"toggle_stats": [ _key_from_string("C") ]
	}

	for action_name in actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for event in actions[action_name]:
			if not InputMap.action_has_event(action_name, event):
				InputMap.action_add_event(action_name, event)

static func _key_from_string(key_name: String) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = OS.find_keycode_from_string(key_name)
	return event

static func _mouse_button(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
