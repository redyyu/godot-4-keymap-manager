extends Resource

class_name KeyChainAction

signal keymap_event_bounded(group, event)

const ERR_ACTION_NOT_EXIST = 'Keymap action dose not exist.'

@export var key :StringName = '-'
@export var name :StringName = '-'
@export var deadzone :float = 0.5
@export var tags :Array[StringName] = []
@export var events :Array[InputEvent] = []

@export var single_event_mode :bool = false :
	set(val):
		if single_event_mode != val:
			single_event_mode = val
			if single_event_mode:
				var removes :Array = []
				for i in events.size():
					if i > 0:
						removes.append(events[i])
				for r in removes:
					# events size might change. that's why use `removes`.
					unbind_event(r)


func sync():
	# NO NEED clear current InputMap. the InputMap is reset anyway.
	if not InputMap.has_action(key):
		InputMap.add_action(key)
	
	InputMap.action_set_deadzone(key, deadzone)
	InputMap.action_erase_events(key)
	for evt in events:
		InputMap.action_add_event(key, evt)


func clear():
	if InputMap.has_action(key):
		InputMap.erase_action(key)
	events.clear()
	tags.clear()


func clear_events():
	events.clear()
	if InputMap.has_action(key):
		InputMap.action_erase_events(key)
	

func has_event(event:InputEventWithModifiers):
	for evt in events:
		if KeyChain.is_equal_input(evt, event):
			return true
	return false


func bind_event(event:InputEventWithModifiers):
	unbind_event(event)
	if single_event_mode:
		# clear up other events before append new one.
		for evt in events:
			unbind_event(evt)
		# append new event to action events.
		events.append(event)
		InputMap.action_add_event(key, event)
		keymap_event_bounded.emit(key, event, tags)


func unbind_event(event:InputEventWithModifiers):
	var removes :Array = []

	for evt in events:
		if KeyChain.is_equal_input(event, evt):
			removes.append(evt)
	
	# remove event it self or equals once for all.
	for r in removes:
		events.erase(r)
		
	if InputMap.has_action(key):
		for r in removes:
			if InputMap.action_has_event(key, r):
				InputMap.action_erase_event(key, r)
