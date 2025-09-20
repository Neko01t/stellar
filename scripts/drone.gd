extends CharacterBody2D

@onready var drone_ani: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: AnimatedSprite2D = $shadow
@onready var uilay: Node2D = $Camera2D/uilay
@onready var camera: Camera2D = $Camera2D
@onready var fog_map = get_node("../Tiles/Fog")
@export var speed: float = 150.0
@export var rotation_speed: float = 3.0  

var THEscore: int = 0
signal buildmode()
# state
var is_landed: bool = false
var can_move: bool = true
var is_in_buildmode: bool = false


func _ready() -> void:
	uilay.get_child(0).position = Vector2(-180, -100)


func _physics_process(delta: float) -> void:
	_update_fog()

	if can_move:
		_handle_movement(delta)

	_handle_rotation(delta)
	_handle_landing(delta)
	_update_ui()

	# DEBUG: add points
	_score_display()


# ----------------------
# Movement
# ----------------------
func _handle_movement(delta: float) -> void:
	var move_dir := Vector2.ZERO

	if Input.is_action_pressed("forward"):
		move_dir += Vector2.UP.rotated(rotation)
	if Input.is_action_pressed("backward"):
		move_dir += Vector2.DOWN.rotated(rotation)
	if Input.is_action_pressed("left"):
		move_dir += Vector2.LEFT.rotated(rotation)
	if Input.is_action_pressed("right"):
		move_dir += Vector2.RIGHT.rotated(rotation)

	# animation
	if Input.is_action_pressed("left"):
		_play_animation("left")
	elif Input.is_action_pressed("right"):
		_play_animation("right")
	else:
		_play_animation("default")

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()

	velocity = move_dir * speed
	move_and_slide()


# ----------------------
# Rotation
# ----------------------
func _handle_rotation(delta: float) -> void:
	if Input.is_action_pressed("lefttor"):
		rotation -= rotation_speed * delta
		uilay.rotation += rotation_speed * delta
	if Input.is_action_pressed("rigthtor"):
		rotation += rotation_speed * delta
		uilay.rotation -= rotation_speed * delta


# ----------------------
# Landing + Camera + Shadow
# ----------------------
func _handle_landing(delta: float) -> void:
	if Input.is_action_just_released("landDown"):
		is_landed = !is_landed
		can_move = !can_move
		print("Landed:", is_landed, " CanMove:", can_move)
		emit_signal("buildmode")

	if is_landed:
		_play_animation("landed")
		camera.zoom = camera.zoom.lerp(Vector2(2, 2), 5 * delta)
		uilay.get_child(0).position = uilay.get_child(0).position.lerp(Vector2(-280, -160), 5 * delta)

		# scale drone + shadow slightly smaller
		drone_ani.scale = drone_ani.scale.lerp(Vector2(0.1, 0.1), 5 * delta)
		shadow.scale = shadow.scale.lerp(Vector2(0.05, 0.05), 5 * delta)
		shadow.position = shadow.position.lerp(Vector2(-8, 0), 5 * delta)
	else:
		camera.zoom = camera.zoom.lerp(Vector2(3, 3), 5 * delta)
		uilay.get_child(0).position = uilay.get_child(0).position.lerp(Vector2(-180, -100), 5 * delta)

		# default flying scale
		drone_ani.scale = drone_ani.scale.lerp(Vector2(0.2, 0.2), 5 * delta)
		shadow.scale = shadow.scale.lerp(Vector2(0.1, 0.1), 5 * delta)
		shadow.position = shadow.position.lerp(Vector2(-19, 0), 5 * delta)


# ----------------------
# Fog of War
# ----------------------
func _update_fog() -> void:
	var tile_pos = fog_map.local_to_map(global_position)
	if fog_map.get_cell_source_id(tile_pos) != -1:
		fog_map.set_cell(tile_pos, -1)
	_clear_fog(3)


func _clear_fog(radius: int = 3) -> void:
	var tile_pos = fog_map.local_to_map(global_position)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = tile_pos + Vector2i(x, y)
			fog_map.set_cell(pos, -1)


# ----------------------
# UI / Score
# ----------------------
func _score_display() -> void:
	uilay.get_child(0).text = "Score %d" % THEscore


func _update_ui() -> void:
	# you can later add build mode UI changes here
	pass


# ----------------------
# Helpers
# ----------------------
func _play_animation(anim: String) -> void:
	drone_ani.play(anim)
	shadow.play(anim)
	


func _on_score_assemenet_score_received(score: int, details: Dictionary) -> void:
	THEscore = score
	print(score)
