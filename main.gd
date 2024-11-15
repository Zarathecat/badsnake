extends Node

var score = 0

# hack because we start off with a game over
# we will use this to avoid playing the deathsound right at
# the start of the game. it also means it doesn't attempt to
# make 1 sound per frame when we die, so accidentally
# ends up sounding better.
var death_counter = 1

var window_size = DisplayServer.window_get_size()

# food_flag is used to track whether we need to make food.
# confusingly, 'false' means we need to make food. I guess
# I was thinking 'is there food?'
var food_flag = true # hack

# grow_flag says whether or not the snake should grow on
# this frame or not.
var grow_flag = false

# eat_flag says whether or not the snake has just eaten.
# This is used as a workaround to disable collision-detection
# for the snake with its new segment when it first gets it,
# so it doesn't instantly die by growing
var eat_flag = false # hack

# There's probably no reason to have both a snake_array and
# segments. This happened because I found out you could get
# a group of nodes after I'd coded it using an array. Maybe
# in the future I'll fix the implementation to use only the
# segments. That might also fix an annoying bug where they
# get out of sync, the code tries to access an invalid index,
# and the snake takes that as its cue to suddenly die.
var snake_array = []
var segments

@export var food_scene: PackedScene
@export var head_scene: PackedScene # This isn't even used.
@export var segment_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Segment.add_to_group("segments")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if food_flag == false:
		food_flag = true
		make_food()

	var snake_length = snake_array.size()
	# Right, let's talk about how you write snake.
	# This implementation represents the snake as an array of coordinate pairs.
	# You have as many pairs as the length of the snake. On each loop,
	# it checks, 'is the snake head in a different position to anything
	# else in the array?' If so, it adds the head to the end of the array,
	# and removes the first element. If not, it keeps the array the same,
	# because otherwise, the snake would have multiple segments at the same
	# coordinate, so it would look like it had shrunk. This isn't as visible
	# on implementations where the snake is always moving, but is visible if
	# the player can stop the snake.
	# You could use that as a gameplay mechanic, if
	# you wanted, but I don't want.
	# First time it runs, put the head coord as only element in array
	if snake_array == []:
		snake_array.push_back($Head.position) # push_back == append
	# If last thing in array doesn't match head
	elif snake_array[snake_length-1] != $Head.position:
		snake_array.push_back($Head.position)
		if grow_flag == false:
			snake_array.pop_front()
		grow_flag = false
	make_snake()
	check_snake($Head.position[0], $Head.position[1])

# Check if snake hit wall
func check_snake(a, b):
	if a == 500 or a == 0 or b == 500 or b == 0:
		print("hit wall!")
		game_over()
	
# This matches the nodes for the snake segments to the coordinates
# in the array. It would likely make more sense to set their positions
# directly and operate on them that way.
func make_snake():
	var segments = get_tree().get_nodes_in_group("segments")
	if snake_array != [] and segments.size() > 0:
		# working around a bug where they get emptied after check
		# I don't think this workaround actually works, so it just
		# pointlessly duplicates some arrays and slows things down.
		var seg_dup = segments.duplicate()
		var sn_dup = snake_array.duplicate()
		# Sometimes the sizes of these mismatch and it errors
		# out, reason as yet unknown, but unsurprising given the
		# spaghetti. Maybe operating directly on segments will fix bug
		for i in range(seg_dup.size()):
			seg_dup[i].position = sn_dup[i-1]
		segments = seg_dup

# Add a segment to the snake, and thus to the scene tree. Track it in the
# list of segment nodes. The position here is it's starting position; after
# this one-off it will be set by the game loop. We give it a specific position
# here so we 'grow' instantly and don't bump into it by accident, but since
# apparently I ended up needing a bunch of hacky flags anyway, it
# might make more sense to instantiate the segment offscreen and then have
# it join the snake on the first loop...
func grow_snake():
	grow_flag = true
	eat_flag = true # hack
	var segment = segment_scene.instantiate()
	# Bug workaround. Shouldn't ever be empty here but sometimes it is...
	if snake_array == []:
		segment.position = $Head.position
	else:
		segment.position = snake_array[0]
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

# Remember to connect the signal from the new piece of food, or
# the snake will eat exactly one piece of food and then ignore it
# from then on!
func make_food():
	var food = food_scene.instantiate()
	var potential_food_pos = Vector2(0,0)
	# Hack. loop until get position not taken by snake
	while true:
		potential_food_pos = get_random_position(window_size)
		if potential_food_pos not in snake_array:
			break
	food.position = potential_food_pos
	food.area_entered.connect(_on_food_area_entered)
	add_child(food)

# queue_free() removes objects from memory. So this destroys all
# snake segments. Should probably look into whether its wise to
# use be using get_tree() in both the make and destroy functions;
# maybe they can get out of step. Anyway. We also clear the array.
func game_over():
	if death_counter % 10 == 0:
		$Deathsound.play()
	death_counter += 1
	print("game over!")
	var segments = get_tree().get_nodes_in_group("segments")
	for segment in segments:
		segment.queue_free()
	snake_array = []

# eat_flag is used here as a hack for turning off
# collision-detection briefly, so the snake won't die if it's lunching.
func _on_head_area_entered(area: Area2D) -> void:
	if eat_flag == true:
		eat_flag = false
	else:
		print("I hit myself!")
		game_over()

# We disable collision-detection so that the snake only eats one
# item of food, and the score doesn't skyrocket. 
# We never bother to enable it again, because we then destroy the
# item of food. The call_deferred() further down averts an
# error that the debugger draws attention to, but which doesn't
# seem to have any effect on gameplay. May as well.
# food_flag = false informs the game that there is 
# no food on the screen.
func _on_food_area_entered(area: Area2D) -> void:
	$Food/CollisionShape2D.set_deferred(&"disabled", true)
	score += 1
	print("ate food!")
	$Food.destroy_food()
	grow_snake.call_deferred()
	food_flag = false
