/* Свет: у каждой лампы есть уровень 0..1. Настоящих источников света немного (POOL),
   каждый кадр они встают на самые заметные лампы рядом с игроком. Остальное делают свечение и эмиссия. */
import * as THREE from 'three';

const POOL = 7;
const KIND = {
  wall: { col: new THREE.Color(0.86, 0.92, 1.0), glow: new THREE.Color(0.5, 0.56, 0.66), I: 9, dist: 15 },
  dome: { col: new THREE.Color(1.0, 0.86, 0.64), glow: new THREE.Color(0.75, 0.6, 0.4), I: 42, dist: 28 },
  em:   { col: new THREE.Color(1.0, 0.16, 0.08), glow: new THREE.Color(0.9, 0.12, 0.05), I: 2.2, dist: 10 },
  bulb: { col: new THREE.Color(1.0, 0.78, 0.5), glow: new THREE.Color(0.9, 0.6, 0.3), I: 3.2, dist: 9 },
};

export function makeLights(scene, W) {
  const pool = [];
  for (let i = 0; i < POOL; i++) { const p = new THREE.PointLight(0xffffff, 0, 10, 2); scene.add(p); pool.push(p); }
  const hemi = new THREE.HemisphereLight(0x9aa3b0, 0x1a1712, 0.02); scene.add(hemi);
  const c = new THREE.Color(), off = new THREE.Color(0.03, 0.03, 0.03);
  let t = 0;

  return {
    hemi, pool,
    /* включить/выключить группу ламп; stagger — задержка между соседними (каскад) */
    setGroup(grp, on, stagger = 0, fromZ = 0) {
      let k = 0;
      const list = W.lamps.filter(l => l.grp === grp).sort((a, b) => Math.abs(a.z - fromZ) - Math.abs(b.z - fromZ));
      for (const l of list) {
        if (l.on === (on ? 1 : 0)) continue;
        l.on = on ? 1 : 0;
        l.delay = stagger * Math.pow(k++, 0.75);  /* дальше — быстрее: свет убегает к горизонту */
        l.fl = on && (l.kind === 'wall' || l.kind === 'dome') ? 0.3 + Math.random() * 0.9 : 0;  /* время «мигания» при пуске */
        l.clicked = false;
      }
    },
    update(dt, cam, onRelay) {
      t += dt;
      const colA = W.glow.geo.attributes.color;
      for (const l of W.lamps) {
        if (l.delay > 0) { l.delay -= dt; continue; }
        if (!l.clicked) { l.clicked = true; if (l.on && onRelay) onRelay(l); }
        let target = l.on;
        if (l.on && l.fl > 0) { l.fl -= dt; target = Math.random() < 0.45 ? 1 : 0.05; }
        if (l.kind === 'bulb' && l.on) target = 0.85 + Math.sin(t * 13) * 0.04 + (Math.random() < 0.01 ? -0.5 : 0);
        if (l.kind === 'em' && l.on) target = 0.75 + Math.sin(t * 1.3 + l.z) * 0.08;
        if (l.dead) target = 0;
        const sp = l.kind === 'wall' || l.kind === 'dome' ? 30 : 8;
        l.lvl += (target - l.lvl) * Math.min(1, dt * sp);
        const K = KIND[l.kind];
        if (l.inst !== undefined) {
          c.copy(K.col).multiplyScalar(l.lvl).lerp(off, l.lvl < 0.05 ? 1 : 0);
          W.lampMeshes[l.kind].setColorAt(l.inst, c);
        }
        c.copy(K.glow).multiplyScalar(l.lvl);
        colA.setXYZ(l.gi, c.r, c.g, c.b);
      }
      for (const k in W.lampMeshes) W.lampMeshes[k].instanceColor.needsUpdate = true;
      colA.needsUpdate = true;
      W.bulb.material.color.setRGB(1 * W.lamps.at(-1).lvl + 0.05, 0.85 * W.lamps.at(-1).lvl + 0.04, 0.6 * W.lamps.at(-1).lvl + 0.03);

      /* выбор источников: заметность = сила / квадрат расстояния */
      const px = cam.position.x, pz = cam.position.z;
      const best = [];
      for (const l of W.lamps) {
        if (l.lvl < 0.02) continue;
        const d2 = (l.x - px) ** 2 + (l.z - pz) ** 2;
        if (d2 > 1600) continue;
        const s = KIND[l.kind].I * l.lvl / (d2 + 4);
        if (best.length < POOL || s > best[best.length - 1].s) {
          best.push({ l, s }); best.sort((a, b) => b.s - a.s); if (best.length > POOL) best.pop();
        }
      }
      /* сколько света вокруг камеры — от этого зависит, видна ли пыль */
      this.near = 0;
      for (const b of best) this.near += KIND[b.l.kind].I * b.l.lvl / ((b.l.x - px) ** 2 + (b.l.y - cam.position.y) ** 2 + (b.l.z - pz) ** 2 + 1);
      pool.forEach((p, i) => {
        const b = best[i];
        if (!b) { p.intensity = 0; return; }
        const K = KIND[b.l.kind];
        p.position.set(b.l.x, b.l.y, b.l.z); p.color.copy(K.col); p.distance = K.dist;
        p.intensity = K.I * b.l.lvl;
      });
    },
  };
}
