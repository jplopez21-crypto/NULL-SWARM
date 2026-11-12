"""Read-only predicates for observing ordinary XP/upgrade touch transactions."""
from lifecycle_observation import FROZEN_FIELDS

UPGRADE_FROZEN_FIELDS = FROZEN_FIELDS + ('level', 'pending')


def upgrade_frozen(before, current):
    return (before.get('state') == before.get('rendered_state') == current.get('state') == current.get('rendered_state') == 'upgrading'
            and before.get('process') is not None and current.get('process') == before['process']
            and current.get('panel') is not None and current['panel'] == before.get('panel') == before.get('rendered_panel') == current.get('rendered_panel')
            and current.get('rendered_frames', -1) > before.get('rendered_frames', -1)
            and current.get('sample_ticks', -1) > before.get('sample_ticks', -1)
            and all(key in before and current.get(key) == before[key] for key in UPGRADE_FROZEN_FIELDS))


def selected_rank(before, current):
    """One rank per tap, allowing new XP levels after the game resumes.

    This observes the early XP-only smoke, without cache/corruption rewards.
    It does not duplicate the game's eligibility or weapon balance rules.
    """
    if before.get('process') is None or current.get('process') != before['process']:
        return None
    if before.get('state') != 'upgrading' or current.get('state') not in ('upgrading', 'playing'):
        return None
    for sample in [before, current]:
        if not isinstance(sample.get('ranks'), dict):
            return None
        values = list(sample['ranks'].values()) + [sample.get('pending'), sample.get('level')]
        if any(type(value) is not int or value < 0 for value in values) or sample['level'] < 1:
            return None
    if before['pending'] < 1 or current['level'] < before['level']:
        return None
    previous, ranks = before['ranks'], current['ranks']
    if not set(previous).issubset(ranks):
        return None
    changes = {key: ranks.get(key, 0) - previous.get(key, 0) for key in set(previous) | set(ranks)}
    changed = [key for key, value in changes.items() if value != 0]
    if len(changed) != 1 or changes[changed[0]] != 1:
        return None
    # Resumed pickup collection can earn new choices between probe snapshots.
    if current['pending'] != before['pending'] - 1 + current['level'] - before['level']:
        return None
    return changed[0]
