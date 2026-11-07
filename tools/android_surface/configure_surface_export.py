#!/usr/bin/env python3
"""Disposable diagnostic preset only; never changes the committed production preset."""
import argparse
from configparser import ConfigParser
from pathlib import Path
import shutil

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--variant',choices=['control','latched'],required=True)
args=parser.parse_args()
config=ConfigParser(interpolation=None);config.optionxform=str;config.read('export_presets.cfg')
config['preset.0.options']['gradle_build/use_gradle_build']='true'
config['preset.0.options']['package/unique_name']='"com.nullswarm.game.surface'+args.variant+'"'
config['preset.0.options']['package/name']='"NULL SWARM Surface '+args.variant+'"'
config['preset.0']['include_filter']='"resources/diagnostics_surface/*.txt"'
with Path('export_presets.cfg').open('w') as f:config.write(f)
assets=Path('resources/diagnostics_surface');assets.mkdir(parents=True,exist_ok=True)
shutil.copyfile(Path(__file__).parent/'Apache-2.0.txt',assets/'Apache-2.0.txt')
(assets/'NOTICE.txt').write_text('GLSurfaceView: Copyright (C) 2008 The Android Open Source Project. Apache License 2.0.\nGodot 4.6.3 source blob 8b25fdfeceb6dcc273646005137a92f161755558.\nNULL//SWARM diagnostic '+args.variant+' rebuild; latched variant adds nonblocking lifecycle-edge recovery.\nNot a production engine upgrade or physical-device certification.\n')
