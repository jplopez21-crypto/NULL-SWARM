#!/usr/bin/env python3
"""Configure an isolated x86_64 read-only probe export; production settings stay separate."""
import argparse
from configparser import ConfigParser
from pathlib import Path
import re


def configure(project, renderer='gl_compatibility', disable_frame_pacing=False):
    if renderer not in ('gl_compatibility', 'mobile'):
        raise ValueError('Unsupported emulator renderer')
    if disable_frame_pacing and renderer != 'mobile':
        raise ValueError('Frame-pacing workaround is limited to the Mobile emulator')
    preset = project / 'export_presets.cfg'
    config = ConfigParser(interpolation=None); config.optionxform = str
    config.read(preset)
    options = config['preset.0.options']
    options['architectures/arm64-v8a'] = 'false'
    options['architectures/x86_64'] = 'true'
    package = 'com.nullswarm.game.mobileqa' if renderer == 'mobile' else 'com.nullswarm.game.emulatorqa'
    options['package/unique_name'] = '"' + package + '"'
    options['package/name'] = '"NULL SWARM Mobile QA"' if renderer == 'mobile' else '"NULL SWARM Emulator QA"'
    project_file = project / 'project.godot'
    text = project_file.read_text()
    for key in ['renderer/rendering_method', 'renderer/rendering_method.mobile']:
        text, count = re.subn(r'^' + re.escape(key) + r'="[^"]*"$', key + '="' + renderer + '"', text, flags=re.M)
        if count != 1:
            raise ValueError('Missing/ambiguous rendering setting: ' + key)
    if disable_frame_pacing:
        key = 'window/frame_pacing/android/enable_frame_pacing'
        if re.search(r'^' + re.escape(key) + r'=', text, flags=re.M):
            text, count = re.subn(r'^' + re.escape(key) + r'=(?:true|false)$', key + '=false', text, flags=re.M)
        else:
            text, count = re.subn(r'^\[display\]$', '[display]\n' + key + '=false', text, flags=re.M)
        if count != 1:
            raise ValueError('Missing/ambiguous emulator frame-pacing setting')
    if re.search(r'^\[qa\]$', text, flags=re.M):
        text, count = re.subn(r'^android_runtime_probe=(?:true|false)$', 'android_runtime_probe=true', text, flags=re.M)
        if count != 1:
            raise ValueError('Missing/ambiguous existing probe setting')
    else:
        text += '\n[qa]\nandroid_runtime_probe=true\n'
    # Validate all source anchors before writing either disposable config file.
    with preset.open('w') as target: config.write(target)
    project_file.write_text(text)
    return package


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path('.'))
    parser.add_argument('--renderer', choices=['gl_compatibility', 'mobile'], default='gl_compatibility')
    parser.add_argument('--disable-emulator-frame-pacing', action='store_true', help='Mobile software-emulator workaround only; does not change phone exports')
    args = parser.parse_args()
    print('EMULATOR_EXPORT', configure(args.project, args.renderer, args.disable_emulator_frame_pacing), args.renderer, 'frame_pacing_override=' + ('off' if args.disable_emulator_frame_pacing else 'unchanged'))


if __name__ == '__main__': main()
