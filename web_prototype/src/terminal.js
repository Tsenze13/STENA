/* Терминал ЩИТ-80: язык команд, файлы, управление питанием и решёткой.
   Ввод берётся по физическим клавишам (e.code), поэтому раскладку переключать не нужно. */
import { audio } from './audio.js';
import { LIMIT, LOAD } from './game.js';

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

export function makeTerminal(G, W) {
  const $ = id => document.getElementById(id);
  const out = $('termOut'), inp = $('termIn');
  const T = { open: false, booted: false, line: '', hist: [], hi: -1, queue: [], typing: false, lines: [] };
  const S = G.S;

  /* вывод с эффектом печати: строки копятся в очереди */
  function say(text, cls = '') { for (const l of text.split('\n')) T.queue.push({ l, cls }); pump(); }
  function pump() {
    if (T.typing || !T.queue.length) return;
    T.typing = true;
    const { l, cls } = T.queue.shift();
    const div = document.createElement('div'); if (cls) div.className = cls;
    out.appendChild(div);
    let i = 0;
    const step = () => {
      const n = Math.max(1, Math.ceil(l.length / 18));
      div.textContent = l.slice(0, i += n);
      out.scrollTop = out.scrollHeight;
      if (i < l.length) setTimeout(step, 12);
      else { T.lines.push(l); if (T.lines.length > 200) T.lines.shift(); drawScreen(); T.typing = false; setTimeout(pump, 18); }
    };
    if (!l.length) { div.innerHTML = '&nbsp;'; T.lines.push(''); T.typing = false; setTimeout(pump, 18); return; }
    step();
  }
  T.flush = () => { /* для тестов: вывести всё сразу */
    while (T.queue.length) { const { l, cls } = T.queue.shift(); const d = document.createElement('div'); if (cls) d.className = cls; d.textContent = l || ' '; out.appendChild(d); T.lines.push(l); }
  };
  T.text = () => out.innerText;

  /* картинка на экране монитора в мире */
  function drawScreen() {
    const { canvas, tex } = W.screens.term, g = canvas.getContext('2d');
    g.fillStyle = G.termOn() ? '#03140a' : '#050505'; g.fillRect(0, 0, canvas.width, canvas.height);
    if (G.termOn()) {
      g.font = '13px "PT Mono", monospace'; g.fillStyle = '#7dff9a'; g.shadowColor = '#7dff9a'; g.shadowBlur = 4;
      const ls = T.lines.slice(-14);
      ls.forEach((l, i) => g.fillText(l.slice(0, 40), 14, 22 + i * 15));
      g.fillText('>' + T.line + '_', 14, 22 + ls.length * 15);
      g.shadowBlur = 0;
      g.fillStyle = 'rgba(0,0,0,.25)'; for (let y = 0; y < canvas.height; y += 3) g.fillRect(0, y, canvas.width, 1);
    }
    tex.needsUpdate = true;
  }
  T.drawScreen = drawScreen;

  function boot() {
    out.innerHTML = ''; T.lines = [];
    say('ЩИТ-80  ВЕРСИЯ 4.1   (С) ЗАВОД «ЭКВАТОР» 1986', 't-dim');
    say('ПРОВЕРКА ПАМЯТИ ......... 64К  НОРМА', 't-dim');
    say('ПУЛЬТ ДЕЖУРНОГО · УЧАСТОК 6');
    say('ПОСЛЕДНИЙ ВХОД: 20.03.1991  03:12  (КАЛИНИН В.)');
    say('');
    say('НОВЫЕ ЗАЯВКИ: 1.   ВВЕДИТЕ HELP ДЛЯ СПИСКА КОМАНД.', 't-warn');
    T.booted = true;
  }

  const FILES = {
    'LOG.TXT': () => `ЖУРНАЛ СМЕНЫ · УЧАСТОК 6
14.03.91  Опять гул за решёткой, со стороны 7-го. Свет на 7-м не давал.
17.03.91  Машины на линии 7. Ходят по ночам, когда дают ток.
          Шум от них — как от лифта, только ближе.
19.03.91  Пропал Сомов. Ушёл чинить свет на 7-м. Рация молчит.
20.03.91  Решётку закрыл. Код сбросил на год ввода участка.
          Если ты это читаешь — не давай свет на 7-й.
          Они идут на ток.                         В.К.`,
    'MANUAL.TXT': () => `ИНСТРУКЦИЯ ДЕЖУРНОГО ЭЛЕКТРИКА
1. Ввод щита ЩР-6 рассчитан на ${LIMIT} А. При перегрузке
   вводной автомат QF0 отключается. Включать вручную на щите.
2. Нагрузки: А — освещение ${LOAD.A} А, Б — пульт ${LOAD.B} А,
   V — привод решётки ГД-6 ${LOAD.V} А.
3. Линия V управляется только с пульта:  POWER V ON
   Линии А и Б можно отключать и с пульта:  POWER A OFF
4. Решётка открывается при поданном питании привода:
   OPEN GD6 <КОД>
5. Состояние участка:  STATUS`,
    'MAIL.TXT': () => {
      const d = new Date(), ds = String(d.getDate()).padStart(2, '0') + '.' + String(d.getMonth() + 1).padStart(2, '0') + '.' + d.getFullYear();
      return `ВХОДЯЩИЕ ЗАЯВКИ
4471  20.03.1991  УЧ.7  МАШИНЫ НА ЛИНИИ        НЕ ВЫПОЛНЕНА
0001  ${ds}  УЧ.6  НЕИСПРАВНОСТЬ ЭЛЕКТРОЩИТОВОЙ
                         ИСПОЛНИТЕЛЬ: НАЗНАЧЕН
                         СТАТУС: ИСПОЛНИТЕЛЬ НА МЕСТЕ
ОТПРАВИТЕЛЬ: —`;
    },
  };

  function status() {
    const st = (on) => on ? 'ВКЛ ' : 'ОТКЛ';
    return `УЧАСТОК 6 · ЩИТ ЩР-6 · ВВОД ${LIMIT} А · ${S.qf0 ? 'НОРМА' : 'ОТКЛ'}
  A  ОСВЕЩЕНИЕ    ${String(LOAD.A).padStart(2)} А   ${st(S.qf1)}
  Б  ПУЛЬТ        ${String(LOAD.B).padStart(2)} А   ${st(S.qf2)}
  V  ПРИВОД ГД-6  ${String(LOAD.V).padStart(2)} А   ${st(S.v)}
НАГРУЗКА: ${G.load()} / ${LIMIT} А
РЕШЁТКА ГД-6: ${S.gate === 'closed' ? 'ЗАКРЫТА' : 'ОТКРЫТА'}`;
  }

  const LINE = { A: 'qf1', B: 'qf2', V: 'v' };
  function exec(raw) {
    const cmd = raw.trim().toUpperCase().replace(/\s+/g, ' ');
    say('>' + cmd, 't-dim');
    if (!cmd) return;
    const [c, a1, a2] = cmd.split(' ');
    switch (c) {
      case 'HELP': case '?':
        say(`КОМАНДЫ:
  DIR              список файлов
  READ <ФАЙЛ>      прочитать файл
  STATUS           состояние участка
  POWER <A|B|V> <ON|OFF>   питание линии
  OPEN <ОБЪЕКТ> <КОД>      открыть
  CLS              очистить экран
  EXIT             выйти`); break;
      case 'DIR': case 'LS':
        say(`LOG.TXT       ЖУРНАЛ СМЕНЫ
MANUAL.TXT    ИНСТРУКЦИЯ ДЕЖУРНОГО
MAIL.TXT      ВХОДЯЩИЕ ЗАЯВКИ`); break;
      case 'READ': case 'TYPE': case 'CAT': {
        if (!a1) { say('?УКАЖИТЕ ФАЙЛ: READ LOG.TXT', 't-err'); break; }
        const f = a1.includes('.') ? a1 : a1 + '.TXT';
        if (FILES[f]) { say(FILES[f]()); if (G.wrist) G.wrist.addNote({ 'LOG.TXT': 'Журнал смены, уч. 6', 'MANUAL.TXT': 'Инструкция дежурного', 'MAIL.TXT': 'Входящие заявки пульта' }[f]); } else say('?ФАЙЛ НЕ НАЙДЕН: ' + f, 't-err');
        break;
      }
      case 'STATUS': say(status()); break;
      case 'POWER': {
        const k = LINE[a1];
        if (!k || (a2 !== 'ON' && a2 !== 'OFF')) { say('?ФОРМАТ: POWER <A|B|V> <ON|OFF>', 't-err'); break; }
        const on = a2 === 'ON';
        if (S[k] === on) { say('ЛИНИЯ ' + a1 + ' УЖЕ ' + (on ? 'ВКЛЮЧЕНА' : 'ОТКЛЮЧЕНА')); break; }
        const r = G.set(k, on);
        if (r === 'trip') return; /* питание пропало, терминал погас */
        audio.relay();
        say('ЛИНИЯ ' + a1 + (on ? ' ВКЛЮЧЕНА' : ' ОТКЛЮЧЕНА') + '.  НАГРУЗКА ' + G.load() + ' / ' + LIMIT + ' А');
        if (k === 'qf2' && !on) return;
        if (k === 'qf1' && !on) say('ОСВЕЩЕНИЕ УЧАСТКА ОТКЛЮЧЕНО.', 't-warn');
        break;
      }
      case 'OPEN': {
        const obj = (a1 || '').replace('-', '');
        if (obj !== 'GD6') { say(a1 ? '?НЕИЗВЕСТНЫЙ ОБЪЕКТ: ' + a1 + '. ДОСТУПНО: GD6' : '?ФОРМАТ: OPEN GD6 <КОД>', 't-err'); break; }
        if (S.gate !== 'closed') { say('РЕШЁТКА ГД-6 УЖЕ ОТКРЫТА'); break; }
        if (!a2) { say('?НУЖЕН КОД: OPEN GD6 <КОД>', 't-err'); break; }
        if (!S.v) { say('НЕТ ПИТАНИЯ ПРИВОДА (ЛИНИЯ V). СМ. MANUAL.TXT', 't-err'); break; }
        if (a2 !== '1987') { audio.beep(220, 0.3); say('НЕВЕРНЫЙ КОД. ПОПЫТКА ЗАРЕГИСТРИРОВАНА.', 't-err'); break; }
        say('КОД ПРИНЯТ. ПРИВОД ГД-6 ПУЩЕН.', 't-warn');
        say('УЧАСТОК 7: СОБСТВЕННЫЙ ВВОД. ОСВЕЩЕНИЕ ВКЛЮЧАЕТСЯ АВТОМАТИЧЕСКИ.', 't-warn');
        G.openGate();
        break;
      }
      case 'CLS': out.innerHTML = ''; T.lines = []; drawScreen(); break;
      case 'EXIT': case 'QUIT': T.close(); break;
      case 'WHO': case 'WHOAMI': say('ДЕЖУРНЫЙ: НЕ ОПРЕДЕЛЁН\nЗАЯВКА 0001 НАЗНАЧЕНА ВАМ.'); break;
      default: audio.beep(330, 0.12); say('?СИНТАКСИЧЕСКАЯ ОШИБКА. HELP — СПИСОК КОМАНД', 't-err');
    }
  }
  T.exec = exec;

  function render() { inp.textContent = T.line; drawScreen(); }

  T.onKey = (e) => {
    if (!T.open) return false;
    if (e.code === 'Escape') { T.close(); return true; }
    if (!G.termOn()) return true;
    if (e.code === 'Enter' || e.code === 'NumpadEnter') { const l = T.line; T.line = ''; if (l.trim()) { T.hist.push(l); T.hi = T.hist.length; } render(); audio.key(); exec(l); return true; }
    if (e.code === 'Backspace') { T.line = T.line.slice(0, -1); render(); audio.key(); return true; }
    if (e.code === 'ArrowUp') { if (T.hi > 0) { T.hi--; T.line = T.hist[T.hi]; render(); } return true; }
    if (e.code === 'ArrowDown') { if (T.hi < T.hist.length - 1) { T.hi++; T.line = T.hist[T.hi]; } else { T.hi = T.hist.length; T.line = ''; } render(); return true; }
    let ch = '';
    const m = e.code.match(/^Key([A-Z])$/); if (m) ch = m[1];
    const d = e.code.match(/^(?:Digit|Numpad)(\d)$/); if (d) ch = d[1];
    if (e.code === 'Space') ch = ' ';
    if (e.code === 'Minus' || e.code === 'NumpadSubtract') ch = '-';
    if (e.code === 'Period' || e.code === 'NumpadDecimal') ch = '.';
    if (e.code === 'Slash' && e.shiftKey) ch = '?';
    if (ch && T.line.length < 48) { T.line += ch; render(); audio.key(); }
    return true;
  };

  T.openUI = () => {
    T.open = true; $('term').hidden = false;
    if (!T.booted) boot();
    render();
  };
  T.close = () => { T.open = false; $('term').hidden = true; if (T.onClose) T.onClose(); };

  /* питание пропало/появилось */
  G.onPowerTerm = (prev) => {
    const was = prev.qf0 && prev.qf2, now = G.termOn();
    W.termLight.intensity = now ? 0.8 : 0;
    if (was && !now) {
      T.booted = false; T.queue = []; T.typing = false;
      if (T.open) { const d = document.createElement('div'); d.className = 't-err'; d.textContent = '*** ПИТАНИЕ ПРОПАЛО ***'; out.appendChild(d); setTimeout(() => { if (T.open && !G.termOn()) T.close(); }, 900); }
      T.lines = [];
    }
    if (!was && now) { audio.beep(1200, 0.08, 0.05); T.lines = ['ЩИТ-80', 'ГОТОВ.']; }
    drawScreen();
  };
  drawScreen();
  return T;
}
