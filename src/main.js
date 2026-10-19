/* Точка входа: рендер, цикл, взаимодействие, экраны. */
import * as THREE from 'three';
import { buildWorld } from './world.js';
import { makeLights } from './lights.js';
import { makePlayer } from './player.js';
import { makeGame } from './game.js';
import { makeTerminal } from './terminal.js';
import { makePanel } from './panel.js';
import { audio } from './audio.js';

export const VERSION = '0.1';
const $ = id => document.getElementById(id);
$('ver').textContent = 'Версия ' + VERSION;

const canvas = $('view');
let renderer;
try {
  renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
} catch (e) { $('start').hidden = true; $('noGl').hidden = false; throw e; }
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.15;
renderer.outputColorSpace = THREE.SRGBColorSpace;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000);
scene.fog = new THREE.FogExp2(0x000000, 0.05);
const cam = new THREE.PerspectiveCamera(72, 1, 0.05, 2500);
scene.add(cam);

const W = buildWorld(scene);
const L = makeLights(scene, W);
const P = makePlayer(cam, W, canvas);
P.yaw = -0.45;
const G = makeGame(W, L, P);
const T = makeTerminal(G, W);
const Pn = makePanel(G);
G.onPower = (prev) => { G.onPowerTerm(prev); if (Pn.open) Pn.render(); };
/* лампы: начальный цвет экземпляров, чтобы не было белой вспышки на первом кадре */
for (const l of W.lamps) if (l.inst !== undefined) (l.kind === 'tube' ? W.tubes : W.ems).setColorAt(l.inst, new THREE.Color(0, 0, 0));

function resize() {
  const w = innerWidth, h = innerHeight;
  renderer.setSize(w, h, false); cam.aspect = w / h; cam.updateProjectionMatrix();
  W.glow.mat.uniforms.scale.value = h * renderer.getPixelRatio() / (2 * Math.tan(cam.fov * Math.PI / 360));
}
addEventListener('resize', resize); resize();

/* ---------- состояние экранов ---------- */
const UI = { started: false, paused: false, overlay: null };
const NOTE = `Смена 3 · 20.03.91

Решётку опять закрыли.
Код сбросили на год ввода участка —
он на табличке у решётки.

На 7-й свет не давать.
Они идут на ток.

Ухожу наверх.
                                    В. Калинин`;

function openOverlay(kind) {
  UI.overlay = kind; P.frozen = true; P.unlock();
  $('prompt').hidden = true;
  if (kind === 'term') T.openUI();
  else if (kind === 'panel') Pn.openUI();
  else if (kind === 'note') { $('noteText').textContent = NOTE; $('note').hidden = false; audio.step(0.6); }
}
function closeOverlay() {
  UI.overlay = null; P.frozen = false;
  if (!G.S.ended) P.lock();
}
T.onClose = closeOverlay; Pn.onClose = closeOverlay;

/* ---------- взаимодействие ---------- */
const ray = new THREE.Raycaster(); ray.far = 2.3;
const center = new THREE.Vector2(0, 0);
let target = null;
function promptFor(a) {
  switch (a) {
    case 'door': return W.door.target ? null : 'E — открыть дверь';
    case 'panel': return 'E — открыть щиток ЩР-6';
    case 'terminal': return G.termOn() ? 'E — сесть за терминал' : 'Терминал без питания';
    case 'note': return 'E — прочитать записку';
    case 'plaque': return 'Участок 6 · введён в эксплуатацию в 1987';
    case 'sign': return 'Электрощитовая';
    case 'gate': return G.S.gate === 'closed' ? 'Решётка ГД-6 заперта. Привод — с пульта' : null;
  }
  return null;
}
function interact() {
  if (!target) return;
  switch (target) {
    case 'door': if (!W.door.target) { W.door.target = 1; audio.door(); } break;
    case 'panel': openOverlay('panel'); break;
    case 'terminal': if (G.termOn()) openOverlay('term'); else { audio.click(); G.toast('Терминал без питания. Нужна линия Б на щитке'); } break;
    case 'note': openOverlay('note'); break;
  }
}
function pickTarget() {
  cam.updateMatrixWorld();
  ray.setFromCamera(center, cam);
  const hit = ray.intersectObjects(W.acts, false)[0];
  target = hit ? hit.object.userData.act : null;
  const txt = target && !UI.overlay ? promptFor(target) : null;
  const pe = $('prompt');
  if (txt) { if (pe.textContent !== txt) pe.textContent = txt; pe.hidden = false; } else pe.hidden = true;
  $('cross').style.background = txt ? 'rgba(255,179,71,.95)' : 'rgba(255,255,255,.55)';
}

