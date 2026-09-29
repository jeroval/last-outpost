extends RefCounted

var path: String
var preserve_backup := false


func _init(save_path := "user://last_outpost_station_v1.json") -> void:
	path = save_path


func exists() -> bool:
	if OS.has_feature("web"):
		var browser := _read_web()
		if not str(browser.get("primary", "")).is_empty() or not str(browser.get("backup", "")).is_empty():
			return true
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")


func save(state: RefCounted) -> Dictionary:
	# The small browser snapshot is committed synchronously. FileAccess's Web
	# filesystem synchronizes asynchronously and may lag behind a page reload.
	if OS.has_feature("web"):
		return _save_web(state)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Impossible d'écrire la sauvegarde. La précédente est conservée."}
	file.store_string(JSON.stringify(state.snapshot()))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return {"ok": false, "message": "Écriture incomplète. La sauvegarde précédente est conservée."}
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) and not preserve_backup:
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			return {"ok": false, "message": "La sauvegarde précédente n'a pas pu être protégée."}
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		return {"ok": false, "message": "La nouvelle sauvegarde n'a pas pu être installée."}
	preserve_backup = false
	return {"ok": true, "message": "Partie sauvegardée. Vous pouvez reprendre depuis l'accueil."}


func load_into(state: RefCounted, living_only := false) -> Dictionary:
	if OS.has_feature("web"):
		var browser := _read_web()
		if not bool(browser.get("ok", false)):
			return {"ok": false, "message": "Le navigateur bloque l'accès à la sauvegarde. Autorisez le stockage local pour reprendre."}
		if not str(browser["primary"]).is_empty() or not str(browser["backup"]).is_empty():
			for candidate in ["primary", "backup"]:
				if _restore_text(state, str(browser[candidate]), living_only):
					preserve_backup = candidate == "backup"
					return {"ok": true, "message": "Sauvegarde de secours chargée." if candidate == "backup" else "Partie reprise."}
			return {"ok": false, "message": "Aucune sauvegarde valide trouvée. Vous pouvez commencer une nouvelle partie."}
		# Older Web builds used user://. Preserve that migration path; the next
		# successful save writes the validated state to the browser store.
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		if _restore_text(state, FileAccess.get_file_as_string(candidate), living_only):
			preserve_backup = candidate.ends_with(".bak")
			return {"ok": true, "message": "Sauvegarde de secours chargée." if candidate.ends_with(".bak") else "Partie reprise."}
	return {"ok": false, "message": "Aucune sauvegarde valide trouvée. Vous pouvez commencer une nouvelle partie."}


func _restore_text(state: RefCounted, text: String, living_only: bool) -> bool:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return false
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return false
	if living_only:
		var health: Variant = parsed.get("health", null)
		if not (health is int or health is float) or not is_finite(float(health)) or float(health) <= 0:
			return false
	return state.restore(parsed)


func _read_web() -> Dictionary:
	var key := JSON.stringify("last-outpost:" + path)
	var script := "(function(){try { const s=window.localStorage, k=%s; return JSON.stringify({ok:true,primary:s.getItem(k)||'',backup:s.getItem(k+'.bak')||''}); } catch(e) { return JSON.stringify({ok:false}); }})()" % key
	var raw: Variant = JavaScriptBridge.eval(script, true)
	if raw is String:
		var data: Variant = JSON.parse_string(raw)
		if data is Dictionary:
			return data
	return {"ok": false}


func _save_web(state: RefCounted) -> Dictionary:
	var key := JSON.stringify("last-outpost:" + path)
	var payload := JSON.stringify(JSON.stringify(state.snapshot()))
	# JSON encoding is required for both JavaScript string arguments. Never
	# concatenate raw save data into executable JavaScript.
	var script := "(function(){try { const s=window.localStorage, k=%s, value=%s, old=s.getItem(k); if(old!==null && !%s) s.setItem(k+'.bak',old); s.setItem(k,value); return s.getItem(k)===value; } catch(e) { return false; }})()" % [key, payload, JSON.stringify(preserve_backup)]
	var written: Variant = JavaScriptBridge.eval(script, true)
	if written == true:
		preserve_backup = false
		return {"ok": true, "message": "Partie sauvegardée dans ce navigateur. Vous pouvez fermer l'onglet."}
	return {"ok": false, "message": "Sauvegarde impossible : le stockage du navigateur est bloqué ou plein. Gardez la partie ouverte."}
