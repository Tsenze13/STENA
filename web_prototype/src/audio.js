/* Звук: всё синтезируется WebAudio, файлов нет. */
let A = null;

export const audio = {
  get on() { return !!A; },
  start() {
    if (A) { if (A.ctx.state === 'suspended') A.ctx.resume(); return; }
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const master = ctx.createGain(); master.gain.value = 0.8; master.connect(ctx.destination);
    /* реверб коридора: сгенерированный отклик, длинный хвост */
    const rev = ctx.createConvolver();
    const len = ctx.sampleRate * 3.2, ir = ctx.createBuffer(2, len, ctx.sampleRate);
    for (let ch = 0; ch < 2; ch++) { const d = ir.getChannelData(ch); for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 3.2); }
    rev.buffer = ir;
    const revGain = ctx.createGain(); revGain.gain.value = 0.45; rev.connect(revGain); revGain.connect(master);
    const noise = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
    { const d = noise.getChannelData(0); for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1; }
    A = { ctx, master, rev, noise };
    startAmbience();
  },
  volume(v) { if (A) A.master.gain.value = v; },
  /* громкость гула ламп 0..1 и сила «дыхания» Стены */
  setHum(v) { if (A) A.hum.gain.setTargetAtTime(v * 0.05, A.ctx.currentTime, 0.4); },
  click: () => { thump(90, 0.18, 0.5); burst(2400, 0.03, 0.25); },
  heavyClick: () => { thump(55, 0.35, 0.9); burst(1600, 0.06, 0.5); },
  bang: () => { thump(40, 0.8, 1); burst(900, 0.5, 0.8, true); },
  step: (k = 1) => burst(R(500, 900), 0.07, 0.12 * k, true, 'lowpass'),
  key: () => burst(R(3000, 5000), 0.015, 0.08),
  beep: (f = 880, d = 0.12, v = 0.08) => tone(f, d, v, 'square'),
  pager: () => { tone(2000, 0.08, 0.06, 'square'); setTimeout(() => tone(2000, 0.08, 0.06, 'square'), 140); setTimeout(() => tone(2400, 0.14, 0.06, 'square'), 280); },
  relay: (dist = 0) => { const k = 1 / (1 + dist * 0.05); thump(120, 0.08, 0.35 * k); burst(3000, 0.02, 0.2 * k, true); },
  tubeBuzz: () => burst(120, 0.25, 0.2, false, 'bandpass'),
  door: () => { grind(1.4, 0.4, 200); thump(70, 0.4, 0.5); },
  grind: (d = 4) => { grind(d, 0.55, 90); },
  clang: (dist = 30) => metal(dist),
  hit: () => { thump(60, 0.3, 0.7); },
};
const R = (a, b) => a + Math.random() * (b - a);

