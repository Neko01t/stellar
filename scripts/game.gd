extends Node2D
var SCORE : int=0
@onready var fog_map: TileMapLayer = $Tiles/Fog
@onready var ground_map: TileMapLayer = $Tiles/Ground
@onready var ui_label: Label = $Meslasyer/Message
@onready var menu: CanvasLayer = $Menu
var budget: int = 100000 
@onready var budget_label: Label = $Menu/VBoxContainer/Label
var click_pos :Vector2 
var building_costs = {
	"house": 5000,
	"road": 2000,
	"solar": 8000,
	"straight": 2000,
	"curve":2500,
	"t_intersection":3000,
	"cross" : 3500
}
var selected_building_type: String = "house"
var is_menu :bool = false
var pops :PackedScene = preload("res://scenes/popup.tscn")
var roads:={
	"straight": preload("res://scenes/straight_road.tscn"),
	"curve": preload("res://scenes/cruve_straight.tscn"),
	"t_intersection": preload("res://scenes/t_intersection.tscn"),
	"cross": preload("res://scenes/cross_road.tscn")
}

@export var building_scene: PackedScene
@export var road_scene: PackedScene
@export var solar_scene: PackedScene
@onready var drone = $Drone
func _ready() -> void:
	menu.visible = false
func _unhandled_input(event: InputEvent) -> void:
	if drone.is_landed and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos = get_global_mouse_position()
			click_pos = world_pos
			var tile_pos = ground_map.local_to_map(world_pos)
			print("Placing building at tile:", tile_pos, " -> position:", ground_map.map_to_local(tile_pos))
			if fog_map.get_cell_source_id(tile_pos) != -1:
				show_message("Survey the area first!")
				return
			place_building(tile_pos,selected_building_type)

func place_building(tile_pos: Vector2i,type: String = "house") -> void:
	var cost = building_costs.get(type, 0)
	budget_label.text  = str(budget)+"$"
	var building
	if type == "house":
		building = building_scene.instantiate()
	elif type == "road":
		print(cost)
		building = road_scene.instantiate()
	elif type == "solar":
		building = solar_scene.instantiate()
	elif type == "straight":
		building = roads["straight"].instantiate()
	elif type == "t_intersection":
		building = roads["t_intersection"].instantiate()
	elif type == "curve":
		building = roads["curve"].instantiate()
	elif type == "cross":
		building = roads["cross"].instantiate()
	else:
		building = building_scene.instantiate()	
	budget -= cost
	drone.score += 10

	if budget < cost:
		show_message("Not enough budget!")
		return
	ground_map.add_child(building)  
	building.position = ground_map.map_to_local(tile_pos)
	building.z_index = 2
	drone.score += 10
	show_message("Building placed! +10 points")



func show_message(text: String) -> void:
	var screen_pos = click_pos if click_pos != null else get_global_mouse_position()
	$Meslasyer.position = screen_pos

	ui_label.position = Vector2(20, -20)  
	ui_label.text = text
	ui_label.visible = true

	var col = ui_label.modulate
	col.a = 1.0
	ui_label.modulate = col

	var tw = create_tween()
	tw.tween_property(ui_label, "modulate:a", 0.0, 0.8)

func _on_house_pressed() -> void:
	selected_building_type = "house"
	show_message("Selected: House")


func _on_road_pressed() -> void:
	selected_building_type = "road"
	show_message("Selected: road")
	_show_popup()


func _on_solar_pressed() -> void:
	selected_building_type = "solar"
	show_message("Selected: solar")

func _show_popup():
	var popup_instance = pops.instantiate()
	add_child(popup_instance)
	popup_instance.connect("road_selected", Callable(self, "_on_popup_signal"))

func _on_popup_signal(road_name):
	selected_building_type = road_name
	show_message(road_name)

func _on_drone_buildmode() -> void:
	menu.visible = !is_menu
	is_menu = !is_menu

func _process(delta: float) -> void:
	if(Input.is_action_just_released("back")):
		var n = ground_map.get_child_count()
		ground_map.get_child(n-1).queue_free()
	if Input.is_action_just_released("escto"):
		get_tree().change_scene_to_file("res://scenes/control.tscn")
