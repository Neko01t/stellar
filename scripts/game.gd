extends Node2D
var SCORE : int=0
@onready var fog_map: TileMapLayer = $Tiles/Fog
@onready var ground_map: TileMapLayer = $Tiles/Ground
@onready var ui_label: Label = $Meslasyer/Message
@onready var menu: CanvasLayer = $Menu
var budget: int = 100000 
var click_pos :Vector2 
var building_costs = {
	"house": 5000,
	"road": 2000,
	"solar": 8000
}
var selected_building_type: String = "house"
var is_menu :bool = false
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
	var building
	if type == "house":
		building = building_scene.instantiate()
	elif type == "road":
		building = road_scene.instantiate()
	elif type == "solar":
		building = solar_scene.instantiate()

	var cost = building_costs.get(type, 0)
	if budget < cost:
		show_message("Not enough budget!")
		return
	budget -= cost
	drone.score += 10  
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


func _on_solar_pressed() -> void:
	selected_building_type = "solar"
	show_message("Selected: solar")


func _on_drone_buildmode() -> void:
	menu.visible = !is_menu
	is_menu = !is_menu
