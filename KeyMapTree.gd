extends Tree

class_name KeymapTree

signal setting_up_keymap(tree)

var event_items :Array[TreeItem] = []
var last_treeitem :TreeItem
var last_metadata :Dictionary

var ico_add: Texture2D = preload("assets/add.svg")
var ico_edit: Texture2D = preload("assets/edit.svg")
var ico_key: Texture2D = preload("assets/keyboard.svg")
var ico_mouse: Texture2D = preload("assets/mouse.svg")
var ico_shortcut: Texture2D = preload("assets/shortcut.svg")

var keyChain :KeyChain


func _ready():
#	set_anchors_preset(Control.PRESET_FULL_RECT)
#	anchors_preset = Control.PRESET_FULL_RECT
	custom_minimum_size = Vector2(100, 100)
	

func load_tree(key_chain :KeyChain):
	keyChain = key_chain
	
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
				evt_tree.add_button(0, ico_edit, 0, false, 'Edit')
				if evt is InputEventMouseButton:
					evt_tree.set_icon(0, ico_mouse)
				else:
					evt_tree.set_icon(0, ico_key)
				evt_tree.set_metadata(0, {
					'action_key': action['key'],
					'event': evt
				})
			if action['events'].is_empty():
				var new_evt_tree = action_tree.create_child()
				new_evt_tree.set_text(0, 'Unset')
				new_evt_tree.add_button(0, ico_add, 0, false, 'Add')
				new_evt_tree.set_metadata(0, {
					'action_key': action['key'],
					'event': null
				})
				
	item_selected.connect(_on_tree_item_selected)
	item_collapsed.connect(_on_tree_item_collapsed)
#	nothing_selected.connect(_on_nothing_selected)


func restore_itemtree(treeitem :TreeItem):
	var metadata = treeitem.get_metadata(0)
	if metadata['event']:
		treeitem.set_text(0, metadata['event'].as_text())
		if metadata['event'] is InputEventKey:
			treeitem.set_icon(0, ico_shortcut)
		elif metadata['event'] is InputEventMouseButton:
			treeitem.set_icon(0, ico_mouse)
		treeitem.add_button(0, ico_edit, 0, false, 'Edit')
	else:
		treeitem.set_text(0, 'Unset')
		treeitem.set_icon(0, null)
		treeitem.add_button(0, ico_add, 0, false, 'Add')


func _on_tree_item_collapsed(treeitem :TreeItem):
	for child in treeitem.get_children():
		restore_itemtree(child)


func _on_tree_item_selected():
	var selected_treeitem = get_selected()
	selected_treeitem.set_text(0, 'Bind new key ...')
	selected_treeitem.erase_button(0, 0)
	selected_treeitem.set_icon(0, null)
	
	if last_treeitem and last_treeitem != selected_treeitem:
		restore_itemtree(last_treeitem)
#		
	last_treeitem = selected_treeitem
	
	setting_up_keymap.emit(self)
