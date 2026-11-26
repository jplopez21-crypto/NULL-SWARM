"""Classify observed touch delivery; never inject, retry or advance the game."""
import math


def describe_delivery(before, current, target):
    result = {'status': 'inconclusive'}
    if (before.get('process') is None or current.get('process') != before['process']
            or type(before.get('sample_ticks')) is not int or type(current.get('sample_ticks')) is not int
            or current['sample_ticks'] <= before['sample_ticks']):
        return result
    if (not isinstance(target, (list, tuple)) or len(target) != 2
            or any(type(n) not in (int, float) or not math.isfinite(n) for n in target)):
        return result
    old, new = before.get('input_delivery'), current.get('input_delivery')
    if not isinstance(old, dict) or not isinstance(new, dict):
        return result
    if any(type(s.get(k)) is not int or s[k] < 0 for s in (old, new) for k in ('presses', 'releases')):
        return result
    if any(type(s.get('window_focused')) is not bool for s in (old, new)):
        return result
    if any(new[k] < old[k] for k in ('presses', 'releases')):
        return result
    recent = new.get('recent')
    if not isinstance(recent, list) or len(recent) > 8:
        return result
    previous_sequence = 0
    for event in recent:
        if (not isinstance(event, dict) or type(event.get('sequence')) is not int
                or event['sequence'] <= previous_sequence
                or type(event.get('index')) is not int or not 0 <= event['index'] <= 31
                or type(event.get('pressed')) is not bool or type(event.get('canceled')) is not bool
                or type(event.get('ticks')) is not int or event['ticks'] < 0
                or not isinstance(event.get('position'), list) or len(event['position']) != 2
                or any(type(n) not in (int, float) or not math.isfinite(n) for n in event['position'])):
            return result
        previous_sequence = event['sequence']
    start, end = old['presses'] + old['releases'], new['presses'] + new['releases']
    events = [e for e in recent if e['sequence'] > start]
    complete = end - start <= 8 and [e['sequence'] for e in events] == list(range(start + 1, end + 1))
    result.update(press_delta=new['presses'] - old['presses'], release_delta=new['releases'] - old['releases'],
                  history_complete=complete, window_focused_before=old['window_focused'], window_focused_after=new['window_focused'])
    if not complete or any(e['ticks'] < before['sample_ticks'] or e['ticks'] > current['sample_ticks'] for e in events):
        return result
    if sum(e['pressed'] for e in events) != result['press_delta'] or sum(not e['pressed'] for e in events) != result['release_delta']:
        return result
    matches = [e for e in events if all(abs(e['position'][i] - target[i]) <= 2 for i in (0, 1))]
    if not events:
        result['status'] = 'not_observed_by_game'
    elif any(e['canceled'] for e in matches):
        result['status'] = 'touch_canceled'
    elif any(a['pressed'] and not b['pressed'] and a['index'] == b['index'] and a['sequence'] < b['sequence']
             for a in matches for b in matches):
        result['status'] = 'delivered_at_target'
    elif any(e['pressed'] for e in matches):
        result['status'] = 'press_without_release'
    else:
        result['status'] = 'delivered_elsewhere'
    return result
