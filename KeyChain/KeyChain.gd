extends Resource

class_name KeyChain

enum UniqueEventMode {
	NONE,
	ALL,
	TAG,
}

signal keymap_bounded(group_key, event)

@export var actions :Array = []
@export var tags :Array[StringName] = []

# same event only exist in one action.
@export var unique_event_mode = UniqueEventMode.ALL
# BTW, event always be unique in group.


func _ready():
	for action in actions:
		action.keymap_event_bounded.connect(_on_keymap_event_bounded)
	

func synchronize(empty_exists :bool = false):
	if empty_exists:
		for act in InputMap.get_actions():
			InputMap.erase_action(act)
	
	for action in actions:
		action.sync()


func clear():
	for action in actions:
		action.clear_events()
	actions.clear()


func clear_events():
	for action in actions:
		action.clear_events()


func remove_event(event):
	for action in actions:
		action.remove_event(event)



func get_actions_tree():
	var output :Array[Dictionary] = []
	for tag in tags:
		var output_tag = {
			'tag': tag,
			'actions': []
		}
		for action in actions:
			if action.tags.has(tag):
				output_tag['actions'].append(action)
		output.append(output_tag)
		
	# find all actions without any tags.
	var others = {
		'tag': '',
		'actions': []
	}
	for action in actions:
		if action.tags.is_empty():
			others['actions'].append(action)
	output.append(others)
	
	return output


func search_actions_by_tag(by_tag :StringName = ''):
	var output :Array = []
	for action in actions:
		if by_tag:
			if action.tags.has(by_tag):
				output.append(action)
		else:
			if action.tags.is_empty():
				output.append(action)
	return output


func add_action(action_key :StringName, action_name :String = '' , tag :StringName = '',
				deadzone: float = 0.5, single_event: bool = false):
	if not action_name:
		action_name = action_key.capitalize()
	
	var action :KeyChainAction
	
	action = get_action(action_key)
	assert(action == null, 'Action key must bee not duplicated.')
	
	if tag and not tags.has(tag):
		tags.append(tag)
		
	print('assert')
	
	action = KeyChainAction.new()
	action.key = action_key
	action.name = action_name
	action.deadzone = deadzone
	action.single_event_mode = single_event
	if tag:
		action.tags = [tag]

	actions.append(action)
	action.keymap_event_bounded.connect(_on_keymap_event_bounded)
	if not InputMap.has_action(action_key): 
		InputMap.add_action(action_key)
		
	return action


func update_action(action_key :StringName, action_name :String = '' , tag :StringName = '',
				deadzone: float = 0.5, single_event: bool = false):
	if not action_name:
		action_name = action_key.capitalize()
	
	var action = get_action(action_key)
	assert(action != null, 'Action not found.')
	
	if tag and not tags.has(tag):
		tags.append(tag)
	
	action.name = action_name
	action.deadzone = deadzone
	action.single_event_mode = single_event
	if tag:
		action.tags = [tag]
		
	return action


func get_action(action_key :StringName):
	for action in actions:
		if action.key == action_key:
			return action
	return null


func del_action(action_key :StringName = ''):
	var action = get_action(action_key)
	if action:
		action.clear_events()
		actions.erase(action)
		if action.keymap_event_bounded.is_connected(_on_keymap_event_bounded):
			action.keymap_event_bounded.diconnect()
		if InputMap.has_action(action.key):
			InputMap.erase_action(action.key)
		

func add_tag(tag :StringName):
	if not tags.has(tag):
		tags.append(tag)
	return tags


func remove_tag(tag :StringName):
	if tags.has(tag):
		tags.erase(tag)
	for action in actions:
		if action.tags.has(tag):
			action.tags.erase(tag)


func clear_tags():
	tags.clear()		
	for action in actions:
		action.tags.clear()


func add_tag_to_action(tag:StringName, action:KeyChainAction):
	add_tag(tag)
	if not action.tags.has(tag):
		action.tags.append(tag)


func remove_tag_from_action(tag:StringName, action:KeyChainAction):
	action.tags.erase(tag)
	

func reset_action_tags():
	var removes :Array = []
	for tag in tags:
		if not tag:
			removes.append(tag)
	for r in removes:
		tags.erase(r)
			
	for action in actions:
		removes = []
		for atag in action.tags:
			if not tags.has(atag):
				removes.append(atag)
		for r in removes:
			action.tags.erase(r)


func _on_keymap_event_bounded(action_key, event, tag):
	match unique_event_mode:
		UniqueEventMode.ALL:
			for action in actions:
				if action.key == action_key:
					continue
				action.remove_event_from_actions(event)
		UniqueEventMode.TAG:
			for action in actions:
				if action.tag == tag:
					if action.key == action_key:
						continue
					action.remove_event_from_actions(event)
	keymap_bounded.emit(action_key, event, tag)


# static functions

static func makeEventMouseButton(event_key, cmd=false, shift=false, alt=false):
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = event_key
	event.alt_pressed = bool(alt)
	event.shift_pressed = bool(shift)
	event.command_or_control_autoremap = bool(cmd)
	return event


static func makeEventKey(event_key, cmd=false, shift=false, alt=false):
	var event: InputEventKey = InputEventKey.new()
	event.keycode = event_key
	event.alt_pressed = bool(alt)
	event.shift_pressed = bool(shift)
	event.command_or_control_autoremap = bool(cmd)
	return event
	

static func is_equal_input(evt_1 :Variant, evt_2 :Variant, not_strict :bool = true):
	# its possible to check event as `null`.
	if evt_1 is InputEventWithModifiers and evt_2 is InputEventWithModifiers:
		if evt_1 == evt_2:
			return true
		if not_strict:
			return evt_1.as_text() == evt_2.as_text()
		else:
			if evt_1 is InputEventKey and evt_2 is InputEventKey:
				if evt_1.keycode != evt_2.keycode:
					return false
				elif evt_1.key_label != evt_2.key_label:
					return false
				elif evt_1.physical_keycode != evt_2.physical_keycode:
					return false
				elif evt_1.unicode != evt_2.unicode:
					return false
			elif evt_1 is InputEventMouseButton and evt_2 is InputEventMouseButton:
				if evt_1.button_index != evt_2.button_index:
					return false
			return [
				evt_1.command_or_control_autoremap == evt_2.command_or_control_autoremap,
				evt_1.is_command_or_control_pressed() == evt_2.is_command_or_control_pressed(),
				evt_1.alt_pressed == evt_2.alt_pressed,
				evt_1.shift_pressed == evt_2.shift_pressed,
				evt_1.ctrl_pressed == evt_2.ctrl_pressed,
				evt_1.meta_pressed == evt_2.meta_pressed,
			].all(func(val): return val == true)
	else:
		return false
