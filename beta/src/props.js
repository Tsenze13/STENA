/* Модели: пульт с терминалом, щиток ЩР-6, двери, мусор. Каждая модель строится лицом к +Z
   в своей группе; группу потом ставят и поворачивают к стене. */
import * as THREE from 'three';
import * as T from './textures.js';
import { roundBox, cableGeo, catenary } from './geo.js';

const std = (o) => new THREE.MeshStandardMaterial(Object.assign({ roughness: 0.85, metalness: 0 }, o));
const mesh = (g, m, x = 0, y = 0, z = 0, parent) => { const o = new THREE.Mesh(g, m); o.position.set(x, y, z); if (parent) parent.add(o); return o; };
const BOX = (w, h, d) => new THREE.BoxGeometry(w, h, d);

/* ================= ПУЛЬТ С ТЕРМИНАЛОМ ================= */
export function makeConsole(screenCanvas) {
  const g = new THREE.Group(), acts = [];
  const steel = std({ color: 0x3f423d, roughness: 0.6, metalness: 0.4 });
  const beige = std({ color: 0xc8c0a8, roughness: 0.65 });
  const dark = std({ color: 0x222320, roughness: 0.5 });
  /* тумба пульта и наклонная столешница */
  mesh(BOX(1.3, 0.92, 0.62), steel, 0, 0.46, -0.04, g);
  const top = mesh(BOX(1.36, 0.05, 0.72), std({ color: 0x5a4a38, roughness: 0.7 }), 0, 0.95, 0, g);
  top.rotation.x = 0.06;
  mesh(BOX(1.3, 0.06, 0.05), dark, 0, 0.88, 0.3, g);
  /* кнопки и лампы на передней панели тумбы */
  for (let i = 0; i < 5; i++) mesh(new THREE.CylinderGeometry(0.018, 0.018, 0.02, 10), std({ color: [0xb33, 0x3a3, 0xdd3, 0xddd, 0x36c][i], roughness: 0.4 }), -0.45 + i * 0.07, 0.8, 0.27, g).rotation.x = Math.PI / 2;
  /* корпус кинескопа: скруглённая передняя часть и сужающийся «затылок» */
  const crt = new THREE.Group(); crt.position.set(0.05, 1.2, -0.02); g.add(crt);
  const body = mesh(roundBox(0.5, 0.42, 0.3, 0.05, 0.012), beige, 0, 0, 0.02, crt);
  const back = mesh(new THREE.CylinderGeometry(0.12, 0.2, 0.28, 4, 1), beige, 0, 0, -0.25, crt);
  back.rotation.x = Math.PI / 2; back.rotation.y = Math.PI / 4; back.scale.set(1.15, 1, 0.9);
  mesh(roundBox(0.42, 0.33, 0.03, 0.04, 0.008), dark, 0, 0.01, 0.17, crt);
  /* выпуклое стекло экрана */
  const sg = new THREE.PlaneGeometry(0.36, 0.27, 18, 14);
  const pa = sg.attributes.position;
  for (let i = 0; i < pa.count; i++) { const x = pa.getX(i) / 0.18, y = pa.getY(i) / 0.135; pa.setZ(i, 0.022 * (1 - x * x * 0.6) * (1 - y * y * 0.6)); }
  sg.computeVertexNormals();
  const stex = new THREE.CanvasTexture(screenCanvas); stex.colorSpace = THREE.SRGBColorSpace;
  const screen = mesh(sg, new THREE.MeshBasicMaterial({ map: stex }), 0, 0.012, 0.18, crt);
  /* стекло поверх: блик */
  mesh(sg.clone(), new THREE.MeshStandardMaterial({ color: 0x000000, roughness: 0.05, metalness: 0.9, transparent: true, opacity: 0.18 }), 0, 0.012, 0.184, crt);
  /* ручки и индикатор питания */
  const led = mesh(new THREE.SphereGeometry(0.008, 8, 6), new THREE.MeshBasicMaterial({ color: 0x301010 }), 0.19, -0.18, 0.175, crt);
  for (let i = 0; i < 2; i++) mesh(new THREE.CylinderGeometry(0.014, 0.014, 0.02, 12), dark, 0.13 - i * 0.05, -0.18, 0.18, crt).rotation.x = Math.PI / 2;
  mesh(BOX(0.36, 0.008, 0.06), dark, 0, -0.2, 0.11, crt);
  /* клавиатура с клавишами */
  const kb = new THREE.Group(); kb.position.set(0.02, 0.99, 0.2); kb.rotation.x = 0.12; g.add(kb);
  mesh(roundBox(0.52, 0.18, 0.035, 0.015, 0.005), beige, 0, 0, 0, kb).rotation.x = -Math.PI / 2;
  const keyG = BOX(0.03, 0.014, 0.03), keyM = std({ color: 0x8a8370, roughness: 0.5 }), keyD = std({ color: 0x4a463d, roughness: 0.5 });
  for (let r = 0; r < 4; r++) for (let c = 0; c < 13; c++) mesh(keyG, (c > 10 || r === 0) ? keyD : keyM, -0.225 + c * 0.0375 + r * 0.008, 0.024, -0.06 + r * 0.037, kb);
  mesh(BOX(0.24, 0.014, 0.03), keyM, -0.02, 0.024, 0.088, kb);
  /* кабели от пульта к стене */
  const cm = std({ color: 0x111111, roughness: 0.6 });
  mesh(cableGeo(catenary(new THREE.Vector3(0.05, 1.1, -0.35), new THREE.Vector3(0.3, 0.05, -0.32), -0.0, 10, new THREE.Vector3(0, 0, -0.05)), 0.012), cm, 0, 0, 0, g);
  mesh(cableGeo(catenary(new THREE.Vector3(-0.4, 0.3, -0.33), new THREE.Vector3(-0.55, 2.6, -0.33), 0.25, 12), 0.018), cm, 0, 0, 0, g);
  for (const m of [body, screen, back, top]) { m.userData.act = 'terminal'; acts.push(m); }
  kb.children.forEach(m => { m.userData.act = 'terminal'; acts.push(m); });
  return { group: g, acts, screen: { canvas: screenCanvas, tex: stex }, led };
}

