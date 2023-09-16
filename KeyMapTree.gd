extends Tree

class_name KeymapTree

var event_items :Array[TreeItem] = []
var last_treeitem :TreeItem
var last_metadata :Dictionary

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
	EDIT_KEYMAP
}
var state = NORMAL

var selected_item :TreeItem
var keymap_items :Array[TreeItem] = []


func _ready():
	custom_minimum_size = Vector2(100, 100)
	

func _input(event):
#	if event is InputEventKey:
#		print('cmd/ctrl:', event.is_command_or_control_pressed() or event.ctrl_pressed, 
#			  '  alt:', event.alt_pressed,
#			  '  shift:', event.shift_pressed)
#		print('keycode:', [KEY_ALT, KEY_META, KEY_CTRL, KEY_SHIFT, KEY_CAPSLOCK].has(event.keycode))
#	return
	if not selected_item:
		return 

	match state:
		EDIT_KEYMAP:
			if not (event is InputEventKey):
				return
				
			var edit_item = selected_item
			var meta = selected_item.get_metadata(0)

			if event.keycode == KEY_ESCAPE:
				reset_keymap_item(edit_item)
			elif event.keycode < 200:
				# prevent special keys pressed alone. 
				# DO NOT support InputEventMouseButton, useless in this case.
				meta['group'].bind_action_event(meta['action_key'],event)
				edit_item.set_metadata(0, {
					'group': meta['group'],
					'action_key': meta['action_key'],
					'event': event,
				})
				for _item in keymap_items:
					if edit_item != _item:
						var _meta = _item.get_metadata(0)
						if KeyChain.is_equal_input(event, _meta['event']):
							_item.set_metadata(0, {
								'group': _meta['group'],
								'action_key': _meta['action_key'],
								'event': null,
							})
					reset_keymap_item(_item)


func reset_keymap_item(item):
	var meta = item.get_metadata(0)
	
	if meta['event']:
		item.set_text(0, meta['event'].as_text())
		if meta['event'] is InputEventMouseButton:
			item.set_icon(0, ico_mouse)
		else:
			item.set_icon(0, ico_key)
		
		clear_item_buttons(item)	
		item.add_button(0, ico_delete, 0, false, 'Delete')
		item.add_button(0, ico_edit, 1, false, 'Edit')
	else:
		item.set_text(0, 'Unset')
		item.set_icon(0, ico_empty)
		clear_item_buttons(item)
		item.add_button(0, ico_add, 0, false, 'Add')
		
	# reset selectable for all items.
	for _item in keymap_items:
		_item.set_selectable(0, true)
		
	mouse_filter = Control.MOUSE_FILTER_STOP
	state = NORMAL


func clear_item_buttons(item):
	while item.get_button_count(0) > 0:
		item.erase_button(0, item.get_button_count(0) -1)
#		await get_tree().create_timer(0.1).timeout


func load_tree(key_chain :KeyChain):
	keyChain = key_chain
	keymap_items.clear()
	
	var root = create_item()
	
	hide_root = true
	for group in keyChain.list_groups():
		var group_tree = root.create_child()
		group_tree.set_text(0, group.name)
		group_tree.set_selectable(0, false)
		group_tree.disable_folding = true
		for action in group.list_actions():
			var action_tree = group_tree.create_child()
			action_tree.set_text(0, action['name'])
			action_tree.collapsed = true
			action_tree.set_selectable(0, false)
			for evt in action['events']:
				var evt_tree = action_tree.create_child()
				evt_tree.set_text(0, evt.as_text())
				evt_tree.add_button(0, ico_delete, 0, false, 'Delete')
				evt_tree.add_button(0, ico_edit, 1, false, 'Edit')
				
				if evt is InputEventMouseButton:
					evt_tree.set_icon(0, ico_mouse)
				else:
					evt_tree.set_icon(0, ico_key)
				evt_tree.set_metadata(0, {
					'group': group,
					'action_key': action['key'],
					'event': evt,
				})
				keymap_items.append(evt_tree)
			if action['events'].is_empty():
				var new_evt_tree = action_tree.create_child()
				new_evt_tree.set_text(0, 'Unset')
				new_evt_tree.add_button(0, ico_add, 0, false, 'Add')
				new_evt_tree.set_metadata(0, {
					'group': group,
					'action_key': action['key'],
					'event': null,
				})
				keymap_items.append(new_evt_tree)
	
	button_clicked.connect(_on_button_click)
	

func _on_button_click(item: TreeItem, _column: int, _id: int, _mouse_button_index: int):
	set_selected(item, 0)
	item.set_text(0, 'Bind new key ...')
	item.set_icon(0, ico_empty)
	
	clear_item_buttons(item)
	
	state = EDIT_KEYMAP

	for _item in keymap_items:
		_item.set_selectable(0, false)
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
#	get_tree().root.get_children()[0].set_process_input(false)
	selected_item = item

