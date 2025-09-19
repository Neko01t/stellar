extends CharacterBody2D

@export var speed: float = 150.0           
@export var rotation_speed: float = 3.0  

func _physics_process(delta: float) -> void:
	var move_dir := Vector2.ZERO


	if Input.is_action_pressed("forward"):
		move_dir += Vector2.UP.rotated(rotation)
	if Input.is_action_pressed("backward"):
		move_dir += Vector2.DOWN.rotated(rotation)
 
	if Input.is_action_pressed("left"):
		move_dir += Vector2.LEFT.rotated(rotation)
	if Input.is_action_pressed("right"):
		move_dir += Vector2.RIGHT.rotated(rotation)

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
	velocity = move_dir * speed
	move_and_slide()

	if Input.is_action_pressed("lefttor"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("rigthtor"):
		rotation += rotation_speed * delta
