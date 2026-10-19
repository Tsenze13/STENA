/* Тело героя.
   Ноги и туловище живут в мире (видно, если посмотреть вниз). Руки — «вьюмодель»: рисуются вторым проходом
   поверх мира, чтобы не проваливаться в стены. Правая рука держит фонарик, на левой — ПТ-1. */
import * as THREE from 'three';
import * as T from './textures.js';
import { roundBox } from './geo.js';

const std = (o) => new THREE.MeshStandardMaterial(Object.assign({ roughness: 0.85, metalness: 0 }, o));
const add = (parent, geo, mat, x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0) => { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.rotation.set(rx, ry, rz); parent.add(m); return m; };
const BX = (w, h, d) => new THREE.BoxGeometry(w, h, d);
const CYL = (r1, r2, h, s = 12) => new THREE.CylinderGeometry(r1, r2, h, s);

/* ткань спецовки: синяя саржа с потёртостями */
function fabric(base) {
  return T.tex(128, 128, (g, w, h) => {
    g.fillStyle = base; g.fillRect(0, 0, w, h);
    for (let y = 0; y < h; y += 2) { g.fillStyle = `rgba(255,255,255,${0.02 + Math.random() * 0.03})`; g.fillRect(0, y, w, 1); }
    for (let i = 0; i < 400; i++) { g.fillStyle = `rgba(0,0,0,${Math.random() * 0.12})`; g.fillRect(Math.random() * w, Math.random() * h, 2, 2); }
  });
}

