#!/usr/bin/env python3
"""Make a disposable x86_64 Compatibility/probe export; never commit generated edits."""
from configparser import ConfigParser
from pathlib import Path

config = ConfigParser(interpolation=None)
config.optionxform = str
config.read('export_presets.cfg')
options = config['preset.0.options']
options['architectures/arm64-v8a'] = 'false'
options['architectures/x86_64'] = 'true'
options['package/unique_name'] = '"com.nullswarm.game.emulatorqa"'
options['package/name'] = '"NULL SWARM Emulator QA"'
with open('export_presets.cfg', 'w') as target:
    config.write(target)
project = Path('project.godot')
text = project.read_text().replace('renderer/rendering_method="mobile"', 'renderer/rendering_method="gl_compatibility"').replace('renderer/rendering_method.mobile="mobile"', 'renderer/rendering_method.mobile="gl_compatibility"')
project.write_text(text + '\n[qa]\nandroid_runtime_probe=true\n')
