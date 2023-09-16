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
	EDIT_KEYMAP
}
var state = NORMAL

var selected_item :TreeItem
var action_items :Array[TreeItem] = []
var tree_root :TreeItem


enum ButtonId {
	DELETE,
	EDIT,
}

@onready var keymap_tree: Tree = $Tree
#@onready var info_panel: Panel = $Panel


func _ready():
	custom_minimum_size = Vector2(100, 100)
	keymap_tree = Tree.new()
	keymap_tree.set_anchors_preset(Control.PRESET_FULL_RECT)
	keymap_tree.hide_root = true
#	info_panel.hide()


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
				set_keymap_item(evt_item)
	
	release_action_items()
	keymap_tree.button_clicked.connect(_on_button_click)


func release_action_items():
	mouse_filter = Control.MOUSE_FILTER_STOP
	state = NORMAL
		
	# make sure `Add` item after all event items.
	for act_tree in action_items:
		var event_items = act_tree.get_children()
		if event_items.size() > 0:
			# check last item is not `add` button. add button has no metadata.
			var last_event_item = event_items[event_items.size() -1]
			if last_event_item.get_metadata(0):
				set_keymap_item(act_tree.create_child())
			else:
				set_keymap_item(last_event_item)
		else:
			set_keymap_item(act_tree.create_child())
			
	# reset selectable for all event items.
	set_items_selectable(true)


func set_keymap_item(item):
	var event = item.get_metadata(0)
	if event:
		item.set_text(0, event.as_text())
		if event is InputEventMouseButton:
			item.set_icon(0, ico_mouse)
		else:
			item.set_icon(0, ico_key)
		
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


func set_items_selectable(val :bool):
	for act_tree in action_items:
		for evt_tree in act_tree.get_children():
			evt_tree.set_selectable(0, val)


func _input(event):
	if not selected_item:
		return 

	match state:
		EDIT_KEYMAP:
			if not (event is InputEventKey):
				# DO NOT support InputEventMouseButton, useless in this case.
				return

			var edit_item = selected_item
			var action = selected_item.get_parent().get_metadata(0)
			var meta_event = selected_item.get_metadata(0)
			
			if event.keycode == KEY_ESCAPE:
				set_keymap_item(edit_item)
				release_action_items()
			elif event.keycode < 200:
				# prevent special keys pressed alone. 
				var actions = keyChain.find_event_exists(event)
				if actions.is_empty():
					action.update_event(meta_event, event)
					edit_item.set_metadata(0, event)
					set_keymap_item(edit_item)
					
					for act_item in action_items:
						var removes :Array = []
						for _item in act_item.get_children():
							if edit_item == _item:
								continue
							if KeyChain.is_equal_input(event, _item.get_metadata(0)):
								removes.append(_item)
						for r in removes:  # DO NOT remove child in children loops.
							act_item.remove_child(r)
					release_action_items()
				else:
					var action_names :Array = []
					for act in actions:
						action_names.append(act.name)


func _on_button_click(item: TreeItem, _column: int, _id: int, _mouse_button_index: int):
	match _id:
		ButtonId.DELETE:
			var event = item.get_metadata(0)
			var action = item.get_parent().get_metadata(0)
			action.unbind_event(event)
			item.get_parent().remove_child(item)
			release_action_items()
			
		ButtonId.EDIT: 
			keymap_tree.set_selected(item, 0)
			item.set_text(0, 'Bind new key ...')
			item.set_icon(0, ico_empty)
			
			clear_item_buttons(item)
			set_items_selectable(false)
			
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			selected_item = item
			state = EDIT_KEYMAP

