/* Щиток ЩР-6: автоматы, амперметр, лампа контактора привода решётки. */
import { audio } from './audio.js';
import { LIMIT, LOAD } from './game.js';

const BRK = [
  { k: 'qf0', n: 'QF0', d: 'ВВОД', a: LIMIT, main: true },
  { k: 'qf1', n: 'QF1', d: 'А · ОСВЕЩЕНИЕ', a: LOAD.A },
  { k: 'qf2', n: 'QF2', d: 'Б · ПУЛЬТ', a: LOAD.B },
];
const MAXA = 30;

export function makePanel(G) {
  const $ = id => document.getElementById(id);
  const S = G.S;
  const Pn = { open: false };

  /* шкала амперметра 0..30 А, красная зона после 20 */
  const ang = a => -80 + 160 * Math.min(a, MAXA) / MAXA;
  const pt = (a, r) => { const t = (ang(a) - 90) * Math.PI / 180; return [100 + Math.cos(t) * r, 105 + Math.sin(t) * r]; };
  let ticks = '';
  for (let a = 0; a <= MAXA; a += 5) { const [x1, y1] = pt(a, 85), [x2, y2] = pt(a, 74), [tx, ty] = pt(a, 62); ticks += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#222" stroke-width="1.5"/><text x="${tx}" y="${ty + 3}" text-anchor="middle">${a}</text>`; }
  $('ammTicks').innerHTML = ticks;
  { const [x1, y1] = pt(LIMIT, 82), [x2, y2] = pt(MAXA, 82); $('ammRed').setAttribute('d', `M${x1} ${y1} A82 82 0 0 1 ${x2} ${y2}`); }

  function render() {
    $('brkRow').innerHTML = BRK.map(b => `<button type="button" class="brk${S[b.k] ? ' on' : ''}${b.main ? ' main' : ''}${b.main && !S.qf0 && S.trips ? ' trip' : ''}" data-k="${b.k}">
      <span class="tog"><i></i></span><b>${b.n}</b><small>${b.d}<br>${b.a} А</small></button>`).join('');
    const a = G.load();
    $('ammNeedle').style.transform = `rotate(${ang(a)}deg)`;
    $('ammVal').textContent = a + ' А из ' + LIMIT;
    $('kmLamp').classList.toggle('on', S.v);
  }
  Pn.render = render;
  $('brkRow').addEventListener('click', e => {
    const b = e.target.closest('.brk'); if (!b) return;
    const k = b.dataset.k;
    audio.click();
    G.set(k, !S[k]);
    render();
  });
  Pn.openUI = () => { Pn.open = true; $('panel').hidden = false; render(); audio.heavyClick(); };
  Pn.close = () => { Pn.open = false; $('panel').hidden = true; audio.click(); if (Pn.onClose) Pn.onClose(); };
  Pn.onKey = (e) => {
    if (!Pn.open) return false;
    if (e.code === 'Escape' || e.code === 'KeyE') { Pn.close(); return true; }
    if (e.code === 'Digit1' || e.code === 'Digit2' || e.code === 'Digit3') { const k = BRK[+e.code.slice(5) - 1].k; audio.click(); G.set(k, !S[k]); render(); return true; }
    return true;
  };
  return Pn;
}
