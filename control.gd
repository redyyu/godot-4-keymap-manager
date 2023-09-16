extends Control

var keymap = [
	{
		'tag': 'Group 1',
		'actions': [
			{
				'key':'group-1-click-1', 'name': 'Test 1 Click 1',
			 	'events': [KeyChain.makeEventKey(KEY_X)]
			},
			{
				'key':'test-1', 'name': 'Test 1 Click 2',
			 	'events': [KeyChain.makeEventKey(KEY_C)]
			},
			{
				'key':'group-1-click-3', 'name': 'Test 1 Click 3',
			 	'events': [KeyChain.makeEventMouseButton(MOUSE_BUTTON_LEFT)]
			}
		]
	},
	{
		'tag': 'Group 2',
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

@onready var keymapManager :PanelContainer = $KeymapManager


func _ready():
	load_default_keymap()
	keymapManager.load_keychain(keyChain)


func load_default_keymap():
	for group in keymap:
		for act in group['actions']:
			var key_action = keyChain.add_action(act['key'], act['name'], group['tag'])
			for evt in act['events']:
				key_action.bind_event(evt)
#	keyChain.synchronize()


func _on_button_pressed():
	if not $Label.text:
		$Label.text = 'Clicked'
	else:
		$Label.text = ''
