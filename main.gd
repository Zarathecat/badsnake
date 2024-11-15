extends Node

var score = 0
# hack because we start off with a game over
var death_counter = 1
var window_size = DisplayServer.window_get_size()
var food_flag = true # hack
var grow_flag = false
var eat_flag = false # hack
var snake_array = []
var segments

@export var food_scene: PackedScene
@export var head_scene: PackedScene
@export var segment_scene: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Segment.add_to_group("segments")
	pass	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if food_flag == false:
		food_flag = true
		make_food()
	
	var snake_length = snake_array.size()
	# first time it runs
	if snake_array == []:
		snake_array.push_back($Head.position)
	# if last thing in array doesn't match head
	elif snake_array[snake_length-1] != $Head.position:
		snake_array.push_back($Head.position)
		if grow_flag == false:
			snake_array.pop_front()
		grow_flag = false
	#print(snake_array)
	make_snake()
	check_snake($Head.position[0], $Head.position[1])

func check_snake(a, b):
	
	if a == 500 or a == 0 or b == 500 or b == 0:
		print("hit wall!")
		game_over()
	
	
	
func make_snake():
	var segments = get_tree().get_nodes_in_group("segments")
	if snake_array != [] and segments.size() > 0:
		#print(segments) #debug
		# working around a bug where they get emptied after check
		var seg_dup = segments.duplicate()
		var sn_dup = snake_array.duplicate()
		# Sometimes the sizes of these mismatch and it errors
		# out, reason as yet unknown, but unsurprising given the
		# spaghetti
		for i in range(seg_dup.size()):
			seg_dup[i].position = sn_dup[i-1]
		segments = seg_dup
		
func grow_snake():
#	$Food/CollisionShape2D.set_deferred(&"disabled", false)
	grow_flag = true
	eat_flag = true # hack
#	$Head/CollisionShape2D.set_deferred(&"disabled", true)
	var segment = segment_scene.instantiate()
	# Bug workaround.
	if snake_array == []:
		segment.position = $Head.position
	else:
		segment.position = snake_array[0]
	add_child(segment)
	segment.add_to_group("segments")

	

func get_random_position(win_size):
	# wall buffer of 20 so food doesn't spawn too close to wall
	var wbuffer = 20
	var win_x = int(win_size[0] - wbuffer)
	var win_y = int(win_size[1] - wbuffer)
	var rand_pos_x = randi_range(wbuffer, win_x)
	var rand_pos_y = randi_range(wbuffer, win_y)
	return Vector2(rand_pos_x, rand_pos_y)

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

func game_over():
	if death_counter % 10 == 0:
		$Deathsound.play()
	death_counter += 1
	print("game over!")
	var segments = get_tree().get_nodes_in_group("segments")
	for segment in segments:
		segment.queue_free()
	snake_array = []

# Deferred things are there to stop it counting as multiple hits

func _on_head_area_entered(area: Area2D) -> void:
#	$Head/CollisionShape2D.set_deferred(&"disabled", true)
	if eat_flag == true:
		eat_flag = false
	else:
		print("I hit myself!")
		game_over()

func _on_food_area_entered(area: Area2D) -> void:
	$Food/CollisionShape2D.set_deferred(&"disabled", true)
	score += 1
	print("ate food!")
	$Food.destroy_food()
	# Non-deferred gives error in debugger but behaves better...
	grow_snake.call_deferred()
	food_flag = false
