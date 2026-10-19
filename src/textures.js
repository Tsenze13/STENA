/* Процедурные текстуры: всё рисуется на canvas при загрузке, картинок в игре нет. */
import * as THREE from 'three';

let seed = 1337;
export const rnd = () => { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; };
const R = (a, b) => a + rnd() * (b - a);

export function tex(w, h, draw, opt = {}) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const g = c.getContext('2d');
  draw(g, w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = opt.data ? THREE.NoColorSpace : THREE.SRGBColorSpace;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = 8;
  if (opt.repeat) t.repeat.set(opt.repeat[0], opt.repeat[1]);
  t.userData.canvas = c;
  return t;
}

/* зерно, пятна, потёки */
function grime(g, w, h, k = 1) {
  for (let i = 0; i < w * h / 60 * k; i++) {
    const v = rnd() < 0.5 ? 0 : 255;
    g.fillStyle = `rgba(${v},${v},${v},${R(0.02, 0.08)})`;
    g.fillRect(rnd() * w, rnd() * h, R(1, 3), R(1, 3));
  }
  for (let i = 0; i < 10 * k; i++) {
    const x = rnd() * w, y = rnd() * h, r = R(20, 120);
    const gr = g.createRadialGradient(x, y, 0, x, y, r);
    gr.addColorStop(0, `rgba(30,25,15,${R(0.05, 0.16)})`);
    gr.addColorStop(1, 'rgba(30,25,15,0)');
    g.fillStyle = gr; g.fillRect(x - r, y - r, r * 2, r * 2);
  }
}
function drips(g, w, y0, h, n, a = 0.12) {
  for (let i = 0; i < n; i++) {
    const x = rnd() * w, len = R(30, h);
    const gr = g.createLinearGradient(0, y0, 0, y0 + len);
    gr.addColorStop(0, `rgba(40,30,15,${R(a * 0.5, a)})`);
    gr.addColorStop(1, 'rgba(40,30,15,0)');
    g.fillStyle = gr; g.fillRect(x, y0, R(2, 8), len);
  }
}

/* стена подъезда: снизу масляная краска, сверху побелка (текстура на 3 м высоты, 4 м ширины) */
export function stairWall() {
  return tex(512, 384, (g, w, h) => {
    const band = h * (1 - 1.5 / 3);
    g.fillStyle = '#c9c4b2'; g.fillRect(0, 0, w, band);
    g.fillStyle = '#3f5a4c'; g.fillRect(0, band, w, h - band);
    g.fillStyle = '#2f4639'; g.fillRect(0, band, w, 4);
    grime(g, w, h, 1.4);
    drips(g, w, 0, band * 0.8, 14, 0.1);
    /* облупленная краска */
    for (let i = 0; i < 18; i++) { g.fillStyle = `rgba(190,185,165,${R(0.4, 0.9)})`; g.fillRect(rnd() * w, band + R(10, h - band - 10), R(4, 18), R(3, 10)); }
  });
}
/* стена служебного коридора: бетон, крашеная полоса, трафаретная линия */
export function corridorWall() {
  return tex(512, 384, (g, w, h) => {
    g.fillStyle = '#7a7a72'; g.fillRect(0, 0, w, h);
    /* швы бетонных панелей */
    g.fillStyle = 'rgba(20,20,18,.35)'; g.fillRect(0, h * 0.42, w, 2); g.fillRect(w - 2, 0, 2, h);
    const band = h * (1 - 1.2 / 3);
    g.fillStyle = '#4a5560'; g.fillRect(0, band, w, h - band);
    g.fillStyle = '#c9a227'; g.fillRect(0, band - 10, w, 6);
    grime(g, w, h, 2);
    drips(g, w, 0, h * 0.6, 20, 0.16);
  });
}
export function floorTiles() {
  return tex(256, 256, (g, w, h) => {
    g.fillStyle = '#3a3330'; g.fillRect(0, 0, w, h);
    const n = 8, s = w / n;
    for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
      const c = rnd() < 0.5 ? [120, 72, 58] : [150, 140, 120];
      const k = R(0.8, 1.05);
      g.fillStyle = `rgb(${c[0] * k | 0},${c[1] * k | 0},${c[2] * k | 0})`;
      g.fillRect(x * s + 1, y * s + 1, s - 2, s - 2);
    }
    grime(g, w, h, 1.5);
  }, { repeat: [3, 2] });
}
export function concreteFloor() {
  return tex(512, 512, (g, w, h) => {
    g.fillStyle = '#56544e'; g.fillRect(0, 0, w, h);
    grime(g, w, h, 3);
    g.fillStyle = 'rgba(0,0,0,.35)'; g.fillRect(0, h - 2, w, 2);
    /* жёлтая разметка по краям */
    g.fillStyle = 'rgba(201,162,39,.75)'; g.fillRect(20, 0, 10, h); g.fillRect(w - 30, 0, 10, h);
  });
}
export function ceiling() {
  return tex(256, 256, (g, w, h) => { g.fillStyle = '#3b3b38'; g.fillRect(0, 0, w, h); grime(g, w, h, 2); });
}
export function metal(col = '#6d4a36') {
  return tex(256, 256, (g, w, h) => {
    g.fillStyle = col; g.fillRect(0, 0, w, h);
    grime(g, w, h, 1.5);
    for (let i = 0; i < 40; i++) { g.strokeStyle = `rgba(220,210,190,${R(0.05, 0.2)})`; g.beginPath(); const x = rnd() * w, y = rnd() * h; g.moveTo(x, y); g.lineTo(x + R(-30, 30), y + R(-6, 6)); g.stroke(); }
  });
}

