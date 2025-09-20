extends Control
@onready var window: Window = $Window

signal road_selected(road_type: String)
@export var sprite_sheet: Texture2D
@export var tile_size := Vector2i(64, 64)  # change to your tile size
@export var road_tiles := {
	"straight": Vector2i(3, 0),
	"curve": Vector2i(2, 1),
	"t_intersection": Vector2i(5, 1),
	"cross": Vector2i(0, 2)
}

func _ready():
	window.show()
	var hbox = $Window/HBoxContainer
	for road_name in road_tiles.keys():
		var btn = Button.new()
		btn.text = ""

		var region = Rect2i(road_tiles[road_name] * tile_size, tile_size)
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = region

		btn.icon = atlas
		#btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.connect("pressed", Callable(self, "_on_button_pressed").bind(road_name))
		hbox.add_child(btn)

func _on_button_pressed(road_name: String) -> void:
	emit_signal("road_selected", road_name)
	window.hide()



func _on_window_close_requested() -> void:
	window.hide()
