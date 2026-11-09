"""UI acceptance contracts, not copies of upgrade eligibility or balance rules."""
import re

PASSIVE_LABELS = {
    'damage': 'AMPLIFIED PULSE', 'rate': 'RAPID CYCLER', 'pierce': 'PHASE ROUNDS',
    'speed': 'SERVO OVERDRIVE', 'health': 'REINFORCED CHASSIS',
    'shield': 'AEGIS CAPACITOR', 'magnet': 'MEMORY TETHER',
}
PREFIX = 'PASSIVE UPLINKS // '


def passive_card(cards):
    """Choose an actual enabled indexed passive button, retaining its UI data."""
    for card in cards:
        if not isinstance(card, dict) or card.get('disabled') is not False or not isinstance(card.get('text'), str):
            continue
        lines = [' '.join(line.split()) for line in card['text'].splitlines() if line.strip()]
        if len(lines) >= 2 and lines[0] in ('01', '02', '03') and lines[1] in PASSIVE_LABELS.values():
            return card
    return None


def passive_summary_matches(text, ranks):
    """Compare the dedicated summary to earned ranks; recipes cannot stand in.

    Caps must be present and at least the observed rank. Exact balance caps are
    covered by engine/UI tests, rather than being duplicated in the ADB driver.
    """
    if not isinstance(text, str) or not isinstance(ranks, dict):
        return False
    expected = {}
    for key, title in PASSIVE_LABELS.items():
        rank = ranks.get(key, 0)
        if type(rank) is not int or rank < 0:
            return False
        if rank > 0:
            expected[title] = rank
    rows = [line for line in text.splitlines() if line.startswith(PREFIX)]
    if len(rows) != 1:
        return False
    body = rows[0][len(PREFIX):]
    if not expected:
        return body == 'NONE YET // COLLECT MEMORY TO UPGRADE'
    observed = {}
    for entry in body.split('•'):
        match = re.fullmatch(r'(.+?) (\d+)/(\d+)', entry.strip())
        if not match:
            return False
        title, rank, cap = match[1], int(match[2]), int(match[3])
        if title not in PASSIVE_LABELS.values() or title in observed or rank < 1 or cap < rank:
            return False
        observed[title] = rank
    return observed == expected
