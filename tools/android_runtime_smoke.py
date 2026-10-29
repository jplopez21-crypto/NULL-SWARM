#!/usr/bin/env python3
"""ADB touch smoke test. Reads telemetry; never grants stats or alters game state."""
import argparse
import json
import math
from pathlib import Path
import struct
import subprocess
import time
import re
import statistics
import xml.etree.ElementTree as ET
from io import BytesIO
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--package', default='com.nullswarm.game.emulatorqa')
parser.add_argument('--output', default='builds/android-runtime')
parser.add_argument('--upgrade-apk', help='Install a same-signer higher-version APK after lifecycle checks')
parser.add_argument('--engineer-backup', help='Explicit synthetic earned-kit code; restored through GUI only after ordinary persistence checks')
args = parser.parse_args()
out = Path(args.output)
out.mkdir(parents=True, exist_ok=True)
checks = []
actions = []
telemetry_path = None
visual_samples = []
screen_dimensions = None


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
            ready = last.get("rendered_frames", 0) >= 3 and last.get("rendered_state") == last["state"] and last.get("rendered_panel") == last.get("panel")
            if predicate(last) and ready:
                return last
        except (ValueError, subprocess.SubprocessError):
            pass
        time.sleep(.25)
    raise AssertionError(f'Runtime condition timed out; last state: {last}')


def check(ok, name):
    checks.append({'name': name, 'passed': bool(ok)})
    print('ANDROID_CHECK', 'passed' if ok else 'failed', name, flush=True)
    if not ok:
        raise AssertionError(name)


def game_frame_fraction(image):
    # NULL//SWARM uses a blue/teal world and panels; the neutral Godot boot image
    # has only a small blue logo. This smoke heuristic detects splash/blank frames.
    sample = Image.open(BytesIO(image)).convert('RGB').resize((64, 36))
    pixels = list(sample.getdata())
    return sum(g >= r + 3 and b >= r + 3 and b >= g for r, g, b in pixels) / len(pixels)


def capture(name, wait_for_game=True):
    global screen_dimensions
    deadline = time.monotonic() + (30 if wait_for_game else 0)
    while True:
        image = adb('exec-out', 'screencap', '-p', binary=True)
        if image[:8] != b'\x89PNG\r\n\x1a\n':
            raise AssertionError('invalid Android screencap')
        fraction = game_frame_fraction(image)
        if not wait_for_game or fraction >= .25:
            break
        if time.monotonic() >= deadline:
            (out / f'{name}-not-ready.png').write_bytes(image)
            raise AssertionError(f'No rendered game frame for {name}; blue/teal fraction={fraction:.3f}')
        time.sleep(.25)
    visual_samples.append({'capture': name, 'game_palette_fraction': round(fraction, 4)})
    (out / f'{name}.png').write_bytes(image)
    screen_dimensions = struct.unpack('>II', image[16:24])
    return screen_dimensions


def screen_point(x, y, state):
    # Landscape and wm size are fixed for this run. Explicit captures refresh
    # the dimensions; input targeting should not force a GPU readback each time.
    width, height = screen_dimensions or capture('latest')
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
    # A timed swipe can batch MOVE and UP into one slow emulator frame.
    # Keep the real pointer held across rendered frames instead.
    adb('shell', 'input', 'motionevent', 'DOWN', *map(str, begin))
    try:
        adb('shell', 'input', 'motionevent', 'MOVE', *map(str, end))
        time.sleep(duration / 1000)
    finally:
        adb('shell', 'input', 'motionevent', 'UP', *map(str, end))
    actions.append({'held_drag': [*begin, *end, duration]})


