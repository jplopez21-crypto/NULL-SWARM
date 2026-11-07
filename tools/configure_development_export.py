#!/usr/bin/env python3
"""Isolate the CI ARM64 development app from previously distributed game builds."""
from configparser import ConfigParser

config = ConfigParser(interpolation=None)
config.optionxform = str
config.read('export_presets.cfg')
config['preset.0.options']['package/unique_name'] = '"com.nullswarm.game.development"'
config['preset.0.options']['package/name'] = '"NULL SWARM Development"'
with open('export_presets.cfg', 'w') as target:
    config.write(target)
