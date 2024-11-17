extends Node

@export var food_scene: PackedScene
@export var segment_scene: PackedScene

var score = 0

var window_size = DisplayServer.window_get_size()

# Says it's time for the snake to die.
# We use a flag for this so that the listener checking for collisions
# doesn't end up with too much to process. It can just set
# a flag and go back to listening. There can be many collisions
# in quick succession, so this stops it getting overwhelmed.
var death_flag = false

# immortal_flag was used to disable collision-detection.
# No longer needed, but kept around as a comment in case
# we reintroduce it as a powerup sometime
#var immortal_flag = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Avoids starting with a game over.
	$Segment/CollisionShape2D.disabled = true
	$Segment.add_to_group("segments")
	food_scene.instantiate()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		
	# Here's how you move snake.
	# This implementation represents the snake as an array of segments.
	# Each segment is an object with a coordinate pair, 'position'.
	# You have as many pairs as the length of the snake. The newest
	# segment goes at the end, followed by the head.
	# With values taken out, it's shaped like this:
	# [x,x,x,x,x]X   ('x' represents a segment, 'X' the head)
	# ----------->   (here, it's moving this way!)
	# So the oldest segment, the tail, is first in the array, index 0.
	# And the newest segment, just behind the head, is at segments[-1].
	# Each loop, we check:
	# 'is the last (newest) thing in the array in a different
	# position to the snake head?' (ie: has the snake moved?)
	# If so, it shifts the position of each segment, starting from the 
	# oldest, the tail (first in the array!), to take the place of the
	# segment ahead of it. And the newest segment takes the head's place.
	# If the snake has not moved, the segments stay where they are.
	# This stops it from shrinking on implementations where the snake
	# can stop.
	var segments = get_tree().get_nodes_in_group("segments")
	var snake_length = segments.size()
	if segments == []:
		pass
	# If last thing in array doesn't match head
	elif segments[-1].position != $Head.position:
		if segments.size() > 1:
			# Re-enable collision detection for ex-newest segment
			segments[-2].get_node("CollisionShape2D").disabled = false
		for i in range(0, snake_length-1):
			# Move each segment along by 1 place
			segments[i].position = segments[i+1].position
		# When the head updates too slowly, the first segment crashes
		# into it. We disable the collision-detection elsewhere.
		# Move front of snake (end of array) forwards
		segments[-1].position = $Head.position
	check_snake($Head.position[0], $Head.position[1])
	if death_flag == true:
		print("I hit something!")
		game_over()

# Check if snake hit wall. a and b are the X and Y coords of the head.
func check_snake(a, b):
	if a == window_size.x or a == 0 or b == window_size.y or b == 0:
		print("hit wall!")
		death_flag = true
	

# Add a segment to the snake, and thus to the scene tree. Track it in the
# list of segment nodes. The position here is its starting position; after
# this one-off it will be set by the game loop. We instantiate the segment
# offscreen and then have it join the snake on the first loop; smoother.
func grow_snake():
	var segment = segment_scene.instantiate()
	var segments = get_tree().get_nodes_in_group("segments")
	# 'winsize+50' is arbitrary choice of offscreen location.
	segment.position = Vector2(window_size.x + 50, window_size.y +50)
	# We turn off node's collision-detection,
	# so that it doesn't hit the head
	# when the head is slow to update its own position.
	segment.get_node("CollisionShape2D").disabled = true
	add_child(segment)
	segment.add_to_group("segments")
	
# Gets a random position on the screen, used for placing the food.
func get_random_position(win_size):
	# wall buffer of 20 so food doesn't spawn too close to wall
	var wbuffer = 20
	var win_x = int(win_size[0] - wbuffer)
	var win_y = int(win_size[1] - wbuffer)
	var rand_pos_x = randi_range(wbuffer, win_x)
	var rand_pos_y = randi_range(wbuffer, win_y)
	return Vector2(rand_pos_x, rand_pos_y)

func make_food():
	var segments = get_tree().get_nodes_in_group("segments")
	var potential_food_pos = Vector2(0,0)
	# Hack. loop until get position not taken by snake
	var seg_pos_array = []
	for segment in segments:
		seg_pos_array.append(segment.position)
	while true:
		potential_food_pos = get_random_position(window_size)
		if potential_food_pos not in seg_pos_array:
			break
	$Food.position = potential_food_pos
	$Food/CollisionShape2D.set_deferred(&"disabled", false)

# queue_free() removes objects from memory. So this destroys all
# snake segments. We set the snake to
# reappear next round in the middle of the screen, and we stop
# it from gliding until the player is ready to retry, via .last_dir
# Some of this stuff needs splitting out and abstracting. Later!
func game_over():	
	$Deathsound.play()
	print("game over!")
	update_score_display()
	var segments = get_tree().get_nodes_in_group("segments")
	for segment in segments:
		segment.queue_free()
	$Head.position = window_size /2
	$Head.last_dir = ""
	score = 0
	death_flag = false # auto-restart

func update_score_display():
	$Hud/Score.text = "Score: " + str(score)

func _on_head_area_entered(area: Area2D) -> void:
	death_flag = true
	#print("I hit myself!") # debugging

# We disable collision-detection so that the snake only eats one
# item of food, and the score doesn't skyrocket. 
func _on_food_area_entered(area: Area2D) -> void:
	$Food/CollisionShape2D.set_deferred(&"disabled", true)
	score += 1
	update_score_display()
	make_food()
	grow_snake()
	
#func _on_lunch_timer_timeout() -> void:
#	immortal_flag = false
