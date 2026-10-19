/* Игрок: взгляд мышью (pointer lock), ходьба, столкновения со стенами, шаги, фонарик. */
import * as THREE from 'three';
import { audio } from './audio.js';

export function makePlayer(cam, W, canvas) {
  const P = {
    pos: new THREE.Vector3(-1.4, 0, 2.7), yaw: 0.25, pitch: 0,
    vel: new THREE.Vector3(), r: 0.3, eye: 1.65, bob: 0, stepAcc: 0,
    keys: {}, locked: false, frozen: false, sens: 1, walked: 0,
  };
  /* фонарик */
  const fl = new THREE.SpotLight(0xfff1d6, 0, 22, 0.42, 0.55, 1.6);
  cam.add(fl); fl.position.set(0.15, -0.12, 0); fl.target.position.set(0.15, -0.16, -1); cam.add(fl.target);
  P.flash = { light: fl, on: false };
  P.toggleFlash = () => { P.flash.on = !P.flash.on; audio.click(); };

  addEventListener('keydown', e => { P.keys[e.code] = true; });
  addEventListener('keyup', e => { P.keys[e.code] = false; });
  addEventListener('blur', () => { P.keys = {}; });
  document.addEventListener('mousemove', e => {
    if (!P.locked || P.frozen) return;
    const k = 0.0022 * P.sens;
    P.yaw -= e.movementX * k;
    P.pitch = Math.max(-1.45, Math.min(1.45, P.pitch - e.movementY * k));
  });
  document.addEventListener('pointerlockchange', () => { P.locked = document.pointerLockElement === canvas; });
  P.lock = () => { try { const r = canvas.requestPointerLock(); if (r && r.catch) r.catch(() => {}); } catch (_) {} };
  P.unlock = () => { if (document.pointerLockElement) document.exitPointerLock(); };

  /* вытолкнуть круг игрока из прямоугольников */
  function collide() {
    for (const c of W.colliders) {
      if (c.on && !c.on()) continue;
      const qx = Math.max(c.x0, Math.min(P.pos.x, c.x1)), qz = Math.max(c.z0, Math.min(P.pos.z, c.z1));
      let dx = P.pos.x - qx, dz = P.pos.z - qz; const d2 = dx * dx + dz * dz;
      if (d2 >= P.r * P.r) continue;
      if (d2 < 1e-8) {
        /* центр внутри: выталкиваем по кратчайшей оси */
        const o = [[c.x0 - P.r - P.pos.x, 0], [c.x1 + P.r - P.pos.x, 0], [0, c.z0 - P.r - P.pos.z], [0, c.z1 + P.r - P.pos.z]];
        o.sort((a, b) => Math.hypot(...a) - Math.hypot(...b));
        P.pos.x += o[0][0]; P.pos.z += o[0][1]; continue;
      }
      const d = Math.sqrt(d2), push = P.r - d;
      P.pos.x += dx / d * push; P.pos.z += dz / d * push;
    }
  }

  P.update = (dt) => {
    let mx = 0, mz = 0;
    if (!P.frozen) {
      if (P.keys.KeyW || P.keys.ArrowUp) mz -= 1;
      if (P.keys.KeyS || P.keys.ArrowDown) mz += 1;
      if (P.keys.KeyA || P.keys.ArrowLeft) mx -= 1;
      if (P.keys.KeyD || P.keys.ArrowRight) mx += 1;
    }
    const run = P.keys.ShiftLeft || P.keys.ShiftRight;
    const sp = run ? 3.6 : 1.9;
    const len = Math.hypot(mx, mz) || 1;
    const s = Math.sin(P.yaw), c = Math.cos(P.yaw);
    const wx = (mx * c + mz * s) / len * sp, wz = (-mx * s + mz * c) / len * sp;
    const a = Math.min(1, dt * 10);
    P.vel.x += (wx - P.vel.x) * a; P.vel.z += (wz - P.vel.z) * a;
    const ox = P.pos.x, oz = P.pos.z;
    /* шагами по 5 см, чтобы не проскочить тонкие стены */
    const steps = Math.ceil(Math.hypot(P.vel.x, P.vel.z) * dt / 0.05) || 1;
    for (let i = 0; i < steps; i++) { P.pos.x += P.vel.x * dt / steps; P.pos.z += P.vel.z * dt / steps; collide(); }
    const moved = Math.hypot(P.pos.x - ox, P.pos.z - oz);
    P.walked += moved;
    const v = moved / Math.max(dt, 1e-4);
    if (v > 0.3) {
      P.bob += dt * (run ? 11 : 7.5);
      P.stepAcc += moved;
      if (P.stepAcc > (run ? 0.85 : 0.7)) { P.stepAcc = 0; audio.step(run ? 1.3 : 1); }
    } else P.bob += (Math.round(P.bob / Math.PI) * Math.PI - P.bob) * Math.min(1, dt * 6);
    const bobA = Math.min(v / 3.6, 1) * 0.035;
    cam.position.set(P.pos.x, P.eye + Math.abs(Math.sin(P.bob)) * bobA, P.pos.z);
    cam.rotation.set(P.pitch, P.yaw, Math.sin(P.bob) * bobA * 0.15, 'YXZ');
    fl.intensity += ((P.flash.on ? 26 : 0) - fl.intensity) * Math.min(1, dt * 20);
  };
  return P;
}
