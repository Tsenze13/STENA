## Щиток ЩР-6 крупным планом: автоматы, амперметр, лампа контактора привода решётки.
class_name PanelUI
extends Control

var G: Game
var is_open := false
var on_close: Callable
var buttons := {}
var amm: Control
var amm_label: Label
var km_lamp: ColorRect
var ang := -80.0

const BRK := [["qf0", "QF0", "ВВОД", Game.LIMIT], ["qf1", "QF1", "А · ОСВЕЩЕНИЕ", 10], ["qf2", "QF2", "Б · ПУЛЬТ", 4]]

func setup(g: Game) -> void:
	G = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.55); dim.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(dim)
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(cc)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 10); cc.add_child(vb)
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.5, 0.52, 0.48); sb.border_color = Color(0.29, 0.3, 0.27); sb.set_border_width_all(3); sb.set_corner_radius_all(6)
	box.add_theme_stylebox_override("panel", sb); box.custom_minimum_size = Vector2(640, 0); vb.add_child(box)
	var col := VBoxContainer.new(); col.add_theme_constant_override("separation", 0); box.add_child(col)
	var head := PanelContainer.new(); var hs := StyleBoxFlat.new(); hs.bg_color = Color(0.16, 0.17, 0.15); hs.set_content_margin_all(8); head.add_theme_stylebox_override("panel", hs); col.add_child(head)
	var hl := HBoxContainer.new(); head.add_child(hl)
	var t1 := Label.new(); t1.text = "ЩР-6"; t1.add_theme_color_override("font_color", Color(1, 0.86, 0.29)); hl.add_child(t1)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hl.add_child(sp)
	var t2 := Label.new(); t2.text = "~380/220 В · ВВОД 20 А"; t2.add_theme_color_override("font_color", Color(0.84, 0.82, 0.74)); hl.add_child(t2)
	var bodyv := VBoxContainer.new(); bodyv.add_theme_constant_override("separation", 14)
	var mc := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + s, 16)
	mc.add_child(bodyv); col.add_child(mc)
	## амперметр
	var ac := CenterContainer.new(); bodyv.add_child(ac)
	amm = _Amm.new(); amm.ui = self; amm.custom_minimum_size = Vector2(230, 140); ac.add_child(amm)
	## автоматы
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 10)
	var rp := PanelContainer.new(); var rs := StyleBoxFlat.new(); rs.bg_color = Color(0.17, 0.18, 0.16); rs.set_content_margin_all(14); rp.add_theme_stylebox_override("panel", rs)
	rp.add_child(row); bodyv.add_child(rp)
	for b in BRK:
		var btn := Button.new(); btn.custom_minimum_size = Vector2(110, 120); btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _toggle(b[0]))
		row.add_child(btn); buttons[b[0]] = btn
	## контактор V
	var km := HBoxContainer.new(); km.add_theme_constant_override("separation", 12); bodyv.add_child(km)
	km_lamp = ColorRect.new(); km_lamp.custom_minimum_size = Vector2(22, 22); km.add_child(km_lamp)
	var kl := Label.new(); kl.text = "КМ-V · привод ГД-6 · 14 А — управление только с пульта (терминал)"; kl.add_theme_color_override("font_color", Color(0.08, 0.09, 0.07)); km.add_child(kl)
	var plate := Label.new(); plate.text = "Нагрузки: А — освещение 10 А · Б — пульт 4 А · V — гермодверь 14 А"
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; plate.add_theme_color_override("font_color", Color(0.16, 0.18, 0.15)); bodyv.add_child(plate)
	var hint := Label.new(); hint.text = "Щёлкай по автоматам (или 1 2 3) · E или Esc — закрыть щиток"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_color_override("font_color", Color(0.55, 0.52, 0.46)); vb.add_child(hint)
	visible = false

class _Amm extends Control:
	var ui
	func _draw() -> void:
		var c := Vector2(size.x / 2, size.y - 22)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.89, 0.82))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.13, 0.13), false, 2.0)
		draw_arc(c, 85, deg_to_rad(-170), deg_to_rad(-10), 32, Color(0.13, 0.13, 0.13), 2.0)
		draw_arc(c, 80, deg_to_rad(-90 + (-80 + 160 * 20 / 30.0)), deg_to_rad(-10), 16, Color(0.7, 0.15, 0.12), 7.0)
		var f := ThemeDB.fallback_font
		for a in range(0, 31, 5):
			var t := deg_to_rad(-90 + (-80 + 160 * a / 30.0))
			draw_line(c + Vector2(cos(t), sin(t)) * 85, c + Vector2(cos(t), sin(t)) * 74, Color(0.13, 0.13, 0.13), 1.5)
			draw_string(f, c + Vector2(cos(t), sin(t)) * 62 + Vector2(-8, 5), str(a), HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color(0.13, 0.13, 0.13))
		var na := deg_to_rad(-90 + ui.ang)
		draw_line(c, c + Vector2(cos(na), sin(na)) * 78, Color(0.07, 0.07, 0.07), 2.5)
		draw_circle(c, 6, Color(0.07, 0.07, 0.07))
		draw_string(f, Vector2(0, size.y - 4), "%d А из %d" % [ui.G.load_a(), Game.LIMIT], HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(0.13, 0.13, 0.13))

func _toggle(k: String) -> void:
	Audio.play("click")
	G.set_line(k, not G.S[k])
	render()

func render() -> void:
	for b in BRK:
		var on: bool = G.S[b[0]]
		var btn: Button = buttons[b[0]]
		btn.text = "%s\n\n%s\n%s\n%d А" % ["▮ I" if on else "▯ O", b[1], b[2], b[3]]
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.94, 0.88, 0.7) if b[0] == "qf0" else Color(0.91, 0.9, 0.86)
		if b[0] == "qf0" and not on and G.S.trips > 0: st.border_color = Color(0.7, 0.15, 0.12); st.set_border_width_all(3)
		for s in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(s, st)
		for s in ["font_color", "font_hover_color", "font_pressed_color"]:
			btn.add_theme_color_override(s, Color(0.08, 0.09, 0.07) if on else Color(0.45, 0.2, 0.15))
	km_lamp.color = Color(1, 0.29, 0.23) if G.S.v else Color(0.24, 0.08, 0.06)
	amm.queue_redraw()

func _process(dt: float) -> void:
	if not is_open: return
	var target := -80.0 + 160.0 * minf(G.load_a(), 30.0) / 30.0
	ang += (target - ang) * min(1.0, dt * 8.0)
	amm.queue_redraw()

func open_ui() -> void:
	is_open = true; visible = true; render(); Audio.play("heavy", -4.0)

func close() -> void:
	is_open = false; visible = false; Audio.play("click", -6.0)
	if on_close.is_valid(): on_close.call()

func key(e: InputEventKey) -> void:
	var c := e.physical_keycode
	if c == KEY_ESCAPE or c == KEY_E: close()
	elif c >= KEY_1 and c <= KEY_3: _toggle(BRK[c - KEY_1][0])
