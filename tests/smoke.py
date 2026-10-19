#!/usr/bin/env python3
"""Автотест прототипа «Стены»: проходит главу 0 через отладочные хуки window.__st и снимает скриншоты.

Запуск:  python3 tests/smoke.py [папка_для_скриншотов]
"""
import sys, time, math, threading, pathlib, functools, http.server, socketserver
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOTS = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
fails = []


def check(name, ok, info=''):
    print(('  ok   ' if ok else '  FAIL ') + name + (('  ' + str(info)) if info != '' else ''))
    if not ok:
        fails.append(name)


class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass


srv = socketserver.TCPServer(('127.0.0.1', 0), functools.partial(Q, directory=str(ROOT)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = f'http://127.0.0.1:{srv.server_address[1]}/index.html'

with sync_playwright() as p:
    b = p.chromium.launch(args=['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'])
    pg = b.new_page(viewport={'width': 960, 'height': 540})
    errs = []
    pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.on('console', lambda m: errs.append(m.text[:300]) if m.type == 'error' and 'fonts.g' not in m.text and 'Failed to load resource' not in m.text else None)
    pg.goto(URL)
    pg.wait_for_function('() => !!window.__st', timeout=20000)
    J = pg.evaluate
    J('() => { window.__st.paused = true }')  # программный рендер медленный: кадры рисуем только для скриншотов

    def shot(name):
        if SHOTS:
            J('() => window.__st.render()')
            pg.screenshot(path=str(SHOTS / (name + '.png')))

    shot('00_start')
    print('Старт')
    J('() => window.__st.start()')
    check('игра запущена', J('() => window.__st.UI.started && !document.getElementById("hud").hidden'))
    check('на пейджере вызов', 'Электрощитовая' in J('() => document.getElementById("pgText").textContent'))
    J('() => window.__st.step(1.5)')
    shot('01_landing')

    print('Дверь')
    J('() => window.__st.tp(0, 1.3, 0, 0)')
    check('смотрим на дверь', J('() => window.__st.look()') == 'door')
    J('() => window.__st.tp(0, 1.0, 0, 0.35)')
    J('() => window.__st.step(0.2)')
    shot('02_door')
    J('() => window.__st.tp(0, 1.3, 0, 0)')
    J('() => window.__st.interact()')
    J('() => window.__st.step(2.5)')
    check('дверь открылась', J('() => window.__st.W.door.open > 0.9'))
    shot('03_door_open')
    J('() => window.__st.tp(0, -1, 0, 0)')
    J('() => window.__st.step(0.5)')
    check('вошли в коридор, пришла заявка', J('() => window.__st.S.entered') and 'ЗАЯВКА 0001' in J('() => document.getElementById("pgText").textContent'))
    J('() => window.__st.tp(-0.4, -1.5, 0.05, 0.03)')
    J('() => window.__st.step(0.3)')
    shot('04_corridor_dark')
    J('() => { window.__st.P.toggleFlash(); window.__st.step(0.5) }')
    shot('04b_flashlight')
    J('() => window.__st.P.toggleFlash()')

    print('Стены держат')
    J('() => window.__st.tp(0, -3, -Math.PI/2, 0)')
    J('() => { const s=window.__st; s.P.keys.KeyW=true; s.step(3); s.P.keys.KeyW=false }')
    x = J('() => window.__st.P.pos.x')
    check('в стену не пройти', x > -1.31, round(x, 3))
    J('() => window.__st.tp(0, -15, 0, 0)')
    J('() => { const s=window.__st; s.P.keys.KeyW=true; s.step(4); s.P.keys.KeyW=false }')
    z = J('() => window.__st.P.pos.z')
    check('решётка держит', z > -19.95, round(z, 3))

    print('Щиток')
    J('() => window.__st.tp(2.4, -7.1, -Math.PI/2, 0)')
    check('смотрим на щиток', J('() => window.__st.look()') == 'panel')
    J('() => window.__st.tp(2.2, -8.9, -Math.PI/2, -0.32)')
    check('терминал без питания', J('() => window.__st.look()') == 'terminal' and not J('() => window.__st.G.termOn()'))
    J('() => window.__st.tp(2.4, -7.1, -Math.PI/2, 0)')
    J('() => window.__st.openOverlay("panel")')
    check('щиток открыт', J('() => !document.getElementById("panel").hidden'))
    pg.click('.brk[data-k=qf0]')
    check('ввод включился, свет есть', J('() => window.__st.S.qf0 && window.__st.G.lightsA()'))
    pg.click('.brk[data-k=qf2]')
    check('терминал запитан', J('() => window.__st.G.termOn()'))
    check('амперметр 14 А', '14 А' in J('() => document.getElementById("ammVal").textContent'))
    shot('05_panel')
    pg.keyboard.press('Escape')
    check('щиток закрылся', J('() => document.getElementById("panel").hidden && !window.__st.UI.overlay'))
    J('() => window.__st.step(2)')
    J('() => window.__st.tp(-0.6, -1.5, 0.05, 0.02)')
    J('() => window.__st.step(0.3)')
    shot('06_corridor_lit')

    print('Терминал')
    J('() => window.__st.tp(2.2, -8.9, -Math.PI/2, -0.32)')
    J('() => window.__st.step(0.2)')
    check('смотрим на терминал', J('() => window.__st.look()') == 'terminal')
    shot('07_terminal_world')
    J('() => window.__st.openOverlay("term")')
    pg.wait_for_timeout(200)
    J('() => window.__st.T.flush()')
    pg.keyboard.type('help')  # ввод по физическим клавишам
    pg.keyboard.press('Enter')
    J('() => window.__st.T.flush()')
    check('HELP печатается с клавиатуры', 'POWER <A|B|V>' in J('() => window.__st.T.text()'))
    for c in ['DIR', 'READ LOG', 'STATUS']:
        J(f'() => window.__st.T.exec("{c}")')
    J('() => window.__st.T.flush()')
    txt = J('() => window.__st.T.text()')
    check('файлы и статус', 'LOG.TXT' in txt and 'Они идут на ток' in txt and 'НАГРУЗКА: 14 / 20' in txt)
    J('() => window.__st.T.exec("OPEN GD6 1987")')
    J('() => window.__st.T.flush()')
    check('без питания привода не открыть', 'НЕТ ПИТАНИЯ ПРИВОДА' in J('() => window.__st.T.text()') and J('() => window.__st.S.gate') == 'closed')
    shot('08_terminal')
    J('() => window.__st.T.exec("POWER V ON")')
    check('перегрузка выбивает ввод', not J('() => window.__st.S.qf0') and J('() => window.__st.S.trips') == 1)
    pg.wait_for_timeout(1200)
    check('терминал погас и закрылся', J('() => document.getElementById("term").hidden && !window.__st.G.termOn()'))
    J('() => window.__st.step(1)')
    J('() => window.__st.tp(2.3, -8.9, -Math.PI/2, -0.1)')
    J('() => window.__st.step(0.3)')
    shot('09_blackout')

    J('() => window.__st.G.set("qf0", true)')
    J('() => window.__st.openOverlay("term")')
    for c in ['POWER A OFF', 'POWER V ON', 'OPEN GD6 1111']:
        J(f'() => window.__st.T.exec("{c}")')
    J('() => window.__st.T.flush()')
    check('свет выключен, привод запитан', not J('() => window.__st.G.lightsA()') and J('() => window.__st.S.v') and J('() => window.__st.G.load()') == 18)
    check('неверный код отклонён', 'НЕВЕРНЫЙ КОД' in J('() => window.__st.T.text()') and J('() => window.__st.S.gate') == 'closed')
    J('() => window.__st.T.exec("OPEN GD-6 1987")')
    check('решётка пошла', J('() => window.__st.S.gate') == 'opening')
    J('() => window.__st.T.close()')

    print('Решётка и участок 7')
    J('() => window.__st.tp(0, -8, 0, 0.05)')
    J('() => window.__st.step(3)')
    shot('10_gate_rising')
    J('() => window.__st.step(4)')
    check('решётка открыта', J('() => window.__st.S.gate') == 'open' and J('() => window.__st.W.gate.open') >= 1)
    J('() => window.__st.step(12)')
    lit = J('() => window.__st.W.lamps.filter(l=>l.grp==="S7"&&l.lvl>0.5).length')
    check('свет на участке 7 включился до горизонта', lit > 200, lit)
    check('вторая заявка', 'ЗАЯВКА 0002' in J('() => document.getElementById("pgText").textContent'))
    J('() => window.__st.tp(0, -12, 0, 0.02)')
    J('() => window.__st.step(0.3)')
    shot('11_endless')
    J('() => { const s=window.__st; s.tp(0,-25,0,0); s.P.keys.KeyW=true; s.step(2); s.P.keys.KeyW=false }')
    check('за решётку можно пройти', J('() => window.__st.P.pos.z') < -26)

    print('Финал')
    J('() => window.__st.tp(0, -50, 0, 0)')
    J('() => window.__st.step(12)')
    shot('12_dark_wave')
    J('() => window.__st.step(20)')
    pg.wait_for_timeout(3000)
    check('финал прототипа', J('() => window.__st.S.ended') and J('() => !document.getElementById("end").hidden'))
    shot('13_end')

    check('нет ошибок JS', not errs, errs[:5])
    b.close()

print()
print('ИТОГ: всё в порядке' if not fails else 'ИТОГ: провалено ' + str(len(fails)) + ': ' + ', '.join(fails))
sys.exit(1 if fails else 0)
