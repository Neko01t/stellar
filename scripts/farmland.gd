extends Node2D
@onready var timer: Timer = $Timer
@onready var farmland: Sprite2D = $Sprite2D
@onready var grownfarm: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	farmland.visible = true
	grownfarm.visible = false
	timer.start()

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func _on_timer_timeout() -> void:
	farmland.visible = false
	grownfarm.visible = true
	grownfarm.play("default")
	var a = label.modulate.a
	a -= 0.05  # decrease by 0.05 per tick
	if a < 0:
		a = 0
	label.modulate.a = a