def dismiss_system_dialogs():
    # Only emulator OS onboarding/launcher failures may be dismissed. Never game ANRs.
    for _ in range(3):
        try:
            adb('shell', 'uiautomator', 'dump', '/sdcard/null-swarm-system-ui.xml')
            xml = adb('shell', 'cat', '/sdcard/null-swarm-system-ui.xml')
            if "isn't responding" in xml and ('NULL SWARM' in xml or args.package in xml):
                raise AssertionError('Android reports a game ANR')
            nodes = list(ET.fromstring(xml).iter('node'))
            target = None
            reason = None
            if 'Pixel Launcher' in xml and "responding" in xml:
                target = next((n for n in nodes if n.get('resource-id') == 'android:id/aerr_close'), None)
                reason = 'Pixel Launcher ANR'
            if target is None:
                target = next((n for n in nodes if n.get('text') == 'Got it'), None)
                reason = 'Android fullscreen onboarding'
            if target is None:
                return
            numbers = list(map(int, re.findall(r'\d+', target.get('bounds', ''))))
            if len(numbers) != 4:
                return
            adb('shell', 'input', 'tap', str((numbers[0]+numbers[2])//2), str((numbers[1]+numbers[3])//2))
            actions.append({'dismissed_system_ui': reason})
            time.sleep(.5)
        except (subprocess.SubprocessError, ET.ParseError):
            return


def launch():
    resolved = adb('shell', 'cmd', 'package', 'resolve-activity', '--brief', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.LAUNCHER', '-p', args.package)
    component = next(line.strip() for line in resolved.splitlines() if '/' in line and args.package in line)
    for _ in range(2):
        adb('shell', 'am', 'start', '-W', '-n', component)
        dismiss_system_dialogs()
        foreground = adb('shell', 'dumpsys', 'activity', 'activities')
        if any(args.package in line and ('mResumedActivity' in line or 'topResumedActivity' in line) for line in foreground.splitlines()):
            return
    raise AssertionError('Game did not become foreground activity after Android system-dialog handling')


def quiet_profile():
    # Diagnostic observation only: no FPS pass gate, inputs, screenshots or grants.
    # The existing read-only probe/audio/rendering stay active on the CI emulator.
    time.sleep(2)
    initial = read()
    started = time.monotonic()
    samples = []
    while time.monotonic() - started < 5:
        current = read()
        text = current.get('performance_stats_text', '')
        fps = re.match(r'^(\d+) FPS /', text)
        samples.append({'wall_seconds': round(time.monotonic() - started, 3),
                        'simulation_seconds': current.get('time', 0), 'state': current['state'],
                        'fps': int(fps.group(1)) if fps else None, 'hud': text})
        time.sleep(.5)
    elapsed = samples[-1]['wall_seconds'] if samples else 0
    active = [s['fps'] for s in samples if s['state'] == 'playing' and s['fps'] is not None]
    return {'method': '2s warm-up then 5s without input/screencap; read-only telemetry sampled about twice per second',
            'variant': 'CI x86_64 Android 35 / Compatibility / SWANGLE software rendering',
            'samples': samples, 'median_fps': statistics.median(active) if active else None,
            'simulation_seconds_per_wall_second': (samples[-1]['simulation_seconds'] - initial.get('time', 0)) / elapsed if elapsed > 0 else None,
            'limits': ['Unseeded fresh deployment; not the earlier capture-heavy combat workload.',
                       'Observational emulator data; no phone-FPS acceptance threshold or CPU/GPU timing claim.']}


report = {'checks': checks, 'actions': actions, 'visual_samples': visual_samples, 'package': args.package,
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
    check(True, 'menu capture contains rendered game instead of boot splash')
    check(s['renderer'] == 'gl_compatibility', 'Android Compatibility renderer initialized')
    tap('SETTINGS', s)
    s = wait(lambda x: any('Performance stats' in b['text'] for b in x['buttons']))
    tap('Performance stats', s)
    s = wait(lambda x: x['settings'].get('performance_stats', False))
    check(True, 'real Android settings touch enables performance preference')
    tap('BACK', s)
    s = wait(lambda x: x['state'] == 'menu' and any('DEPLOY' in b['text'] for b in x['buttons']))
    tap('DEPLOY', s)
    s = wait(lambda x: x['state'] == 'playing')
    before = s['position']
    move(1, 0, s, 1200)
    s = wait(lambda x: math.dist(x.get('position', before), before) > 1)
    check(s['drags'] > 0 and s['touches'] > 0, 'real Android touch events moved player')
    dash_before = s['dashes']
    tap('DASH', s)
    s = wait(lambda x: x['dashes'] > dash_before and x.get('dash_readiness', 100) < 100)
    check(True, 'touch dash activated')
    check(s.get('operative_visible', False) and 0 <= s['dash_readiness'] < 100, 'dash keeps operative visible and updates readiness gauge')
    capture('combat')
    s = wait(lambda x: x.get('performance_stats_visible', False) and 'ENEMIES' in x.get('performance_stats_text', ''))
    check(True, 'performance diagnostics are visibly active during real Android gameplay')
    capture('performance-stats')
    tap('PAUSE')
    s = wait(lambda x: x['state'] == 'paused')
    elapsed = s['time']
    time.sleep(1)
    check(abs(read()['time'] - elapsed) < .05, 'touch pause freezes simulation')
    capture('paused')
    ranks_before_build = s['ranks']
    tap('BUILD // MUTATIONS', s)
    s = wait(lambda x: 'DEPLOYMENT BUILD' in x.get('build_text', ''))
    check(all(name in s['build_text'] for name in ['PULSE RIFLE', 'ARCSTORM RIFLE', 'SOLAR HALO', 'SINGULARITY LANCE']),
          'Android touch opens real equipped-weapon and mutation guide')
    capture('build-overview')
    time.sleep(1)
    s = read()
    check(s['state'] == 'paused' and abs(s['time'] - elapsed) < .05 and s['ranks'] == ranks_before_build,
          'build guide keeps Android combat and ranks paused')
    tap('BACK TO PAUSE', s)
    s = wait(lambda x: not x.get('build_text', '') and any(b['text'] == 'RESUME' for b in x['buttons']))
    check(s['state'] == 'paused', 'Android guide back returns to pause')
    tap('RESUME')
    wait(lambda x: x['state'] == 'playing')
    check(True, 'touch resume returns to combat')
    deadline = time.monotonic() + 120
    selected = False
    while time.monotonic() < deadline:
        s = read()
        if s['state'] == 'results':
            raise AssertionError('run ended before XP/upgrade/checkpoint smoke completed')
        if s['state'] == 'upgrading':
            capture('upgrade')
            before_ranks = s['ranks']
            tap('01\n', s)
            wait(lambda x: x.get('ranks') != before_ranks)
            selected = True
        elif s['state'] == 'playing':
            if selected and s.get('kills', 0) > 0 and s.get('xp', 0) > 0 and s.get('salvage', 0) > 0:
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
    check(s.get('salvage', 0) > 0, 'normal gameplay checkpoints nonzero earned salvage before lifecycle tests')
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
    old_process = s['process']
    adb('shell', 'am', 'force-stop', args.package)
    launch()
    s = wait(lambda x: x['state'] == 'menu' and x['process'] != old_process)
    check(s['salvage'] == salvage and salvage > 0, 'force-stop/relaunch retains exact nonzero banked progression and opens menu')
    check(s['settings']['shake'] == new_shake, 'touch-changed setting survives Android force-stop/relaunch')
    check(s['settings'].get('performance_stats', False), 'performance preference survives Android force-stop/relaunch')
    capture('relaunched')
    check(True, 'relaunch menu is visibly rendered')
    backup_before = s
    tap('PROGRESS BACKUP', s)
    s = wait(lambda x: any(b['text'] == 'EXPORT MY PROGRESS' for b in x['buttons']))
    tap('EXPORT MY PROGRESS', s)
    s = wait(lambda x: x.get('backup_code_length', 0) > 100)
    tap('COMMAND MENU', s)
    s = wait(lambda x: any('DEPLOY' in b['text'] for b in x['buttons']))
    tap('PROGRESS BACKUP', s)
    s = wait(lambda x: any(b['text'] == 'PASTE CODE' for b in x['buttons']) and x.get('backup_code_length', 0) == 0)
    tap('PASTE CODE', s)
    s = wait(lambda x: x.get('backup_code_length', 0) > 100)
    check(True, 'Android backup code survives real clipboard export and paste')
    capture('progress-backup')
    tap('PREVIEW RESTORE', s)
    s = wait(lambda x: any(b['text'] == 'RESTORE THIS BACKUP' for b in x['buttons']))
    tap('RESTORE THIS BACKUP', s)
    s = wait(lambda x: x.get('backup_recovery_available', False) and any(b['text'] == 'EXPORT MY PROGRESS' for b in x['buttons']))
    check(s['settings'] == backup_before['settings'] and s['salvage'] == backup_before['salvage'] and s['salvage'] > 0,
          'touch-confirmed backup restore preserves progress and creates recovery copy')
    capture('progress-restored')
    tap('COMMAND MENU', s)
    s = wait(lambda x: any('DEPLOY' in b['text'] for b in x['buttons']))
    if args.upgrade_apk:
        before_update = s
        package_info = adb('shell', 'dumpsys', 'package', args.package)
        old_version = int(re.search(r'versionCode=(\d+)', package_info).group(1))
        adb('shell', 'am', 'force-stop', args.package)
        installed = adb('install', '-r', args.upgrade_apk)
        if 'Success' not in installed:
            raise AssertionError('Android rejected the in-place APK update')
        package_info = adb('shell', 'dumpsys', 'package', args.package)
        new_version = int(re.search(r'versionCode=(\d+)', package_info).group(1))
        check(new_version > old_version, 'Android accepts higher-version same-signer APK update')
        launch()
        s = wait(lambda x: x['state'] == 'menu' and x['process'] != before_update['process'])
        check(s['settings'] == before_update['settings'] and s['salvage'] == before_update['salvage'] and s['salvage'] > 0,
              'in-place APK update retains changed settings and banked progression')
        capture('updated-install')
        report['apk_update'] = {'from_version': old_version, 'to_version': new_version,
                               'settings_retained': True, 'salvage': s['salvage']}
        tap('DEPLOY', s)
        s = wait(lambda x: x['state'] == 'playing' and x.get('performance_stats_visible', False) and 'ENEMIES' in x.get('performance_stats_text', ''))
        check(True, 'saved performance diagnostics appear on deployment after APK update')
        capture('performance-restored')
        report['quiet_profile'] = quiet_profile()
    if args.engineer_backup:
        code = Path(args.engineer_backup).read_text().strip()
        if not re.fullmatch(r'NS1\.[A-Za-z0-9+/=]+\.[0-9a-f]{64}', code):
            raise AssertionError('Invalid synthetic Engineer fixture format')
        # Standard earned-salvage/lifecycle/update assertions above use ordinary
        # play. Only now replace progress with a labelled earned-kit fixture.
        tap('PAUSE')
        s = wait(lambda x: x['state'] == 'paused')
        tap('END DEPLOYMENT', s)
        s = wait(lambda x: x['state'] == 'menu')
        tap('PROGRESS BACKUP', s)
        s = wait(lambda x: bool(x.get('edit_fields')))
        x, y, w, h = s['edit_fields'][0]
        px, py = screen_point(x + w / 2, y + h / 2, s)
        adb('shell', 'input', 'tap', str(px), str(py))
        adb('shell', 'input', 'text', code)
        s = wait(lambda x: x.get('backup_code_length') == len(code))
        tap('PREVIEW RESTORE', s)
        s = wait(lambda x: any('RESTORE THIS BACKUP' in b['text'] for b in x['buttons']))
        tap('RESTORE THIS BACKUP', s)
        s = wait(lambda x: x.get('architects', 0) == 1 and any('COMMAND MENU' in b['text'] for b in x['buttons']))
        tap('COMMAND MENU', s)
        s = wait(lambda x: any('FOUNDRY' in b['text'] for b in x['buttons']))
        tap('FOUNDRY', s)
        s = wait(lambda x: any('ENGINEER' in b['text'] and not b['disabled'] for b in x['buttons']))
        tap('ENGINEER', s)
        s = wait(lambda x: x.get('selected_kit') == 'engineer')
        check(True, 'synthetic Architect fixture restores through GUI and real Foundry touch selects Engineer')
        capture('engineer-foundry')
        tap('BACK', s)
        s = wait(lambda x: any('DEPLOY ENGINEER' in b['text'] for b in x['buttons']))
        tap('DEPLOY ENGINEER', s)
        s = wait(lambda x: x['state'] == 'playing' and x.get('sentry', {}).get('enabled'))
        check(s['hp'] == 80 and s['ranks'] == {'drone': 1} and s['sentry']['remaining'] == 0,
              'Engineer deployment has actual advertised equipment health and passive')
        origin = s['position']
        tap('DASH', s)
        s = wait(lambda x: x.get('sentry', {}).get('activations', 0) == 1 and math.dist(x['position'], origin) > 1)
        check(math.dist(s['sentry']['position'], origin) < .1 and s['sentry']['remaining'] > 0,
              'Engineer real touch dash leaves sentry at takeoff')
        tap('DASH', s)
        time.sleep(.4)
        s = read()
        check(s['sentry']['activations'] == 1, 'rejected Android dash cannot stack or refresh Engineer sentries')
        tap('PAUSE', s)
        s = wait(lambda x: x['state'] == 'paused')
        frozen = s['sentry']['remaining']
        time.sleep(1)
        check(frozen > 0 and read()['sentry']['remaining'] == frozen, 'Android pause freezes active Engineer sentry lifetime')
        tap('RESUME')
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            s = read()
            if s['state'] == 'results':
                raise AssertionError('Engineer run ended before sentry firing was exercised')
            if s['state'] == 'upgrading':
                tap('01\n', s)
                wait(lambda x: x['state'] != 'upgrading')
                continue
            if s['sentry']['shots'] > 0:
                break
            if s.get('dash_readiness', 0) >= 99:
                tap('DASH', s)
            goals = s.get('targets', [])
            if goals:
                goal = min(goals, key=lambda p: math.dist(s['position'], p))
                move(goal[0] - s['position'][0], goal[1] - s['position'][1], s, 650)
            else:
                move(math.cos(s['time'] * .15), math.sin(s['time'] * .15), s, 650)
        s = read()
        check(s['sentry']['shots'] > 0, 'Engineer sentry fires during normal Android touch combat')
        capture('engineer-combat')
        report['engineer_fixture'] = {'method': 'Synthetic earned-kit backup restored through normal GUI after ordinary progression/update checks; no progress grant by Android game/probe',
                                      'sentry': s['sentry'], 'simulation_seconds': s['time'], 'hp': s['hp'], 'kills': s['kills']}
        adb('shell', 'am', 'force-stop', args.package)
        launch()
        s = wait(lambda x: x['state'] == 'menu' and x.get('selected_kit') == 'engineer')
        check(True, 'earned-kit fixture Engineer selection survives Android relaunch')
    log = adb('logcat', '-d')
    (out / 'logcat.txt').write_text(log)
    fatal = [line for line in log.splitlines() if any(token in line for token in ['SCRIPT ERROR', 'FATAL EXCEPTION', 'Fatal signal']) or ('godot' in line.lower() and ('ERROR:' in line or 'USER ERROR' in line))]
    game_anrs = [line for line in log.splitlines() if 'ANR in ' + args.package in line]
    check(not fatal and not game_anrs, 'no script errors, game ANRs or Android fatal crashes in logcat')
    report['status'] = 'passed'
except Exception as error:
    report['status'] = 'failed'
    report['error'] = str(error)
    try:
        capture('failure', wait_for_game=False)
        (out / 'logcat.txt').write_text(adb('logcat', '-d'))
    except Exception:
        pass
    raise
finally:
    (out / 'android-runtime.json').write_text(json.dumps(report, indent=2))
    print('ANDROID_RUNTIME_RESULT', report['status'], 'checks=', len(checks))
