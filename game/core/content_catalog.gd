extends RefCounted

const CONTENT_PATH := "res://data/content.json"

var items: Dictionary = {}
var recipes: Dictionary = {}
var sites: Dictionary = {}
var trade_offers: Dictionary = {}
var errors: Array[String] = []


func _init() -> void:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Catalogue introuvable : " + CONTENT_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Catalogue JSON invalide")
		return
	for item in parsed.get("items", []):
		if item is Dictionary and item.has("id"):
			items[item["id"]] = item
	for key in parsed.get("recipes", {}):
		recipes[key] = parsed["recipes"][key]
	for key in parsed.get("trade_offers", {}):
		trade_offers[key] = parsed["trade_offers"][key]
	for site in parsed.get("sites", []):
		if site is Dictionary and site.has("id"):
			sites[site["id"]] = site
	for recipe in recipes.values():
		for item_id in recipe.get("inputs", {}):
			if not items.has(item_id):
				push_error("Objet inconnu dans une recette : " + item_id)
	for site in sites.values():
		for drop in site.get("loot", []):
			if not items.has(drop.get("item", "")):
				push_error("Objet inconnu dans un lieu : " + str(site.get("id", "")))
	for offer_id in trade_offers:
		var offer: Dictionary = trade_offers[offer_id]
		if int(offer.get("limit", 0)) <= 0:
			errors.append("Limite de troc invalide : " + str(offer_id))
		for field in ["give", "receive"]:
			if not offer.get(field) is Dictionary or offer[field].is_empty():
				errors.append("Troc incomplet : " + str(offer_id))
				continue
			for item_id in offer[field]:
				if not items.has(item_id) or int(offer[field][item_id]) <= 0:
					errors.append("Objet ou quantité de troc invalide : " + str(offer_id))
	for message in errors:
		push_error(message)


func item_name(item_id: String) -> String:
	return str(items.get(item_id, {}).get("name", item_id))


func item_weight(item_id: String) -> int:
	return int(items.get(item_id, {}).get("weight", 1))
