## Экраны и подсказки: старт, пауза, финал, прицел, подсказка взаимодействия, всплывающие сообщения, записка.
class_name Hud
extends CanvasLayer

var start_screen: Control
var pause_screen: Control
var end_screen: Control
var end_text: Label
var note_screen: Control
var prompt: Label
var toast_l: Label
var toast_t := 0.0
var cross: ColorRect
var fade: ColorRect
var hint: Label
var on_start: Callable
var on_resume: Callable
var on_volume: Callable
var on_sens: Callable

const NOTE := "Смена 3 · 20.03.91\n\nРешётку опять закрыли.\nКод сбросили на год ввода участка —\nон на табличке у решётки.\n\nНа 7-й свет не давать.\nОни идут на ток.\n\nУхожу наверх.\n                              В. Калинин"

func _font(names: Array, bold := false) -> SystemFont:
	var f := SystemFont.new(); f.font_names = PackedStringArray(names); f.font_weight = 700 if bold else 400
	return f

func build(version: String) -> void:
	layer = 10
	var title_font := _font(["Oswald", "Bahnschrift", "Arial Narrow", "DejaVu Sans Condensed", "Liberation Sans Narrow"], true)
	## прицел, подсказка, сообщения
	cross = ColorRect.new(); cross.size = Vector2(4, 4); cross.color = Color(1, 1, 1, 0.55)
	cross.set_anchors_preset(Control.PRESET_CENTER); cross.position -= Vector2(2, 2); add_child(cross)
	prompt = _label("", 15, Color(1, 0.7, 0.28)); prompt.set_anchors_preset(Control.PRESET_CENTER)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.position = Vector2(-300, 34); prompt.size = Vector2(600, 24); add_child(prompt)
	toast_l = _label("", 15, Color(0.85, 0.82, 0.76)); toast_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; toast_l.position = Vector2(-400, 80); toast_l.size = Vector2(800, 24); add_child(toast_l)
	hint = _label("Tab — ПТ-1", 12, Color(0.37, 0.35, 0.31)); hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); hint.position = Vector2(18, -28); add_child(hint)
	fade = ColorRect.new(); fade.color = Color(0, 0, 0, 0); fade.set_anchors_preset(Control.PRESET_FULL_RECT); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(fade)
	## старт
	start_screen = _screen(Color(0, 0, 0, 1))
	var sv := _col(start_screen)
	var t := _label("С Т Е Н А", 110, Color(0.91, 0.88, 0.8)); t.add_theme_font_override("font", title_font); sv.add_child(t)
	sv.add_child(_label("Прототип · Глава 0 · Электрощитовая", 16, Color(0.54, 0.52, 0.46)))
	var b := _button("ВОЙТИ"); b.pressed.connect(func(): if on_start.is_valid(): on_start.call()); sv.add_child(b)
	sv.add_child(_label("W A S D — идти   ·   Мышь — смотреть   ·   E — взаимодействовать\nF — фонарик   ·   Tab — наручный терминал   ·   Shift — быстрее   ·   Esc — пауза", 13, Color(0.54, 0.52, 0.46)))
	sv.add_child(_label("Лучше в наушниках и в темноте.   Версия " + version, 12, Color(0.37, 0.35, 0.31)))
	## пауза
	pause_screen = _screen(Color(0, 0, 0, 0.8)); pause_screen.visible = false
	var pv := _col(pause_screen)
	var pt := _label("ПАУЗА", 34, Color(0.91, 0.88, 0.8)); pt.add_theme_font_override("font", title_font); pv.add_child(pt)
	var rb := _button("ПРОДОЛЖИТЬ"); rb.pressed.connect(func(): if on_resume.is_valid(): on_resume.call()); pv.add_child(rb)
	pv.add_child(_slider("Громкость", 0.0, 1.0, 0.8, func(v): if on_volume.is_valid(): on_volume.call(v)))
	pv.add_child(_slider("Чувствительность мыши", 0.3, 2.5, 1.0, func(v): if on_sens.is_valid(): on_sens.call(v)))
	var qb := _button("ВЫЙТИ ИЗ ИГРЫ"); qb.pressed.connect(func(): get_tree().quit()); pv.add_child(qb)
	## записка
	note_screen = _screen(Color(0, 0, 0, 0.55)); note_screen.visible = false
	var nv := _col(note_screen)
	var paper := PanelContainer.new(); var ps := StyleBoxFlat.new(); ps.bg_color = Color(0.91, 0.89, 0.81); ps.set_content_margin_all(28); paper.add_theme_stylebox_override("panel", ps)
	paper.rotation = -0.02; paper.custom_minimum_size = Vector2(460, 0)
	var nl := _label(NOTE, 18, Color(0.16, 0.15, 0.13)); nl.add_theme_font_override("font", _font(["Segoe Print", "Comic Sans MS", "DejaVu Serif"])); paper.add_child(nl)
	nv.add_child(paper); nv.add_child(_label("E или Esc — положить", 13, Color(0.54, 0.52, 0.46)))
	## финал
	end_screen = _screen(Color(0.01, 0.01, 0.01, 1)); end_screen.visible = false
	var ev := _col(end_screen)
	var et := _label("Конец прототипа", 34, Color(0.91, 0.88, 0.8)); et.add_theme_font_override("font", title_font); ev.add_child(et)
	end_text = _label("", 15, Color(0.54, 0.52, 0.46)); ev.add_child(end_text)
	var qb2 := _button("ВЫЙТИ"); qb2.pressed.connect(func(): get_tree().quit()); ev.add_child(qb2)

func _label(text: String, size_px: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.add_theme_font_size_override("font_size", size_px); l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _button(text: String) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size = Vector2(220, 48)
	var st := StyleBoxFlat.new(); st.bg_color = Color(1, 0.7, 0.28); st.set_corner_radius_all(2)
	var sh := st.duplicate(); sh.bg_color = Color(1, 0.78, 0.45)
	b.add_theme_stylebox_override("normal", st); b.add_theme_stylebox_override("hover", sh); b.add_theme_stylebox_override("pressed", sh); b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color(0.07, 0.05, 0.02))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b

func _slider(text: String, lo: float, hi: float, v: float, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 12); h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(_label(text, 14, Color(0.54, 0.52, 0.46)))
	var s := HSlider.new(); s.min_value = lo; s.max_value = hi; s.step = 0.05; s.value = v; s.custom_minimum_size = Vector2(200, 20)
	s.value_changed.connect(cb); h.add_child(s)
	return h

func _screen(bg: Color) -> Control:
	var c := ColorRect.new(); c.color = bg; c.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(c)
	return c

func _col(parent: Control) -> VBoxContainer:
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); parent.add_child(cc)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 18); v.alignment = BoxContainer.ALIGNMENT_CENTER; cc.add_child(v)
	return v

func toast(txt: String, sec := 3.5) -> void:
	toast_l.text = txt; toast_t = sec

func set_prompt(txt: String) -> void:
	prompt.text = txt
	cross.color = Color(1, 0.7, 0.28, 0.95) if txt != "" else Color(1, 1, 1, 0.55)

func show_end(txt: String) -> void:
	end_text.text = txt; end_screen.visible = true

func _process(dt: float) -> void:
	if toast_t > 0:
		toast_t -= dt
		toast_l.modulate.a = clamp(toast_t * 2.0, 0.0, 1.0)
