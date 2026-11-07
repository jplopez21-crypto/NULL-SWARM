#!/usr/bin/env python3
"""Configure an isolated x86_64 read-only probe export; production settings stay separate."""
import argparse
from configparser import ConfigParser
from pathlib import Path
import re


def configure(project, renderer='gl_compatibility'):
    if renderer not in ('gl_compatibility', 'mobile'):
        raise ValueError('Unsupported emulator renderer')
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
    args = parser.parse_args()
    print('EMULATOR_EXPORT', configure(args.project, args.renderer), args.renderer)


if __name__ == '__main__': main()
