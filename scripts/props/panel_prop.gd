@tool
## Щиток ЩР-6 на стене ниши: модель (props.gd, PanelModel) и зона взаимодействия «E — открыть щиток».
class_name PanelProp
extends LevelPart

var model: Props.PanelModel

func _build() -> void:
	model = Props.PanelModel.new()
	gen.add_child(model.node)
	Geo.act_zone(gen, Vector3(0.8, 1.0, 0.5), Vector3(0, 0, 0.1), "panel")
