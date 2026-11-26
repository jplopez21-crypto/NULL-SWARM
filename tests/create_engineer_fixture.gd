extends SceneTree

func _initialize() -> void:
	# Explicit synthetic earned-kit data for Android GUI testing only. This script
	# is excluded from APKs; the Android game/probe has no Engineer grant switch.
	var store := SaveStore.new()
	store.data = SaveStore.defaults()
	store.data["runs"] = 1
	store.data["wardens"] = 1
	store.data["architects"] = 1
	store.data["salvaged_kills"] = 150
	var code := store.backup_code()
	if code.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://builds/qa")
	QAReport.text_file("res://builds/qa/engineer-fixture.txt", code)
	print("ENGINEER_FIXTURE_CREATED synthetic_earned_kit=true")
	quit()
