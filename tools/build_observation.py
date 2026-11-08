"""Read-only acceptance for navigating a paused, genuinely earned build."""
from upgrade_observation import UPGRADE_FROZEN_FIELDS

BUILD_FROZEN_FIELDS = (*UPGRADE_FROZEN_FIELDS, 'settings', 'selected_kit', 'dash_readiness', 'dashes')


def frozen_navigation(before, current):
    """Require fresh rendered panels and unchanged gameplay across menu touches.

    Panel IDs may change during navigation; each must match its own rendered ID.
    This observes the game rather than reimplementing progression/build rules.
    """
    return (before.get('process') is not None and current.get('process') == before['process']
            and before.get('state') == before.get('rendered_state') == 'paused'
            and current.get('state') == current.get('rendered_state') == 'paused'
            and all(type(s.get('panel')) is int and s['panel'] > 0 and s['panel'] == s.get('rendered_panel') for s in (before, current))
            and current.get('rendered_frames', -1) > before.get('rendered_frames', -1)
            and current.get('sample_ticks', -1) > before.get('sample_ticks', -1)
            and all(key in before and key in current and before[key] == current[key] for key in BUILD_FROZEN_FIELDS))
