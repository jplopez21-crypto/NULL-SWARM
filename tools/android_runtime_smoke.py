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
import select
import os
import xml.etree.ElementTree as ET
from io import BytesIO
from PIL import Image
from lifecycle_observation import fresh_resumed_frame, frozen_run, app_egl_failures
from upgrade_observation import upgrade_frozen, selected_rank
from build_observation import frozen_navigation
from passive_observation import PASSIVE_LABELS, passive_card, passive_summary_matches

parser = argparse.ArgumentParser()
parser.add_argument('--package', default='com.nullswarm.game.emulatorqa')
parser.add_argument('--output', default='builds/android-runtime')
parser.add_argument('--upgrade-apk', help='Install a same-signer higher-version APK after lifecycle checks')
parser.add_argument('--engineer-backup', help='Explicit synthetic earned-kit code; restored through GUI only after ordinary persistence checks')
mode = parser.add_mutually_exclusive_group()
mode.add_argument('--mobile-smoke', action='store_true', help='Require actual Mobile renderer; exercise genuine touch/combat and one return without stat grants')
mode.add_argument('--lifecycle-only', action='store_true', help='Run strict Home/launcher recovery cycles without granting progress')
parser.add_argument('--lifecycle-cycles', type=int, default=6, choices=range(1, 31), help='Bounded lifecycle sample count (default 6, maximum 30)')
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
    if isinstance(last, dict):
        compact = {k: v for k, v in last.items() if k not in {'performance_report_text', 'targets', 'build_text'}}
        compact['performance_report_characters'] = len(last.get('performance_report_text', ''))
        compact['target_count'] = len(last.get('targets', []))
    else:
        compact = last
    raise AssertionError(f'Runtime condition timed out; last state: {compact}')


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



