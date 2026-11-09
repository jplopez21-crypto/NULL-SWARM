import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / 'tools'))
from passive_observation import passive_card, passive_summary_matches


class PassiveObservationTests(unittest.TestCase):
    def test_real_spaced_card_prefers_passive_without_mutating_offer(self):
        cards = [{'text': '01\n\nARC EMITTER\nNEW WEAPON // CHAIN', 'disabled': False},
                 {'text': '02\n\nRAPID CYCLER\nCooldown .50s → .44s', 'disabled': False}]
        before = copy.deepcopy(cards)
        self.assertIs(passive_card(cards), cards[1])
        self.assertEqual(cards, before)

    def test_disabled_unknown_unindexed_and_malformed_cards_are_rejected(self):
        for card in [None, {}, {'text': 3, 'disabled': False},
                     {'text': '02\nRAPID CYCLER', 'disabled': True},
                     {'text': 'RAPID CYCLER', 'disabled': False},
                     {'text': '04\nRAPID CYCLER', 'disabled': False},
                     {'text': '01\nUNKNOWN UPLINK', 'disabled': False},
                     {'text': '01\nARC EMITTER\nRANK 1 → 2', 'disabled': False}]:
            with self.subTest(card=card):self.assertIsNone(passive_card([card]))

    def test_summary_reports_current_ranks_independently_of_recipe_text(self):
        text = 'AMPLIFIED PULSE 2/3 + ARC EMITTER 0/3\nPASSIVE UPLINKS // AMPLIFIED PULSE 2/7   •   AEGIS CAPACITOR 1/5\nBack'
        self.assertTrue(passive_summary_matches(text, {'damage': 2, 'shield': 1, 'arc': 1, 'repair': 5}))
        self.assertFalse(passive_summary_matches('AMPLIFIED PULSE 2/3', {'damage': 2}))

    def test_missing_extra_repeated_wrong_rank_and_impossible_cap_are_rejected(self):
        for body in ['NONE YET // COLLECT MEMORY TO UPGRADE', 'AMPLIFIED PULSE 1/7',
                     'AMPLIFIED PULSE 2/1', 'AMPLIFIED PULSE 2/7 • AMPLIFIED PULSE 2/7',
                     'AMPLIFIED PULSE 2/7 • RAPID CYCLER 1/7', 'UNKNOWN 2/7']:
            with self.subTest(body=body):self.assertFalse(passive_summary_matches('PASSIVE UPLINKS // '+body, {'damage': 2}))

    def test_honest_empty_summary_and_duplicate_rows(self):
        text = 'PASSIVE UPLINKS // NONE YET // COLLECT MEMORY TO UPGRADE'
        self.assertTrue(passive_summary_matches(text, {'orbit': 1}))
        self.assertFalse(passive_summary_matches(text, {'rate': 1}))
        self.assertFalse(passive_summary_matches(text+'\n'+text, {}))

    def test_incomplete_or_invalid_observations_are_rejected(self):
        for text, ranks in [(None, {}), ('', None), ('', {}),
                            ('PASSIVE UPLINKS // RAPID CYCLER 1/7', {'rate': True}),
                            ('PASSIVE UPLINKS // RAPID CYCLER 1/7', {'rate': -1})]:
            with self.subTest(text=text, ranks=ranks):self.assertFalse(passive_summary_matches(text, ranks))


if __name__ == '__main__':unittest.main()
