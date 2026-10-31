extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func visit(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		failures.append("Cannot open " + path)
		return
	for folder in directory.get_directories():
		if folder.begins_with(".") or folder in ["builds", "docs", "tools"]:
			continue
		visit(path.path_join(folder))
	for name in directory.get_files():
		if name.get_extension() not in ["gd", "tscn", "tres", "res", "gdshader"]:
			continue
		checks += 1
		var resource: Resource = ResourceLoader.load(path.path_join(name))
		if resource == null or (resource is Script and not resource.can_instantiate()):
			failures.append(path.path_join(name))

func run() -> void:
	visit("res://")
	QAReport.write("res://builds/qa/resource-validation.json", {"checks": checks, "failures": failures})
	for failure in failures:
		push_error(failure)
	print("RESOURCE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