class MultiTouch:
    """Drive genuine Android MotionEvents through a shell-only helper, with ACKs."""
    def __enter__(self):
        self.process = subprocess.Popen(
            ['adb', 'shell', 'CLASSPATH=/data/local/tmp/null-swarm-touch.jar',
             'app_process', '/', 'NullSwarmTouch'], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        self.buffer = b''
        try:
            self.expect('READY')
        except Exception:
            self.process.kill()
            self.process.communicate()
            raise
        return self

    def expect(self, expected):
        deadline = time.monotonic() + 15
        output = []
        while time.monotonic() < deadline:
            while b'\n' not in self.buffer:
                if not select.select([self.process.stdout], [], [], max(0, deadline - time.monotonic()))[0]:
                    raise AssertionError(f'Android touch injector timed out: {expected}; {output}')
                chunk = os.read(self.process.stdout.fileno(), 4096)
                if not chunk:
                    raise AssertionError(f'Android touch injector closed: {expected}; {output}')
                self.buffer += chunk
            raw, self.buffer = self.buffer.split(b'\n', 1)
            line = raw.decode('utf-8', errors='replace').strip()
            if line == expected:
                return
            output.append(line)
            if self.process.poll() is not None:
                break
        raise AssertionError(f'Android multi-touch injector did not acknowledge {expected}: {output}')

    def send(self, action, pointer, xy):
        command = f'{action} {pointer} {xy[0]} {xy[1]}'
        self.process.stdin.write(command + '\n')
        self.process.stdin.flush()
        self.expect('ACK ' + command)

    def __exit__(self, kind, value, traceback):
        try:
            self.process.stdin.write('quit\n')
            self.process.stdin.flush()
            self.process.communicate(timeout=10)
        except (BrokenPipeError, subprocess.TimeoutExpired):
            self.process.kill()
            self.process.communicate()
        if kind is None and self.process.returncode != 0:
            raise AssertionError('Android multi-touch injector failed')


def touch_sample(state):
    return {key: state.get(key) for key in ['touch_controls', 'position', 'dashes', 'dash_readiness', 'time', 'state']}


def multitouch_dash(order):
    s = wait(lambda x: x['state'] == 'menu' and any('DEPLOY' in b['text'] for b in x['buttons']))
    tap('DEPLOY', s)
    s = wait(lambda x: x['state'] == 'playing' and x.get('dash_readiness', 0) >= 99)
    before = s['dashes']
    button = next(b for b in s['buttons'] if 'DASH' in b['text'])
    x, y, w, h = button['rect']
    dash = screen_point(x + w / 2, y + h / 2, s)
    origin = screen_point(120, s['canvas'][1] - 110, s)
    held = screen_point(195, s['canvas'][1] - 110, s)
    samples = {}
    with MultiTouch() as fingers:
        if order == 'joystick-first':
            fingers.send('down', 7, origin)
            fingers.send('move', 7, held)
            wait(lambda x: x.get('touch_controls', {}).get('stick', [0, 0])[0] > .9)
            fingers.send('down', 11, dash)
        else:
            fingers.send('down', 11, dash)
            wait(lambda x: x['dashes'] == before + 1 and x.get('touch_controls', {}).get('dash_id', -1) >= 0)
            fingers.send('down', 7, origin)
            fingers.send('move', 7, held)
        s = wait(lambda x: x['state'] == 'playing' and x['dashes'] == before + 1
                 and x.get('touch_controls', {}).get('dash_id', -1) >= 0
                 and x.get('touch_controls', {}).get('joystick_id', -1) >= 0
                 and x.get('touch_controls', {}).get('stick', [0, 0])[0] > .9)
        controls = s['touch_controls']
        check(controls['dash_id'] != controls['joystick_id'], f'{order}: independent held fingers activate dash and movement together')
        samples['both_held'] = touch_sample(s)
        capture('multitouch-' + order)
        position = s['position']
        fingers.send('up', 11, dash)
        s = wait(lambda x: x.get('touch_controls', {}).get('dash_id', -2) == -1
                 and x.get('touch_controls', {}).get('stick', [0, 0])[0] > .9
                 and math.dist(x['position'], position) > .2)
        check(s['touch_controls']['joystick_id'] >= 0, f'{order}: releasing dash preserves held movement')
        samples['dash_released'] = touch_sample(s)
        fingers.send('up', 7, held)
        s = wait(lambda x: x.get('touch_controls', {}).get('joystick_id', -2) == -1
                 and x.get('touch_controls', {}).get('stick') == [0, 0])
        check(s['touch_controls']['dash_id'] == -1, f'{order}: both touch controls release cleanly')
        check(s['dashes'] == before + 1, f'{order}: touch releases produce exactly one dash')
        samples['released'] = touch_sample(s)
    actions.append({'multitouch': order, 'injection': 'shell UID / real Android two-pointer MotionEvent', 'samples': samples})
    tap('PAUSE', s)
    s = wait(lambda x: x['state'] == 'paused')
    end_to_menu(s)


def multitouch_pause():
    s = wait(lambda x: x['state'] == 'menu' and any('DEPLOY' in b['text'] for b in x['buttons']))
    tap('DEPLOY', s)
    s = wait(lambda x: x['state'] == 'playing')
    button = next(b for b in s['buttons'] if 'PAUSE' in b['text'])
    x, y, w, h = button['rect']
    pause = screen_point(x + w / 2, y + h / 2, s)
    origin = screen_point(120, s['canvas'][1] - 110, s)
    held = screen_point(195, s['canvas'][1] - 110, s)
    start = s['position']
    samples = {}
    with MultiTouch() as fingers:
        fingers.send('down', 7, origin)
        fingers.send('move', 7, held)
        s = wait(lambda x: x['state'] == 'playing' and x.get('touch_controls', {}).get('stick', [0, 0])[0] > .9
                 and math.dist(x['position'], start) > .2)
        samples['walking'] = touch_sample(s)
        fingers.send('down', 11, pause)
        s = wait(lambda x: x['state'] == 'paused')
        controls = s['touch_controls']
        check(controls['joystick_id'] == controls['dash_id'] == controls['pause_id'] == -1
              and controls['stick'] == [0, 0] and not controls['pause_enabled'] and not controls['dash_enabled'],
              'held joystick plus second-finger Pause freezes and clears both HUD actions')
        samples['paused_while_fingers_held'] = touch_sample(s)
        elapsed, position, dashes = s['time'], s['position'], s['dashes']
        time.sleep(1)
        frozen = read()
        check(frozen['state'] == 'paused' and frozen['time'] == elapsed and frozen['position'] == position and frozen['dashes'] == dashes,
              'two-finger Pause keeps actual simulation and dash frozen')
        capture('multitouch-paused')
        fingers.send('up', 11, pause)
        fingers.send('up', 7, held)
    tap('RESUME')
    s = wait(lambda x: x['state'] == 'playing' and x['time'] > elapsed)
    controls = s['touch_controls']
    check(controls['joystick_id'] == controls['dash_id'] == controls['pause_id'] == -1 and controls['stick'] == [0, 0]
          and controls['pause_enabled'] and controls['dash_enabled'] and s['position'] == position and s['dashes'] == dashes,
          'touch Resume restores controls without stale walking or deferred dash')
    samples['resumed'] = touch_sample(s)
    actions.append({'multitouch_pause': True, 'injection': 'shell UID / real Android two-pointer MotionEvent', 'samples': samples})
    tap('PAUSE', s)
    s = wait(lambda x: x['state'] == 'paused')
    end_to_menu(s)


def end_to_menu(s):
    tap('END DEPLOYMENT', s)
    s = wait(lambda x: x['state'] == 'results')
    tap('COMMAND MENU', s)
    return wait(lambda x: x['state'] == 'menu')


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
def lifecycle_repro():
    report['cycles'] = []
    report['scope'] = f'{args.lifecycle_cycles} Home/launcher transitions with 0.25/1/3 second background dwell. Real frames/screens, frozen state and advancing resumed combat required. No retries, process restarts, save grants or warning suppression.'
    try:
        adb('logcat', '-c')
        launch()
        s = wait(lambda x: x['state'] == 'menu', 60)
        report['engine'] = s['engine']
        report['renderer'] = s['renderer']
        capture('lifecycle-menu')
        check(s['renderer'] == 'gl_compatibility', 'lifecycle reproduction uses actual Compatibility renderer')
        tap('DEPLOY', s)
        s = wait(lambda x: x['state'] == 'playing' and x.get('time', 0) > 0)
        for index in range(1, args.lifecycle_cycles + 1):
            dwell = [0.25, 1.0, 3.0][(index - 1) % 3]
            before = read()
            row = {'index': index, 'background_seconds': dwell, 'before': before, 'status': 'in_progress'}
            report['cycles'].append(row)
            adb('shell', 'input', 'keyevent', '3')
            time.sleep(dwell)
            launch()
            s = wait(lambda x: fresh_resumed_frame(before, x))
            row['returned'] = s
            check(True, f'cycle {index}: same process presents a fresh frame after foreground notification')
            capture(f'lifecycle-{index:02d}-returned')
            time.sleep(.5)
            frozen = read()
            row['frozen'] = frozen
            check(frozen_run(s, frozen), f'cycle {index}: paused gameplay rewards and RNG remain frozen')
            tap('RESUME', frozen)
            s = wait(lambda x: x['state'] == 'playing' and x['time'] > frozen['time'] and x['rendered_frames'] > frozen['rendered_frames'])
            check(True, f'cycle {index}: touch Resume advances real combat again')
            row['resumed'] = s
            row['status'] = 'passed'
        log = adb('logcat', '-d')
        (out / 'logcat.txt').write_text(log)
        report['app_egl_failures'] = app_egl_failures(log, s['process'])
        fatal = [line for line in log.splitlines() if any(token in line for token in ['SCRIPT ERROR', 'FATAL EXCEPTION', 'Fatal signal']) or ('godot' in line.lower() and ('ERROR:' in line or 'USER ERROR' in line)) or 'ANR in ' + args.package in line]
        check(not fatal, f'{args.lifecycle_cycles}-cycle run has no script error app ANR or fatal crash')
        report['status'] = 'passed'
        return 0
    except Exception as error:
        report['status'] = 'failed'
        report['error'] = str(error)
        try:
            capture('lifecycle-failure', wait_for_game=False)
            log = adb('logcat', '-d')
            (out / 'logcat.txt').write_text(log)
            report['app_egl_failures'] = app_egl_failures(log, report['cycles'][-1]['before']['process']) if report['cycles'] else []
        except Exception:
            pass
        return 1
    finally:
        (out / 'android-lifecycle.json').write_text(json.dumps(report, indent=2))
        print('ANDROID_LIFECYCLE_RESULT', report['status'], 'checks=', len(checks), flush=True)


def mobile_collect_offer(s, deadline):
    # Targets are real unattracted memory pickups exposed by the read-only probe.
    while s['state'] != 'upgrading':
        if s['state'] != 'playing' or time.monotonic() >= deadline:
            raise AssertionError('Mobile run could not earn a passive within its normal-play budget')
        targets = s.get('targets', [])
        if targets:
            x, z = s['position']
            target = min(targets, key=lambda p: (p[0]-x)**2 + (p[1]-z)**2)
            move(target[0]-x, target[1]-z, s, 650)
        else:
            time.sleep(.25)
        s = read()
    return s


def mobile_earned_upgrades(start):
    deadline = time.monotonic() + 300
    s = mobile_collect_offer(start, deadline)
    transactions = []
    check(s['state'] == 'upgrading' and s['level'] >= 2 and s['xp'] > 0
          and s['pending'] > 0 and s.get('memory_audio_plays', 0) > 0,
          'ordinary Mobile kills and memory collection earn XP level and upgrade choices')
    while s['state'] == 'upgrading' or not any(s['ranks'].get(key, 0) > 0 for key in PASSIVE_LABELS):
        if len(transactions) >= 8:
            raise AssertionError('Mobile early-upgrade queue exceeded bounded smoke budget')
        s = mobile_collect_offer(s, deadline)
        offered = wait(lambda x: x['state'] == 'upgrading' and x['pending'] > 0)
        cards = [b for b in offered['buttons'] if re.match(r'^0[123]\n', b['text']) and not b['disabled']]
        capture(f'mobile-upgrade-{len(transactions)+1:02d}')
        time.sleep(.5)
        frozen = wait(lambda x: x['state'] == 'upgrading'
                      and x['rendered_frames'] > offered['rendered_frames']
                      and x['sample_ticks'] > offered['sample_ticks'])
        if len(cards) != 3 or {b['text'].split('\n', 1)[0] for b in cards} != {'01','02','03'} or not upgrade_frozen(offered, frozen):
            raise AssertionError('Mobile upgrade offer is invalid or gameplay advanced while choosing')
        chosen = passive_card(cards) or next(b for b in cards if b['text'].startswith('01\n'))
        chosen_index = chosen['text'].split('\n', 1)[0]
        tap(chosen_index+'\n', frozen)
        selected = wait(lambda x: x.get('ranks') != frozen['ranks'])
        changed = selected_rank(frozen, selected)
        if changed is None:
            raise AssertionError('Mobile upgrade touch did not apply exactly one rank/choice transaction')
        transactions.append({'offered':offered,'frozen':frozen,'selected':selected,
                             'chosen_text':chosen['text'],'chosen_index':chosen_index,'changed_rank':changed})
        s = wait(lambda x: x['state'] == 'upgrading' or (x['state'] == 'playing' and x['pending'] == 0
                 and x['time'] > frozen['time'] and x['rendered_frames'] > frozen['rendered_frames']))
    check(bool(transactions), 'Mobile upgrade cards freeze real gameplay XP rewards RNG and queued choices')
    check(all(selected_rank(t['frozen'],t['selected']) == t['changed_rank'] for t in transactions),
          'each Mobile upgrade tap applies exactly one rank and consumes one earned choice')
    last = transactions[-1]['frozen']
    s = wait(lambda x: x['state'] == 'playing' and x['pending'] == 0
             and x['time'] > last['time'] and x['rendered_frames'] > last['rendered_frames'])
    check(s['renderer'] == 'mobile', 'Mobile selected build resumes combat with an empty upgrade queue')
    check(any(s['ranks'].get(key, 0) > 0 for key in PASSIVE_LABELS),
          'ordinary Mobile offers and touches acquire an actual passive rank without grants or rerolls')
    report['earned_upgrade'] = {'transactions':transactions,'resumed':s,
                               'method':'Ordinary kills and memory pickups, real joystick/card touches. No fixture or stat grant.',
                               'selection_strategy':'Prefer a visible passive; otherwise choose first and earn another offer. At most eight choices and a 300-second collection deadline; no rerolls.'}
    capture('mobile-upgrade-applied')
    return s


def mobile_earned_build(start):
    tap('PAUSE', start)
    paused = wait(lambda x: x['state'] == x.get('rendered_state') == 'paused'
                  and x.get('panel') == x.get('rendered_panel') and bool(x['ranks']))
    tap('BUILD // MUTATIONS', paused)
    guide = wait(lambda x: 'DEPLOYMENT BUILD' in x.get('build_text', '')
                 and x.get('panel') == x.get('rendered_panel'))
    check(frozen_navigation(paused, guide)
          and all(name in guide['build_text'] for name in ['PULSE RIFLE', 'ARCSTORM RIFLE', 'SOLAR HALO', 'SINGULARITY LANCE'])
          and not guide['chain_feedback']['visible'],
          'Mobile touch opens mutation guide with the genuinely earned build and no combat HUD bleed')
    check(passive_summary_matches(guide['build_text'], guide['ranks']),
          'Mobile dedicated passive summary matches the actual earned ranks and displays valid caps')
    capture('mobile-build-earned')
    time.sleep(.5)
    frozen = wait(lambda x: x['rendered_frames'] > guide['rendered_frames'] and x['sample_ticks'] > guide['sample_ticks'])
    check(frozen_navigation(guide, frozen) and frozen['panel'] == guide['panel']
          and frozen['build_text'] == guide['build_text'],
          'Mobile build guide freezes gameplay XP ranks rewards RNG dash and settings while rendering')
    tap('CORRUPTION //', frozen)
    review = wait(lambda x: 'ACTIVE CORRUPTION' in x.get('build_text', '') and x.get('panel') == x.get('rendered_panel'))
    check(frozen_navigation(frozen, review) and 'CLEAN SIGNAL' in review['build_text']
          and 'NEXT OPTIONAL LINK //' in review['build_text'] and 'GAIN //' not in review['build_text'],
          'Mobile actual build opens honest clean corruption review without altering earned progression')
    capture('mobile-corruption-review')
    time.sleep(.5)
    review_frozen = wait(lambda x: x['rendered_frames'] > review['rendered_frames'] and x['sample_ticks'] > review['sample_ticks'])
    check(frozen_navigation(review, review_frozen) and review_frozen['panel'] == review['panel']
          and review_frozen['build_text'] == review['build_text'],
          'Mobile corruption review freezes gameplay while fresh menu frames render')
    tap('BACK TO BUILD', review_frozen)
    restored = wait(lambda x: 'DEPLOYMENT BUILD' in x.get('build_text', '') and x.get('panel') == x.get('rendered_panel'))
    check(frozen_navigation(review_frozen, restored) and restored['build_text'] == guide['build_text'],
          'Mobile corruption Back restores the identical earned build without resuming combat')
    tap('BACK TO PAUSE', restored)
    back = wait(lambda x: not x.get('build_text', '') and x.get('panel') == x.get('rendered_panel')
                and any(b['text'] == 'RESUME' for b in x['buttons']))
    check(frozen_navigation(frozen, back) and back['panel'] != frozen['panel'],
          'Mobile build back restores a fresh pause panel without resuming or changing the earned build')
    tap('RESUME', back)
    resumed = wait(lambda x: x['state'] == x.get('rendered_state') == 'playing'
                   and x['time'] > back['time'] and x['rendered_frames'] > back['rendered_frames'])
    check(resumed['process'] == back['process'] and resumed['renderer'] == 'mobile'
          and resumed['ranks'] == back['ranks'] and not resumed.get('build_text', '')
          and any(b['text'] == 'II  PAUSE' for b in resumed['buttons'])
          and any(b['text'].startswith('DASH') for b in resumed['buttons']),
          'Mobile build Resume restores combat and both HUD actions with earned ranks intact')
    report['earned_build'] = {'paused':paused,'guide':guide,'frozen':frozen,'back':back,'resumed':resumed,
                              'corruption_review':{'opened':review,'frozen':review_frozen,'returned':restored},
                              'method':'Actual touch navigation after ordinary earned XP/upgrade selection; no fixture or stat grant.'}
    capture('mobile-build-resumed')
    return resumed


def mobile_smoke():
    report['variant'] = 'x86_64 Android 35 / required Mobile renderer / read-only opt-in probe'
    report['scope'] = 'Mobile startup, actual two-finger controls, ordinary combat/earned XP/upgrade choices, earned-build and clean corruption-review navigation, and one same-process foreground return. No stat grants; no fallback accepted. Frame-pacing configuration is reported separately; not a phone FPS, shipping frame-pacing or full-run acceptance test.'
    try:
        adb('logcat', '-c')
        launch()
        s = wait(lambda x: x['state'] == 'menu', 120)
        report['engine'] = s['engine']; report['renderer'] = s['renderer']
        check(s['renderer'] == 'mobile', 'actual Mobile renderer is active; Compatibility fallback is rejected')
        capture('mobile-menu')
        multitouch_dash('joystick-first')
        multitouch_pause()
        s = wait(lambda x: x['state'] == 'menu')
        tap('DEPLOY', s)
        s = wait(lambda x: x['state'] == 'playing')
        s = wait(lambda x: x.get('kills', 0) > 0 and sum(x.get('damage_by_weapon', {}).values()) > 0, 120)
        check(True, 'ordinary Mobile automatic combat spawns and destroys enemies with effective damage')
        report['combat_snapshot'] = s
        capture('mobile-combat')
        s = mobile_earned_upgrades(s)
        s = mobile_earned_build(s)
        before = read()
        adb('shell', 'input', 'keyevent', '3'); time.sleep(1); launch()
        returned = wait(lambda x: fresh_resumed_frame(before, x), 60)
        check(returned['renderer'] == 'mobile', 'Mobile returns in the same process with a fresh paused foreground frame')
        capture('mobile-returned')
        time.sleep(.5); frozen = read()
        check(frozen_run(returned, frozen), 'Mobile paused gameplay rewards and RNG remain frozen')
        tap('RESUME', frozen)
        resumed = wait(lambda x: x['state'] == 'playing' and x['time'] > frozen['time'] and x['rendered_frames'] > frozen['rendered_frames'], 60)
        check(resumed['renderer'] == 'mobile', 'Mobile touch Resume advances combat and rendering')
        report['lifecycle'] = {'before': before, 'returned': returned, 'frozen': frozen, 'resumed': resumed}
        log = adb('logcat', '-d'); (out/'logcat.txt').write_text(log)
        report['graphics_log'] = [line for line in log.splitlines() if str(resumed['process']) in line.split() and ('Vulkan' in line or 'Mobile' in line)]
        fatal = [line for line in log.splitlines() if any(t in line for t in ['SCRIPT ERROR', 'FATAL EXCEPTION', 'Fatal signal']) or ('godot' in line.lower() and ('ERROR:' in line or 'USER ERROR' in line)) or 'ANR in ' + args.package in line]
        check(not fatal, 'Mobile smoke has no script error app ANR or fatal crash')
        report['status'] = 'passed'; return 0
    except Exception as error:
        report['status'] = 'failed'; report['error'] = str(error)
        try:
            capture('mobile-failure', wait_for_game=False)
            (out/'logcat.txt').write_text(adb('logcat', '-d'))
        except Exception:
            pass
        return 1
    finally:
        (out/'android-mobile.json').write_text(json.dumps(report, indent=2))
        print('ANDROID_MOBILE_RESULT', report['status'], 'checks=', len(checks), flush=True)


if args.mobile_smoke:
    raise SystemExit(mobile_smoke())


if args.lifecycle_only:
    raise SystemExit(lifecycle_repro())


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
    dash_label = next(b['text'] for b in s['buttons'] if 'DASH' in b['text'])
    check('READY' not in dash_label and '0.0s' not in dash_label,
          'active Android dash cooldown text agrees with unavailable readiness')
    check(s.get('operative_visuals') == {'instances': 5, 'surfaces': 6, 'triangles': 296},
          'Android operative uses the actual shared faceted armor and rifle geometry')
    report['operative_visuals'] = s['operative_visuals']
    lanes = s.get('attack_lanes', {})
    check(all(lanes.get(k, {}).get('triangles') == n and lanes[k].get('surfaces') == 1
              and lanes[k].get('ground_mesh') and lanes[k].get('length') == 7
              for k, n in [('charge', 12), ('sentry', 7)]),
          'Android pooled enemies contain original directional charge and sentry ground meshes')
    report['attack_lane_geometry'] = lanes
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
    chain_sampled = False
    destruction_sampled = False
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
            destruction = s.get('destruction_feedback', {})
            if not destruction_sampled and s.get('kills', 0) > 0 and destruction.get('fragments_live', 0) > 0 and destruction.get('fragment_triangles') == 8:
                report['destruction_feedback_sample'] = {**destruction, 'kills': s['kills'], 'scope': 'Actual ordinary Android death/pooled geometry; audio dispatch/PCM metadata, emulator sound output disabled.'}
                capture('destruction-feedback')
                destruction_sampled = True
            feedback = s.get('chain_feedback', {})
            if not chain_sampled and s.get('kills', 0) > 0 and feedback.get('visible') and 0 < feedback.get('value', 0) <= 100 and any(text in feedback.get('text', '') for text in ['CHAIN', 'OVERCLOCK']):
                report['chain_feedback_sample'] = {**feedback, 'kills': s['kills']}
                capture('chain-feedback')
                chain_sampled = True
            if selected and s.get('kills', 0) > 0 and s.get('xp', 0) > 0 and s.get('salvage', 0) > 0 and s.get('memory_audio_plays', 0) > 0 and destruction_sampled:
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
    check(s.get('memory_audio_plays', 0) > 0, 'ordinary Android XP collection requests dedicated memory audio playback')
    report['memory_audio_sample'] = {'accepted_plays': s.get('memory_audio_plays', 0), 'collected_xp': s.get('xp', 0),
                                   'level': s.get('level'), 'scope': 'Actual accepted playback calls; emulator audio is disabled, not a human listening test.'}
    check(s.get('salvage', 0) > 0, 'normal gameplay checkpoints nonzero earned salvage before lifecycle tests')
    check(chain_sampled, 'actual Android kills display live chain or Overclock gauge')
    check(destruction_sampled, 'ordinary Android enemy death displays actual pooled eight-triangle chips')
    destruction = s.get('destruction_feedback', {})
    check(destruction.get('kill_cue_last_dispatch_ms', -1) >= 0 and destruction.get('kill_cue_pcm_bytes') == 6174
          and len(destruction.get('kill_cue_pcm_sha256', '')) == 64,
          'ordinary Android enemy death dispatches original bounded destruction cue')
    report['destruction_audio_sample'] = destruction
    report['gameplay_snapshot'] = s
    capture('after-upgrade')
    before_background = read()
    adb('shell', 'input', 'keyevent', '3')
    time.sleep(1)
    launch()
    s = wait(lambda x: fresh_resumed_frame(before_background, x))
    check(True, 'Android background/resume preserves paused state with a fresh foreground frame')
    capture('background-resumed')
    salvage = s['salvage']
    tap('SETTINGS', s)
    s = wait(lambda x: any('Camera shake' in b['text'] for b in x['buttons']))
    old_shake = s['settings']['shake']
    tap('Camera shake', s)
    s = wait(lambda x: x['settings']['shake'] != old_shake)
    new_shake = s['settings']['shake']
    capture('settings-changed')
    paused_clock = s['time']
    paused_salvage = s['salvage']
    tap('PERFORMANCE REPORT', s)
    s = wait(lambda x: bool(x.get('performance_report_text')))
    performance = json.loads(s['performance_report_text'])
    check(performance['summary']['observations'] > 0 and all(row['fps'] > 0 for row in performance['samples'])
          and performance['device']['renderer'] == s['renderer'] and not s.get('edit_fields'),
          'Android report contains real positive combat observations and read-only device context')
    capture('performance-report')
    report['performance_report_sample'] = performance
    tap('COPY REPORT', s)
    s = wait(lambda x: x.get('performance_copy_status') == 'Report copied.')
    check(True, 'Android performance report clipboard write and readback passed')
    tap('BACK TO SETTINGS', s)
    s = wait(lambda x: any('Camera shake' in b['text'] for b in x['buttons']))
    check(s['state'] == 'paused' and s['time'] == paused_clock and s['salvage'] == paused_salvage,
          'performance report back preserves paused combat and exact progression')
    tap('BACK', s)
    s = wait(lambda x: x['state'] == 'paused' and any(b['text'] == 'END DEPLOYMENT' for b in x['buttons']))
    tap('END DEPLOYMENT', s)
    s = wait(lambda x: x['state'] == 'results')
    check(s.get('results_title') == 'DEPLOYMENT ENDED' and s['kills'] > 0 and s['xp'] > 0,
          'ending an ordinary earned Android run opens honest completed results')
    capture('earned-results')
    frozen = {key: s[key] for key in ['time', 'kills', 'ranks', 'combat_rng', 'damage_by_weapon', 'salvage']}
    tap('RUN ANALYSIS', s)
    s = wait(lambda x: bool(x.get('run_analysis_text')))
    names = {'pulse': 'PULSE SHOTS', 'arcstorm': 'ARCSTORM CHAINS', 'halo': 'SOLAR HALO HEAT',
             'drone': 'DRONE SYSTEMS', 'singularity': 'SINGULARITY LANCE', 'arc': 'ARC EMITTER',
             'rail': 'RAIL LANCE', 'orbit': 'PLASMA ORBITALS', 'thermal': 'THERMAL BURST'}
    damage = {k: float(v) for k, v in frozen['damage_by_weapon'].items() if math.isfinite(float(v)) and float(v) > 0}
    total = sum(damage.values())
    text = s['run_analysis_text']
    check(total > 0 and all(names[k] in text and f'{v / total * 100:.1f}%' in text for k, v in damage.items()),
          'earned Android analysis displays actual recorded damage channels and mathematically correct shares')
    capture('earned-analysis')
    time.sleep(1)
    s = read()
    check(all(s[key] == value for key, value in frozen.items()),
          'viewing earned Android analysis freezes time RNG ranks damage kills and rewards')
    report['earned_analysis'] = {'method': 'Ordinary touch combat/XP/upgrades followed by End Deployment and Run Analysis; before any synthetic Engineer progress fixture',
                                'damage_by_weapon': damage, 'text': text, 'frozen': frozen}
    tap('BACK TO RESULTS', s)
    s = wait(lambda x: x.get('results_title') == 'DEPLOYMENT ENDED' and not x.get('run_analysis_text'))
    check(s['state'] == 'results' and all(s[key] == value for key, value in frozen.items()),
          'earned Android analysis Back returns to the same result without duplicate rewards')
    salvage = s['salvage']
    tap('COMMAND MENU', s)
    s = wait(lambda x: x['state'] == 'menu')
    check(s['salvage'] == salvage and not s.get('run_analysis_text'),
          'completed Android deployment returns to menu retaining exact earned salvage')
    tap('DEPLOY', s)
    s = wait(lambda x: x['state'] == 'playing')
    tap('PAUSE', s)
    s = wait(lambda x: x['state'] == 'paused')
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
        s = end_to_menu(s)
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
    for order in ['joystick-first', 'dash-first']:
        multitouch_dash(order)
    multitouch_pause()
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
