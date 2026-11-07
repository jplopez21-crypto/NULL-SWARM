#!/usr/bin/env python3
"""Exercise voluntary results, analysis and cancel from exact APK assets, without source/test imports.
Usage: python3 check_exported_end.py path/to.apk --output receipt.json
Linux headless desktop fixture; does not establish earned Android-run interaction.
"""
import argparse,hashlib,json,os,re,subprocess,sys,tempfile,zipfile
from pathlib import Path,PurePosixPath
RUNNER='''extends SceneTree
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in range(5):
		await process_frame
func click(game: Node3D, text: String) -> void:
	for button in game.ui.screen.find_children("*", "Button", true, false):
		if button.text != text or not button.is_visible_in_tree():
			continue
		var motion := InputEventMouseMotion.new()
		motion.position = button.get_global_rect().get_center()
		root.push_input(motion, true)
		var press := InputEventMouseButton.new()
		press.position = motion.position
		press.button_index = MOUSE_BUTTON_LEFT
		press.button_mask = MOUSE_BUTTON_MASK_LEFT
		press.pressed = true
		root.push_input(press, true)
		press = press.duplicate()
		press.pressed = false
		press.button_mask = 0
		root.push_input(press, true)
		return
	check(false, "missing actual exported control: " + text)
func run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	await settle()
	game.start_run()
	var victim: Node3D = game.combat.spawn(0, Vector3(4, 0, 0))
	victim.hp = 10.0
	game.combat._damage(victim, 5.0, Vector3.ZERO, false, "pulse")
	game.combat._damage(victim, 1000.0, Vector3.ZERO, false, "arcstorm")
	check(game.combat.damage_by_weapon == {"pulse": 5.0, "arcstorm": 5.0}, "exported effective damage excludes overkill")
	game.pause_run()
	await settle()
	click(game, "END DEPLOYMENT")
	await settle()
	check(game.ui.results_heading.text == "DEPLOYMENT ENDED" and game.result_aborted, "actual exported End Deployment opens truthful voluntary results")
	var frozen_save: Dictionary = game.save.data.duplicate(true)
	var frozen_damage: Dictionary = game.combat.damage_by_weapon.duplicate(true)
	var frozen_ranks: Dictionary = game.progress.ranks.duplicate(true)
	var frozen_time: float = game.combat.director.elapsed
	var frozen_rng: int = game.combat.rng.state
	for visit in range(2):
		click(game, "RUN ANALYSIS")
		await settle()
		var text: String = game.ui.visible_run_analysis()
		check(text.contains("PULSE SHOTS") and text.contains("ARCSTORM CHAINS") and text.count("50.0%") == 2, "exported analysis shows both real effective-damage shares")
		var bars: Array[Node] = game.ui.screen.find_children("*", "ProgressBar", true, false)
		check(bars.size() == 2 and bars[0].value == 50.0 and bars[1].value == 50.0, "actual exported graph matches recorded damage")
		game._process(5.0)
		game._physics_process(5.0)
		if visit == 0:
			var cancel := InputEventJoypadButton.new()
			cancel.button_index = JOY_BUTTON_B
			cancel.pressed = true
			root.push_input(cancel, true)
		else:
			var cancel := InputEventKey.new()
			cancel.keycode = KEY_ESCAPE
			cancel.physical_keycode = KEY_ESCAPE
			cancel.pressed = true
			root.push_input(cancel, true)
		await settle()
		check(game.ui.visible_run_analysis().is_empty() and game.state == game.State.RESULTS, "exported B/Escape returns to the same completed run")
		check(game.combat.director.elapsed == frozen_time and game.combat.rng.state == frozen_rng and game.progress.ranks == frozen_ranks and game.combat.damage_by_weapon == frozen_damage and game.save.data == frozen_save, "exported navigation changes no combat stats or reward ledger")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("EXPORTED_ANALYSIS_RESULT ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
'''
def main():
 if sys.platform != "linux":raise SystemExit("This verifier requires Linux for isolated XDG user data; no game was launched.")
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('apk',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args();apk=a.apk.resolve();out=a.output.resolve();out.parent.mkdir(parents=True,exist_ok=True)
 receipt={'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'scope':'Headless desktop fixture using exact APK assets, an external driver, isolated user data and actual production damage/GUI/joypad/key handling. Explicit frozen enemy/HP fixture; not an Android device, earned run, audio listening or performance acceptance.'}
 with tempfile.TemporaryDirectory(prefix='null-swarm-export-analysis-') as isolated:
  root=Path(isolated);pack=root/'exact-assets.zip';driver=root/'driver.gd';driver.write_text(RUNNER);project=root/'empty';project.mkdir()
  with zipfile.ZipFile(apk) as source,zipfile.ZipFile(pack,'w',zipfile.ZIP_DEFLATED) as target:
   for name in source.namelist():
    if name.startswith('assets/') and not name.endswith('/'):
     rel=PurePosixPath(name.removeprefix('assets/'));assert not rel.is_absolute() and '..' not in rel.parts;target.writestr(str(rel),source.read(name))
  env=os.environ.copy()
  for key,suffix in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[key]=str(root/suffix)
  command=['godot','--headless','--path',str(project),'--main-pack',str(pack),'--script',str(driver)]
  try:
   run=subprocess.run(command,cwd=project,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=30);text=run.stdout;receipt['exit_code']=run.returncode
  except subprocess.TimeoutExpired as error:text=(error.stdout or b'').decode() if isinstance(error.stdout,bytes) else error.stdout or '';receipt['exit_code']=None;receipt['timeout_seconds']=30
  out.with_suffix('.log').write_text(text)
  match=re.search(r'^EXPORTED_ANALYSIS_RESULT (.+)$',text,re.M)
  receipt['result']=json.loads(match.group(1)) if match else None
  receipt['errors']=[line for line in text.splitlines() if re.search(r'SCRIPT ERROR|Parse Error|Failed to load|^ERROR:|ObjectDB instances leaked|resources still in use',line)]
  receipt['status']='passed' if receipt['exit_code']==0 and receipt['result'] and receipt['result']['checks']==10 and not receipt['result']['failures'] and not receipt['errors'] else 'failed'
 out.write_text(json.dumps(receipt,indent=2)+'\n');print('EXPORTED_ANALYSIS',receipt['status'],receipt['result']);return 0 if receipt['status']=='passed' else 1
if __name__=='__main__':raise SystemExit(main())