export function makeBody(scene, vmScene, cam, WR) {
  const cloth = std({ map: fabric('#2c3a52'), roughness: 0.95 });
  const clothDark = std({ map: fabric('#222c3e'), roughness: 0.95 });
  const glove = std({ color: 0x6b4a2e, roughness: 0.75 });
  const boot = std({ color: 0x1b1a18, roughness: 0.6 });
  const belt = std({ color: 0x3b2a1a, roughness: 0.6 });
  const metal = std({ color: 0x8a8578, metalness: 0.8, roughness: 0.35 });
  const reflect = std({ color: 0xc9a227, roughness: 0.5 });

  /* ================= НОГИ И ТУЛОВИЩЕ (мир) ================= */
  const root = new THREE.Group(); scene.add(root);
  /* туловище за камерой (сверху его всё равно не видно), ноги — чуть впереди:
     глядя вниз, видно ноги в спецовке и ботинки */
  const body = new THREE.Group(); root.add(body);
  const torso = add(body, new THREE.CapsuleGeometry(0.17, 0.22, 4, 12), cloth, 0, 1.17, 0.26); torso.scale.set(1.15, 1, 0.72);
  const legs = [];
  for (const s of [-1, 1]) {
    const hip = new THREE.Group(); hip.position.set(s * 0.1, 0.9, -0.04); body.add(hip);
    add(hip, new THREE.CapsuleGeometry(0.075, 0.28, 4, 10), cloth, 0, -0.21, 0);
    const knee = new THREE.Group(); knee.position.set(0, -0.43, 0); hip.add(knee);
    add(knee, new THREE.CapsuleGeometry(0.065, 0.28, 4, 10), cloth, 0, -0.2, 0);
    add(knee, CYL(0.07, 0.072, 0.06, 10), clothDark, 0, -0.33, 0);                    // манжета
    add(knee, BX(0.12, 0.1, 0.27), boot, 0, -0.4, -0.05);
    add(knee, BX(0.125, 0.03, 0.28), std({ color: 0x0d0d0c }), 0, -0.445, -0.05);     // подошва
    legs.push({ hip, knee, s });
  }

  /* ================= РУКИ (вьюмодель) ================= */
  const vm = new THREE.Group(); vmScene.add(vm);
  const hemi = new THREE.HemisphereLight(0x8a93a0, 0x15130f, 0.25); vmScene.add(hemi);
  const vmL = [new THREE.PointLight(0xffffff, 0, 30, 2), new THREE.PointLight(0xffffff, 0, 30, 2)]; vmL.forEach(l => vmScene.add(l));

  /* перчатка: ладонь и пальцы, согнутые в хват */
  function hand(parent, grip, side) {
    const h = new THREE.Group(); parent.add(h);
    add(h, BX(0.085, 0.032, 0.095), glove, 0, 0, 0);
    for (let i = 0; i < 4; i++) {
      const f = new THREE.Group(); f.position.set(-0.03 + i * 0.02, 0, -0.045); h.add(f);
      add(f, BX(0.017, 0.02, 0.045), glove, 0, 0, -0.022);
      const f2 = new THREE.Group(); f2.position.set(0, 0, -0.045); f.add(f2);
      add(f2, BX(0.016, 0.019, 0.035), glove, 0, 0, -0.016);
      f.rotation.x = grip ? -1.2 : -0.25; f2.rotation.x = grip ? -1.3 : -0.3;
    }
    const th = new THREE.Group(); th.position.set(side * 0.045, 0, -0.01); h.add(th);
    add(th, BX(0.02, 0.022, 0.05), glove, 0, 0, -0.022); th.rotation.set(grip ? -0.6 : 0, side * 0.5, 0);
    add(h, CYL(0.05, 0.048, 0.05, 12), glove, 0, 0, 0.06, Math.PI / 2);                  // раструб перчатки
    return h;
  }
  function forearm(parent) {
    add(parent, CYL(0.047, 0.04, 0.3, 12), cloth, 0, 0, -0.15, Math.PI / 2);
    add(parent, CYL(0.05, 0.05, 0.04, 12), clothDark, 0, 0, -0.27, Math.PI / 2);         // манжета
    add(parent, CYL(0.055, 0.05, 0.34, 12), cloth, 0.03, -0.03, 0.15, Math.PI / 2 + 0.3, 0, 0.1); // плечо уходит назад
  }

  /* ----- правая рука с фонариком ----- */
  const R = new THREE.Group(); vm.add(R);
  forearm(R);
  const rh = hand(R, true, -1); rh.position.set(0, 0, -0.34);
  const flash = new THREE.Group(); flash.position.set(0, 0.005, -0.36); R.add(flash);
  add(flash, CYL(0.022, 0.022, 0.2, 14), std({ color: 0x2a2a28, metalness: 0.6, roughness: 0.4 }), 0, 0, -0.03, Math.PI / 2);
  add(flash, CYL(0.034, 0.024, 0.06, 14), std({ color: 0x3a3a36, metalness: 0.7, roughness: 0.3 }), 0, 0, -0.15, Math.PI / 2);
  const lens = add(flash, new THREE.CircleGeometry(0.03, 16), new THREE.MeshBasicMaterial({ color: 0x222222 }), 0, 0, -0.181, 0, Math.PI);
  add(flash, BX(0.01, 0.012, 0.02), std({ color: 0x9a2a1a }), 0, 0.024, 0.0);                    // кнопка
  const tipLocal = new THREE.Vector3(0, 0.005, -0.55);

  /* ----- левая рука с ПТ-1 ----- */
  const Lg = new THREE.Group(); vm.add(Lg);
  forearm(Lg);
  const lh = hand(Lg, false, 1); lh.position.set(0, 0, -0.34);
  const dev = new THREE.Group(); dev.position.set(0, 0.06, -0.16); dev.scale.setScalar(1.3); Lg.add(dev);
  const devM = std({ color: 0x5c5e55, metalness: 0.5, roughness: 0.5 });
  add(dev, roundBox(0.11, 0.035, 0.165, 0.012, 0.004), devM, 0, 0, 0);
  add(dev, BX(0.09, 0.004, 0.128), std({ color: 0x111111, roughness: 0.3 }), 0, 0.022, 0);     // рамка экрана
  const stex = new THREE.CanvasTexture(WR.canvas); stex.colorSpace = THREE.SRGBColorSpace;
  const sg = new THREE.PlaneGeometry(0.11, 0.0733); sg.rotateX(-Math.PI / 2); sg.rotateY(Math.PI / 2);
  const screen = add(dev, sg, new THREE.MeshBasicMaterial({ map: stex, toneMapped: false }), 0, 0.0245, 0);
  for (const [z, c] of [[0.065, 0xc0392b], [0.045, 0xe0b020]]) add(dev, CYL(0.006, 0.006, 0.012, 8), std({ color: c }), 0.058, 0.0, z, 0, 0, Math.PI / 2);   // тумблеры сбоку
  add(dev, CYL(0.01, 0.01, 0.014, 10), metal, -0.058, 0.0, 0.06, 0, 0, Math.PI / 2);               // разъём кабеля
  add(dev, CYL(0.004, 0.004, 0.05, 6), std({ color: 0x111111 }), 0.03, 0.03, 0.09, 0.4);          // антенна
  for (const z of [-0.06, 0.06]) add(Lg, CYL(0.052, 0.052, 0.02, 14), std({ color: 0x1d1d1b, roughness: 0.6 }), 0, 0, -0.16 + z, Math.PI / 2); // ремни
  /* спиральный кабель от разъёма к поясу */
  { const pts = []; for (let i = 0; i <= 60; i++) { const t = i / 60, a = t * 40; pts.push(new THREE.Vector3(-0.07 + Math.cos(a) * 0.01, Math.sin(a) * 0.01 - t * 0.1, -0.1 + t * 0.32)); }
    add(Lg, new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 120, 0.004, 5), std({ color: 0x151515 })); }
  const wristGlowVm = new THREE.PointLight(0x6dff8a, 0, 0.6, 2); wristGlowVm.position.set(0, 0.1, -0.16); Lg.add(wristGlowVm);
  /* свет экрана в мире: когда рука поднята, экран подсвечивает всё вокруг */
  const wristGlow = new THREE.PointLight(0x6dff8a, 0, 5, 2); wristGlow.position.set(-0.05, -0.2, -0.35); cam.add(wristGlow);

  /* позы рук в пространстве камеры */
  const pose = (x, y, z, rx, ry, rz) => ({ p: new THREE.Vector3(x, y, z), q: new THREE.Quaternion().setFromEuler(new THREE.Euler(rx, ry, rz, 'YXZ')) });
  const P_R = { rest: pose(0.24, -0.27, -0.1, 0.1, 0.06, 0), reach: pose(0.12, -0.2, -0.22, 0.2, 0.05, 0), low: pose(0.27, -0.5, -0.02, -0.4, 0.1, 0) };
  const raisedQ = new THREE.Quaternion().setFromRotationMatrix(new THREE.Matrix4().makeBasis(new THREE.Vector3(0, -1, 0), new THREE.Vector3(0, 0, 1), new THREE.Vector3(-1, 0, 0)))
    .premultiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), -0.32));
  const P_L = { rest: pose(-0.27, -0.42, -0.06, 0.12, -0.18, 0.15), raised: { p: new THREE.Vector3(-0.2, -0.15, -0.38), q: raisedQ } };
  R.position.copy(P_R.rest.p); R.quaternion.copy(P_R.rest.q);
  Lg.position.copy(P_L.rest.p); Lg.quaternion.copy(P_L.rest.q);

  const Bd = { root, vm, R, L: Lg, screen, stex, tipLocal, reachT: 0, swayX: 0, swayY: 0, lastYaw: 0, lastPitch: 0, flashLens: lens };
  WR.onDraw = () => { stex.needsUpdate = true; };
  Bd.reach = () => { Bd.reachT = 0.45; };

  const tmpV = new THREE.Vector3(), tmpQ = new THREE.Quaternion();
  /* st: {pos, yaw, pitch, bob, speed, flashOn, busy, lights:[PointLight…]} */
  Bd.update = (dt, st) => {
    /* ноги и туловище */
    root.position.set(st.pos.x, 0, st.pos.z); root.rotation.y = st.yaw;
    const k = Math.min(1, st.speed / 2.2);
    for (const L of legs) {
      const ph = st.bob + (L.s > 0 ? Math.PI : 0);
      L.hip.rotation.x = Math.sin(ph) * 0.5 * k;
      L.knee.rotation.x = -Math.max(0, Math.sin(ph + Math.PI / 2)) * 0.75 * k;
    }
    /* вьюмодель следует за камерой */
    vm.position.copy(cam.position); vm.quaternion.copy(cam.quaternion);
    /* инерция при повороте головы и покачивание на ходу */
    let dy = st.yaw - Bd.lastYaw; dy = Math.atan2(Math.sin(dy), Math.cos(dy));
    Bd.swayX += (-dy * 0.6 - Bd.swayX) * Math.min(1, dt * 8); Bd.swayY += ((st.pitch - Bd.lastPitch) * 0.6 - Bd.swayY) * Math.min(1, dt * 8);
    Bd.lastYaw = st.yaw; Bd.lastPitch = st.pitch;
    const bobX = Math.sin(st.bob) * 0.012 * k, bobY = -Math.abs(Math.cos(st.bob)) * 0.012 * k;
    const sx = Math.max(-0.06, Math.min(0.06, Bd.swayX)), sy = Math.max(-0.05, Math.min(0.05, Bd.swayY));
    /* правая рука */
    Bd.reachT = Math.max(0, Bd.reachT - dt);
    const rT = Bd.reachT > 0 ? P_R.reach : (st.busy ? P_R.low : P_R.rest);
    const a = Math.min(1, dt * (Bd.reachT > 0 ? 14 : 8));
    tmpV.copy(rT.p).add(new THREE.Vector3(sx + bobX, sy + bobY, 0));
    R.position.lerp(tmpV, a); R.quaternion.slerp(rT.q, a);
    /* левая рука с ПТ-1 */
    const lT = WR.raised && !st.busy ? P_L.raised : P_L.rest;
    const b = Math.min(1, dt * 9);
    tmpV.copy(lT.p).add(new THREE.Vector3(sx * 0.7 + bobX * 0.7, sy * 0.7 + bobY, 0));
    Lg.position.lerp(tmpV, b); Lg.quaternion.slerp(lT.q, b);
    /* подсветка экрана ПТ-1: сильнее, когда рука поднята; мигает при новой заявке */
    const glowK = WR.raised ? 1 : (WR.unread ? (Math.sin(performance.now() / 160) > 0 ? 0.5 : 0.1) : 0.15);
    wristGlowVm.intensity = 0.05 * glowK;
    wristGlow.intensity += ((WR.raised ? 0.9 : 0) - wristGlow.intensity) * Math.min(1, dt * 6);
    screen.material.color.setScalar(0.55 + 0.45 * glowK);
    /* линза фонарика */
    lens.material.color.setHex(st.flashOn ? 0xfff4d8 : 0x222222);
    /* свет для рук: копия двух главных источников мира */
    for (let i = 0; i < vmL.length; i++) {
      const s = st.lights[i];
      if (!s || s.intensity <= 0) { vmL[i].intensity = 0; continue; }
      vmL[i].position.copy(s.position); vmL[i].color.copy(s.color); vmL[i].intensity = s.intensity; vmL[i].distance = s.distance;
    }
    hemi.intensity = 0.06 + (st.flashOn ? 0.25 : 0) + (WR.raised ? 0.08 : 0);
    /* кончик фонарика в координатах камеры — туда ставим луч */
    R.updateMatrix();
    return tipLocal.clone().applyMatrix4(R.matrix);
  };
  return Bd;
}