/* ================= ЩИТОК ЩР-6 ================= */
export function makePanel() {
  const g = new THREE.Group(), acts = [];
  const grey = std({ color: 0x7d8278, roughness: 0.55, metalness: 0.35 });
  const inside = std({ color: 0x5f645c, roughness: 0.7, metalness: 0.2 });
  const W = 0.72, H = 0.95, D = 0.2;
  /* корпус (короб без передней стенки) */
  mesh(BOX(W, H, 0.02), inside, 0, 0, -D / 2 + 0.01, g);
  for (const [w, h, d, x, y] of [[0.02, H, D, -W / 2, 0], [0.02, H, D, W / 2, 0], [W, 0.02, D, 0, H / 2], [W, 0.02, D, 0, -H / 2]]) mesh(BOX(w, h, d), grey, x, y, 0, g);
  /* дверца на петлях слева, открыта */
  const hinge = new THREE.Group(); hinge.position.set(-W / 2, 0, D / 2); g.add(hinge);
  const door = mesh(BOX(W, H, 0.02), grey, W / 2, 0, 0, hinge);
  const face = mesh(new THREE.PlaneGeometry(W - 0.02, H - 0.02), std({ map: T.panelTex(), roughness: 0.6, metalness: 0.2 }), W / 2, 0, 0.011, hinge);
  hinge.rotation.y = -1.9;
  const warn = mesh(new THREE.PlaneGeometry(0.16, 0.19), std({ map: T.warnTex() }), W / 2, 0.15, -0.012, hinge); warn.rotation.y = Math.PI;
  /* DIN-рейка и автоматы */
  mesh(BOX(W - 0.1, 0.03, 0.01), std({ color: 0xaaaaaa, metalness: 0.8, roughness: 0.3 }), 0, -0.12, -D / 2 + 0.03, g);
  const brk = {};
  const bm = std({ color: 0xe8e4d8, roughness: 0.5 }), lever = std({ color: 0x1a1a1a, roughness: 0.4 });
  [['qf0', -0.2, 0.1], ['qf1', 0.0, 0.07], ['qf2', 0.12, 0.07]].forEach(([k, x, w]) => {
    mesh(BOX(w, 0.14, 0.09), k === 'qf0' ? std({ color: 0xf0e0b2, roughness: 0.5 }) : bm, x, -0.12, -D / 2 + 0.07, g);
    const lv = mesh(BOX(w * 0.45, 0.04, 0.03), lever, x, -0.1, -D / 2 + 0.125, g);
    brk[k] = lv;
  });
  /* контактор V и лампы */
  mesh(BOX(0.1, 0.12, 0.1), std({ color: 0x3a3d39 }), 0.26, -0.12, -D / 2 + 0.07, g);
  const lampMain = mesh(new THREE.SphereGeometry(0.018, 10, 8), new THREE.MeshBasicMaterial({ color: 0x401010 }), -0.2, 0.06, -D / 2 + 0.06, g);
  const lampV = mesh(new THREE.SphereGeometry(0.018, 10, 8), new THREE.MeshBasicMaterial({ color: 0x401010 }), 0.26, 0.0, -D / 2 + 0.06, g);
  /* амперметр */
  const dial = T.tex(128, 128, (c, w, h) => {
    c.fillStyle = '#e8e3d2'; c.beginPath(); c.arc(64, 64, 62, 0, 7); c.fill();
    c.strokeStyle = '#222'; c.lineWidth = 2;
    for (let a = 0; a <= 30; a += 5) { const t = (-80 + 160 * a / 30 - 90) * Math.PI / 180; c.beginPath(); c.moveTo(64 + Math.cos(t) * 52, 70 + Math.sin(t) * 52); c.lineTo(64 + Math.cos(t) * 42, 70 + Math.sin(t) * 42); c.stroke(); }
    c.strokeStyle = '#b3261e'; c.lineWidth = 6; c.beginPath(); c.arc(64, 70, 50, (-80 + 160 * 20 / 30 - 90) * Math.PI / 180, (80 - 90) * Math.PI / 180); c.stroke();
    c.fillStyle = '#222'; c.font = '700 18px PT Mono, monospace'; c.textAlign = 'center'; c.fillText('A', 64, 100);
  });
  mesh(new THREE.CylinderGeometry(0.08, 0.08, 0.04, 24), std({ color: 0x222222 }), 0.05, 0.22, -D / 2 + 0.04, g).rotation.x = Math.PI / 2;
  mesh(new THREE.CircleGeometry(0.07, 24), new THREE.MeshStandardMaterial({ map: dial, roughness: 0.4 }), 0.05, 0.22, -D / 2 + 0.061, g);
  const needle = new THREE.Group(); needle.position.set(0.05, 0.207, -D / 2 + 0.064); g.add(needle);
  mesh(BOX(0.003, 0.06, 0.002), new THREE.MeshBasicMaterial({ color: 0x111111 }), 0, 0.03, 0, needle);
  /* провода из щитка вверх */
  const cm = std({ color: 0x151515 });
  for (let i = 0; i < 4; i++) mesh(new THREE.CylinderGeometry(0.012, 0.012, 1.4, 6), cm, -0.25 + i * 0.07, H / 2 + 0.7, -0.02, g);
  for (const m of [door, face, ...g.children.filter(c => c.isMesh)]) { m.userData.act = 'panel'; acts.push(m); }

  let ang = -80;
  return {
    group: g, acts,
    /* отразить состояние автоматов и нагрузки на модели */
    update(S, load, dt) {
      for (const k of ['qf0', 'qf1', 'qf2']) brk[k].position.y += ((S[k] ? -0.09 : -0.15) - brk[k].position.y) * Math.min(1, dt * 18);
      lampMain.material.color.setHex(S.qf0 ? 0xff3322 : 0x401010);
      lampV.material.color.setHex(S.v ? 0xff3322 : 0x401010);
      const target = -80 + 160 * Math.min(load, 30) / 30;
      ang += (target - ang) * Math.min(1, dt * 5);
      needle.rotation.z = -ang * Math.PI / 180;
    },
  };
}

