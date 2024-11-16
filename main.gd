extends Node

var score = 0

var window_size = DisplayServer.window_get_size()

# eat flag signals that the snake has had some food
# used to trigger the snake's growth, score update etc
var eat_flag = false

# immortal_flag is set when the snake has *just* eaten.
# This is used as a workaround to disable collision-detection
# for the snake with its new segment when it first gets it,
# so it doesn't instantly die by growing
var immortal_flag = false

# Self-explanatory. Says it's time for the snake to die.
var death_flag = false

@export var food_scene: PackedScene
@export var segment_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	immortal_flag = true
	$LunchTimer.start() # Hack to avoid starting the game with a gameover
	$Segment.add_to_group("segments")
	food_scene.instantiate()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# If snake has just eaten some food	
	if eat_flag == true:
		print("ate food!")
		$LunchTimer.start()
		score += 1
		print("Score: " + str(score))
		make_food()
		grow_snake()
		eat_flag = false
		
	# Right, let's talk about how you write snake.
	# This implementation represents the snake as an array of segments.
	# Each segment is an object with a coordinate pair, 'position'.
	# You have as many pairs as the length of the snake. On each loop,
	# this checks, 'is the last (newest) thing in the array in a different
	# position to the snake head?' (ie: has the snake moved?)
	# If so, it shifts the position of each segment, starting from the 
	# oldest, the tail (first in the array!), to take the place of the
	# segment ahead of it. And the first segment takes the place of the
	# head.
	# If the snake has not moved, the segments stay where they are.
	# We used to use all sorts of horrible flags, but now segment-creation
	# is handled elsewhere, so the logic here doesn't need to chagne.
	var segments = get_tree().get_nodes_in_group("segments")
	var snake_length = segments.size()
	if segments == []:
		pass
	# If last thing in array doesn't match head
	elif segments[-1].position != $Head.position:
		# Re-enable collision detection for ex-first-segment, now 2nd
		if segments.size() > 1:
			segments[-2].get_node("CollisionShape2D").disabled = false
		for i in range(0, snake_length-1):
			# Move each segment along by 1
			segments[i].position = segments[i+1].position
		# When the head updates too slowly, the first segment crashes
		# into it. So collision detection for the first segment should
		# always be disabled.
		segments[-1].position = $Head.position
	check_snake($Head.position[0], $Head.position[1])
	if death_flag == true:
		print("I hit something!")
		game_over()

# Check if snake hit wall
func check_snake(a, b):
	if a == window_size.x or a == 0 or b == window_size.y or b == 0:
		print("hit wall!")
		death_flag = true
	

# Add a segment to the snake, and thus to the scene tree. Track it in the
# list of segment nodes. The position here is its starting position; after
# this one-off it will be set by the game loop. We instantiate the segment
# offscreen and then have it join the snake on the first loop, so we don't
# hit it.
func grow_snake():
	var segment = segment_scene.instantiate()
	var segments = get_tree().get_nodes_in_group("segments")
	segment.position = Vector2(window_size.x + 50, window_size.y +50) # hack
	# The new node can't detect collisions, so that it doesn't hit the head
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
	print("Score: " + str(score))
	var segments = get_tree().get_nodes_in_group("segments")
	for segment in segments:
		segment.queue_free()
	$Head.position = window_size /2
	$Head.last_dir = ""
	score = 0
	death_flag = false # auto-restart

# immortal_flag is used here as a hack for turning off
# collision-detection briefly, so the snake won't die if it's lunching.
func _on_head_area_entered(area: Area2D) -> void:
	if immortal_flag == false:
		death_flag = true
		#print("I hit myself!") # debugging

# We disable collision-detection so that the snake only eats one
# item of food, and the score doesn't skyrocket. 
# We never bother to enable it again, because we then destroy the
# item of food.
func _on_food_area_entered(area: Area2D) -> void:
	$Food/CollisionShape2D.set_deferred(&"disabled", true)
	eat_flag = true
	immortal_flag = true
	
func _on_lunch_timer_timeout() -> void:
	immortal_flag = false
