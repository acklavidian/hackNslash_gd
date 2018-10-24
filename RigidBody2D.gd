extends KinematicBody2D
var Ability = load('res://Ability.gd')
var AbilityQueue = load('res://AbilityQueue.gd')

enum Direction { RIGHT LEFT UP DOWN HORIZONTAL VERTICAL }
enum Status {
	ASCENDING
	DESCENDING
	AIRBORN
	HORIZONTAL_MOVEMENT
	MOVING_LEFT
	MOVING_RIGHT
	MOVING
	VERTICAL_MOVEMENT
	RAPID_HORIZONTAL_MOVEMENT
	REDUCED_HEIGHT
	TOUCHING
	TOUCHING_RIGHT
	TOUCHING_LEFT
	TOUCHING_FLOOR
	TOUCHING_WALL
	MULTIPLE_JUMP
	MAX_JUMP
	ATTACKING
}

var velocity = Vector2()
var base_speed = 50
var max_jump_count = 2
var jump_count = 0
var jump_speed = 100
var height
var status = {} setget , get_status
var debug_output
var is_attacking = false

func _ready():
	height = $CollisionShape2D.scale.y
	debug_output = $Camera2D.get_node('Debug')
	
func is_touching_wall():
	return $RightRay.is_colliding() || $LeftRay.is_colliding()
	
func is_touching_floor():
	return $FloorRay.is_colliding()
	
func get_input():
	var speed = 0
	if velocity.y < 200: velocity.y += 5
	if is_touching_wall() && is_moving(DOWN):
		if !is_on_floor(): velocity.y = 5
	if Input.is_action_just_pressed('jump') && jump_count < max_jump_count:
		jump_count += 1
		velocity.y = -jump_speed
		if is_touching_wall() && !is_touching_floor():
			base_speed = -base_speed
	if Input.is_action_just_released('walk_right') || Input.is_action_just_released('walk_left') || is_touching_floor():
		base_speed = abs(base_speed)
	if Input.is_action_pressed('walk_right'):
		if not is_on_wall(): speed = base_speed
	if Input.is_action_pressed('walk_left'):
		if not is_on_wall(): speed = -base_speed
	if Input.is_action_pressed('run'):
		speed *= 2
	if Input.is_action_just_pressed('crouch'):
		$CollisionShape2D.scale.y = $CollisionShape2D.scale.y * 0.5
	if Input.is_action_just_released('crouch'):
		$CollisionShape2D.scale.y = $CollisionShape2D.scale.y * 2
	if Input.is_action_just_pressed('attack') || is_attacking:
		is_attacking = true
		speed = -100 if $AnimatedSprite.flip_h else 100
	if is_animation_at_end('attacking'):
		is_attacking = false
	velocity.x = speed
	velocity = velocity
	
func is_animation_at_end (animation_name = $AnimatedSprite.animation):
	var current_frame = $AnimatedSprite.frame + 1
	var animation_length = $AnimatedSprite.frames.get_frame_count(animation_name)
	return current_frame >= animation_length if animation_name == $AnimatedSprite.animation else false

func is_moving(direction=null):
	match direction:
		RIGHT: return velocity.x > 1
		LEFT: return velocity.x < -1
		UP: return velocity.y < -1
		DOWN: return velocity.y > 1
		VERTICAL: return is_moving(UP) || is_moving(DOWN)
		HORIZONTAL: return is_moving(RIGHT) || is_moving(LEFT)
		_: return is_moving(HORIZONTAL) || is_moving(VERTICAL)

func is_collision_direction(direction):
	if get_slide_count() > 0:
		var collision = get_slide_collision(0)
		if collision:
			match direction:
				LEFT: return collision.position.x < position.x && (collision.position.y - position.y) < 10
				RIGHT: return collision.position.x > position.x && (collision.position.y - position.y) < 10
				HORIZONTAL: return is_collision_direction(LEFT) || is_collision_direction(RIGHT)
				VERTICAL: return is_on_floor() || is_on_ceiling()


func get_status ():
	status = {}
	if is_moving(UP): status[ASCENDING] = true
	if is_moving(DOWN): status[DESCENDING] = true
	if $FloorRay.is_colliding(): status[TOUCHING_FLOOR] = true
	if $RightRay.is_colliding() || $LeftRay.is_colliding(): status[TOUCHING_WALL] = true
	if abs(velocity.x) > abs(base_speed): status[RAPID_HORIZONTAL_MOVEMENT] = true
	if is_moving(HORIZONTAL): status[HORIZONTAL_MOVEMENT] = true
	if is_moving(VERTICAL): status[VERTICAL_MOVEMENT] = true
	if $CollisionShape2D.scale.y < height: status[REDUCED_HEIGHT] = true
	if is_on_ceiling() || is_on_wall() || is_on_floor(): status[TOUCHING] = true
	if $RightRay.is_colliding(): status[TOUCHING_RIGHT] = true
	if $LeftRay.is_colliding(): status[TOUCHING_LEFT] = true
	if is_moving(LEFT): status[MOVING_LEFT] = true
	if is_moving(RIGHT): status[MOVING_RIGHT] = true
	if is_moving(): status[MOVING] = true
	if jump_count >= max_jump_count: status[MAX_JUMP] = true
	if jump_count > 1: status[MULTIPLE_JUMP] = true
	if not is_on_floor(): status[AIRBORN] = true
	if is_attacking: status[ATTACKING] = true
	return status

func debug ():
	var output = ''
	for flag_index in Status.keys():
		output += flag_index + ('+++++++++++++' if status.has(Status[flag_index]) else '') + '\n'
	 debug_output.text = output
	
	
func react():
	var status = self.status
	var is_facing_backward = status.has(TOUCHING_LEFT) || status.has(MOVING_LEFT)
	var animation = 'standing'
	if status.has([TOUCHING_WALL, DESCENDING]):
		is_facing_backward = !is_facing_backward
	
	if status.has(TOUCHING_FLOOR):
		if status.has_all([REDUCED_HEIGHT, RAPID_HORIZONTAL_MOVEMENT]): animation = 'rolling'
		elif status.has_all([REDUCED_HEIGHT, HORIZONTAL_MOVEMENT]): animation = 'waddling'
		elif status.has(REDUCED_HEIGHT): animation = 'crouching'
		elif status.has(RAPID_HORIZONTAL_MOVEMENT): animation = 'running'
		elif status.has_all([TOUCHING_WALL, TOUCHING_FLOOR, HORIZONTAL_MOVEMENT]): animation = 'pushing'
		elif status.has(HORIZONTAL_MOVEMENT): animation = 'walking'
		else: animation = 'standing'
	else:
		if status.has_all([ASCENDING, MULTIPLE_JUMP]): animation = 'rolling'
		elif status.has(ASCENDING): animation = 'jumping'
		elif status.has_all([TOUCHING_WALL, AIRBORN]): animation = 'wall_sliding'
		elif status.has(DESCENDING): animation = 'falling'
	if status.has(ATTACKING):
		animation = 'attacking'
	
	if status.has(HORIZONTAL_MOVEMENT):
		$AnimatedSprite.flip_h = is_facing_backward
	$AnimatedSprite.play(animation)
	
func _physics_process(delta):
	if is_touching_floor() && !is_moving(UP):
		jump_count = 0
	elif is_touching_wall():
		jump_count = 1
	get_input()

	velocity = move_and_slide(velocity, Vector2(0, -1))
	react()
