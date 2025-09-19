extends CharacterBody2D
@onready var drone_ani: AnimatedSprite2D = $AnimatedSprite2D
@export var speed: float = 150.0           
@export var rotation_speed: float = 3.0  
@onready var uilay: Node2D = $Camera2D/uilay
@onready var camera: Camera2D = $Camera2D
@onready var shadow: AnimatedSprite2D = $Camera2D/uilay/shadow

@onready var fog_map = get_node("../Tiles/Fog")

var score:int = 0
func _ready() -> void:
	uilay.get_child(0).position = Vector2(-180,-100)
# state 
var is_landed: bool = false
var can_move: bool = true
var is_in_buildmode : bool = false

func _physics_process(delta: float) -> void:
	remmove_fog()
	var move_dir := Vector2.ZERO
	if can_move:
		if Input.is_action_pressed("forward"):
			move_dir += Vector2.UP.rotated(rotation)
		if Input.is_action_pressed("backward"):
			move_dir += Vector2.DOWN.rotated(rotation)
	 
		if Input.is_action_pressed("left"):
			move_dir += Vector2.LEFT.rotated(rotation)
		if Input.is_action_pressed("right"):
			move_dir += Vector2.RIGHT.rotated(rotation)

		if Input.is_action_pressed("left"):
			drone_ani.play("left")
			shadow.play("left")
		elif Input.is_action_pressed("right"):
			drone_ani.play("right")
			shadow.play("right")
		else:
			drone_ani.play("default")
			shadow.play("default")
			
	if Input.is_action_just_released("landDown"):
		is_landed = !is_landed
		can_move = !can_move
		print(is_landed,can_move)
	if is_landed:
		drone_ani.play("landed")
		shadow.play("landed")
		camera.zoom = camera.zoom.lerp(Vector2(2,2),5*delta)
		shadow.position = shadow.position.lerp(Vector2(-8,0),5*delta)
		uilay.get_child(0).position = uilay.get_child(0).position.lerp(Vector2(-280,-160),5*delta)
		drone_ani.scale = drone_ani.scale.lerp(Vector2(0.9, 0.9), 5 * delta)
		shadow.scale = drone_ani.scale.lerp(Vector2(0.9, 0.9), 5 * delta)
	else:
		shadow.scale = drone_ani.scale.lerp(Vector2(0.7, 0.7), 5 * delta)
		shadow.position = shadow.position.lerp(Vector2(-19,0),5*delta)
		uilay.get_child(0).position = uilay.get_child(0).position.lerp(Vector2(-180,-100),5*delta)
		camera.zoom = camera.zoom.lerp(Vector2(3,3),5*delta)
		drone_ani.scale = drone_ani.scale.lerp(Vector2(1, 1), 5 * delta)

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
	velocity = move_dir * speed
	move_and_slide()

	if Input.is_action_pressed("lefttor"):
		rotation -= rotation_speed * delta
		uilay.rotation += rotation_speed*delta
	if Input.is_action_pressed("rigthtor"):
		rotation += rotation_speed * delta
		uilay.rotation -= rotation_speed*delta
	if Input.is_action_just_pressed("Debug_add_points"):
		score += 1
		uilay.get_child(0).text = "Score %d" % [score] 
func remmove_fog():
	var tile_pos = fog_map.local_to_map(global_position)
	if fog_map.get_cell_source_id(tile_pos) != -1:
		fog_map.set_cell(tile_pos, -1) 
	clear_fog(2)


func clear_fog(radius := 5):
	var tile_pos = fog_map.local_to_map(global_position)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = tile_pos + Vector2i(x, y)
			fog_map.set_cell(pos, -1)  
