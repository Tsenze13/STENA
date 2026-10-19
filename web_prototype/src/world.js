/* Геометрия первой сцены: лестничная площадка 6 этажа, дверь «Электрощитовая», служебный коридор Стены.
   Ось: коридор уходит в -Z. Пол на y=0. Площадка z∈[0,4], дверь на z=0, переборка с решёткой ГД-6 на z=GATE_Z.
   Коридор 4 м шириной и 9 м высотой, слева мостки на 4,2 м. */
import * as THREE from 'three';
import * as T from './textures.js';
import { makeBatch, catenary, cableGeo } from './geo.js';
import { makeConsole, makePanel, makeDoor } from './props.js';

export const CORR_W = 4, CORR_H = 9, LEN = 2000, GATE_Z = -20, NICHE = [-6, -10], NICHE_H = 3.2;
const DET = 260; /* дальше этого детали (провода, мусор) не строим: туман всё равно скрывает */
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

  /* ================= ВЫСОКИЙ КОРИДОР ================= */
  const m4 = new THREE.Matrix4();
  const R = (a, b) => a + T.rnd() * (b - a);
  const B = makeBatch();               /* мелкие детали склеиваются по материалам */
  const tw = T.tallWall();
  const wallMat = (len) => std({ map: rep(tw, len / 6, 1) });
  const metalM = std({ color: 0x4d4f4a, metalness: 0.55, roughness: 0.55 });
  const darkM = std({ color: 0x2a2b28, metalness: 0.4, roughness: 0.6 });
  const pipeM = std({ color: 0x5a5148, metalness: 0.45, roughness: 0.5 });
  const rustM = std({ color: 0x6b3f22, metalness: 0.3, roughness: 0.8 });
  const cableM = std({ color: 0x121212, roughness: 0.55 });
  const BX = (w, h, d) => new THREE.BoxGeometry(w, h, d);

  /* стена с дверью со стороны коридора поднимается до потолка */
  box(CORR_W + 0.6, CORR_H - 3, 0.2, wallMat(4), 0, 3 + (CORR_H - 3) / 2, -0.1);
  /* стены коридора */
  const wallL = (z0, z1) => { const L = Math.abs(z1 - z0); box(0.3, CORR_H, L, wallMat(L), -HW - 0.15, CORR_H / 2, (z0 + z1) / 2); col(-HW - 0.3, -HW, z0, z1); };
  const wallR = (z0, z1, y0 = 0) => { const L = Math.abs(z1 - z0), h = CORR_H - y0; box(0.3, h, L, wallMat(L), HW + 0.15, y0 + h / 2, (z0 + z1) / 2); if (!y0) col(HW, HW + 0.3, z0, z1); };
  wallL(0, -LEN); wallR(0, NICHE[0]); wallR(NICHE[1], -LEN); wallR(NICHE[0], NICHE[1], NICHE_H);
  const cf = T.concreteFloor();
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(CORR_W, LEN), std({ map: rep(cf, 1, LEN / CORR_W) }));
  floor.rotation.x = -Math.PI / 2; floor.position.set(0, 0, -LEN / 2); scene.add(floor);
  const cc = new THREE.Mesh(new THREE.PlaneGeometry(CORR_W, LEN), std({ map: rep(ceilT, 1, LEN / CORR_W), color: 0x777777 }));
  cc.rotation.x = Math.PI / 2; cc.position.set(0, CORR_H, -LEN / 2); scene.add(cc);
  box(CORR_W + 1, CORR_H, 0.3, std({ color: 0x111111 }), 0, CORR_H / 2, -LEN - 0.15); col(-HW, HW, -LEN - 0.3, -LEN);

  /* пилястры и потолочные балки каждые 6 м (instanced — их сотни) */
  const ribN = Math.floor(LEN / 6);
  const pilL = new THREE.InstancedMesh(BX(0.4, CORR_H, 0.3), std({ color: 0x5c5f58, roughness: 0.8 }), ribN);
  const pilR = new THREE.InstancedMesh(BX(0.4, CORR_H, 0.3), pilL.material, ribN);
  const beam = new THREE.InstancedMesh(BX(CORR_W, 0.5, 0.3), pilL.material, ribN);
  for (let i = 0; i < ribN; i++) {
    const z = -6 * (i + 1);
    m4.makeTranslation(-HW + 0.15, CORR_H / 2, z); pilL.setMatrixAt(i, m4);
    m4.makeTranslation(z <= NICHE[0] && z >= NICHE[1] ? 99 : HW - 0.15, CORR_H / 2, z); pilR.setMatrixAt(i, m4);
    m4.makeTranslation(0, CORR_H - 0.25, z); beam.setMatrixAt(i, m4);
  }
  scene.add(pilL, pilR, beam);
  /* пилястры выступают — коллайдеры вблизи */
  for (let z = -6; z > -DET; z -= 6) { col(-HW, -HW + 0.35, z - 0.15, z + 0.15); if (!(z <= NICHE[0] && z >= NICHE[1])) col(HW - 0.35, HW, z - 0.15, z + 0.15); }

  /* трубы, короба и кабель-каналы вдоль всего коридора */
  const longCyl = (r, x, y, mat) => { const p = new THREE.Mesh(new THREE.CylinderGeometry(r, r, LEN, 12), mat); p.rotation.x = Math.PI / 2; p.position.set(x, y, -LEN / 2); scene.add(p); };
  longCyl(0.13, HW - 0.25, 7.7, pipeM); longCyl(0.08, HW - 0.55, 8.05, pipeM); longCyl(0.08, HW - 0.25, 8.3, rustM);
  longCyl(0.11, -HW + 0.3, 7.3, pipeM); longCyl(0.05, -HW + 0.55, 7.55, rustM);
  box(0.9, 0.7, LEN, std({ color: 0x6c706a, metalness: 0.5, roughness: 0.45 }), HW - 0.6, 6.2, -LEN / 2);            // вентиляционный короб
  for (const [x, y] of [[-HW + 0.2, 5.9], [-HW + 0.2, 6.6], [HW - 0.2, 3.9], [HW - 0.2, 4.6]]) box(0.36, 0.05, LEN, metalM, x, y, -LEN / 2);
  for (const [x, y] of [[-HW + 0.12, 5.95], [-HW + 0.2, 5.96], [-HW + 0.28, 5.95], [HW - 0.15, 3.95], [HW - 0.25, 3.96]]) longCyl(0.025, x, y, cableM);
  /* фланцы короба и хомуты труб */
  for (let z = -1.5; z > -DET; z -= 3) {
    B.add(BX(1.0, 0.8, 0.06), metalM, HW - 0.6, 6.2, z);
    B.add(BX(0.06, 0.5, 0.1), darkM, HW - 0.06, 7.95, z);
  }

  /* ================= МОСТКИ на 4,2 м слева ================= */
  const CW_Y = 4.2, CW_X = -HW + 1.15;
  const gr = T.grateTex();
  const grateM = new THREE.MeshStandardMaterial({ map: gr, alphaTest: 0.5, side: THREE.DoubleSide, metalness: 0.5, roughness: 0.6, transparent: false });
  const walk = (z0, z1) => {
    const L = Math.abs(z1 - z0), zc = (z0 + z1) / 2;
    const t = gr.clone(); t.needsUpdate = true; t.repeat.set(1.15 / 0.5, L / 0.5);
    const p = new THREE.Mesh(new THREE.PlaneGeometry(1.15, L), grateM.clone()); p.material.map = t;
    p.rotation.x = -Math.PI / 2; p.position.set(-HW + 0.575, CW_Y, zc); scene.add(p);
    box(0.06, 0.16, L, metalM, CW_X, CW_Y - 0.06, zc);                                    // край
    box(0.04, 0.04, L, std({ map: T.hazardTex(), metalness: 0.4 }), CW_X, CW_Y + 1.05, zc); // поручень
    box(0.03, 0.03, L, metalM, CW_X, CW_Y + 0.55, zc);
    for (let z = z0; z >= z1; z -= 1.5) B.add(BX(0.04, 1.05, 0.04), metalM, CW_X, CW_Y + 0.52, z);
  };
  walk(-0.5, GATE_Z + 0.4); walk(GATE_Z - 0.4, -DET);
  /* кронштейны под мостками у каждой пилястры */
  for (let z = -6; z > -DET; z -= 6) { const g = B.add(BX(0.08, 1.45, 0.08), darkM, -HW + 0.6, CW_Y - 0.55, z, 0, 0, -0.85); }
  /* лестница-стремянка на мостки */
  for (const lz of [-13.2, -61.2]) {
    for (const dz of [-0.25, 0.25]) B.add(BX(0.05, CW_Y + 1.1, 0.05), metalM, -HW + 0.14, (CW_Y + 1.1) / 2, lz + dz);
    for (let y = 0.3; y < CW_Y + 1; y += 0.3) B.add(BX(0.04, 0.03, 0.5), metalM, -HW + 0.14, y, lz);
  }

  /* ================= ПЕРЕБОРКА ГД-6 ================= */
  const bulkM = std({ map: rep(tw, 0.7, 1), color: 0x9a9a92 });
  const GO = 4.2, GH = 1.6; /* высота проёма, полуширина */
  box(HW - GH, CORR_H, 0.7, bulkM, -(HW + GH) / 2, CORR_H / 2, GATE_Z); box(HW - GH, CORR_H, 0.7, bulkM, (HW + GH) / 2, CORR_H / 2, GATE_Z);
  box(GH * 2, CORR_H - GO, 0.7, bulkM, 0, GO + (CORR_H - GO) / 2, GATE_Z);
  col(-HW, -GH, GATE_Z - 0.35, GATE_Z + 0.35); col(GH, HW, GATE_Z - 0.35, GATE_Z + 0.35);
  const hz = std({ map: T.hazardTex() });
  for (const s of [1, -1]) {
    const p = new THREE.Mesh(new THREE.PlaneGeometry(GO, 0.16), hz); p.rotation.z = Math.PI / 2; p.position.set(s * (GH + 0.08), GO / 2, GATE_Z + 0.355); scene.add(p);
  }
  { const p = new THREE.Mesh(new THREE.PlaneGeometry(GH * 2 + 0.32, 0.16), hz); p.position.set(0, GO + 0.08, GATE_Z + 0.355); scene.add(p); }
  const gate = new THREE.Group(); gate.position.set(0, 0, GATE_Z); scene.add(gate);
  const gm = std({ color: 0x3a3a36, metalness: 0.6, roughness: 0.45 });
  for (let x = -GH + 0.1; x < GH - 0.05; x += 0.15) { const b = new THREE.Mesh(new THREE.CylinderGeometry(0.024, 0.024, GO - 0.05, 6), gm); b.position.set(x, GO / 2, 0); gate.add(b); }
  for (const y of [0.08, 1.4, 2.8, GO - 0.1]) { const b = new THREE.Mesh(BX(GH * 2 - 0.04, 0.08, 0.08), gm); b.position.set(0, y, 0); gate.add(b); }
  gate.children.forEach(c => { c.userData.act = 'gate'; W.acts.push(c); });
  W.gate = { g: gate, open: 0, moving: false, lift: GO + 0.1 };
  col(-GH, GH, GATE_Z - 0.1, GATE_Z + 0.1, () => W.gate.open < 0.6);
  const gd = new THREE.Mesh(new THREE.PlaneGeometry(1.0, 0.3), new THREE.MeshStandardMaterial({ map: T.stencil('ГД-6', 512, 160, 'rgba(201,162,39,.95)'), transparent: true }));
  gd.position.set(0, GO + 0.5, GATE_Z + 0.36); scene.add(gd);
  /* проблесковый маячок над решёткой: крутится, пока решётка движется */
  const bc = new THREE.Group(); bc.position.set(GH - 0.3, GO + 0.55, GATE_Z + 0.45); scene.add(bc);
  box(0.16, 0.06, 0.16, darkM, 0, -0.08, 0, bc);
  const bcLamp = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.08, 0.14, 12), new THREE.MeshBasicMaterial({ color: 0x3a2205 }));
  bc.add(bcLamp);
  const bcLight = new THREE.SpotLight(0xffa020, 0, 14, 0.6, 0.5, 1.5); bcLight.position.set(0, 0, 0); bc.add(bcLight); bc.add(bcLight.target); bcLight.target.position.set(1, -0.4, 0);
  W.beacon = { g: bc, lamp: bcLamp, light: bcLight };
  /* табличка участка */
  const plq = new THREE.Mesh(new THREE.PlaneGeometry(0.6, 0.42), std({ map: T.textTex(384, 270, '#b9a77a', [
    { text: 'УЧАСТОК 6', size: 44, color: '#2a2214' }, { text: 'ВВЕДЁН В ЭКСПЛУАТАЦИЮ', size: 22, color: '#2a2214' }, { text: '1987', size: 64, color: '#2a2214' }], { grime: 1, frame: '#5b4a2a' }), roughness: 0.4, metalness: 0.5 }));
  plq.rotation.y = -Math.PI / 2; plq.position.set(HW - 0.005, 1.6, GATE_Z + 2.2); scene.add(plq);
  plq.userData.act = 'plaque'; W.acts.push(plq);

  /* трафаретные отметки расстояния на левой стене */
  for (let d = 50; d <= 500; d += 50) {
    const m = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 0.44), new THREE.MeshStandardMaterial({ map: T.stencil((d <= -GATE_Z ? '6-' : '7-') + String(d).padStart(4, '0'), 512, 160, 'rgba(225,220,200,.6)', 96), transparent: true }));
    m.rotation.y = Math.PI / 2; m.position.set(-HW + 0.005, 2.3, -d - 3); scene.add(m);
  }
  /* огромный номер участка на переборке со стороны 7-го и на стене у входа */
  for (const [t, x, y, z, ry] of [['6', -HW + 0.01, 6.8, -3, Math.PI / 2], ['7', 0, 6.6, GATE_Z - 0.36, Math.PI]]) {
    const m = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 1.8), new THREE.MeshStandardMaterial({ map: T.stencil(t, 256, 256, 'rgba(225,220,200,.5)', 230), transparent: true }));
    m.position.set(x, y, z); m.rotation.y = ry; scene.add(m);
  }

  /* ================= НИША: щиток, пульт, записка ================= */
  const nz0 = NICHE[0], nz1 = NICHE[1], nx = HW + 1.8, nzc = (nz0 + nz1) / 2;
  const nMat = std({ map: rep(T.corridorWall(), 1, 1) });
  box(0.3, NICHE_H, 4.3, nMat, nx + 0.15, NICHE_H / 2, nzc); col(nx, nx + 0.3, nz0, nz1);
  box(1.8, NICHE_H, 0.3, nMat, HW + 0.9, NICHE_H / 2, nz0 + 0.15); col(HW, nx, nz0, nz0 + 0.3);
  box(1.8, NICHE_H, 0.3, nMat, HW + 0.9, NICHE_H / 2, nz1 - 0.15); col(HW, nx, nz1 - 0.3, nz1);
  const nf = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 4), std({ map: rep(cf, 0.6, 1.2) })); nf.rotation.x = -Math.PI / 2; nf.position.set(HW + 0.9, 0.001, nzc); scene.add(nf);
  const nc = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 4), std({ map: rep(ceilT, 0.6, 1.2) })); nc.rotation.x = Math.PI / 2; nc.position.set(HW + 0.9, NICHE_H, nzc); scene.add(nc);
  /* щиток */
  const pn = makePanel(); pn.group.position.set(nx - 0.1, 1.45, -7.1); pn.group.rotation.y = -Math.PI / 2; scene.add(pn.group);
  W.acts.push(...pn.acts); W.panel = pn;
  /* пульт с терминалом */
  const scr = document.createElement('canvas'); scr.width = 320; scr.height = 240;
  const cn = makeConsole(scr); cn.group.position.set(nx - 0.36, 0, -8.85); cn.group.rotation.y = -Math.PI / 2; scene.add(cn.group);
  W.acts.push(...cn.acts); W.screens.term = cn.screen; W.termLed = cn.led;
  col(nx - 0.75, nx, -9.6, -8.1);
  W.termLight = new THREE.PointLight(0x6dff8a, 0, 3.5, 2); W.termLight.position.set(nx - 0.9, 1.35, -8.85); scene.add(W.termLight);
  /* записка на боковой стене ниши */
  const note = new THREE.Mesh(new THREE.PlaneGeometry(0.21, 0.27), std({ map: T.paperTex() }));
  note.position.set(nx - 1.15, 1.5, nz1 + 0.005); scene.add(note);
  box(0.02, 0.02, 0.01, std({ color: 0xaa2222 }), nx - 1.15, 1.62, nz1 + 0.01);
  note.userData.act = 'note'; W.acts.push(note);

  /* ================= ДВЕРИ ================= */
  const doors = [
    /* [сторона, z, тип, ярус] — между пилястрами (z = -6k-3) */
    [-1, -9, 'service', 0], [1, -15, 'hermetic', 0], [-1, -15, 'service', 1],
    [-1, -27, 'hermetic', 0], [1, -27, 'cage', 0], [-1, -33, 'service', 1], [1, -39, 'service', 0], [-1, -45, 'cage', 0],
    [1, -51, 'hermetic', 0], [-1, -57, 'service', 0], [-1, -69, 'service', 1], [1, -63, 'service', 0], [-1, -75, 'hermetic', 0],
    [1, -81, 'cage', 0], [-1, -93, 'service', 0], [1, -99, 'hermetic', 0], [-1, -105, 'service', 1], [1, -117, 'service', 0],
    [-1, -129, 'cage', 0], [1, -141, 'hermetic', 0], [-1, -153, 'service', 0], [1, -171, 'service', 0], [-1, -189, 'hermetic', 0],
    [1, -207, 'cage', 0], [-1, -225, 'service', 0], [1, -243, 'service', 0],
  ];
  for (const [s, z, type, tier] of doors) {
    const sect = z > GATE_Z ? 6 : 7, num = sect + '-' + (tier ? 'В' : '') + String(Math.round(Math.abs(z > GATE_Z ? z : z - GATE_Z))).padStart(3, '0');
    const d = makeDoor(type, num, T.rnd() < 0.2);
    d.group.position.set(s * (HW - 0.005), tier ? CW_Y : 0, z); d.group.rotation.y = s < 0 ? Math.PI / 2 : -Math.PI / 2;
    scene.add(d.group); W.acts.push(...d.acts);
  }
  /* служебная дверь в переборке на уровне мостков */
  { const d = makeDoor('service', '6-К1'); d.group.position.set(-HW + 0.6, CW_Y, GATE_Z + 0.36); scene.add(d.group); W.acts.push(...d.acts); }

  /* ================= ПРОВОДА ================= */
  const V = (x, y, z) => new THREE.Vector3(x, y, z);
  const nearGate = (z0, z1) => Math.max(z0, z1) > GATE_Z - 0.6 && Math.min(z0, z1) < GATE_Z + 0.6;
  /* петли, свисающие из кабель-каналов */
  for (const [x, y, sx] of [[-HW + 0.36, 5.9, 1], [-HW + 0.36, 6.6, 1], [HW - 0.36, 3.9, -1], [HW - 0.36, 4.6, -1]]) {
    for (let z = -1; z > -DET;) {
      const L = R(1.8, 5.5);
      if (T.rnd() < 0.5 && !nearGate(z, z - L) && !(sx < 0 && y < 5 && z < NICHE[0] + 1 && z - L > NICHE[1] - 1) && !(y < 4.7 && sx < 0 && z > NICHE[1] - 1 && z - L < NICHE[0] + 1)) {
        const sag = R(0.3, y < 4.7 ? 0.6 : 1.5), r = R(0.012, 0.03);
        B.raw(cableGeo(catenary(V(x, y, z), V(x, y, z - L), sag, 12, V(sx * R(0.05, 0.25), 0, 0)), r, 16, 5), cableM);
      }
      z -= L * R(0.5, 1.2);
    }
  }
  /* пролёты через коридор */
  for (let z = -2.5; z > -DET; z -= R(3.5, 8)) {
    if (nearGate(z - 1, z + 1)) continue;
    const n = 1 + Math.floor(T.rnd() * 3);
    for (let i = 0; i < n; i++) {
      const y0 = R(6.3, 8.4), y1 = R(6.3, 8.4), zz = z + R(-0.8, 0.8);
      B.raw(cableGeo(catenary(V(-HW + 0.3, y0, zz), V(HW - 0.3, y1, zz + R(-1.5, 1.5)), R(0.6, 2.4), 16), R(0.018, 0.05), 20, 5), cableM);
    }
  }
  /* оборванные концы, свисающие с балок */
  for (let z = -6; z > -DET; z -= 6) {
    if (T.rnd() < 0.55 || Math.abs(z - GATE_Z) < 2) continue;
    const x = R(-0.6, 1.2), y1 = R(4.6, 6.8), bend = R(-0.4, 0.4);
    B.raw(cableGeo([V(x, CORR_H - 0.5, z), V(x + bend * 0.3, (CORR_H + y1) / 2, z + 0.1), V(x + bend, y1, z + R(-0.3, 0.3))], R(0.015, 0.03), 10, 5), cableM);
  }

  /* ================= МУСОР, ЯЩИКИ, ЛУЖИ ================= */
  const crateM = std({ map: T.crateTex(), roughness: 0.9 });
  const crate = (x, z, s, ry = 0, y = 0) => { B.add(BX(s, s * 0.8, s), crateM, x, y + s * 0.4, z, 0, ry, 0); if (!y) col(x - s / 2, x + s / 2, z - s / 2, z + s / 2); };
  crate(-HW + 0.75, -4.4, 0.7, 0.1); crate(-HW + 0.55, -4.1, 0.45, 0.4, 0.56);
  crate(HW - 0.7, -18.5, 0.8, -0.2); crate(-HW + 0.7, -22.6, 0.6, 0.3);
  for (let z = -30; z > -DET; z -= R(8, 22)) crate((T.rnd() < 0.5 ? -1 : 1) * (HW - R(0.6, 0.8)), z + R(1, 2.5), R(0.45, 0.9), R(-0.5, 0.5));
  /* кабельный барабан */
  { const g = new THREE.CylinderGeometry(0.5, 0.5, 0.08, 20); for (const dz of [-0.25, 0.25]) B.add(g, std({ color: 0x5b4a33 }), -HW + 0.7, 0.5, -16.5 + dz, Math.PI / 2, 0, 0);
    B.add(new THREE.CylinderGeometry(0.32, 0.32, 0.5, 16), cableM, -HW + 0.7, 0.5, -16.5, Math.PI / 2, 0, 0); col(-HW, -HW + 1.2, -16.9, -16.1); }
  /* листы бумаги на полу */
  const paperM = std({ color: 0xc8c0aa, roughness: 0.95, side: THREE.DoubleSide });
  for (let i = 0; i < 70; i++) B.add(new THREE.PlaneGeometry(0.21, 0.29), paperM, R(-HW + 0.2, HW - 0.2), 0.004 + i * 0.00002, i < 12 ? R(-1, -19) : R(-20, -DET), -Math.PI / 2, 0, R(0, 6.28));
  /* лужи */
  const puddleM = new THREE.MeshStandardMaterial({ color: 0x1c1d1f, roughness: 0.12, metalness: 0.0, transparent: true, opacity: 0.6, polygonOffset: true, polygonOffsetFactor: -1 });
  for (let i = 0; i < 26; i++) { const z = i < 4 ? R(-3, -18) : R(-22, -DET); B.add(new THREE.CircleGeometry(1, 20), puddleM, R(-1.2, 1.2), 0.003, z, -Math.PI / 2, 0, 0, R(0.4, 1.3), R(0.3, 0.9), 1); }

  /* ================= СВЕТИЛЬНИКИ ================= */
  /* настенные лампы на пилястрах (чередуются стороны), подвесные купола, аварийные красные */
  const kinds = { wall: [], dome: [], em: [] };
  for (let i = 0, z = -3; z > -LEN; z -= 6, i++) {
    const s = i % 2 ? 1 : -1;
    if (s > 0 && z <= NICHE[0] && z >= NICHE[1]) continue;
    kinds.wall.push({ x: s * (HW - 0.35), y: 3.35, z: z - 3, s });
  }
  kinds.wall.push({ x: HW + 1.0, y: NICHE_H - 0.1, z: -8, s: 0 });   /* лампа в нише */
  for (let z = -9; z > -LEN; z -= 18) kinds.dome.push({ x: 0.35, y: 7.0, z });
  for (let z = -1.5; z > -LEN; z -= 12) kinds.em.push({ x: -HW + 0.06, y: 2.6, z });
  const lampMesh = (geo, n) => new THREE.InstancedMesh(geo, new THREE.MeshBasicMaterial({ color: 0xffffff, fog: false }), n);
  W.lampMeshes = {
    wall: lampMesh(BX(0.08, 0.06, 0.5), kinds.wall.length),
    dome: lampMesh(new THREE.CircleGeometry(0.32, 16).rotateX(Math.PI / 2), kinds.dome.length),
    em: lampMesh(BX(0.06, 0.1, 0.18), kinds.em.length),
  };
  const wallHousing = BX(0.3, 0.14, 0.6), domeShade = new THREE.ConeGeometry(0.42, 0.32, 16, 1, true);
  kinds.wall.forEach((l, i) => {
    const hx = l.s ? l.x - l.s * 0.05 : l.x;
    m4.makeTranslation(l.s ? l.x + l.s * 0.02 : l.x, l.y - 0.08, l.z); W.lampMeshes.wall.setMatrixAt(i, m4);
    if (-l.z < DET + 40) B.add(wallHousing, darkM, hx, l.y, l.z);
    W.lamps.push({ kind: 'wall', x: l.s ? l.x - l.s * 0.5 : l.x, y: l.y - 0.3, z: l.z, grp: l.z > GATE_Z ? 'A' : 'S7', inst: i, lvl: 0, on: 0, fl: 0, delay: 0 });
  });
  kinds.dome.forEach((l, i) => {
    m4.makeTranslation(l.x, l.y - 0.16, l.z); W.lampMeshes.dome.setMatrixAt(i, m4);
    if (-l.z < DET + 40) { B.add(domeShade, std({ color: 0x3c4a3c, side: THREE.DoubleSide, metalness: 0.4, roughness: 0.5 }), l.x, l.y, l.z); B.add(new THREE.CylinderGeometry(0.008, 0.008, CORR_H - l.y - 0.3, 4), darkM, l.x, (CORR_H + l.y) / 2, l.z); }
    W.lamps.push({ kind: 'dome', x: l.x, y: l.y - 0.4, z: l.z, grp: l.z > GATE_Z ? 'A' : 'S7', inst: i, lvl: 0, on: 0, fl: 0, delay: 0 });
  });
  kinds.em.forEach((l, i) => {
    m4.makeTranslation(l.x, l.y, l.z); W.lampMeshes.em.setMatrixAt(i, m4);
    W.lamps.push({ kind: 'em', x: l.x + 0.4, y: l.y, z: l.z, grp: 'E', inst: i, lvl: 1, on: 1, fl: 0, delay: 0 });
  });
  Object.values(W.lampMeshes).forEach(m => scene.add(m));
  W.lamps.push({ kind: 'bulb', x: -1.1, y: 2.5, z: 2, grp: 'L', lvl: 1, on: 1, fl: 0.05, delay: 0 });

  /* свечение: точки со своим шейдером (видны далеко, не меньше 2 px) */
  const n = W.lamps.length, pos = new Float32Array(n * 3), colA = new Float32Array(n * 3), sz = new Float32Array(n);
  const GS = { wall: 1.0, dome: 1.8, em: 0.22, bulb: 0.5 };
  W.lamps.forEach((l, i) => { pos.set([l.kind === 'wall' && l.x !== HW + 1.0 ? l.x * 0.85 : l.x, l.kind === 'dome' ? l.y + 0.2 : l.kind === 'wall' ? l.y + 0.2 : l.y, l.z], i * 3); sz[i] = GS[l.kind]; l.gi = i; });
  const gg = new THREE.BufferGeometry();
  gg.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  gg.setAttribute('color', new THREE.BufferAttribute(colA, 3));
  gg.setAttribute('size', new THREE.BufferAttribute(sz, 1));
  const glowMat = new THREE.ShaderMaterial({
    uniforms: { scale: { value: 600 } },
    vertexShader: `attribute float size;attribute vec3 color;varying vec3 vC;uniform float scale;
      void main(){vC=color;vec4 mv=modelViewMatrix*vec4(position,1.0);gl_Position=projectionMatrix*mv;
      float s=size*scale/max(-mv.z,0.1);gl_PointSize=min(max(s,dot(color,vec3(1.0))>0.01?2.5:0.0),256.0);}`,
    fragmentShader: `varying vec3 vC;void main(){vec2 d=gl_PointCoord-0.5;float r=length(d)*2.0;float a=pow(max(1.0-r,0.0),2.2);gl_FragColor=vec4(vC*a,1.0);}`,
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
  });
  const glow = new THREE.Points(gg, glowMat); glow.frustumCulled = false; scene.add(glow);
  W.glow = { geo: gg, mat: glowMat };

  /* ================= ПЫЛЬ В ВОЗДУХЕ ================= */
  const DN = 700, dp = new Float32Array(DN * 3);
  for (let i = 0; i < DN; i++) dp.set([R(-HW, HW), R(0, 9), R(-10, 10)], i * 3);
  const dg = new THREE.BufferGeometry(); dg.setAttribute('position', new THREE.BufferAttribute(dp, 3));
  const dust = new THREE.Points(dg, new THREE.PointsMaterial({ color: 0xb0aa9c, size: 0.016, transparent: true, opacity: 0, depthWrite: false }));
  dust.frustumCulled = false; scene.add(dust);
  W.dust = { pts: dust, geo: dg, t: 0 };
  W.updateDust = (dt, cz) => {
    const a = dg.attributes.position; W.dust.t += dt;
    for (let i = 0; i < DN; i++) {
      let y = a.getY(i) - dt * 0.05 + Math.sin(W.dust.t * 0.3 + i) * dt * 0.03, z = a.getZ(i) + Math.cos(W.dust.t * 0.2 + i * 1.7) * dt * 0.04;
      if (y < 0) y += 9;
      if (z > cz + 10) z -= 20; else if (z < cz - 10) z += 20;
      a.setY(i, y); a.setZ(i, z);
    }
    a.needsUpdate = true;
  };

  B.build(scene);
  return W;
}
