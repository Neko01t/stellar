extends Node2D
@onready var label: Label = $Label

func _on_timer_timeout() -> void:
	while(label.modulate.a != 0):
		var a = label.modulate.a
		a -= 0.05  
		if a < 0:
			a = 0
		label.modulate.a = a
