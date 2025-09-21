extends Node2D
@onready var drone: CharacterBody2D = $"../Drone"
@onready var http_request: HTTPRequest = $"../HTTPRequest"
const FALLBACK_API = "APIkey"
var GEMINI_API_KEY = "apiKey2"
const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="
var Buildings_data := []

signal score_received(score: int, details: Dictionary)

var RULES = """
Scoring Rules:
Base Score:
- Each Asset Placed Correctly = +10
- Wrong/Misplaced Asset = -5

Proximity Rules:
- School near Houses = +15
- Hospital near Houses = +15
- Farm near Water Source = +20
- Solar Panel near House/School/Hospital = +10
- Well/Water Tank near Houses = +15
- Roads connect all major assets = +30

Penalty Rules:
- Farm too close to Houses = -10
- Hospital far from Road = -15
- Solar Panels in Forest/Green Zones = -20
- Assets disconnected (no road link) = -25
- Roads too close to Farms = -10
- Buildings overlapping other buildings = -20
- Wells too far from Houses = -15
- Roads overlapping buildings = -15
- Any asset placed outside the allowed map area = -20

Bonus Points:
- Clustered community (Houses + School + Hospital nearby) = +30
- Balanced mix (Food + Education + Energy) = +40
- Road network connects >80% of assets = +50
"""

func _on_data_ready():
	print("sending prompt. . .")

	var prompt = RULES + "\n\nHere is the list of placed buildings:\n" + JSON.stringify(Buildings_data) + """
Please calculate the total score based on the rules above. 
Reply ONLY in JSON with this format:
{
  "score": <number>,
  "details": {
	"Base": <number>,
	"Proximity": <number>,
	"Penalties": <number>,
	"Bonus": <number>
  }
}
"""
	send_gemini_request(prompt)


func send_gemini_request(prompt: String):
	var url = GEMINI_URL + GEMINI_API_KEY
	var headers = ["Content-Type: application/json"]

	var data = {
		"contents": [{
			"parts": [{"text": prompt}]
		}]
	}

	var json_data = JSON.stringify(data)
	print("requesting to api .. . ")
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Request error:", error)

func is_building_info_empty(info: Dictionary) -> bool:
	for key in info.keys():
		var value = info[key]
		if value != null and str(value).strip_edges() != "":
			return false
	return true
func _on_farm_building_placed(buildings_data: Array, current_budget: Variant) -> void:
	# Store the buildings data
	Buildings_data = buildings_data

	# Only send to Gemini if there is at least one building
	if Buildings_data.size() > 0:
		_on_data_ready()  # Sends the prompt to Gemini
	# Increment drone score  
	drone.THEscore += 1
	# Example: check neighbors (optional)
	for i in range(Buildings_data.size()):
		var b1 = Buildings_data[i]
		for j in range(i + 1, Buildings_data.size()):
			var b2 = Buildings_data[j]
			var dist = b1["position"].distance_to(b2["position"])
			if dist < 100:
				pass  # you can handle proximity logic here

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Result:", result)
	print("HTTP Code:", response_code)
	print("Body:", body.get_string_from_utf8())

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("candidates"):
			var reply_text = json["candidates"][0]["content"]["parts"][0]["text"]
			print("Raw reply:", reply_text)
			var rep = reply_text.substr(7, reply_text.length() - 7)
			rep = rep.substr(0, rep.length() - 4)
			var reply_json = JSON.parse_string(rep)
			if typeof(reply_json) == TYPE_DICTIONARY:
				print("✅ Final Score:", reply_json["score"])
				print("Details:", reply_json["details"])
				emit_signal("score_received", reply_json["score"], reply_json["details"])

			if typeof(reply_json) == TYPE_DICTIONARY:
				print("✅ Final Score:", reply_json["score"])
				print("Details:", reply_json["details"])
			else:
				print("⚠️ Gemini reply not JSON:", reply_text)
		else:
			print("⚠️ No 'candidates' in response")
	else:
		print("❌ Error:", response_code, body.get_string_from_utf8())
