/* Состояние сцены и сюжетные события: питание участка, решётка, заявки на пейджер, финал прототипа. */
import { audio } from './audio.js';
import { GATE_Z } from './world.js';

export const LIMIT = 20;
export const LOAD = { A: 10, B: 4, V: 14 };

export function makeGame(W, L, P) {
  const $ = id => document.getElementById(id);
  const S = {
    qf0: false,  /* вводной автомат (выбит) */
    qf1: true,   /* А — освещение */
    qf2: false,  /* Б — терминал */
    v: false,    /* V — привод решётки, только с пульта */
    trips: 0, entered: false, gate: 'closed', t: 0, ev: [], ended: false, darkStarted: false, goal: '',
  };
  const G = { S };

  /* ---------- HUD ---------- */
  let toastT = 0;
  G.toast = (txt, sec = 3.5) => { const e = $('toast'); e.textContent = txt; e.hidden = false; toastT = sec; };
  G.goal = (txt) => { S.goal = txt; if (G.wrist) G.wrist.setGoal(txt); };
  /* заявки приходят на ПТ-1 (наручный терминал) */
  G.pager = (txt) => {
    S.pagerText = txt;
    if (G.wrist) G.wrist.notify(txt);
    if (!S.raisedOnce) G.toast('Новая заявка на ПТ-1 — нажми Tab', 4);
  };
  /* отложенное событие */
  G.later = (sec, fn) => S.ev.push({ t: S.t + sec, fn });

  /* ---------- питание ---------- */
  G.load = () => S.qf0 ? (S.qf1 ? LOAD.A : 0) + (S.qf2 ? LOAD.B : 0) + (S.v ? LOAD.V : 0) : 0;
  G.termOn = () => S.qf0 && S.qf2;
  G.lightsA = () => S.qf0 && S.qf1;
  G.onPower = null; /* терминал и щиток подписываются */
  function apply(prev) {
    L.setGroup('A', G.lightsA(), 0.12, 0);
    audio.setHum(G.lightsA() ? 1 : 0);
    if (G.onPower) G.onPower(prev);
    progress();
  }
  /* любое переключение: проверяем перегрузку */
  G.set = (k, val) => {
    const prev = { ...S };
    S[k] = val;
    if (k === 'qf0' && !val) S.v = false;          /* без ввода контактор отпадает */
    if (S.qf0 && G.load() > LIMIT) {
      const over = G.load();
      S.qf0 = false; S.v = false; S.trips++;
      audio.bang();
      G.toast('Выбило вводной автомат: нагрузка ' + over + ' А при пределе ' + LIMIT + ' А');
      G.goal('Снова включи ввод на щитке ЩР-6. Нагрузка — не больше 20 А');
      apply(prev);
      return 'trip';
    }
    apply(prev);
    return 'ok';
  };

  /* ---------- задачи по ходу ---------- */
  function progress() {
    if (S.gate !== 'closed' || !S.entered) return;
    if (!S.qf0) G.goal('Включи питание участка на щитке ЩР-6 в нише справа');
    else if (!S.qf2) G.goal('Подай питание на терминал — линия Б на щитке');
    else G.goal('Открой решётку ГД-6 с терминала');
  }

  G.enterCorridor = () => {
    if (S.entered) return;
    S.entered = true;
    G.pager('ЗАЯВКА 0001\nУЧ.6 · Восстановить питание.\nОткрыть ГД-6. Срочно.');
    if (!P.flash.on) G.later(1.2, () => { if (!P.flash.on && !S.qf0) G.toast('Темно. F — фонарик', 4); });
    progress();
  };

  /* ---------- решётка ---------- */
  G.openGate = () => {
    if (S.gate !== 'closed') return;
    S.gate = 'opening'; W.gate.moving = true;
    audio.grind(5.2); G.goal('');
    G.later(5.6, () => {
      S.gate = 'open'; W.gate.moving = false; audio.heavyClick();
      G.later(1.4, () => L.setGroup('S7', true, 0.07, GATE_Z));
      G.later(5.5, () => { G.pager('ЗАЯВКА 0002\nУЧ.7 · Неисправность.\nМашины на линии. Срочно.'); G.goal('Иди дальше по коридору'); });
      G.later(14, () => audio.clang(300));
    });
  };

  /* ---------- финал прототипа: свет гаснет издалека, что-то идёт ---------- */
  function startDark() {
    if (S.darkStarted) return;
    S.darkStarted = true;
    const far = W.lamps.filter(l => l.grp === 'S7' && l.z < -95 && l.z > -700).sort((a, b) => a.z - b.z);
    far.forEach((l, i) => G.later(i * 0.055, () => { l.dead = true; }));
    const dur = far.length * 0.055;
    G.later(0.5, () => audio.clang(220));
    G.later(dur * 0.5, () => audio.clang(120));
    G.later(dur + 1.5, () => { audio.clang(60); G.toast('Что-то идёт по коридору', 3); });
    G.later(dur + 5, () => audio.clang(30));
    G.later(dur + 8, () => audio.clang(12));
    G.later(dur + 10, () => {
      audio.bang();
      for (const l of W.lamps) l.dead = true;
      P.flash.on = false; P.frozen = true;
      G.pager('ЗАЯВКА 0003\nУЧ.7 · Исполнитель на месте.\nЗаявка принята.');
    });
    G.later(dur + 14, () => G.end());
  }
  G.end = () => {
    if (S.ended) return;
    S.ended = true;
    $('fade').classList.add('on');
    setTimeout(() => {
      P.unlock();
      const s = Math.round(S.t), mm = String(Math.floor(s / 60)).padStart(2, '0'), ss = String(s % 60).padStart(2, '0');
      $('endTxt').textContent = 'Глава 0 · Электрощитовая\nВремя: ' + mm + ':' + ss + (S.trips ? ' · выбило ввод: ' + S.trips : '') +
        '\n\nДальше — магистраль, машины и первые ответы.';
      $('end').hidden = false; $('hud').hidden = true;
    }, 2600);
  };

  G.update = (dt) => {
    S.t += dt;
    for (let i = S.ev.length - 1; i >= 0; i--) if (S.t >= S.ev[i].t) { const e = S.ev.splice(i, 1)[0]; e.fn(); }
    if (toastT > 0) { toastT -= dt; if (toastT <= 0) $('toast').hidden = true; }
    if (!S.entered && P.pos.z < -0.6) G.enterCorridor();
    if (S.gate === 'open' && P.pos.z < -45) startDark();
    /* решётка */
    if (W.gate.moving) W.gate.open = Math.min(1, W.gate.open + dt / 5.4);
    W.gate.g.position.y = W.gate.open * W.gate.lift + (W.gate.moving ? Math.sin(S.t * 40) * 0.004 : 0);
    /* маячок крутится, пока решётка едет */
    const bOn = W.gate.moving;
    W.beacon.g.rotation.y += bOn ? dt * 7 : 0;
    W.beacon.lamp.material.color.setHex(bOn ? 0xffa020 : 0x3a2205);
    W.beacon.light.intensity = bOn ? 30 : 0;
    /* щиток: автоматы и стрелка на модели */
    W.panel.update(S, G.load(), dt);
    W.termLed.material.color.setHex(G.termOn() ? 0x30ff60 : 0x301010);
    /* дверь */
    W.door.open += (W.door.target - W.door.open) * Math.min(1, dt * 2.2);
    W.door.pivot.rotation.y = W.door.open * 1.75;
    /* табличка мигает, пока на участке нет питания */
    const lit = S.qf0 || Math.sin(S.t * 0.9) > -0.2 || (Math.random() < 0.03);
    W.sign.map = lit && !(Math.random() < 0.02) ? W.signLit : W.signOff;
  };

  G.start = () => {
    G.pager('ВЫЗОВ\nНеисправность.\nЭлектрощитовая · 6 этаж.');
    G.goal('Найди электрощитовую');
    apply({ ...S });
  };
  return G;
}
