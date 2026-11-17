"""Ordinary Mobile mutation flow with injectable device I/O for offline testing."""
import json
import math
from pathlib import Path
import time as real_time
from mutation_observation import complete as mutation_complete, active_build, dealt_damage, earned_history
from passive_observation import passive_summary_matches
from build_observation import frozen_navigation
from lifecycle_observation import fresh_resumed_frame


def run_mobile_mutation(io, report, output, package, clock=None):
    """Production uses real ADB; unit tests provide explicitly synthetic device I/O."""
    time = real_time if clock is None else clock
    out = Path(output)
    out.mkdir(parents=True, exist_ok=True)
    adb, launch, wait = io.adb, io.launch, io.wait
    capture, tap, move, read = io.capture, io.tap, io.move, io.read
    check, mobile_pick_upgrade = io.check, io.pick_upgrade
    report['variant'] = 'x86_64 Android 35 / required Mobile renderer / ordinary mutation pursuit'
    report['scope'] = 'Bounded coverage experiment. Death, offer exhaustion and time/choice budgets are observations. Collection success is not mutation acceptance; verified coverage requires active build text and real Arcstorm damage. No grants, rerolls, seed writes or fallback.'
    report['transactions'] = []
    report['mutation_verified'] = False
    report['coverage'] = 'not_reached'
    mutation_candidate_verified = False
    began = time.monotonic()
    try:
        adb('logcat', '-c')
        launch()
        menu = wait(lambda x: x['state'] == 'menu', 120)
        report['engine'] = menu['engine']; report['renderer'] = menu['renderer']
        check(menu['renderer'] == 'mobile', 'mutation pursuit requires actual Mobile renderer without fallback')
        capture('mutation-menu')
        tap('DEPLOY', menu)
        s = wait(lambda x: x['state'] == 'playing')
        start = s
        report['start'] = start
        check(s['selected_kit'] == 'vanguard' and not s['ranks'] and s['level'] == 1
              and not s['corruption']['accepted'], 'mutation pursuit starts a clean ordinary Vanguard deployment')
        deadline = time.monotonic() + 720
        reason = 'budget'
        while True:
            report['latest'] = s
            if s['state'] == 'results':
                reason = 'run_ended'; break
            if time.monotonic() >= deadline:
                break
            if s['state'] == 'upgrading':
                if len(report['transactions']) >= 24:
                    reason = 'choice_budget'; break
                transaction, s = mobile_pick_upgrade(f'mutation-choice-{len(report["transactions"])+1:02d}', pursue_mutation=True)
                report['transactions'].append(transaction)
                continue
            if s['state'] != 'playing':
                raise AssertionError('Unexpected state during ordinary mutation pursuit')
            if mutation_complete(s['ranks']) and dealt_damage(s):
                reason = 'mutation_damage'; break
            targets = s.get('targets', [])
            if targets:
                x,z = s['position']; goal = min(targets, key=lambda p:(p[0]-x)**2+(p[1]-z)**2)
                move(goal[0]-x, goal[1]-z, s, 650)
            else:
                move(math.cos(s['time']*.45), math.sin(s['time']*.45), s, 500)
            s = read()
        report['stop_reason'] = reason
        report['final_combat'] = s
        check(earned_history(start, report['transactions'], s), 'recorded ordinary touches account for every earned rank without grants or extra selections')
        report['coverage'] = 'eligible' if mutation_complete(s['ranks']) else ('partial' if any(s['ranks'].get(k,0)>0 for k in ('damage','arc')) else 'not_reached')
        if s['state'] == 'playing':
            tap('PAUSE', s)
            paused = wait(lambda x: x['state'] in ('paused','upgrading','results'))
            if paused['state'] == 'paused':
                tap('BUILD // MUTATIONS', paused)
                guide = wait(lambda x:'DEPLOYMENT BUILD' in x.get('build_text',''))
                check(frozen_navigation(paused, guide) and passive_summary_matches(guide['build_text'],guide['ranks']),
                      'mutation pursuit build review matches actual earned ranks and freezes gameplay')
                capture('mutation-build')
                report['build'] = guide
                if mutation_complete(guide['ranks']):
                    check(active_build(guide), 'actually earned Arcstorm is equipped and marked ACTIVE in the build guide')
                adb('shell','input','keyevent','3'); time.sleep(1); launch()
                returned = wait(lambda x:fresh_resumed_frame(guide,x),60)
                check(frozen_navigation(guide,returned) and returned['build_text']==guide['build_text'],
                      'earned mutation build survives a same-process background return with unchanged ranks and gameplay')
                capture('mutation-returned')
                report['returned'] = returned
                mutation_candidate_verified = active_build(guide) and active_build(returned) and dealt_damage(s)
                tap('BACK TO PAUSE', returned)
                back = wait(lambda x:x['state']=='paused' and any(b['text']=='RESUME' for b in x['buttons']))
                tap('RESUME',back)
                resumed = wait(lambda x:x['state'] in ('playing','results') and x['time']>back['time'],60)
                check(resumed['process']==back['process'] and resumed['renderer']=='mobile'
                      and resumed['ranks']==back['ranks'], 'mutation build resumes ordinary combat with earned ranks intact')
                report['resumed'] = resumed
                capture('mutation-resumed')
        log = adb('logcat','-d');(out/'logcat.txt').write_text(log)
        report['graphics_log'] = [line for line in log.splitlines() if str(start['process']) in line.split() and ('Vulkan' in line or 'Mobile' in line)]
        fatal = [line for line in log.splitlines() if any(t in line for t in ['SCRIPT ERROR','FATAL EXCEPTION','Fatal signal']) or ('godot' in line.lower() and ('ERROR:' in line or 'USER ERROR' in line)) or 'ANR in '+package in line]
        check(not fatal, 'mutation pursuit has no script error app ANR or fatal crash')
        # Publish acceptance only after resume, capture and final crash checks pass.
        report['mutation_verified'] = mutation_candidate_verified
        if mutation_candidate_verified:
            report['coverage'] = 'active_and_damaged'
        report['status'] = 'observed'
        return 0
    except Exception as error:
        report['status'] = 'failed';report['error'] = str(error)
        report['mutation_verified'] = False
        report['coverage_before_failure'] = report['coverage']
        report['coverage'] = 'unverified'
        try:
            capture('mutation-failure',wait_for_game=False)
            (out/'logcat.txt').write_text(adb('logcat','-d'))
        except Exception:
            pass
        return 1
    finally:
        report['wall_seconds'] = round(time.monotonic()-began,2)
        (out/'android-mutation.json').write_text(json.dumps(report,indent=2))
        print('ANDROID_MUTATION_RESULT',report['status'],'coverage=',report['coverage'],'checks=',len(report["checks"]),flush=True)
