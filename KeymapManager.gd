extends PanelContainer

class_name KeymapManager

var ico_add: Texture2D = preload("assets/add.svg")
var ico_edit: Texture2D = preload("assets/edit.svg")
var ico_delete: Texture2D = preload("assets/remove.svg")
var ico_key: Texture2D = preload("assets/keyboard.svg")
var ico_mouse: Texture2D = preload("assets/mouse.svg")
var ico_shortcut: Texture2D = preload("assets/shortcut.svg")
var ico_empty: Texture2D = preload("assets/trans.png")

var keyChain :KeyChain

enum {
	NORMAL,
	EDIT_KEYMAP,
	CONFLICT,
}
var state = NORMAL

var selected_item :TreeItem
var action_items :Array[TreeItem] = []
var tree_root :TreeItem
var conflicts :Array = []
var conflict_event :InputEvent 


enum ButtonId {
	DELETE,
	EDIT,
}

@onready var keymap_tree: Tree = $Tree
@onready var conflicts_info :Control = $ConflictsInfo
@onready var conflicts_text :Label = $ConflictsInfo/column/ConflictsText


func _ready():
	custom_minimum_size = Vector2(100, 100)
	keymap_tree.scroll_horizontal_enabled = false
	conflicts_info.hide()


func load_keychain(key_chain :KeyChain):
	keyChain = key_chain
	action_items.clear()
	tree_root = keymap_tree.create_item()
	
	for tag_group in keyChain.pack_actions_tree():
		var tag_tree = tree_root.create_child()
		tag_tree.set_text(0, tag_group['tag'])
		tag_tree.set_selectable(0, false)
		tag_tree.disable_folding = true
		for action in tag_group['actions']:
			var action_tree = tag_tree.create_child()
			action_items.append(action_tree)
			action_tree.set_text(0, action['name'])
			action_tree.collapsed = true
			action_tree.set_selectable(0, false)
			action_tree.set_metadata(0, action)
			for evt in action['events']:
				var evt_item = action_tree.create_child()
				evt_item.set_metadata(0, evt)
				set_event_item(evt_item)
	
	set_action_items()
	keymap_tree.button_clicked.connect(_on_button_click)


func show_conflicts_confirm(event):
	conflict_event = event
	var conflict_names :Array[StringName] = []
	for conflict in conflicts:
		conflict_names.append(conflict.name)
	
	conflicts_text.text = 'Key bind conflict: ' + ', '.join(conflict_names)
	conflicts_info.show()


func set_action_items():	
	# make sure `Add` item after all event items.
	for act_tree in action_items:
		var event_items = act_tree.get_children()
		if event_items.size() > 0:
			# check last item is not `add` button. add button has no metadata.
			var last_event_item = event_items[event_items.size() -1]
			if last_event_item.get_metadata(0):
				set_event_item(act_tree.create_child())
			else:
				set_event_item(last_event_item)
		else:
			set_event_item(act_tree.create_child())
			
	# release tree items.
	freeze_tree_items(true)
	
	state = NORMAL


func set_event_item(item):
	var event = item.get_metadata(0)
	if event:
		item.set_text(0, event.as_text())
		if event is InputEventMouseButton:
			item.set_icon(0, ico_mouse)
		else:
			item.set_icon(0, ico_key)
		item.set_icon_modulate(0, Color.WHITE)
		
		clear_item_buttons(item)
		item.add_button(0, ico_delete, ButtonId.DELETE, false, 'Delete')
		item.add_button(0, ico_edit, ButtonId.EDIT, false, 'Edit')
	else:
		if item.get_parent().get_child_count() > 1:
			item.set_text(0, 'Add new key')
		else:
			item.set_text(0, 'Unset')
		item.set_icon(0, ico_shortcut)
		item.set_icon_modulate(0, Color.DIM_GRAY)
		
		clear_item_buttons(item)
		item.add_button(0, ico_add, ButtonId.EDIT, false, 'Add')


func clear_item_buttons(item):
	while item.get_button_count(0) > 0:
		item.erase_button(0, item.get_button_count(0) -1)
#		await get_tree().create_timer(0.1).timeout


func freeze_tree_items(val :bool):
	for act_tree in action_items:
		act_tree.disable_folding = not val
		for evt_tree in act_tree.get_children():
			evt_tree.set_selectable(0, val)
	if val:
		keymap_tree.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		keymap_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	keymap_tree.scroll_vertical_enabled = val


func bind_event_to_item(item, event):
	var action = item.get_parent().get_metadata(0)
	var meta_event = item.get_metadata(0)
	
	if meta_event:
		action.bind_event(event, meta_event)
	else:
		action.bind_event(event)
	item.set_metadata(0, event)
	set_event_item(item)
	
	for act_item in action_items:
		var removes :Array = []
		for _item in act_item.get_children():
			if item == _item:
				continue
			if KeyChain.is_equal_input(event, _item.get_metadata(0)):
				removes.append(_item)
		for r in removes:  # DO NOT remove child in children loops.
			act_item.remove_child(r)


func _input(event):
	if not selected_item:
		return 

	match state:
		EDIT_KEYMAP:
			if not (event is InputEventKey):
				# DO NOT support InputEventMouseButton, useless in this case.
				return
			elif event.keycode == KEY_ESCAPE:
				set_event_item(selected_item)
				set_action_items()
			elif event.keycode < 200:
				# prevent special keys pressed alone. 
				conflicts = keyChain.find_event_exists(event)
				if conflicts.is_empty():
					bind_event_to_item(selected_item, event)
					set_action_items()
				else:
					show_conflicts_confirm(event)


func _on_button_click(item: TreeItem, _column: int, _id: int, _mouse_button_index: int):
	match _id:
		ButtonId.DELETE:
			var event = item.get_metadata(0)
			var action = item.get_parent().get_metadata(0)
			action.unbind_event(event)
			item.get_parent().remove_child(item)
			set_action_items()
			
		ButtonId.EDIT: 
			keymap_tree.set_selected(item, 0)
			item.set_text(0, 'Bind new key ...')
			item.set_icon(0, ico_empty)
			
			clear_item_buttons(item)
			
			# freeze all tree times
			freeze_tree_items(false)
			selected_item = item
			state = EDIT_KEYMAP


func _on_conflict_confirmed():
	conflicts_info.hide()
	bind_event_to_item(selected_item, conflict_event)
	set_action_items()


func _on_conflict_canceled():
	conflicts_info.hide()
	set_event_item(selected_item)
	set_action_items()
