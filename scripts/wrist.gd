## ПТ-1 — переносной терминал на левой руке. Заменяет пейджер: заявки, задача, записи, связь со щитком.
## Рисуется в SubViewport, текстура которого натянута на экран прибора (body.gd).
class_name Wrist
extends Control

const PAGES := ["ЗАЯВКИ", "ЗАДАЧА", "ЗАПИСИ"]
const FG := Color(0.55, 1.0, 0.65)
const DIM := Color(0.18, 0.54, 0.28)
const BG := Color(0.016, 0.07, 0.03)

var page := 0
var raised := false
var unread := false
var orders: Array[String] = []
var goal := ""
var notes: Array[String] = []
var link := ""
var t := 0.0
var font: Font

func _ready() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["PT Mono", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"])
	font = f
	size = Vector2(384, 256)

func notify(txt: String) -> void:
	orders.push_front(txt)
	unread = true
	page = 0
	Audio.play("pager", -6.0)
	queue_redraw()

func set_goal(txt: String) -> void:
	if goal != txt:
		goal = txt; queue_redraw()

func add_note(n: String) -> void:
	if not notes.has(n):
		notes.append(n); queue_redraw()

func set_page(i: int) -> void:
	if page != i:
		page = i; Audio.play("key"); queue_redraw()

func set_link(l: String) -> void:
	if link != l:
		link = l; queue_redraw()

func raise(on: bool) -> void:
	if raised == on:
		return
	raised = on
	Audio.play("click", -8.0)
	if on and unread:
		unread = false
	queue_redraw()

func _process(dt: float) -> void:
	t += dt
	if unread or int(t) != int(t - dt):
		queue_redraw()

## перенос строк по ширине
func _wrap(text: String, w: float, fs: int) -> Array:
	var out := []
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var tt := word if line == "" else line + " " + word
			if font.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w and line != "":
				out.append(line); line = word
			else:
				line = tt
		out.append(line)
	return out

func _draw() -> void:
	var W := size.x; var H := size.y
	var blink := unread and int(t * 3.0) % 2 == 0
	draw_rect(Rect2(0, 0, W, H), BG)
	draw_rect(Rect2(0, 0, W, 30), FG if blink else Color(0.04, 0.16, 0.07))
	draw_string(font, Vector2(10, 22), "! НОВАЯ ЗАЯВКА" if blink else "ПТ-1 · УЧ.6", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BG if blink else FG)
	var clock := Time.get_time_string_from_system().substr(0, 5)
	draw_string(font, Vector2(W - 70, 22), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BG if blink else FG)
	for i in PAGES.size():
		var x := 8.0 + i * 124.0
		if i == page:
			draw_rect(Rect2(x, 36, 118, 22), FG)
			draw_string(font, Vector2(x + 8, 53), "%d %s" % [i + 1, PAGES[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BG)
		else:
			draw_rect(Rect2(x + 0.5, 36.5, 117, 21), DIM, false, 1.0)
			draw_string(font, Vector2(x + 8, 53), "%d %s" % [i + 1, PAGES[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, DIM)
	var lines := []
	if page == 0:
		if orders.is_empty(): lines = ["Заявок нет."]
		else:
			for i in min(2, orders.size()):
				lines.append_array(_wrap(orders[i], W - 20, 17))
				if i == 0 and orders.size() > 1: lines.append("— — —")
	elif page == 1:
		lines = _wrap(goal if goal != "" else "Задач нет.", W - 20, 17)
	else:
		if notes.is_empty(): lines = ["Записей нет."]
		else:
			for i in notes.size(): lines.append("%d. %s" % [i + 1, notes[i]])
	for i in min(7, lines.size()):
		draw_string(font, Vector2(10, 84 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, DIM if lines[i] == "— — —" else FG)
	draw_rect(Rect2(0, H - 28, W, 28), Color(0.04, 0.16, 0.07))
	draw_string(font, Vector2(10, H - 9), ("СВЯЗЬ: " + link) if link != "" else "СВЯЗЬ: НЕТ · подойди к щитку", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, FG if link != "" else DIM)
	var y := 0.0
	while y < H:
		draw_rect(Rect2(0, y, W, 1), Color(0, 0, 0, 0.22)); y += 3
