# version: 0.1.0
# https://github.com/redyyu/godot-4-keymap-manager
# redy.ru@gmail.com

class_name KeyChain extends Resource

enum UniqueEventMode {
	NONE,
	ALL,
	TAG,
}

signal keymap_bounded(group_key, event)

@export var actions :Array[KeyChainAction] = []
@export var tags :Array = []

# same event only exist in one action.
@export var unique_event_mode = UniqueEventMode.ALL
# BTW, event always be unique in group.

@export var single_event_mode = false


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


# return a list or dict. list as default.
func pack_actions_tree(as_list :bool = true) -> Variant: 
	var output :Dictionary = {'': []}
	var output_list :Array = []
	for tag in tags:
		output[tag] = []
		
	for action in actions:
		if action.tags.is_empty():
			output[''].append(action)
		else:
			for t in action.tags:
				if output.has(t):
					output[t].append(action)
	if as_list:
		for tag in tags:
			output_list.append({
				'tag': tag,
				'actions': output[tag]
			})
		output_list.append({
			'tag': '',
			'actions': output['']
		})
		return output_list
	else:
		return output


func search_actions_by_tag(by_tag :StringName = '') -> Array:
	var output :Array = []
	for action in actions:
		if by_tag:
			if action.tags.has(by_tag):
				output.append(action)
		else:
			if action.tags.is_empty():
				output.append(action)
	return output


func add_action(action_key :StringName, 
				action_name :String = '',
				tag :StringName = '', 
				deadzone: float = 0.5) -> KeyChainAction:
					
	if not action_name:
		action_name = action_key.capitalize()
	
	var action :KeyChainAction
	
	action = get_action(action_key)
	assert(action == null, 
		   'Action key must bee not duplicated. - {a}'.format({'a':action_key}))
	
	add_tag(tag)
	
	action = KeyChainAction.new()
	action.key = action_key
	action.name = action_name
	action.deadzone = deadzone
	action.single_event_mode = single_event_mode
	action.tags = [tag] if tag else []

	actions.append(action)
	action.keymap_event_bounded.connect(_on_keymap_event_bounded)
	if not InputMap.has_action(action_key): 
		InputMap.add_action(action_key)
		
	return action


func update_action(action_key :StringName, 
				   action_name :String = '',
				   tag :StringName = '', 
				   deadzone: float = 0.5) -> KeyChainAction:
					
	if not action_name:
		action_name = action_key.capitalize()
	
	var action = get_action(action_key)
	assert(action != null, 'Action not found. - {a}'.format({'a':action_key}))
	
	add_tag(tag)
		
	action.name = action_name
	action.deadzone = deadzone
	action.single_event_mode = single_event_mode
	action.tags = [tag] if tag else []
		
	return action


# get a KeyChainAction or null.
func get_action(action_key :StringName):
	for action in actions:
		if action.key == action_key:
			return action
	return null


func del_action(action_key :StringName):
	var action = get_action(action_key)
	if action:
		action.clear_events()
		actions.erase(action)
		if action.keymap_event_bounded.is_connected(_on_keymap_event_bounded):
			action.keymap_event_bounded.diconnect()
		if InputMap.has_action(action.key):
			InputMap.erase_action(action.key)
		

func add_tag(tag :StringName) -> Array:
	if tag and (not tags.has(tag)):
		tags.append(tag)
	return tags


func remove_tag(tag :StringName):
	if tags.has(tag):
		tags.erase(tag)
	# keep remove tag from action, even tag is not exists in `tags`.
	for action in actions:
		if action.tags.has(tag):
			action.tags.erase(tag)


func append_tags(new_tags: Array):
	for t in new_tags:
		if t is StringName or t is String:
			tags.append(t)


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


func find_event_exists(event :InputEvent, 
					   by_tags = false) -> Array:
						
	var confilicts :Array = []
	
	if by_tags == false:
		for act in actions:
			if act.has_event(event):
				confilicts.append(act)
	else:
		if by_tags is String or by_tags is StringName:
			by_tags = [by_tags]
		elif not by_tags is Array:
			by_tags = []
		
		if by_tags.is_empty():
			for act in actions:
				if act.tags.is_empty() and act.has_event(event):
					confilicts.append(act)
		else:
			for t in by_tags:
				for act in actions:
					if act.tags.has(t) and act.has_event(event):
						confilicts.append(act)

	return confilicts


