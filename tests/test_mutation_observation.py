import copy
from pathlib import Path
import sys
import unittest
import test_upgrade_observation as fixtures

sys.path.insert(0,str(Path(__file__).parents[1]/'tools'))
from mutation_observation import card_title, choose_card, recipe_cards_valid, complete, active_build, dealt_damage, earned_history, selected_card_rank, CARD_RANKS


def card(index,title,damage=0,arc=0,badge=False):
    return {'text':f'{index}\n'+('MUTATES: ARCSTORM RIFLE\n' if badge else '\n')+title+f'\nARCSTORM: Pulse {min(3,damage)}/3 + Arc {min(3,arc)}/3','disabled':False}


class MutationObservationTests(unittest.TestCase):
    def test_actual_enabled_recipe_cards_are_selected_without_rewriting_them(self):
        cards=[card('01','DRONE HIVE'),card('02','ARC EMITTER'),card('03','AMPLIFIED PULSE')]
        before=copy.deepcopy(cards)
        self.assertIs(choose_card(cards,{'arc':2,'damage':1}),cards[2])
        self.assertIs(choose_card(cards,{'arc':2,'damage':3}),cards[1])
        self.assertEqual(cards,before)
        cards[1]['disabled']=True
        self.assertIsNot(choose_card(cards,{'damage':3}),cards[1])

    def test_completing_mutation_badge_does_not_hide_card_title(self):
        c=card('02','ARC EMITTER',3,2,True)
        self.assertEqual(card_title(c),'ARC EMITTER')
        self.assertIs(choose_card([c],{'damage':3,'arc':2}),c)
        self.assertTrue(recipe_cards_valid([c],{'damage':3,'arc':2}))

    def test_fallback_prefers_visible_passives_and_preserves_weapon_slots(self):
        cards=[card('01','DRONE HIVE'),card('02','SERVO OVERDRIVE'),card('03','MEMORY TETHER')]
        self.assertIs(choose_card(cards,{}),cards[2])
        self.assertIsNone(choose_card([{'text':'REROLL / 2','disabled':False}],{}))
        with self.assertRaises(ValueError):choose_card(cards,{'damage':True})

    def test_counter_contract_uses_current_saturated_ranks(self):
        cards=[card('01','AMPLIFIED PULSE',4,3)]
        self.assertTrue(recipe_cards_valid(cards,{'damage':4,'arc':3}))
        self.assertFalse(recipe_cards_valid(cards,{'damage':2,'arc':3}))
        self.assertFalse(complete({'damage':True,'arc':3}))
        self.assertFalse(complete({'damage':3,'arc':2}))
        self.assertTrue(complete({'damage':4,'arc':3}))

    def test_active_build_needs_equipped_slot_not_just_recipe_title(self):
        sample={'state':'paused','rendered_state':'paused','panel':5,'rendered_panel':5,'ranks':{'damage':3,'arc':3},
                'build_text':'DEPLOYMENT BUILD\n01 // ARCSTORM RIFLE\nARCSTORM RIFLE // ACTIVE'}
        self.assertTrue(active_build(sample))
        for changes in [{'build_text':'ARCSTORM RIFLE // ACTIVE'},{'panel':0,'rendered_panel':0},
                        {'rendered_panel':4},{'state':'playing'},{'ranks':{'damage':2,'arc':3}},{'build_text':None}]:
            self.assertFalse(active_build({**sample,**changes}))

    def test_real_positive_finite_damage_requires_earned_recipe(self):
        sample={'ranks':{'damage':3,'arc':3},'damage_by_weapon':{'arcstorm':12.5}}
        self.assertTrue(dealt_damage(sample))
        for amount in [0,-1,True,float('nan'),float('inf'),'100']:
            self.assertFalse(dealt_damage({**sample,'damage_by_weapon':{'arcstorm':amount}}))
        self.assertFalse(dealt_damage({**sample,'ranks':{'damage':1,'arc':3}}))
        self.assertFalse(dealt_damage({**sample,'damage_by_weapon':[]}))

    def history(self):
        fixture=fixtures.UpgradeObservationTests();fixture.setUp()
        before=copy.deepcopy(fixture.before);before['buttons']=[card('01','AMPLIFIED PULSE'),card('02','ARC EMITTER'),card('03','MEMORY TETHER')]
        frozen=copy.deepcopy(before);frozen.update(rendered_frames=22,sample_ticks=300)
        selected=copy.deepcopy(frozen);selected.update(state='playing',pending=0,ranks={'damage':1})
        row={'offered':before,'frozen':frozen,'selected':selected,'chosen_text':before['buttons'][0]['text'],'chosen_index':'01','changed_rank':'damage'}
        return {'process':42,'ranks':{}},[row],selected

    def test_history_accounts_for_actual_card_and_single_rank_transaction(self):
        start,rows,final=self.history();saved=copy.deepcopy(rows)
        self.assertTrue(earned_history(start,rows,final))
        self.assertEqual(rows,saved)
        self.assertTrue(earned_history(start,[],start))  # Honest unreached run, not a mutation claim.
        self.assertFalse(earned_history(start,rows,{**final,'ranks':{'damage':2}}))
        self.assertFalse(earned_history(start,rows,{**final,'process':43}))

    def test_history_rejects_wrong_card_stale_panel_and_injected_prior_rank(self):
        for key,value in [('chosen_text','fake'),('chosen_index','02'),('changed_rank','arc')]:
            start,rows,final=self.history();rows[0][key]=value
            self.assertFalse(earned_history(start,rows,final))
        start,rows,final=self.history();rows[0]['frozen']['rendered_panel']=0
        self.assertFalse(earned_history(start,rows,final))
        start,rows,final=self.history();start['ranks']={'arc':1}
        self.assertFalse(earned_history(start,rows,final))

    def test_history_rejects_a_different_visible_card_applying_the_recorded_rank(self):
        start,rows,final=self.history()
        # The log consistently says Arc was tapped, while the actual delta is damage.
        # Merely checking one legal increment and a visible button used to accept this.
        rows[0].update(chosen_text=rows[0]['frozen']['buttons'][1]['text'],chosen_index='02')
        self.assertFalse(earned_history(start,rows,final))

    def test_selected_card_effect_covers_passives_weapons_evolutions_and_badges(self):
        expected={'AMPLIFIED PULSE':'damage','RAPID CYCLER':'rate','PHASE ROUNDS':'pierce',
                  'SERVO OVERDRIVE':'speed','REINFORCED CHASSIS':'health','AEGIS CAPACITOR':'shield',
                  'MEMORY TETHER':'magnet','PLASMA ORBITALS':'orbit','SOLAR HALO':'orbit',
                  'ARC EMITTER':'arc','RAIL LANCE':'rail','SINGULARITY LANCE':'rail',
                  'THERMAL BURST':'thermal','DRONE HIVE':'drone','FIELD REPAIR':'repair'}
        self.assertEqual(CARD_RANKS,expected)
        for title,rank in expected.items():
            with self.subTest(title=title):
                start,rows,final=self.history();before=rows[0]['frozen']
                chosen=card('01',title,badge=True);before['buttons']=[chosen]
                after={**final,'ranks':{rank:1}}
                self.assertEqual(selected_card_rank(chosen,before,after),rank)
                self.assertIsNone(selected_card_rank(chosen,before,{**after,'ranks':{'unrelated':1}}))

    def test_selected_card_effect_rejects_disabled_unknown_and_absent_buttons(self):
        start,rows,final=self.history();before=rows[0]['frozen'];chosen=before['buttons'][0]
        self.assertIsNone(selected_card_rank({**chosen,'disabled':True},before,final))
        self.assertIsNone(selected_card_rank(card('01','FUTURE WEAPON'),before,final))
        self.assertIsNone(selected_card_rank(chosen,{**before,'buttons':[]},final))

    def test_history_rejects_ambiguous_duplicate_buttons(self):
        start,rows,final=self.history()
        rows[0]['frozen']['buttons'].append(copy.deepcopy(rows[0]['frozen']['buttons'][0]))
        self.assertFalse(earned_history(start,rows,final))