/* ================= ДВЕРИ ================= */
const doorMats = {};
function dm(key, f) { return doorMats[key] || (doorMats[key] = f()); }
export function makeDoor(type, label, lit = false) {
  const g = new THREE.Group(), acts = [];
  const frame = dm('frame', () => std({ color: 0x3a3a35, metalness: 0.5, roughness: 0.6 }));
  let w = 1.1, h = 2.15;
  if (type === 'hermetic') {
    w = 1.3; h = 2.1;
    mesh(roundBox(w + 0.36, h + 0.36, 0.25, 0.3, 0.02), frame, 0, h / 2 + 0.05, -0.08, g);
    const slab = mesh(roundBox(w, h, 0.16, 0.24, 0.02), dm('herm', () => std({ map: T.metal('#4d5a52'), metalness: 0.5, roughness: 0.5 })), 0, h / 2 + 0.05, 0.04, g);
    const wheel = mesh(new THREE.TorusGeometry(0.2, 0.025, 8, 24), dm('wheel', () => std({ color: 0x7a2a1c, metalness: 0.6, roughness: 0.4 })), 0, 1.15, 0.16, g);
    for (let i = 0; i < 3; i++) { const sp = mesh(BOX(0.4, 0.025, 0.025), wheel.material, 0, 1.15, 0.16, g); sp.rotation.z = i * Math.PI / 3; }
    for (let i = 0; i < 12; i++) { const a = i / 12 * Math.PI * 2; mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.04, 8), frame, Math.cos(a) * (w / 2 + 0.08), h / 2 + 0.05 + Math.sin(a) * (h / 2 + 0.08) * 0.95, 0.06, g).rotation.x = Math.PI / 2; }
    const hz = mesh(new THREE.PlaneGeometry(w + 0.3, 0.12), dm('haz', () => std({ map: T.hazardTex() })), 0, 0.06, 0.06, g);
    acts.push(slab, wheel, hz);
  } else if (type === 'cage') {
    mesh(BOX(w + 0.1, 0.06, 0.06), frame, 0, h, 0, g);
    for (const x of [-w / 2, w / 2]) mesh(BOX(0.06, h, 0.06), frame, x, h / 2, 0, g);
    const bar = new THREE.CylinderGeometry(0.012, 0.012, h - 0.1, 5);
    for (let x = -w / 2 + 0.1; x < w / 2; x += 0.11) acts.push(mesh(bar, frame, x, h / 2, 0, g));
    for (const y of [0.3, 1.1, 1.9]) acts.push(mesh(BOX(w, 0.03, 0.03), frame, 0, y, 0, g));
    /* за решёткой — темнота */
    mesh(new THREE.PlaneGeometry(w, h), dm('void', () => new THREE.MeshBasicMaterial({ color: 0x000000 })), 0, h / 2, -0.05, g);
  } else {
    mesh(BOX(w + 0.16, 0.08, 0.14), frame, 0, h + 0.04, 0, g);
    for (const x of [-w / 2 - 0.04, w / 2 + 0.04]) mesh(BOX(0.08, h, 0.14), frame, x, h / 2, 0, g);
    const col = ['#5a3c2c', '#3d4a52', '#5b5a3a', '#4a2e2e'][Math.floor(Math.random() * 4)];
    const slab = mesh(BOX(w, h, 0.05), dm('svc' + col, () => std({ map: T.metal(col), metalness: 0.35, roughness: 0.6 })), 0, h / 2, 0.01, g);
    mesh(BOX(0.04, 0.16, 0.05), dm('hd', () => std({ color: 0x8a8378, metalness: 0.8, roughness: 0.35 })), w / 2 - 0.12, 1.0, 0.06, g);
    acts.push(slab);
  }
  /* номер над дверью */
  const num = mesh(new THREE.PlaneGeometry(0.6, 0.2), new THREE.MeshStandardMaterial({ map: T.stencil(label, 384, 128, 'rgba(225,220,200,.8)', 90), transparent: true }), 0, h + 0.34, 0.08, g);
  /* лампа над дверью: красная, если «занято» */
  const lamp = mesh(new THREE.SphereGeometry(0.045, 10, 8), new THREE.MeshBasicMaterial({ color: lit ? 0xff2a1a : 0x2a0c08 }), 0.45, h + 0.34, 0.09, g);
  acts.forEach(a => { a.userData.act = 'locked'; a.userData.label = label; });
  return { group: g, acts, lamp, h };
}