func _on_keymap_event_bounded(action_key, event, action_tags):
	match unique_event_mode:
		UniqueEventMode.ALL:
			for action in actions:
				if action.key != action_key:
					action.unbind_event(event)
		UniqueEventMode.TAG:
			if action_tags.is_empty():
				for action in actions:
					if action.key != action_key and action.tags.is_empty():
						action.unbind_event(event)
			else:
				for tag in action_tags:
					for action in actions:
						if action.key != action_key and action.tags.has(tag):
							action.unbind_event(event)
	keymap_bounded.emit(action_key, event, action_tags)


# static functions

static func makeEventMouseButton(event_key :MouseButton, 
								 cmd :bool=false,
								 shift :bool=false,
								 alt :bool=false) -> InputEventMouseButton:

	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = event_key
	event.alt_pressed = bool(alt)
	event.shift_pressed = bool(shift)
	event.command_or_control_autoremap = bool(cmd)
	return event


static func makeEventKey(event_key :Key,
						 cmd :bool=false,
						 shift :bool=false,
						 alt :bool=false) -> InputEventKey:

	var event: InputEventKey = InputEventKey.new()
	event.keycode = event_key
	event.alt_pressed = bool(alt)
	event.shift_pressed = bool(shift)
	event.command_or_control_autoremap = bool(cmd)
	return event
	

static func is_equal_input(evt_1, evt_2, not_strict :bool = true) -> bool:
	# use Variant, because its possible to check event as `null`.
	
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
			elif (evt_1 is InputEventMouseButton and 
				  evt_2 is InputEventMouseButton):
				if evt_1.button_index != evt_2.button_index:
					return false
			
			# use those for save line width only.
			var evt_1_command_automap = evt_1.command_or_control_autoremap
			var evt_2_command_automap = evt_2.command_or_control_autoremap
			var evt_1_cmd_pressed = evt_1.is_command_or_control_pressed()
			var evt_2_cmd_pressed = evt_2.is_command_or_control_pressed()
			
			return [
				evt_1_command_automap == evt_2_command_automap,
				evt_1_cmd_pressed == evt_2_cmd_pressed,
				evt_1.alt_pressed == evt_2.alt_pressed,
				evt_1.shift_pressed == evt_2.shift_pressed,
				evt_1.ctrl_pressed == evt_2.ctrl_pressed,
				evt_1.meta_pressed == evt_2.meta_pressed,
			].all(func(val): return val == true)
	else:
		return false


# Key Actions

class KeyChainAction extends Resource:

	signal keymap_event_bounded(group, event)

	const ERR_ACTION_NOT_EXIST = 'Keymap action dose not exist.'

	@export var key :StringName = ''
	@export var name :String = ''
	@export var deadzone :float = 0.5
	@export var tags :Array = []
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
		if InputMap.action_get_events(key).size() > 0:
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


	func count_events() -> int:
		return events.size()


	func has_event(event:InputEventWithModifiers) -> bool:
		for evt in events:
			if KeyChain.is_equal_input(evt, event):
				return true
		return false


	func bind_event(event:InputEventWithModifiers, old_event:Variant = null):
		var insert_index = 0
		
		if single_event_mode:
			# clear up other events before append new one.
			for evt in events:
				unbind_event(evt)
			# NO NEED events.clear(), already removed all in unbind_event().
		else:
			if old_event is InputEventWithModifiers:
				# remove old event and take the place.
				for i in events.size():
					if old_event == events[i]:
						unbind_event(old_event)
						insert_index = i
						break
			# make sure event not duplicated.
			unbind_event(event)
		# append new event to action events.
		if not events.has(event):
			events.insert(insert_index, event)
			keymap_event_bounded.emit(key, event, tags)
			if InputMap.has_action(key):
				InputMap.action_add_event(key, event)


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
