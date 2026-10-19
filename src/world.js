/* Геометрия первой сцены: лестничная площадка 6 этажа, дверь «Электрощитовая», служебный коридор Стены.
   Ось: коридор уходит в -Z. Пол на y=0. Площадка z∈[0,4], дверь на z=0, решётка ГД-6 на z=GATE_Z. */
import * as THREE from 'three';
import * as T from './textures.js';

export const CORR_W = 3.2, CORR_H = 3.2, LEN = 2000, GATE_Z = -20, NICHE = [-6, -10];
const HW = CORR_W / 2;

export function buildWorld(scene) {
  const W = { colliders: [], acts: [], lamps: [], screens: {} };
  const std = (o) => new THREE.MeshStandardMaterial(Object.assign({ roughness: 0.9, metalness: 0 }, o));
  const box = (w, h, d, mat, x, y, z, parent = scene) => {
    const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
    m.position.set(x, y, z); parent.add(m); return m;
  };
  /* коллайдер: прямоугольник на полу */
  const col = (x0, x1, z0, z1, on) => W.colliders.push({ x0: Math.min(x0, x1), x1: Math.max(x0, x1), z0: Math.min(z0, z1), z1: Math.max(z0, z1), on });
  /* текстура с повтором по размеру грани */
  const rep = (t, rx, ry) => { const c = t.clone(); c.needsUpdate = true; c.repeat.set(rx, ry); return c; };

  /* ================= ЛЕСТНИЧНАЯ ПЛОЩАДКА ================= */
  const sw = T.stairWall();
  const stairMat = (rx) => std({ map: rep(sw, rx, 1) });
  const lw = 0.2;
  box(6 + lw * 2, 3, lw, stairMat(1.5), 0, 1.5, 4 + lw / 2);              // дальняя стена
  box(lw, 3, 4, stairMat(1), -3 - lw / 2, 1.5, 2);                        // левая стена (окно)
  box(lw, 3, 4, stairMat(1), 3 + lw / 2, 1.5, 2);                         // правая стена
  col(-3.5, 3.5, 4, 4.5); col(-3.5, -3, -0.2, 4.5); col(3, 3.5, -0.2, 4.5);
  const floorT = T.floorTiles();
  const lf = new THREE.Mesh(new THREE.PlaneGeometry(3.8, 4), std({ map: rep(floorT, 2.3, 2.4) }));
  lf.rotation.x = -Math.PI / 2; lf.position.set(-1.1, 0, 2); scene.add(lf);
  const ceilT = T.ceiling();
  const lc = new THREE.Mesh(new THREE.PlaneGeometry(6, 4), std({ map: rep(ceilT, 2, 1.4) }));
  lc.rotation.x = Math.PI / 2; lc.position.set(0, 3, 2); scene.add(lc);

  /* лестница вниз (справа) и перила */
  const stepMat = std({ color: 0x77736a });
  for (let i = 0; i < 12; i++) box(2.2, 0.17, 0.3, stepMat, 1.9, -0.085 - i * 0.17, 0.75 + i * 0.3);
  box(2.2, 0.1, 0.5, stepMat, 1.9, -0.05, 0.35);
  const rail = std({ color: 0x2d2a24, roughness: 0.5, metalness: 0.4 });
  box(0.05, 0.05, 3.6, rail, 0.8, 0.95, 2.2);
  for (let z = 0.5; z < 4; z += 0.25) box(0.02, 0.9, 0.02, rail, 0.8, 0.48, z);
  box(0.06, 1.0, 0.06, rail, 0.8, 0.5, 0.42);
  col(0.75, 3, 0.4, 4);
  /* темнота лестничного пролёта */
  const pit = new THREE.Mesh(new THREE.PlaneGeometry(2.2, 4), new THREE.MeshBasicMaterial({ color: 0x000000 }));
  pit.rotation.x = -Math.PI / 2; pit.position.set(1.9, -2.2, 2.2); scene.add(pit);

  /* окно с ночным городом */
  const night = T.tex(256, 256, (g, w, h) => {
    const gr = g.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, '#05070d'); gr.addColorStop(1, '#1a1410'); g.fillStyle = gr; g.fillRect(0, 0, w, h);
    for (let i = 0; i < 70; i++) { g.fillStyle = Math.random() < 0.7 ? 'rgba(255,190,110,.8)' : 'rgba(200,220,255,.6)'; g.fillRect(Math.random() * w, h * 0.55 + Math.random() * h * 0.45, 2, 2); }
  });
  const win = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 1.3), new THREE.MeshBasicMaterial({ map: night }));
  win.rotation.y = Math.PI / 2; win.position.set(-2.89, 1.75, 2.2); scene.add(win);
  const frame = std({ color: 0x5b4a39 });
  box(0.08, 0.08, 1.5, frame, -2.86, 2.42, 2.2); box(0.08, 0.08, 1.5, frame, -2.86, 1.08, 2.2);
  box(0.08, 1.4, 0.08, frame, -2.86, 1.75, 1.47); box(0.08, 1.4, 0.08, frame, -2.86, 1.75, 2.93); box(0.06, 1.3, 0.05, frame, -2.86, 1.75, 2.2);
  box(0.22, 0.05, 1.6, frame, -2.8, 1.05, 2.2);
  /* батарея под окном */
  const rad = std({ color: 0x8c8676, roughness: 0.6 });
  for (let i = 0; i < 9; i++) box(0.08, 0.55, 0.06, rad, -2.85, 0.5, 1.7 + i * 0.12);

  /* номер этажа */
  const six = new THREE.Mesh(new THREE.PlaneGeometry(0.9, 0.9), new THREE.MeshStandardMaterial({ map: T.stencil('6', 256, 256, 'rgba(225,220,200,.85)', 220), transparent: true, roughness: 0.9 }));
  six.position.set(-1.6, 1.9, 3.89); six.rotation.y = Math.PI; scene.add(six);

  /* лампочка на проводе */
  const bulb = new THREE.Mesh(new THREE.SphereGeometry(0.06, 12, 8), new THREE.MeshBasicMaterial({ color: 0xffd9a0 }));
  bulb.position.set(-1.1, 2.62, 2); scene.add(bulb);
  box(0.01, 0.32, 0.01, rail, -1.1, 2.84, 2);
  W.bulb = bulb;

  /* ================= СТЕНА С ДВЕРЬЮ (z=0) ================= */
  const doorWallMat = stairMat(0.8);
  box(2.4, 3, lw, doorWallMat, -1.8, 1.5, 0);
  box(2.4, 3, lw, doorWallMat, 1.8, 1.5, 0);
  box(1.2, 0.9, lw, std({ color: 0xbdb8a6 }), 0, 2.55, 0);
  col(-3.2, -0.6, -0.1, 0.1); col(0.6, 3.2, -0.1, 0.1);
  const jamb = std({ color: 0x3b2c22 });
  box(0.08, 2.15, 0.26, jamb, -0.64, 1.07, 0); box(0.08, 2.15, 0.26, jamb, 0.64, 1.07, 0); box(1.36, 0.08, 0.26, jamb, 0, 2.14, 0);

  /* дверь на петлях (слева), открывается внутрь */
  const doorPivot = new THREE.Group(); doorPivot.position.set(-0.6, 0, 0); scene.add(doorPivot);
  const doorMat = std({ map: T.metal('#5a3c2c'), roughness: 0.7, metalness: 0.3 });
  const door = box(1.2, 2.1, 0.06, doorMat, 0.6, 1.05, 0, doorPivot);
  const warn = new THREE.Mesh(new THREE.PlaneGeometry(0.34, 0.4), std({ map: T.warnTex() }));
  warn.position.set(0.6, 1.45, 0.035); doorPivot.add(warn);
  const handle = box(0.12, 0.03, 0.05, std({ color: 0x999088, metalness: 0.8, roughness: 0.3 }), 1.05, 1.0, 0.06, doorPivot);
  door.userData.act = 'door'; warn.userData.act = 'door'; handle.userData.act = 'door';
  W.acts.push(door, warn, handle);
  W.door = { pivot: doorPivot, open: 0, target: 0 };
  col(-0.6, 0.6, -0.05, 0.05, () => W.door.open < 0.6);

  /* табличка «Электрощитовая» */
  W.signLit = T.signTex(true); W.signOff = T.signTex(false);
  const signMat = new THREE.MeshBasicMaterial({ map: W.signLit });
  const sign = box(1.3, 0.33, 0.08, std({ color: 0x1a1a1a }), 0, 2.55, 0.15);
  const signFace = new THREE.Mesh(new THREE.PlaneGeometry(1.26, 0.3), signMat);
  signFace.position.set(0, 2.55, 0.195); scene.add(signFace);
  W.sign = signMat; sign.userData.act = 'sign'; W.acts.push(sign);

  /* ================= КОРИДОР ================= */
  const cw = T.corridorWall();
  const wallMat = (len) => std({ map: rep(cw, len / 4, 1) });
  const segL = (z0, z1) => { const L = Math.abs(z1 - z0); box(0.3, CORR_H, L, wallMat(L), -HW - 0.15, CORR_H / 2, (z0 + z1) / 2); col(-HW - 0.3, -HW, z0, z1); };
  const segR = (z0, z1) => { const L = Math.abs(z1 - z0); box(0.3, CORR_H, L, wallMat(L), HW + 0.15, CORR_H / 2, (z0 + z1) / 2); col(HW, HW + 0.3, z0, z1); };
  segL(0, -LEN); segR(0, NICHE[0]); segR(NICHE[1], -LEN);
  /* в начале коридор ниже площадки по высоте двери — закрываем стыком */
  box(CORR_W + 0.6, 0.3, 0.2, std({ color: 0x3b3b38 }), 0, CORR_H + 0.05, -0.1);
  const cf = T.concreteFloor();
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(CORR_W, LEN), std({ map: rep(cf, 1, LEN / CORR_W) }));
  floor.rotation.x = -Math.PI / 2; floor.position.set(0, 0, -LEN / 2); scene.add(floor);
  const cc = new THREE.Mesh(new THREE.PlaneGeometry(CORR_W, LEN), std({ map: rep(ceilT, 1, LEN / CORR_W) }));
  cc.rotation.x = Math.PI / 2; cc.position.set(0, CORR_H, -LEN / 2); scene.add(cc);
  box(CORR_W + 1, CORR_H, 0.3, std({ color: 0x111111 }), 0, CORR_H / 2, -LEN - 0.15); col(-HW, HW, -LEN - 0.3, -LEN);

  /* кабель-канал и кабели слева, трубы под потолком */
  const tray = std({ color: 0x4d4f4a, metalness: 0.5, roughness: 0.6 });
  box(0.28, 0.06, LEN, tray, -HW + 0.14, 2.62, -LEN / 2);
  const cab = std({ color: 0x151515, roughness: 0.6 });
  for (let i = 0; i < 3; i++) { const c = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, LEN, 6), cab); c.rotation.x = Math.PI / 2; c.position.set(-HW + 0.06 + i * 0.08, 2.68, -LEN / 2); scene.add(c); }
  const pipe = std({ color: 0x5a5148, metalness: 0.4, roughness: 0.5 });
  for (const [x, r] of [[0.75, 0.09], [1.05, 0.06]]) { const p = new THREE.Mesh(new THREE.CylinderGeometry(r, r, LEN, 10), pipe); p.rotation.x = Math.PI / 2; p.position.set(x, CORR_H - 0.18, -LEN / 2); scene.add(p); }

  /* рёбра-рамы каждые 6 м */
  const ribStep = 6, ribN = Math.floor(LEN / ribStep);
  const ribMat = std({ color: 0x5c5f58, roughness: 0.8 });
  const pilL = new THREE.InstancedMesh(new THREE.BoxGeometry(0.22, CORR_H, 0.35), ribMat, ribN);
  const pilR = new THREE.InstancedMesh(new THREE.BoxGeometry(0.22, CORR_H, 0.35), ribMat, ribN);
  const beam = new THREE.InstancedMesh(new THREE.BoxGeometry(CORR_W, 0.25, 0.35), ribMat, ribN);
  const m4 = new THREE.Matrix4();
  for (let i = 0; i < ribN; i++) {
    const z = -ribStep * (i + 1);
    m4.makeTranslation(-HW + 0.11, CORR_H / 2, z); pilL.setMatrixAt(i, m4);
    m4.makeTranslation(z < NICHE[0] && z > NICHE[1] ? 99 : HW - 0.11, CORR_H / 2, z); pilR.setMatrixAt(i, m4);
    m4.makeTranslation(0, CORR_H - 0.125, z); beam.setMatrixAt(i, m4);
  }
  scene.add(pilL, pilR, beam);

  /* ================= НИША: щиток, терминал, записка ================= */
  const nz0 = NICHE[0], nz1 = NICHE[1], nx = HW + 1.8, nzc = (nz0 + nz1) / 2;
  const nMat = std({ map: rep(cw, 1, 1) });
  box(0.3, CORR_H, 4.3, nMat, nx + 0.15, CORR_H / 2, nzc); col(nx, nx + 0.3, nz0, nz1);
  box(1.8, CORR_H, 0.3, wallMat(1.8), HW + 0.9, CORR_H / 2, nz0 + 0.15); col(HW, nx, nz0, nz0 + 0.3);
  box(1.8, CORR_H, 0.3, wallMat(1.8), HW + 0.9, CORR_H / 2, nz1 - 0.15); col(HW, nx, nz1 - 0.3, nz1);
  const nf = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 4), std({ map: rep(cf, 0.6, 1.2) })); nf.rotation.x = -Math.PI / 2; nf.position.set(HW + 0.9, 0.001, nzc); scene.add(nf);
  const nc = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 4), std({ map: rep(ceilT, 0.6, 1.2) })); nc.rotation.x = Math.PI / 2; nc.position.set(HW + 0.9, CORR_H, nzc); scene.add(nc);

  /* щиток ЩР-6 на задней стене ниши */
  const pan = box(0.16, 1.0, 0.72, std({ color: 0x7d8278, roughness: 0.6, metalness: 0.3 }), nx - 0.08, 1.45, -7.1);
  const panFace = new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.98), std({ map: T.panelTex(), roughness: 0.6, metalness: 0.2 }));
  panFace.rotation.y = -Math.PI / 2; panFace.position.set(nx - 0.165, 1.45, -7.1); scene.add(panFace);
  pan.userData.act = 'panel'; panFace.userData.act = 'panel'; W.acts.push(pan, panFace);
  /* индикатор «ввод» на щитке */
  W.panelLamp = new THREE.Mesh(new THREE.SphereGeometry(0.025, 10, 8), new THREE.MeshBasicMaterial({ color: 0x401010 }));
  W.panelLamp.position.set(nx - 0.17, 1.86, -6.88); scene.add(W.panelLamp);
  /* трубы кабелей от щитка вверх */
  box(0.06, 1.0, 0.06, pipe, nx - 0.05, 2.45, -6.95); box(0.06, 1.0, 0.06, pipe, nx - 0.05, 2.45, -7.25);

  /* стол и терминал */
  const desk = std({ color: 0x4a3b2d, roughness: 0.8 });
  box(0.8, 0.05, 1.3, desk, nx - 0.45, 1.0, -8.9);
  box(0.7, 0.95, 1.2, std({ color: 0x3d3f3a, roughness: 0.7, metalness: 0.3 }), nx - 0.4, 0.48, -8.9);
  const crtMat = std({ color: 0xc9c2ae, roughness: 0.7 });
  const crt = box(0.5, 0.42, 0.52, crtMat, nx - 0.42, 1.24, -8.9);
  box(0.36, 0.3, 0.4, crtMat, nx - 0.2, 1.24, -8.9);
  const kb = box(0.22, 0.04, 0.5, std({ color: 0xb8b09a }), nx - 0.78, 1.045, -8.9);
  /* экран: живая текстура, рисуется из терминала */
  const scr = document.createElement('canvas'); scr.width = 256; scr.height = 200;
  const scrTex = new THREE.CanvasTexture(scr); scrTex.colorSpace = THREE.SRGBColorSpace;
  const screen = new THREE.Mesh(new THREE.PlaneGeometry(0.4, 0.31), new THREE.MeshBasicMaterial({ map: scrTex }));
  screen.rotation.y = -Math.PI / 2; screen.position.set(nx - 0.675, 1.26, -8.9); scene.add(screen);
  W.screens.term = { canvas: scr, tex: scrTex };
  for (const m of [crt, kb, screen]) { m.userData.act = 'terminal'; W.acts.push(m); }
  W.termLight = new THREE.PointLight(0x6dff8a, 0, 3.5, 2); W.termLight.position.set(nx - 1.0, 1.35, -8.9); scene.add(W.termLight);

  /* записка на боковой стене ниши */
  const note = new THREE.Mesh(new THREE.PlaneGeometry(0.21, 0.27), std({ map: T.paperTex() }));
  note.position.set(nx - 0.55, 1.45, nz1 + 0.005); scene.add(note);
  box(0.02, 0.02, 0.01, std({ color: 0xaa2222 }), nx - 0.55, 1.57, nz1 + 0.01);
  note.userData.act = 'note'; W.acts.push(note);

  /* ================= РЕШЁТКА ГД-6 ================= */
  const gate = new THREE.Group(); gate.position.set(0, 0, GATE_Z); scene.add(gate);
  const gm = std({ color: 0x3a3a36, metalness: 0.6, roughness: 0.45 });
  for (let x = -HW + 0.12; x < HW - 0.05; x += 0.16) { const b = new THREE.Mesh(new THREE.CylinderGeometry(0.022, 0.022, CORR_H - 0.3, 6), gm); b.position.set(x, (CORR_H - 0.3) / 2, 0); gate.add(b); }
  for (const y of [0.08, 1.1, 2.1, CORR_H - 0.34]) { const b = new THREE.Mesh(new THREE.BoxGeometry(CORR_W - 0.1, 0.07, 0.07), gm); b.position.set(0, y, 0); gate.add(b); }
  gate.children.forEach(c => { c.userData.act = 'gate'; W.acts.push(c); });
  W.gate = { g: gate, open: 0, moving: false };
  col(-HW, HW, GATE_Z - 0.1, GATE_Z + 0.1, () => W.gate.open < 0.75);
  /* направляющие и табличка над решёткой */
  box(0.1, CORR_H, 0.2, std({ color: 0xc9a227 }), -HW + 0.05, CORR_H / 2, GATE_Z); box(0.1, CORR_H, 0.2, std({ color: 0xc9a227 }), HW - 0.05, CORR_H / 2, GATE_Z);
  const gd = new THREE.Mesh(new THREE.PlaneGeometry(1.0, 0.3), new THREE.MeshStandardMaterial({ map: T.stencil('ГД-6', 512, 160, 'rgba(201,162,39,.95)'), transparent: true }));
  gd.position.set(0, CORR_H - 0.13, GATE_Z + 0.18); scene.add(gd);
  /* табличка участка на правой стене перед решёткой */
  const plq = new THREE.Mesh(new THREE.PlaneGeometry(0.6, 0.42), std({ map: T.textTex(384, 270, '#b9a77a', [
    { text: 'УЧАСТОК 6', size: 44, color: '#2a2214' }, { text: 'ВВЕДЁН В ЭКСПЛУАТАЦИЮ', size: 22, color: '#2a2214' }, { text: '1987', size: 64, color: '#2a2214' }], { grime: 1, frame: '#5b4a2a' }), roughness: 0.4, metalness: 0.5 }));
  plq.rotation.y = -Math.PI / 2; plq.position.set(HW - 0.005, 1.6, GATE_Z + 1.6); scene.add(plq);
  plq.userData.act = 'plaque'; W.acts.push(plq);

  /* трафаретные отметки расстояния на левой стене */
  for (let d = 50; d <= 500; d += 50) {
    const m = new THREE.Mesh(new THREE.PlaneGeometry(1.1, 0.34), new THREE.MeshStandardMaterial({ map: T.stencil('6-' + String(d).padStart(4, '0'), 512, 160, 'rgba(225,220,200,.6)', 96), transparent: true }));
    m.rotation.y = Math.PI / 2; m.position.set(-HW + 0.005, 1.95, -d); scene.add(m);
  }

  /* ================= СВЕТИЛЬНИКИ ================= */
  /* корпуса трубок + сами трубки (instanced, цвет = яркость) + свечение точками */
  const tubeZ = [];
  for (let z = -3; z > -LEN; z -= 6) tubeZ.push(z);
  const housing = new THREE.InstancedMesh(new THREE.BoxGeometry(0.22, 0.08, 1.3), std({ color: 0x2b2b28 }), tubeZ.length);
  const tubes = new THREE.InstancedMesh(new THREE.BoxGeometry(0.1, 0.05, 1.2), new THREE.MeshBasicMaterial({ color: 0xffffff, fog: false }), tubeZ.length);
  tubeZ.forEach((z, i) => {
    m4.makeTranslation(0, CORR_H - 0.04, z); housing.setMatrixAt(i, m4);
    m4.makeTranslation(0, CORR_H - 0.1, z); tubes.setMatrixAt(i, m4);
    W.lamps.push({ kind: 'tube', x: 0, y: CORR_H - 0.3, z, grp: z > GATE_Z ? 'A' : 'S7', inst: i, lvl: 0, on: 0, fl: 0, delay: 0 });
  });
  scene.add(housing, tubes);
  W.tubes = tubes;
  /* аварийные лампы (красные, от аккумуляторов) */
  const emZ = [];
  for (let z = -1.5; z > -LEN; z -= 12) emZ.push(z);
  const ems = new THREE.InstancedMesh(new THREE.BoxGeometry(0.06, 0.1, 0.18), new THREE.MeshBasicMaterial({ color: 0xffffff, fog: false }), emZ.length);
  emZ.forEach((z, i) => {
    m4.makeTranslation(-HW + 0.04, 2.3, z); ems.setMatrixAt(i, m4);
    W.lamps.push({ kind: 'em', x: -HW + 0.3, y: 2.3, z, grp: 'E', inst: i, lvl: 1, on: 1, fl: 0, delay: 0 });
  });
  scene.add(ems);
  W.ems = ems;
  /* лампочка на площадке */
  W.lamps.push({ kind: 'bulb', x: -1.1, y: 2.5, z: 2, grp: 'L', lvl: 1, on: 1, fl: 0.05, delay: 0 });

  /* свечение: точки со своим шейдером (видны далеко, не меньше 2 px) */
  const n = W.lamps.length, pos = new Float32Array(n * 3), colA = new Float32Array(n * 3), sz = new Float32Array(n);
  W.lamps.forEach((l, i) => { pos.set([l.x, l.kind === 'tube' ? CORR_H - 0.12 : l.y, l.z], i * 3); sz[i] = l.kind === 'tube' ? 1.6 : l.kind === 'em' ? 0.22 : 0.5; l.gi = i; });
  const gg = new THREE.BufferGeometry();
  gg.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  gg.setAttribute('color', new THREE.BufferAttribute(colA, 3));
  gg.setAttribute('size', new THREE.BufferAttribute(sz, 1));
  const glowMat = new THREE.ShaderMaterial({
    uniforms: { scale: { value: 600 } },
    vertexShader: `attribute float size;attribute vec3 color;varying vec3 vC;uniform float scale;
      void main(){vC=color;vec4 mv=modelViewMatrix*vec4(position,1.0);gl_Position=projectionMatrix*mv;
      float s=size*scale/max(-mv.z,0.1);gl_PointSize=max(s,dot(color,vec3(1.0))>0.01?2.5:0.0);}`,
    fragmentShader: `varying vec3 vC;void main(){vec2 d=gl_PointCoord-0.5;float r=length(d)*2.0;float a=pow(max(1.0-r,0.0),2.2);gl_FragColor=vec4(vC*a,1.0);}`,
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
  });
  const glow = new THREE.Points(gg, glowMat); glow.frustumCulled = false; scene.add(glow);
  W.glow = { geo: gg, mat: glowMat };

  return W;
}
