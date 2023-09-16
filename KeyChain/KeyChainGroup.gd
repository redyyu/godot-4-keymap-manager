extends Resource

class_name KeyChainGroup

signal keymap_event_bounded(group, event)

const ERR_ACTION_NOT_EXIST = 'Keymap action dose not exist.'

@export var key:StringName = '-'
@export var name:StringName = '-'
@export var actions_dict:Dictionary = {}
@export var ordered_actions:Array = []

@export var single_event_mode :bool = false :
	set(val):
		if single_event_mode != val:
			single_event_mode = val
			if single_event_mode:
				for action in ordered_actions:
					var removes :Array = []
					for i in action['events']:
						if i > 0:
							removes.append(action['events'][i])
					for r in removes:
						unbind_action_event(action['key'], r)


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
	for k in actions_dict:
		if InputMap.has_action(k):
			InputMap.erase_action(k)
	actions_dict.clear()
	ordered_actions.clear()


func clear_events():
	for k in actions_dict:
		var exist_action = actions_dict[k]
		exist_action['events'].clear()
		if InputMap.has_action(k):
			InputMap.action_erase_events(k)


func remove_event_from_actions(event :InputEventWithModifiers):
	# remove same event or equals event from all actions.
	for k in actions_dict:
		unbind_action_event(k, event)


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
		if single_event_mode:
			# clear up other events before append new one.
			for evt in target_action['events']:
				unbind_action_event(action_key, evt)
		# append new event to action events.
		target_action['events'].append(event)
		InputMap.action_add_event(action_key, event)
		keymap_event_bounded.emit(key, event)


func unbind_action_event(action_key :StringName, event:InputEventWithModifiers):
	var removes :Array = []
	var target_action = get_action(action_key)
	if target_action['events'].has(event):
		# event is the one in action.
		removes.append(event)
	else:
		# equals event in action.
		for evt in target_action['events']:
			if KeyChain.is_equal_input(event, evt):
				removes.append(evt)
	
	# remove event it self or equals once for all.
	for r in removes:
		target_action['events'].erase(r)
		
	if InputMap.has_action(action_key):
		for r in removes:
			if InputMap.action_has_event(action_key, r):
				InputMap.action_erase_event(action_key, r)

