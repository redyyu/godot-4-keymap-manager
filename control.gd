extends Control

var keymap = [
	{
		'key': 'group-1',
		'name': 'Group 1',
		'actions': [
			{
				'key':'group-1-click-1', 'name': 'Test 1 Click 1',
			 	'events': [KeyChain.makeEventKey(KEY_X)]
			},
			{
				'key':'group-1-click-2', 'name': 'Test 1 Click 2',
			 	'events': [KeyChain.makeEventKey(KEY_C)]
			},
			{
				'key':'group-1-click-3', 'name': 'Test 1 Click 3',
			 	'events': [KeyChain.makeEventMouseButton(MOUSE_BUTTON_LEFT)]
			}
		]
	},
	{
		'key': 'group-2',
		'name': 'Group 2',
		'actions': [
			{
				'key':'group-2-click-1', 'name': 'Test 2 Click 1',
			 	'events': [KeyChain.makeEventKey(KEY_A, false, false, true)]
			},
			{
				'key':'group-2-click-2', 'name': 'Test 2 Click 2',
			 	'events': [KeyChain.makeEventKey(KEY_S, false, true)]
			},
			{
				'key':'group-2-click-3', 'name': 'Test 2 Click 3',
			 	'events': [KeyChain.makeEventKey(KEY_D, true)]
			},
			{
				'key':'group-2-click-4', 'name': 'DUP Test 1 Click 3',
			 	'events': [KeyChain.makeEventMouseButton(MOUSE_BUTTON_LEFT)]
			}
		]
	}
]

var keyChain = KeyChain.new()
var keymapTree = KeymapTree.new()

@onready var panel :PanelContainer = $PanelContainer


func _ready():
	load_default_keymap()
	keymapTree.load_tree(keyChain)
	keymapTree.set_anchors_preset(Control.PRESET_FULL_RECT)
	keymapTree.custom_minimum_size = Vector2(100, 100)
	panel.add_child(keymapTree)


func load_default_keymap():	
	for item in keymap:
		var key_group = keyChain.add_group(item['key'], item['name'])
		for act in item['actions']:
			key_group.add_action(act['key'], act['name'])
			for evt in act['events']:
				key_group.bind_action_event(act['key'], evt)
	keyChain.synchronize()
