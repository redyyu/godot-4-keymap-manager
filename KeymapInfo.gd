extends PanelContainer


@onready var label = $Label
@onready var btn_confirm = $BtnConfirm
@onready var btn_cancel = $BtnCancel


func set_conflict_info(action_names):
	var text = ', '.join(action_names)
