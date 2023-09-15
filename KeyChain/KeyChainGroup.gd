extends Resource

class_name KeyChainGroup

signal event_bounded(group, event)

const ERR_ACTION_NOT_EXIST = 'Keymap action dose not exist.'

@export var key:StringName = '-'
@export var name:StringName = '-'
@export var actions_dict:Dictionary = {}
@export var ordered_actions:Array = []
@export var deep_match_event :bool = false


func sync():
	# NO NEED clear current InputMap. the InputMap is reset anyway.
	for k in actions_dict:
		var exist_action = actions_dict[k]
		if not InputMap.has_action(k):
			InputMap.add_action(k)
		
		InputMap.action_set_deadzone(k, exist_action['deadzone'])
		InputMap.action_erase_events(k)
		for evt in exist_action['events']:
			InputMap.action_add_event(k, evt)


func clear():
	# NO NEED sync.
	for k in actions_dict:
		if InputMap.has_action(k):
			InputMap.erase_action(k)
	actions_dict.clear()
	ordered_actions.clear()


func clear_events():
	# NO NEED sync.
	for k in actions_dict:
		var exist_action = actions_dict[k]
		exist_action['events'].clear()
		InputMap.action_erase_events(k)


func remove_event(event :InputEventWithModifiers):
	# NO NEED sync.
	for k in actions_dict:
		var exist_action = actions_dict[k]
		if exist_action['events'].has(event):
			exist_action['events'].erase(event)
		else:
			var removes :Array = [] 
			for evt in exist_action['events']:
				if KeyChain.is_equals_event(event, evt, deep_match_event):
					removes.append(evt)
			for r in removes:
				exist_action['events'].erase(r)
				
		if InputMap.has_action(k) and InputMap.action_has_event(k, event):
			InputMap.action_erase_event(k, event)


func add_action(action_key :StringName, action_name :String = '', deadzone: float = 0.5):
	if not action_name:
		action_name = action_key.capitalize()
	
	var action
	if actions_dict.get(action_key):
		action = actions_dict[action_key]
		action['name'] = action_name
		action['deadzone'] = deadzone
	else:
		action = {
			'key': action_key,
			'name': action_name,
			'deadzone': deadzone,
			'events': []
		}
		actions_dict[action_key] = action
		ordered_actions.append(action)

	if InputMap.has_action(action_key):
		InputMap.action_set_deadzone(action_key, deadzone)
		InputMap.action_erase_events(action_key)
	else:
		InputMap.add_action(action_key, deadzone)
	
	return action


func list_actions():
	return ordered_actions


func get_action(action_key :StringName):
	return actions_dict.get(action_key)


func del_action(action_key :StringName):
	if actions_dict.has(action_key):
		var exist_aciton = actions_dict[action_key]
		ordered_actions.erase(exist_aciton)
		actions_dict.erase(exist_aciton)
	
	if InputMap.has_action(action_key):
		InputMap.erase_action(action_key)


func get_action_deadzone(action_key :StringName):
	var target_action = get_action(action_key)
	if target_action:
		return target_action.get('deadzone')
	else:
		return null


func set_action_deadzone(action_key :StringName, deadzone :float = 0.5):
	var target_action = get_action(action_key)
	if target_action:
		target_action['deadzone'] = deadzone
		InputMap.action_set_deadzone(action_key, deadzone)
	

func clear_action_events(action_key :StringName):
	var target_action = get_action(action_key)
	if target_action:
		target_action['events'].clear()
		InputMap.action_erase_events(action_key)


func get_action_events(action_key :StringName):
	var target_action = get_action(action_key)
	if target_action:
		return target_action['events']
	return []
	

func has_action_event(action_key :StringName, event:InputEventWithModifiers):
	var target_action = get_action(action_key)
	var has_event = false
	if target_action:
		has_event = target_action['events'].has(event)
	if has_event:
		return true
	else:
		for evt in target_action['events']:
			if evt.as_text() == event.as_text():
				return true
	return false


func is_event_in_action(event:InputEventWithModifiers):
	var is_in_action = false
	for k in actions_dict:
		var act = actions_dict[k]
		if has_action_event(act['key'], event):
			is_in_action = true

	return is_in_action


func bind_action_event(action_key :StringName, event:InputEventWithModifiers):
	var target_action = get_action(action_key)
	if target_action:
		for k in actions_dict:
			unbind_action_event(k, event)
		target_action['events'].append(event)
		InputMap.action_add_event(action_key, event)
		event_bounded.emit(key, event)


func unbind_action_event(action_key :StringName, event:InputEventWithModifiers):
	var target_action = get_action(action_key)
	if target_action['events'].has(event):
		target_action['events'].erase(event)
	else:
		var removes :Array = []
		for evt in target_action['events']:
			if KeyChain.is_equals_event(event, evt, deep_match_event):
				removes.append(evt)
		for r in removes:
			target_action['events'].erase(r)
	
	if InputMap.has_action(action_key) and InputMap.action_has_event(action_key, event):
		InputMap.action_erase_event(action_key, event)


func get_event_from_action(action_key_or_dict, event:InputEventWithModifiers):
	var action = null
	if action_key_or_dict is Dictionary:
		action = action_key_or_dict
	else:
		action = actions_dict[action_key_or_dict]
		
	for evt in action['events']:
		if KeyChain.is_equals_event(event, evt, deep_match_event):
			return evt
	return null


func get_action_from_ordered(action_key_or_dict):
	var action_key = null
	if action_key_or_dict is Dictionary:
		action_key = action_key_or_dict['key']
	else:
		action_key = action_key_or_dict
	for act in ordered_actions:
		if action_key == act['key']:
			return act
	return null

