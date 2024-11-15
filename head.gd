extends Area2D

# When snake hits itself
signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

var last_dir = "none"# hack

func _ready():
	screen_size = get_viewport_rect().size

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed(&"move_right") and last_dir != "left":
		velocity.x += 1
		last_dir = "right"
	if Input.is_action_pressed(&"move_left") and last_dir != "right":
		velocity.x -= 1
		last_dir = "left"
	if Input.is_action_pressed(&"move_down") and last_dir != "up":
		velocity.y += 1
		last_dir = "down"
	if Input.is_action_pressed(&"move_up") and last_dir != "down":
		velocity.y -= 1
		last_dir = "up"
		
	# hack to glide	
	elif last_dir == "right":
		velocity.x += 1
	elif last_dir == "left":
		velocity.x -= 1
	elif last_dir == "down":
		velocity.y += 1
	elif last_dir == "up":
		velocity.y -= 1


	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
