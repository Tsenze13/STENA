@tool
## Переборка ГД-6: стены поперёк коридора, подъёмная решётка, жёлтые полосы, проблесковый маячок.
## Решётку поднимает игра (game.gd) — здесь только модель.
class_name Bulkhead
extends LevelPart

const HW := World.HW
const CORR_H := World.CORR_H
const GO := 4.2       # высота проёма
const GH := 1.6       # половина ширины проёма

var gate := {}
var beacon := {}

func _build() -> void:
	piece("Bulkhead")
	var bulk := Tex.surface("bulk", Color(0.52, 0.52, 0.49), 0.9, 0.0, 0.4)
	wall(Vector3(HW - GH, CORR_H, 0.7), Vector3(-(HW + GH) / 2, CORR_H / 2, 0), bulk)
	wall(Vector3(HW - GH, CORR_H, 0.7), Vector3((HW + GH) / 2, CORR_H / 2, 0), bulk)
	wall(Vector3(GH * 2, CORR_H - GO, 0.7), Vector3(0, GO + (CORR_H - GO) / 2, 0), bulk)
	for s in [1.0, -1.0]:
		B.box(Vector3(0.16, GO, 0.01), Tex.hazard(), Vector3(s * (GH + 0.08), GO / 2, 0.355))
	B.box(Vector3(GH * 2 + 0.32, 0.16, 0.01), Tex.hazard(), Vector3(0, GO + 0.08, 0.355))
	var g := Node3D.new(); gen.add_child(g)
	## решётка — модель (Poly Haven large_iron_gate, CC0), вписана в проём
	Geo.model(g, "res://assets/models/large_iron_gate/large_iron_gate_1k.gltf", Vector3(GH * 2 - 0.04, GO - 0.02, 0.12))
	Geo.act_zone(g, Vector3(GH * 2, GO, 0.2), Vector3(0, GO / 2, 0), "gate")
	piece("LiveGate")   # коллайдер решётки игра выключает — не запекается
	gate = {"node": g, "open": 0.0, "moving": false, "lift": GO + 0.1, "shape": Geo.solid(solids, Vector3(GH * 2, GO, 0.2), Vector3(0, GO / 2, 0))}
	piece("Bulkhead")
	Geo.paint(gen, "ГД-6", 0.3, Color(0.79, 0.64, 0.15), Vector3(0, GO + 0.5, 0.36), Vector3.ZERO, 0.3)
	Geo.paint(gen, "7", 2.0, Color(0.85, 0.83, 0.76), Vector3(0, 6.6, -0.36), Vector3(0, PI, 0), 0.45)
	## проблесковый маячок: крутится, пока решётка движется
	var bc := Node3D.new(); bc.position = Vector3(GH - 0.3, GO + 0.55, 0.45); gen.add_child(bc)
	Geo.box_node(bc, Vector3(0.16, 0.06, 0.16), Tex.dark_metal(), Vector3(0, -0.08, 0))
	var lamp := Geo.cyl_node(bc, 0.07, 0.08, 0.14, Tex.plain("beacon_off", Color(0.23, 0.13, 0.02), 0.3), Vector3.ZERO, Vector3.ZERO, 12)
	var sl := SpotLight3D.new(); sl.light_color = Color(1, 0.6, 0.12); sl.spot_range = 14; sl.spot_angle = 30; sl.light_energy = 0
	sl.rotation = Vector3(-0.35, PI / 2, 0); bc.add_child(sl)
	beacon = {"node": bc, "lamp": lamp, "light": sl}
