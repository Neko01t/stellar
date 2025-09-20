extends Node2D
@onready var drone: CharacterBody2D = $"../Drone"

@onready var http_request: HTTPRequest = $"../HTTPRequest"

var GEMINI_API_KEY = "AIzaSyCKTgkY2Q2jzybFP-uHq2cXbl9QBHGC0cs"
var GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="

func _ready():
	print("sending prompt. . .")
	var prompt = "Hello Gemini! Tell me a joke."
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


func _on_farm_building_placed(buildings_data: Variant, current_budget: Variant) -> void:
	print("Buildings data:", buildings_data)
	print("Current budget:", current_budget)
	drone.score += 1
	# Example: check neighbors
	for i in range(buildings_data.size()):
		var b1 = buildings_data[i]
		for j in range(i+1, buildings_data.size()):
			var b2 = buildings_data[j]
			var dist = b1["position"].distance_to(b2["position"])
			if dist < 100:  # adjust distance threshold as needed
				print(b1["name"], " is near ", b2["name"])


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Result:", result)
	print("HTTP Code:", response_code)
	print("Body:", body.get_string_from_utf8())

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Parsed JSON:", json)
		if json and json.has("candidates"):
			var reply = json["candidates"][0]["content"]["parts"][0]["text"]
			print("val", reply)
		else:
			print("⚠️ No 'candidates' in response")
	else:
		print("❌ Error:", response_code, body.get_string_from_utf8())
