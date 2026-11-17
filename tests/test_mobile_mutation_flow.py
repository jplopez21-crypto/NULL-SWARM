"""Synthetic device-I/O tests of the actual runner, never Android acceptance."""
import copy
from contextlib import redirect_stdout
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
import test_mutation_observation as cards_fixture

sys.path.insert(0,str(Path(__file__).parents[1]/'tools'))
from mobile_mutation_flow import run_mobile_mutation
from mutation_observation import CARD_RANKS, choose_card, complete, earned_history
from passive_observation import PASSIVE_LABELS


class Clock:
    def __init__(self):self.now=0.
    def monotonic(self):return self.now
    def sleep(self,seconds):self.now+=seconds


class Device:
    """Explicit simulation of protocol responses; contains no ADB or game process."""
    def __init__(self,report,clock,mode):
        self.report,self.clock,self.mode=report,clock,mode
        self.picks=0;self.moves=0;self.background=False;self.launched=False
        self.state={'process':42,'engine':'synthetic','renderer':'mobile','state':'menu','rendered_state':'menu',
                    'panel':1,'rendered_panel':1,'rendered_frames':10,'sample_ticks':1000,'time':0.,
                    'position':[0.,0.],'hp':100.,'kills':0,'xp':0,'ranks':{},'pending':0,'level':1,
                    'combat_rng':'synthetic','damage_by_weapon':{},'salvage':0,'settings':{'quality':1},
                    'selected_kit':'vanguard','dash_readiness':100.,'dashes':0,
                    'health':{'current':100.,'maximum':100.,'shield':30.,'max_shield':30.},
                    'corruption':{'accepted':[]},'lifecycle':{'foreground_generation':0,'rendered_generation':0,'background_events':0},
                    'buttons':[],'targets':[],'build_text':''}
        if mode=='fallback':self.state['renderer']='gl_compatibility'

    def snapshot(self):return copy.deepcopy(self.state)
    def frame(self,state=None,panel=None):
        if state is not None:self.state.update(state=state,rendered_state=state)
        if panel is not None:self.state.update(panel=panel,rendered_panel=panel)
        self.state['rendered_frames']+=2;self.state['sample_ticks']+=100
    def read(self):return self.snapshot()
    def wait(self,predicate,timeout=30):
        self.assert_ready(predicate(self.state),'Synthetic device cannot satisfy requested transition')
        return self.snapshot()
    def assert_ready(self,value,message):
        if not value:raise AssertionError(message)
    def check(self,value,label):
        self.report['checks'].append({'name':label,'passed':bool(value)})
        self.assert_ready(value,label)
    def launch(self):
        if self.background:
            life=self.state['lifecycle'];life['foreground_generation']+=1;life['rendered_generation']=life['foreground_generation']
            self.frame();self.background=False
        self.launched=True
    def adb(self,*args):
        if args==('shell','input','keyevent','3'):
            self.background=True;self.state['lifecycle']['background_events']+=1
        if args==('logcat','-d'):
            return 'FATAL EXCEPTION: synthetic late log failure' if self.mode=='fatal' else 'synthetic 42 Vulkan 1.3.0 - Forward Mobile'
        return ''
    def capture(self,name,wait_for_game=True):
        if self.mode=='capture' and name=='mutation-resumed':raise RuntimeError('synthetic late capture failure')
        self.report['visual_samples'].append({'capture':name,'mode':'synthetic; no image generated'})
    def tap(self,label,state):
        self.report['actions'].append({'tap':label,'mode':'synthetic'})
        if label=='DEPLOY':self.frame('playing',0)
        elif label=='PAUSE':
            self.frame('upgrading' if self.mode=='pause_race' else 'paused',101)
            if self.mode=='pause_race':self.state['pending']=1
        elif label=='BUILD // MUTATIONS':
            self.frame('paused',102)
            title='ARCSTORM RIFLE' if complete(self.state['ranks']) else 'PULSE RIFLE'
            status='ACTIVE' if complete(self.state['ranks']) else 'IN PROGRESS'
            passives=[f'{title} {self.state["ranks"][key]}/7' for key,title in PASSIVE_LABELS.items() if self.state['ranks'].get(key,0)>0]
            self.state['build_text']=f'DEPLOYMENT BUILD\n01 // {title}\nARCSTORM RIFLE // {status}\nPASSIVE UPLINKS // '+(' • '.join(passives) if passives else 'NONE YET // COLLECT MEMORY TO UPGRADE')
        elif label=='BACK TO PAUSE':
            self.frame('paused',103);self.state['build_text']='';self.state['buttons']=[{'text':'RESUME','disabled':False}]
        elif label=='RESUME':
            if self.mode=='resume':raise RuntimeError('synthetic resume failure after active build observation')
            self.frame('playing',0);self.state['time']+=.1
        else:raise AssertionError('Unexpected synthetic touch: '+label)
    def move(self,dx,dz,state,duration):
        self.moves+=1;self.clock.now+=.01
        if self.moves>25:raise AssertionError('Synthetic loop exceeded its test bound')
        self.state['time']+=1.
        if self.mode=='death':
            self.frame('results',200);self.state['hp']=0.;return
        if self.mode=='unexpected':self.frame('menu',201);return
        self.frame('upgrading',10+self.moves);self.state['level']+=1;self.state['pending']=1
        self.state['kills']+=1;self.state['xp']+=18+(self.state['level']-2)*10
        ranks=self.state['ranks']
        if self.mode=='choices' and self.picks<24:
            schedule=['MEMORY TETHER']*5+['AEGIS CAPACITOR']*5+['REINFORCED CHASSIS']*5+['SERVO OVERDRIVE']*5+['PHASE ROUNDS']*3+['RAPID CYCLER']
            self.state['buttons']=[cards_fixture.card('01',schedule[self.picks])]
        else:
            self.state['buttons']=[cards_fixture.card('01','AMPLIFIED PULSE',ranks.get('damage',0),ranks.get('arc',0)),
                                   cards_fixture.card('02','ARC EMITTER',ranks.get('damage',0),ranks.get('arc',0)),
                                   cards_fixture.card('03','MEMORY TETHER')]
    def pick_upgrade(self,name,pursue_mutation=False):
        self.assert_ready(pursue_mutation,'Runner must request explicit recipe pursuit')
        offered=self.snapshot();self.frame();frozen=self.snapshot();chosen=choose_card(frozen['buttons'],frozen['ranks'])
        key=CARD_RANKS[cards_fixture.card_title(chosen)];ranks=self.state['ranks'].copy();ranks[key]=ranks.get(key,0)+1
        self.state.update(ranks=ranks,pending=0);self.frame('playing',0);self.state['time']+=.05
        self.picks+=1
        if complete(ranks) and self.mode!='eligible':self.state['damage_by_weapon']['arcstorm']=12.5
        if (self.mode=='partial' and self.picks==1) or (self.mode=='eligible' and complete(ranks)):self.clock.now=1000.
        selected=self.snapshot();self.report['actions'].append({'tap':chosen['text'].split('\n',1)[0]+'\n','mode':'synthetic'})
        row={'offered':offered,'frozen':frozen,'selected':selected,'chosen_text':chosen['text'],
             'chosen_index':chosen['text'].split('\n',1)[0],'changed_rank':key}
        return row,selected


