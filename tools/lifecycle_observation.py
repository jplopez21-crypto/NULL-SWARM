"""Read-only acceptance predicates shared by Android lifecycle diagnostics."""
FROZEN_FIELDS = ('time', 'position', 'hp', 'kills', 'xp', 'ranks', 'combat_rng', 'damage_by_weapon', 'salvage')

def fresh_resumed_frame(before, current):
    old = before.get('lifecycle', {})
    now = current.get('lifecycle', {})
    generation = now.get('foreground_generation', -1)
    return (before.get('process') is not None and current.get('process') == before.get('process')
            and current.get('state') == current.get('rendered_state') == 'paused'
            and current.get('panel') == current.get('rendered_panel')
            and current.get('sample_ticks', -1) > before.get('sample_ticks', -1)
            and current.get('rendered_frames', -1) > before.get('rendered_frames', -1)
            and generation > old.get('foreground_generation', 0)
            and now.get('rendered_generation', -1) == generation)

def frozen_run(before, current):
    return current.get('state') == 'paused' and all(key in before and current.get(key) == before[key] for key in FROZEN_FIELDS)

def app_egl_failures(log, process):
    # Count the GLThread warning once; the driver error is the same failed swap.
    return [line for line in log.splitlines() if len(line.split()) > 3
            and line.split()[2] == str(process) and 'eglSwapBuffers failed: EGL_BAD_SURFACE' in line]
