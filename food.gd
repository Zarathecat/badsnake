extends Area2D

signal hit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("food ready")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func destroy_food():
	queue_free()
