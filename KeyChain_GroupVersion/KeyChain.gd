extends Resource

class_name KeyChain

const DEFAULT_GROUP_KEY = 'default'

signal keymap_bounded(group_key, event)

@export var ordered_groups:Array = []
@export var groups_dict:Dictionary = {}

# same event only exist in one group.
@export var unique_event_cross_groups = true  
# BTW, event always be unique in group.


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


func _ready():
	if groups_dict.is_empty():
		add_group(DEFAULT_GROUP_KEY, DEFAULT_GROUP_KEY.capitalize())
	
	for group in ordered_groups:
		group.keymap_event_bounded.connect(_on_keymap_event_bounded)
	

func synchronize(empty_exists :bool = false):
	if empty_exists:
		for act in InputMap.get_actions():
			InputMap.erase_action(act)
	
	for k in groups_dict:
		groups_dict[k].sync()


func clear():
	for k in groups_dict:
		groups_dict[k].clear()
	ordered_groups.clear()
	groups_dict.clear()


func clear_events():
	for k in groups_dict:
		groups_dict[k].clear_events()


func remove_event(event):
	for k in groups_dict:
		groups_dict[k].remove_event(event)


func add_group(group_key :StringName, group_name :String = ''):
	if not group_name:
		group_name = group_key.capitalize()
	
	var group
	
	if groups_dict.has(group_key):
		group = groups_dict[group_key]
		group.name = group_name
	else:
		group = KeyChainGroup.new()
		group.name = group_name
		group.key = group_key
	
		groups_dict[group_key] = group
		ordered_groups.append(group)
		group.keymap_event_bounded.connect(_on_keymap_event_bounded)
	return group


func list_groups():
	return ordered_groups


func get_group(group_key :StringName = ''):
	if not group_key:
		group_key = DEFAULT_GROUP_KEY
	return groups_dict.get(group_key)


func del_group(group_key :StringName = ''):
	var group = get_group(group_key)
	if group:
		group.clear()
		ordered_groups.erase(group)
		groups_dict.erase(group_key)
		if group.keymap_event_bounded.is_connected(_on_keymap_event_bounded):
			group.keymap_event_bounded.diconnect()
		

func _on_keymap_event_bounded(group_key, event):
	if unique_event_cross_groups:
		for _group in ordered_groups:
			if _group.key == group_key:
				continue
			_group.remove_event_from_actions(event)
	keymap_bounded.emit(group_key, event)