function out(node, wet = 0.35) {
  node.connect(A.master);
  if (wet > 0) { const s = A.ctx.createGain(); s.gain.value = wet; node.connect(s); s.connect(A.rev); }
}
function tone(f, d, v, type = 'sine') {
  if (!A) return;
  const t = A.ctx.currentTime, o = A.ctx.createOscillator(), g = A.ctx.createGain();
  o.type = type; o.frequency.value = f;
  g.gain.setValueAtTime(v, t); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  o.connect(g); out(g, 0.15); o.start(t); o.stop(t + d + 0.05);
}
function thump(f, d, v) {
  if (!A) return;
  const t = A.ctx.currentTime, o = A.ctx.createOscillator(), g = A.ctx.createGain();
  o.frequency.setValueAtTime(f * 2, t); o.frequency.exponentialRampToValueAtTime(f * 0.6, t + d);
  g.gain.setValueAtTime(v, t); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  o.connect(g); out(g, 0.5); o.start(t); o.stop(t + d + 0.05);
}
function burst(f, d, v, wet = false, type = 'highpass') {
  if (!A) return;
  const t = A.ctx.currentTime, s = A.ctx.createBufferSource(), fl = A.ctx.createBiquadFilter(), g = A.ctx.createGain();
  s.buffer = A.noise; s.playbackRate.value = R(0.8, 1.2);
  fl.type = type; fl.frequency.value = f; fl.Q.value = type === 'bandpass' ? 8 : 0.7;
  g.gain.setValueAtTime(v, t); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  s.connect(fl); fl.connect(g); out(g, wet ? 0.6 : 0.15); s.start(t, Math.random()); s.stop(t + d + 0.05);
}
function grind(d, v, base) {
  if (!A) return;
  const t = A.ctx.currentTime, s = A.ctx.createBufferSource(), fl = A.ctx.createBiquadFilter(), g = A.ctx.createGain();
  s.buffer = A.noise; s.loop = true;
  fl.type = 'bandpass'; fl.Q.value = 5;
  fl.frequency.setValueAtTime(base, t);
  for (let i = 1; i < 12; i++) fl.frequency.setValueAtTime(base * R(0.7, 1.6), t + d * i / 12);
  g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(v, t + 0.2);
  g.gain.setValueAtTime(v, t + d - 0.3); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  const o = A.ctx.createOscillator(), og = A.ctx.createGain(); o.type = 'sawtooth'; o.frequency.value = base * 0.5; og.gain.value = v * 0.15;
  o.connect(og); og.connect(g);
  s.connect(fl); fl.connect(g); out(g, 0.6); s.start(t); s.stop(t + d); o.start(t); o.stop(t + d);
}
/* далёкий металлический удар: частичные тона, глушим высокие с расстоянием */
function metal(dist) {
  if (!A) return;
  const t = A.ctx.currentTime, k = Math.min(1, 12 / Math.max(dist, 1));
  const lp = A.ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 400 + 6000 * k;
  const g = A.ctx.createGain(); g.gain.value = 0.5 * Math.max(k, 0.12);
  lp.connect(g); g.connect(A.master); const s = A.ctx.createGain(); s.gain.value = 1.2; g.connect(s); s.connect(A.rev);
  for (const [f, a, dd] of [[180, 1, 2.5], [431, 0.6, 1.8], [797, 0.4, 1.2], [1263, 0.25, 0.8], [2310, 0.15, 0.5]]) {
    const o = A.ctx.createOscillator(), og = A.ctx.createGain();
    o.frequency.value = f * R(0.98, 1.02);
    og.gain.setValueAtTime(a * 0.3, t); og.gain.exponentialRampToValueAtTime(0.0001, t + dd);
    o.connect(og); og.connect(lp); o.start(t); o.stop(t + dd + 0.1);
  }
}
/* фон: низкий гул Стены и сетевой гул ламп */
function startAmbience() {
  const { ctx } = A;
  /* дыхание: шум через низкий фильтр с медленным колебанием */
  const s = ctx.createBufferSource(); s.buffer = A.noise; s.loop = true;
  const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 140;
  const g = ctx.createGain(); g.gain.value = 0.22;
  const lfo = ctx.createOscillator(), lg = ctx.createGain(); lfo.frequency.value = 0.07; lg.gain.value = 60;
  lfo.connect(lg); lg.connect(lp.frequency);
  s.connect(lp); lp.connect(g); g.connect(A.master); s.start(); lfo.start();
  const sub = ctx.createOscillator(), sg = ctx.createGain(); sub.frequency.value = 38; sg.gain.value = 0.05;
  sub.connect(sg); sg.connect(A.master); sub.start();
  /* сетевой гул 50 Гц и гармоники */
  const hum = ctx.createGain(); hum.gain.value = 0;
  const hl = ctx.createBiquadFilter(); hl.type = 'lowpass'; hl.frequency.value = 900;
  for (const [f, a] of [[100, 1], [200, 0.4], [300, 0.25]]) { const o = ctx.createOscillator(), og = ctx.createGain(); o.type = 'sawtooth'; o.frequency.value = f; og.gain.value = a * 0.3; o.connect(og); og.connect(hl); o.start(); }
  hl.connect(hum); hum.connect(A.master);
  A.hum = hum;
}
