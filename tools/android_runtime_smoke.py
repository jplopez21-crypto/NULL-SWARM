#!/usr/bin/env python3
"""ADB touch smoke test. Reads telemetry; never grants stats or alters game state."""
import argparse
import json
import math
from pathlib import Path
import struct
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--package', default='com.nullswarm.game.emulatorqa')
parser.add_argument('--output', default='builds/android-runtime')
args = parser.parse_args()
out = Path(args.output)
out.mkdir(parents=True, exist_ok=True)
checks = []
actions = []
telemetry_path = None


def adb(*cmd, binary=False):
    return subprocess.check_output(['adb', *cmd], timeout=20, text=not binary)


def read():
    global telemetry_path
    if telemetry_path is None:
        paths = adb('shell', 'run-as', args.package, 'find', 'files', '-name', 'qa-runtime.json').splitlines()
        if not paths:
            raise ValueError('telemetry not yet written')
        telemetry_path = paths[0].strip()
    return json.loads(adb('shell', 'run-as', args.package, 'cat', telemetry_path))


def wait(predicate, timeout=30):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        try:
            last = read()
            if predicate(last):
                return last
        except (ValueError, subprocess.SubprocessError):
            pass
        time.sleep(.25)
    raise AssertionError(f'Runtime condition timed out; last state: {last}')


def check(ok, name):
    checks.append({'name': name, 'passed': bool(ok)})
    if not ok:
        raise AssertionError(name)


def capture(name):
    image = adb('exec-out', 'screencap', '-p', binary=True)
    if image[:8] != b'\x89PNG\r\n\x1a\n':
        raise AssertionError('invalid Android screencap')
    (out / f'{name}.png').write_bytes(image)
    return struct.unpack('>II', image[16:24])


def screen_point(x, y, state):
    width, height = capture('latest')
    cw, ch = state['canvas']
    scale = min(width / cw, height / ch)
    return round((width - cw * scale) / 2 + x * scale), round((height - ch * scale) / 2 + y * scale)


def tap(label, state=None):
    state = state or read()
    button = next(b for b in state['buttons'] if label in b['text'] and not b['disabled'])
    x, y, w, h = button['rect']
    px, py = screen_point(x + w / 2, y + h / 2, state)
    adb('shell', 'input', 'tap', str(px), str(py))
    actions.append({'tap': label, 'screen': [px, py], 'from': state['state']})


def move(dx, dz, state, duration=800):
    length = math.hypot(dx, dz)
    if length < .1:
        return
    x, y = 120, state['canvas'][1] - 110
    begin = screen_point(x, y, state)
    end = screen_point(x + dx / length * 70, y + dz / length * 70, state)
    adb('shell', 'input', 'swipe', *map(str, (*begin, *end, duration)))
    actions.append({'swipe': [*begin, *end, duration]})


def launch():
    adb('shell', 'monkey', '-p', args.package, '-c', 'android.intent.category.LAUNCHER', '1')


report = {'checks': checks, 'actions': actions, 'package': args.package,
          'variant': 'x86_64 Android 35 / Compatibility / read-only opt-in probe',
          'limitations': ['Does not validate ARM64 Mobile renderer, physical touch latency, cutouts or phone performance.',
                          'Victory/death are headless integration checks, not forced emulator outcomes.']}
try:
    adb('logcat', '-c')
    launch()
    s = wait(lambda x: x['state'] == 'menu', 60)
    report['engine'] = s['engine']
    report['renderer'] = s['renderer']
    capture('menu')
    check(s['renderer'] == 'gl_compatibility', 'Android Compatibility renderer initialized')
    tap('DEPLOY', s)
    s = wait(lambda x: x['state'] == 'playing')
    before = s['position']
    move(1, 0, s, 1200)
    s = wait(lambda x: math.dist(x.get('position', before), before) > 1)
    check(s['drags'] > 0 and s['touches'] > 0, 'real Android touch events moved player')
    dash_before = s['dashes']
    tap('DASH', s)
    wait(lambda x: x['dashes'] > dash_before)
    check(True, 'touch dash activated')
    capture('combat')
    tap('PAUSE')
    s = wait(lambda x: x['state'] == 'paused')
    elapsed = s['time']
    time.sleep(1)
    check(abs(read()['time'] - elapsed) < .05, 'touch pause freezes simulation')
    capture('paused')
    tap('RESUME')
    wait(lambda x: x['state'] == 'playing')
    check(True, 'touch resume returns to combat')
    deadline = time.monotonic() + 120
    selected = False
    while time.monotonic() < deadline:
        s = read()
        if s['state'] == 'results':
            raise AssertionError('run ended before XP/upgrade smoke completed')
        if s['state'] == 'upgrading':
            capture('upgrade')
            before_ranks = s['ranks']
            tap('01\n', s)
            wait(lambda x: x.get('ranks') != before_ranks)
            selected = True
        elif s['state'] == 'playing':
            if selected and s.get('kills', 0) > 0 and s.get('xp', 0) > 0:
                break
            targets = s.get('targets', [])
            if targets:
                x, z = s['position']
                target = min(targets, key=lambda p: (p[0]-x)**2 + (p[1]-z)**2)
                move(target[0]-x, target[1]-z, s, 650)
            else:
                time.sleep(.5)
        time.sleep(.2)
    check(selected and s.get('xp', 0) > 0 and s.get('kills', 0) > 0, 'auto combat, XP collection and real upgrade touch passed')
    report['gameplay_snapshot'] = s
    capture('after-upgrade')
    adb('shell', 'input', 'keyevent', '3')
    time.sleep(1)
    launch()
    s = wait(lambda x: x['state'] == 'paused')
    check(True, 'Android background/resume preserves paused state')
    capture('background-resumed')
    salvage = s['salvage']
    tap('SETTINGS', s)
    s = wait(lambda x: any('Camera shake' in b['text'] for b in x['buttons']))
    old_shake = s['settings']['shake']
    tap('Camera shake', s)
    s = wait(lambda x: x['settings']['shake'] != old_shake)
    new_shake = s['settings']['shake']
    capture('settings-changed')
    tap('BACK', s)
    adb('shell', 'am', 'force-stop', args.package)
    launch()
    s = wait(lambda x: x['state'] == 'menu')
    check(s['salvage'] >= salvage, 'force-stop/relaunch retains banked progression and opens menu')
    check(s['settings']['shake'] == new_shake, 'touch-changed setting survives Android force-stop/relaunch')
    capture('relaunched')
    log = adb('logcat', '-d')
    (out / 'logcat.txt').write_text(log)
    fatal = [line for line in log.splitlines() if any(token in line for token in ['SCRIPT ERROR', 'FATAL EXCEPTION', 'Fatal signal'])]
    check(not fatal, 'no script errors or Android fatal crashes in logcat')
    report['status'] = 'passed'
except Exception as error:
    report['status'] = 'failed'
    report['error'] = str(error)
    try:
        capture('failure')
        (out / 'logcat.txt').write_text(adb('logcat', '-d'))
    except Exception:
        pass
    raise
finally:
    (out / 'android-runtime.json').write_text(json.dumps(report, indent=2))
    print('ANDROID_RUNTIME_RESULT', report['status'], 'checks=', len(checks))