class MobileMutationFlowTests(unittest.TestCase):
    def run_flow(self,mode):
        report={'checks':[],'actions':[],'visual_samples':[],'test_mode':'synthetic driver harness; not Android telemetry'}
        clock=Clock();device=Device(report,clock,mode)
        with tempfile.TemporaryDirectory() as tmp:
            console=StringIO()
            with redirect_stdout(console):
                code=run_mobile_mutation(device,report,tmp,'test.synthetic',clock=clock)
            self.assertIn('ANDROID_MUTATION_RESULT',console.getvalue())
            saved=json.loads((Path(tmp)/'android-mutation.json').read_text())
            self.assertEqual(saved,report)
        return code,report,device

    def test_success_requires_real_acceptance_predicates_across_the_whole_synthetic_flow(self):
        code,r,d=self.run_flow('success')
        self.assertEqual((code,r['status'],r['coverage'],r['mutation_verified']),(0,'observed','active_and_damaged',True))
        self.assertEqual(d.picks,6)
        self.assertTrue(earned_history(r['start'],r['transactions'],r['final_combat']))
        self.assertTrue(all(c['passed'] for c in r['checks']))
        self.assertIn('synthetic',r['test_mode'])

    def test_normal_death_is_an_observation_not_mutation_acceptance(self):
        code,r,d=self.run_flow('death')
        self.assertEqual((code,r['status'],r['stop_reason'],r['mutation_verified']),(0,'observed','run_ended',False))
        self.assertEqual(d.picks,0)

    def test_partial_budget_keeps_actual_rank_and_false_acceptance(self):
        code,r,d=self.run_flow('partial')
        self.assertEqual((code,r['coverage'],r['stop_reason'],r['mutation_verified']),(0,'partial','budget',False))
        self.assertEqual(d.picks,1)

    def test_complete_recipe_and_active_text_without_damage_are_not_verified(self):
        code,r,d=self.run_flow('eligible')
        self.assertEqual((code,r['coverage'],r['mutation_verified']),(0,'eligible',False))
        self.assertIn('ARCSTORM RIFLE // ACTIVE',r['build']['build_text'])

    def test_choice_cap_does_not_select_a_twenty_fifth_upgrade(self):
        code,r,d=self.run_flow('choices')
        self.assertEqual((code,r['stop_reason'],r['mutation_verified']),(0,'choice_budget',False))
        self.assertEqual((d.picks,d.moves),(24,25))

    def test_renderer_fallback_fails(self):
        code,r,d=self.run_flow('fallback')
        self.assertEqual((code,r['status'],r['mutation_verified']),(1,'failed',False))
        self.assertEqual(d.picks,0)

    def test_late_resume_capture_or_crash_failure_cannot_leave_verified_acceptance(self):
        for mode in ['resume','capture','fatal']:
            with self.subTest(mode=mode):
                code,r,d=self.run_flow(mode)
                self.assertEqual((code,r['status']),(1,'failed'))
                self.assertFalse(r['mutation_verified'],f'status={r["status"]},coverage={r["coverage"]}')
                self.assertEqual(r['coverage'],'unverified')
                self.assertIn('build',r)  # Observed snapshots survive even when acceptance fails.

    def test_pause_race_leaves_mutation_unverified(self):
        code,r,d=self.run_flow('pause_race')
        self.assertEqual((code,r['coverage'],r['mutation_verified']),(0,'eligible',False))
        self.assertNotIn('returned',r)

    def test_unexpected_state_is_a_failure(self):
        code,r,d=self.run_flow('unexpected')
        self.assertEqual((code,r['status'],r['mutation_verified']),(1,'failed',False))
        self.assertIn('Unexpected state',r['error'])