/* надписи */
export function textTex(w, h, bg, lines, opt = {}) {
  return tex(w, h, (g) => {
    if (bg) { g.fillStyle = bg; g.fillRect(0, 0, w, h); }
    g.textAlign = 'center'; g.textBaseline = 'middle';
    const total = lines.reduce((a, l) => a + l.size * 1.2, 0);
    let y = h / 2 - total / 2;
    for (const l of lines) {
      let fs = l.size; g.font = `${l.weight || 700} ${fs}px ${l.font || 'Oswald, Arial Narrow, sans-serif'}`;
      while (g.measureText(l.text).width > w * 0.9 && fs > 8) { fs -= 2; g.font = `${l.weight || 700} ${fs}px ${l.font || 'Oswald, Arial Narrow, sans-serif'}`; }
      g.fillStyle = l.color || '#111';
      if (l.glow) { g.shadowColor = l.color; g.shadowBlur = l.glow; }
      y += l.size * 0.6; g.fillText(l.text, w / 2, y); y += l.size * 0.6;
      g.shadowBlur = 0;
    }
    if (opt.grime) grime(g, w, h, opt.grime);
    if (opt.frame) { g.strokeStyle = opt.frame; g.lineWidth = 6; g.strokeRect(5, 5, w - 10, h - 10); }
  });
}
export function signTex(lit) {
  return textTex(512, 128, lit ? '#2a0806' : '#140504', [{ text: 'ЭЛЕКТРОЩИТОВАЯ', size: 64, color: lit ? '#ff4a35' : '#5a1a14', glow: lit ? 24 : 0 }]);
}
export function warnTex() {
  return tex(256, 300, (g, w) => {
    g.fillStyle = '#f2c519'; g.fillRect(0, 0, w, 300);
    g.fillStyle = '#111';
    g.beginPath(); g.moveTo(w / 2, 20); g.lineTo(w - 26, 200); g.lineTo(26, 200); g.closePath(); g.lineWidth = 14; g.strokeStyle = '#111'; g.stroke();
    g.beginPath(); g.moveTo(140, 70); g.lineTo(104, 135); g.lineTo(132, 135); g.lineTo(112, 185); g.lineTo(160, 118); g.lineTo(132, 118); g.lineTo(150, 70); g.closePath(); g.fill();
    g.font = '700 26px Oswald, Arial Narrow, sans-serif'; g.textAlign = 'center';
    g.fillText('ОСТОРОЖНО!', w / 2, 240); g.font = '700 20px Oswald, Arial Narrow, sans-serif'; g.fillText('ЭЛЕКТРИЧЕСКОЕ НАПРЯЖЕНИЕ', w / 2, 272);
    grime(g, w, 300, 0.8);
  });
}
export function stencil(text, w = 512, h = 160, color = 'rgba(230,225,210,.75)', size = 110) {
  return tex(w, h, (g) => {
    g.font = `600 ${size}px Oswald, Arial Narrow, sans-serif`;
    g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillStyle = color;
    g.fillText(text, w / 2, h / 2);
    /* выщербленный трафарет */
    g.globalCompositeOperation = 'destination-out';
    for (let i = 0; i < 400; i++) { g.fillStyle = `rgba(0,0,0,${R(0.2, 0.8)})`; g.fillRect(rnd() * w, rnd() * h, R(1, 4), R(1, 4)); }
    g.globalCompositeOperation = 'source-over';
  });
}
export function panelTex() {
  return tex(256, 360, (g, w, h) => {
    g.fillStyle = '#7d8278'; g.fillRect(0, 0, w, h);
    g.fillStyle = '#2a2d27'; g.fillRect(14, 14, w - 28, 40);
    g.fillStyle = '#ffdb4a'; g.font = '700 26px PT Mono, monospace'; g.textAlign = 'center'; g.fillText('ЩР-6', w / 2, 44);
    g.strokeStyle = '#3c3f39'; g.lineWidth = 3; g.strokeRect(14, 70, w - 28, h - 90);
    g.fillStyle = '#3c3f39'; g.beginPath(); g.arc(w - 30, h / 2, 8, 0, 7); g.fill();
    grime(g, w, h, 1);
  });
}
export function paperTex() {
  return tex(128, 160, (g, w, h) => {
    g.fillStyle = '#ddd5bf'; g.fillRect(0, 0, w, h);
    g.strokeStyle = 'rgba(40,40,60,.55)'; g.lineWidth = 1.5;
    for (let y = 28; y < h - 10; y += 12) { g.beginPath(); g.moveTo(12, y); g.lineTo(12 + R(60, 104), y + R(-1, 1)); g.stroke(); }
    grime(g, w, h, 0.6);
  });
}
