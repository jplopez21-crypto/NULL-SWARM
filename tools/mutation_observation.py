"""Visible-card selection and read-only Arcstorm acceptance contracts for ADB QA."""
import math
import re
from passive_observation import PASSIVE_LABELS
from upgrade_observation import selected_rank, upgrade_frozen

RECIPE = {'AMPLIFIED PULSE': 'damage', 'ARC EMITTER': 'arc'}
CARD_RANKS = {**{title: key for key, title in PASSIVE_LABELS.items()},
              'PLASMA ORBITALS': 'orbit', 'SOLAR HALO': 'orbit',
              'ARC EMITTER': 'arc', 'RAIL LANCE': 'rail', 'SINGULARITY LANCE': 'rail',
              'THERMAL BURST': 'thermal', 'DRONE HIVE': 'drone', 'FIELD REPAIR': 'repair'}


def card_title(card):
    if not isinstance(card, dict) or card.get('disabled') is not False or not isinstance(card.get('text'), str):
        return None
    lines = [line.strip() for line in card['text'].splitlines() if line.strip()]
    return next((line for line in lines[1:] if not line.startswith('MUTATES:')), None) if lines and re.fullmatch(r'0[123]', lines[0]) else None


def complete(ranks):
    return (isinstance(ranks, dict) and all(type(ranks.get(k, 0)) is int and ranks.get(k, 0)>=3 for k in RECIPE.values()))


def choose_card(cards, ranks):
    if not isinstance(ranks, dict) or any(type(ranks.get(k, 0)) is not int or ranks.get(k, 0)<0 for k in RECIPE.values()):
        raise ValueError('invalid recipe ranks')
    enabled = [(card_title(c), c) for c in cards if card_title(c)]
    targets = [(ranks.get(RECIPE[t], 0), i, c) for i,(t,c) in enumerate(enabled) if t in RECIPE and ranks.get(RECIPE[t],0)<3]
    if targets:
        return min(targets, key=lambda row: row[:2])[2]
    for title in ['MEMORY TETHER','AEGIS CAPACITOR','REINFORCED CHASSIS','RAPID CYCLER','SERVO OVERDRIVE','PHASE ROUNDS','AMPLIFIED PULSE']:
        for t,c in enabled:
            if t==title and t in PASSIVE_LABELS.values():return c
    return enabled[0][1] if enabled else None


def recipe_cards_valid(cards, ranks):
    if not isinstance(ranks, dict) or any(type(ranks.get(k,0)) is not int or ranks.get(k,0)<0 for k in RECIPE.values()):
        return False
    expected=f'Pulse {min(3,ranks.get("damage",0))}/3 + Arc {min(3,ranks.get("arc",0))}/3'
    return all(expected in c['text'] for c in cards if card_title(c) in RECIPE)


def active_build(sample):
    return (sample.get('state')==sample.get('rendered_state')=='paused' and type(sample.get('panel')) is int and sample['panel']>0
            and sample['panel']==sample.get('rendered_panel') and complete(sample.get('ranks'))
            and isinstance(sample.get('build_text'),str) and {'01 // ARCSTORM RIFLE','ARCSTORM RIFLE // ACTIVE'}.issubset(set(sample['build_text'].splitlines())))


def dealt_damage(sample):
    damage=sample.get('damage_by_weapon',{})
    if not isinstance(damage,dict):return False
    amount=damage.get('arcstorm',0)
    return complete(sample.get('ranks')) and type(amount) in (int,float) and math.isfinite(amount) and amount>0


def selected_card_rank(card, before, current):
    """Require the visible selected card's effect, not merely any rank increment."""
    expected = CARD_RANKS.get(card_title(card))
    if expected is None:
        return None
    matches = [c for c in before.get('buttons', []) if card_title(c) and c['text'] == card['text']]
    if len(matches) != 1:
        return None
    return expected if selected_rank(before, current) == expected else None


def earned_history(start, transactions, final):
    previous=start.get('ranks');process=start.get('process')
    if process is None or not isinstance(previous,dict) or final.get('process')!=process:return False
    for t in transactions:
        before,frozen,after=(t.get(k,{}) for k in ('offered','frozen','selected'))
        if before.get('process')!=process or before.get('ranks')!=previous or not upgrade_frozen(before,frozen):return False
        cards=[c for c in frozen.get('buttons',[]) if card_title(c)]
        chosen=[c for c in cards if c['text']==t.get('chosen_text') and c['text'].startswith(t.get('chosen_index','')+'\n')]
        if (len(chosen)!=1 or t.get('chosen_index') not in ('01','02','03')
                or not recipe_cards_valid(cards,frozen.get('ranks'))):
            return False
        changed=selected_card_rank(chosen[0],frozen,after)
        if not changed or changed!=t.get('changed_rank'):
            return False
        previous=after['ranks']
    return final.get('ranks')==previous
