#!/usr/bin/env python3
"""Retain an unfixed control's known Surface failure without claiming it passed."""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--directory',type=Path,required=True);p.add_argument('--exit-code',type=int,required=True);a=p.parse_args()
r=json.loads((a.directory/'android-lifecycle.json').read_text())
log=(a.directory/'logcat.txt').read_text()
fatal=any(s in log for s in ['SCRIPT ERROR','FATAL EXCEPTION','Fatal signal','ANR in '+r['package']])
if a.exit_code==0:
 assert r['status']=='passed'
 outcome='no_persistent_failure_observed'
elif a.exit_code==1:
 assert r['status']=='failed' and not fatal
 assert r.get('app_egl_failures') and any(s in r.get('error','') for s in ['Runtime condition timed out','No rendered game frame'])
 outcome='known_surface_failure_reproduced'
else:raise SystemExit('Unexpected control failure or timeout; inspect diagnostics')
assert not fatal
(a.directory/'control-outcome.json').write_text(json.dumps({'driver_exit_code':a.exit_code,'driver_status':r['status'],'outcome':outcome,'scope':'Control collection outcome, not a passing recovery test when driver_status is failed.'},indent=2)+'\n')
print('SURFACE_CONTROL_OUTCOME',outcome)
