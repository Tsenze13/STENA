/* ПТ-1 — переносной терминал на левой руке. Заменяет пейджер: заявки, задача, записи, связь со щитком.
   Экран — canvas, который рисуется на модели прибора (body.js). */
import { audio } from './audio.js';

const PAGES = ['ЗАЯВКИ', 'ЗАДАЧА', 'ЗАПИСИ'];

export function makeWrist() {
  const cv = document.createElement('canvas'); cv.width = 384; cv.height = 256;
  const WR = {
    canvas: cv, page: 0, raised: false, unread: false, orders: [], goal: '', notes: [], link: null, t: 0, dirty: true,
    onDraw: null,
  };
  WR.notify = (txt) => {
    WR.orders.unshift({ txt, t: new Date() });
    WR.unread = true; WR.page = 0; WR.dirty = true;
    audio.pager();
  };
  WR.setGoal = (txt) => { if (WR.goal !== txt) { WR.goal = txt; WR.dirty = true; } };
  WR.addNote = (name) => { if (!WR.notes.includes(name)) { WR.notes.push(name); WR.dirty = true; } };
  WR.setPage = (i) => { if (WR.page !== i) { WR.page = i; WR.dirty = true; audio.key(); } };
  WR.setLink = (l) => { const s = JSON.stringify(l); if (s !== WR._link) { WR._link = s; WR.link = l; WR.dirty = true; } };
  WR.raise = (on) => {
    if (WR.raised === on) return;
    WR.raised = on; audio.click();
    if (on && WR.unread) { WR.unread = false; WR.dirty = true; }
  };

  /* перенос строк по ширине */
  function wrap(g, text, w) {
    const out = [];
    for (const para of text.split('\n')) {
      let line = '';
      for (const word of para.split(' ')) {
        const t = line ? line + ' ' + word : word;
        if (g.measureText(t).width > w && line) { out.push(line); line = word; } else line = t;
      }
      out.push(line);
    }
    return out;
  }

  WR.draw = (dt) => {
    WR.t += dt;
    const blink = WR.unread && Math.floor(WR.t * 3) % 2 === 0;
    if (!WR.dirty && !WR.unread && Math.floor(WR.t) === WR._sec) return;
    WR._sec = Math.floor(WR.t); WR.dirty = false;
    const g = cv.getContext('2d'), W = cv.width, H = cv.height;
    const fg = '#8dffa6', dim = '#2f8a48';
    g.fillStyle = '#041208'; g.fillRect(0, 0, W, H);
    g.shadowColor = fg; g.shadowBlur = 5;
    /* шапка */
    g.fillStyle = blink ? fg : '#0a2a12'; g.fillRect(0, 0, W, 30);
    g.fillStyle = blink ? '#041208' : fg; g.font = '700 18px "PT Mono", monospace';
    g.fillText(blink ? '! НОВАЯ ЗАЯВКА' : 'ПТ-1 · УЧ.6', 10, 21);
    const c = new Date(), clock = String(c.getHours()).padStart(2, '0') + ':' + String(c.getMinutes()).padStart(2, '0');
    g.textAlign = 'right'; g.fillText(clock, W - 10, 21); g.textAlign = 'left';
    /* вкладки */
    g.font = '15px "PT Mono", monospace';
    PAGES.forEach((p, i) => {
      const x = 8 + i * 124;
      if (i === WR.page) { g.fillStyle = fg; g.fillRect(x, 36, 118, 22); g.fillStyle = '#041208'; } else { g.strokeStyle = dim; g.strokeRect(x + 0.5, 36.5, 117, 21); g.fillStyle = dim; }
      g.fillText((i + 1) + ' ' + p, x + 8, 52);
    });
    /* содержимое */
    g.fillStyle = fg; g.font = '17px "PT Mono", monospace';
    let lines = [];
    if (WR.page === 0) {
      if (!WR.orders.length) lines = ['Заявок нет.'];
      else for (const [i, o] of WR.orders.slice(0, 2).entries()) { lines.push(...wrap(g, o.txt, W - 20)); if (i === 0 && WR.orders.length > 1) lines.push('— — —'); }
    } else if (WR.page === 1) lines = wrap(g, WR.goal || 'Задач нет.', W - 20);
    else lines = WR.notes.length ? WR.notes.map((n, i) => (i + 1) + '. ' + n) : ['Записей нет.'];
    lines.slice(0, 7).forEach((l, i) => { g.fillStyle = (WR.page === 0 && l === '— — —') ? dim : fg; g.fillText(l, 10, 84 + i * 22); });
    /* связь */
    g.fillStyle = '#0a2a12'; g.fillRect(0, H - 28, W, 28);
    g.fillStyle = WR.link ? fg : dim; g.font = '15px "PT Mono", monospace';
    g.fillText(WR.link ? 'СВЯЗЬ: ' + WR.link.name + ' · ' + WR.link.info : 'СВЯЗЬ: НЕТ · подойди к щитку', 10, H - 9);
    g.shadowBlur = 0;
    g.fillStyle = 'rgba(0,0,0,.22)'; for (let y = 0; y < H; y += 3) g.fillRect(0, y, W, 1);
    if (WR.onDraw) WR.onDraw();
  };
  return WR;
}
