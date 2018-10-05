extends KinematicBody2D

enum Direction { RIGHT LEFT UP DOWN HORIZONTAL VERTICAL }
enum Status {
#	SLOW_MOVEMENT
#	RAPID_MOVEMENT
#	RAPID_VERTICAL_MOVEMENT
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
}

var velocity = Vector2()
var base_speed = 50
var max_jump_count = 2
var jump_count = 0
var jump_speed = 100
var height
var status = {} setget , get_status



func _ready():
	height = $CollisionShape2D.scale.y

func get_input():
	var speed = base_speed
	velocity = Vector2(0, velocity.y + 5)

	if Input.is_action_pressed('run'):
		speed *= 2
	if Input.is_action_pressed('walk_right'):
		velocity.x = speed
	if Input.is_action_pressed('walk_left'):
		velocity.x = -speed
	if Input.is_action_just_pressed('crouch'):
		$CollisionShape2D.scale.y = $CollisionShape2D.scale.y * 0.5
	if Input.is_action_just_released('crouch'):
		$CollisionShape2D.scale.y = $CollisionShape2D.scale.y * 2
	if Input.is_action_just_pressed('jump') && jump_count < max_jump_count:
		jump_count += 1
		velocity.y = -jump_speed
	if is_on_wall():
		velocity.y = 0 if is_on_floor() else 10


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
	if is_on_floor(): status[TOUCHING_FLOOR] = true
	if is_on_wall(): status[TOUCHING_WALL] = true
	if abs(velocity.x) > base_speed: status[RAPID_HORIZONTAL_MOVEMENT] = true
	if is_moving(HORIZONTAL): status[HORIZONTAL_MOVEMENT] = true
	if is_moving(VERTICAL): status[VERTICAL_MOVEMENT] = true
	if $CollisionShape2D.scale.y < height: status[REDUCED_HEIGHT] = true
	if self.is_collision_direction(HORIZONTAL) || self.is_collision_direction(VERTICAL): status[TOUCHING] = true
	if is_collision_direction(RIGHT): status[TOUCHING_RIGHT] = true
	if is_collision_direction(LEFT): status[TOUCHING_LEFT] = true
	if is_moving(LEFT): status[MOVING_LEFT] = true
	if is_moving(RIGHT): status[MOVING_RIGHT] = true
	if is_moving(): status[MOVING] = true
	if jump_count >= max_jump_count: status[MAX_JUMP] = true
	if jump_count > 1: status[MULTIPLE_JUMP] = true
	if not is_on_floor(): status[AIRBORN] = true
	return status

func react():
	var status = self.status
	var is_facing_backward = status.has(TOUCHING_LEFT) || status.has(MOVING_LEFT)

	if status.has([TOUCHING_WALL, DESCENDING]):
		is_facing_backward = !is_facing_backward


	print('------')
	print('left? ', is_moving(LEFT))

	if status.has(MOVING_LEFT): print('MOVING_LEFT')
	if status.has(TOUCHING_LEFT): print('TOUCHING_LEFT')
	if status.has(TOUCHING_FLOOR): print('TOUCHING_FLOOR')
	if status.has(DESCENDING): print('DESCENDING')
	if status.has(RAPID_HORIZONTAL_MOVEMENT): print('RAPID_HORIZONTAL_MOVEMENT')
	if status.has(HORIZONTAL_MOVEMENT): print('HORIZONTAL_MOVEMENT')
	
	if status.has(HORIZONTAL_MOVEMENT):
		$AnimatedSprite.flip_h = is_facing_backward
	if status.has(TOUCHING_FLOOR):
		if status.has_all([REDUCED_HEIGHT, RAPID_HORIZONTAL_MOVEMENT]): $AnimatedSprite.play('rolling')
		elif status.has_all([REDUCED_HEIGHT, HORIZONTAL_MOVEMENT]): $AnimatedSprite.play('waddling')
		elif status.has(REDUCED_HEIGHT): $AnimatedSprite.play('crouching')
		elif status.has(RAPID_HORIZONTAL_MOVEMENT): $AnimatedSprite.play('running')
		elif status.has(HORIZONTAL_MOVEMENT): $AnimatedSprite.play('walking')
		else: $AnimatedSprite.play('standing')
	else:
		if status.has_all([ASCENDING, MULTIPLE_JUMP]): $AnimatedSprite.play('rolling')
		elif status.has(ASCENDING): $AnimatedSprite.play('jumping')
		elif status.has_all([TOUCHING_WALL, DESCENDING]): $AnimatedSprite.play('wall_sliding')
		elif status.has(DESCENDING): $AnimatedSprite.play('falling')
		

#	$AnimatedSprite.flip_h = is_collision_direction(LEFT) if is_on_wall() else is_moving(LEFT)

#func react():
#	# print ($AnimatedSprite.frame, ':of:', $AnimatedSprite.frames.get_frame_count($AnimatedSprite.animation))
#
##	if is_collision_direction(LEFT) || is_collision_direction(RIGHT):
##		var collision = get_slide_collision(0)
##		print('cx: ', collision.position.x, ', x: ', position.x)
##		print('Left: ', is_collision_direction(LEFT))
##		print('Right: ', is_collision_direction(RIGHT))
#	$AnimatedSprite.flip_h = is_collision_direction(LEFT) if is_on_wall() else is_moving(LEFT)
#	if is_on_floor():
#		var is_crouching = $CollisionShape2D.scale.y < height
#		if is_on_wall():
#			$AnimatedSprite.play('pushing')
#		elif is_moving(HORIZONTAL):
#			var is_walking = abs(velocity.x) <= base_speed
#			if is_crouching:
#				$AnimatedSprite.play('waddling' if is_walking else 'rolling')
#			else:
#				$AnimatedSprite.play('walking' if is_walking  else 'running')
#		else:
#			$AnimatedSprite.play('crouching' if is_crouching else 'standing')
#	else:
#		if is_moving(UP):
#			if velocity.y < -10:
#				$AnimatedSprite.play('jumping' if jump_count < 2 else 'rolling')
#		elif is_moving(DOWN):
#			if is_on_wall():
#				$AnimatedSprite.play('wall_sliding')
#			elif velocity.y > 10:
#				$AnimatedSprite.play('falling' if jump_count < 2 else 'rolling')


func _physics_process(delta):
	if is_on_floor():
		jump_count = 0

	get_input()
	velocity = move_and_slide(velocity, Vector2(0, -1))

	react()