/* ---------- клавиши ---------- */
addEventListener('keydown', e => {
  if (!UI.started || G.S.ended) return;
  if (UI.overlay === 'term') { if (T.onKey(e)) e.preventDefault(); return; }
  if (UI.overlay === 'panel') { if (Pn.onKey(e)) e.preventDefault(); return; }
  if (UI.overlay === 'note') { if (e.code === 'KeyE' || e.code === 'Escape') { $('note').hidden = true; closeOverlay(); } return; }
  if (UI.paused) { if (e.code === 'Escape') resume(); return; }
  if (e.code === 'KeyE') interact();
  else if (e.code === 'KeyF') P.toggleFlash();
  else if (e.code === 'Escape') pause();
});
document.addEventListener('pointerlockchange', () => {
  /* курсор отпустили сами (Esc браузера) во время игры — пауза */
  if (!document.pointerLockElement && UI.started && !UI.overlay && !UI.paused && !G.S.ended) pause();
});
canvas.addEventListener('click', () => { if (UI.started && !UI.overlay && !UI.paused && !G.S.ended) P.lock(); });

function pause() { UI.paused = true; $('pause').hidden = false; P.unlock(); }
function resume() { UI.paused = false; $('pause').hidden = true; P.lock(); }
$('resumeBtn').addEventListener('click', resume);
$('vol').addEventListener('input', e => audio.volume(+e.target.value));
$('sens').addEventListener('input', e => { P.sens = +e.target.value; });
$('againBtn').addEventListener('click', () => location.reload());
$('startBtn').addEventListener('click', () => {
  audio.start(); audio.volume(+$('vol').value);
  $('start').hidden = true; $('hud').hidden = false;
  UI.started = true; G.start(); P.lock();
});

/* ---------- цикл ---------- */
let relayT = 0;
function relay(l) {
  const d = Math.abs(l.z - P.pos.z);
  if (d > 80 || relayT > 0) return;
  relayT = 0.05; audio.relay(d);
}
function tick(dt) {
  relayT -= dt;
  if (!UI.paused) {
    P.update(UI.overlay ? 0 : dt);
    G.update(dt);
    L.update(dt, cam, relay);
    L.hemi.intensity = G.lightsA() ? 0.06 : 0.015;
  }
  pickTarget();
}
let last = performance.now();
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000); last = now;
  if (window.__st && window.__st.paused) { requestAnimationFrame(frame); return; } /* тесты крутят игру сами */
  if (UI.started) tick(dt);
  else { P.update(0); L.update(dt, cam); }
  renderer.render(scene, cam);
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

/* ---------- отладка и тесты ---------- */
window.__st = {
  G, S: G.S, W, P, T, Pn, L, UI, cam, renderer, VERSION,
  start: () => $('startBtn').click(),
  /* прокрутить игру на sec секунд без рендера */
  step(sec, d = 1 / 60) { for (let t = 0; t < sec; t += d) tick(d); },
  tp(x, z, yaw = P.yaw, pitch = 0) { P.pos.set(x, 0, z); P.yaw = yaw; P.pitch = pitch; P.update(0); },
  look() { pickTarget(); return target; },
  interact, openOverlay, closeOverlay, render: () => renderer.render(scene, cam),
};
