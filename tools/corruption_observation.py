"""Observe a real Redline card transaction without duplicating eligibility rules."""
import math
import re
from upgrade_observation import upgrade_frozen


def redline_terms(text):
    if not isinstance(text, str) or 'REDLINE SYNC' not in text:
        return None
    hp = re.search(r'Maximum HP (\d+)\s*->\s*(\d+)', text)
    cycle = re.search(r'Weapon cycles \+(\d+)%', text)
    if not hp or not cycle:
        return None
    before, after, gain = int(hp[1]), int(hp[2]), int(cycle[1])
    return {'before_max': before, 'after_max': after, 'cycle_gain': gain} if 0 < after < before and gain > 0 else None


def corruption_offer_frozen(before, current):
    return (upgrade_frozen(before, current)
            and all(key in before and key in current and before[key] == current[key] for key in ('health', 'corruption')))


def redline_selected(before, current, text):
    terms = redline_terms(text)
    if terms is None or before.get('state') != 'upgrading' or current.get('state') not in ('playing', 'upgrading'):
        return False
    if before.get('process') is None or current.get('process') != before['process'] or current.get('ranks') != before.get('ranks'):
        return False
    if not isinstance(before.get('ranks'), dict):
        return False
    for sample in (before, current):
        if any(type(sample.get(key)) is not int or sample[key] < 0 for key in ('pending', 'level')) or sample['level'] < 1:
            return False
        if not isinstance(sample.get('health'), dict) or not isinstance(sample.get('corruption'), dict):
            return False
        if any(type(sample['health'].get(key)) not in (int, float) or not math.isfinite(sample['health'][key]) for key in ('current', 'maximum', 'max_shield')):
            return False
    old, new = before['corruption'], current['corruption']
    if not isinstance(old.get('accepted'), list) or 'redline' in old['accepted'] or new.get('accepted') != old['accepted'] + ['redline']:
        return False
    if before['pending'] < 1 or current['level'] < before['level'] or current['pending'] != before['pending'] - 1 + current['level'] - before['level']:
        return False
    if type(new.get('next_level')) is not int or new['next_level'] <= before['level']:
        return False
    if type(new.get('cycle_rate')) not in (int, float) or not math.isclose(new['cycle_rate'], 1 + terms['cycle_gain'] / 100, rel_tol=1e-6):
        return False
    return (before['health']['maximum'] == terms['before_max'] and current['health']['maximum'] == terms['after_max']
            and 0 < current['health']['current'] <= min(before['health']['current'], terms['after_max'])
            and current['health']['max_shield'] == before['health']['max_shield']
            and all(key in old and new.get(key) == old[key] for key in ('enemy_pace', 'walk_rate', 'extra_rounds', 'extra_drones')))
