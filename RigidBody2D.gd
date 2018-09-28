extends KinematicBody2D

enum Direction { RIGHT LEFT UP DOWN HORIZONTAL VERTICAL }
enum Status {
	STANDING
	WALKING
	RUNNING
	JUMPING
	FALLING
	CROUCHING
	ATTACKING
	THROWING
}

var velocity = Vector2()
var base_speed = 50
var max_jump_count = 2
var jump_count = 0
var jump_speed = 100
var height 

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

	
func is_moving(direction):
	match direction:
		RIGHT: return velocity.x > 10
		LEFT: return velocity.x < -10
		UP: return velocity.y < 10
		DOWN: return velocity.y > -10
		VERTICAL: return is_moving(UP) || is_moving(DOWN)
		HORIZONTAL: return is_moving(RIGHT) || is_moving(LEFT)
		_: return is_moving(HORIZONTAL) || is_moving(VERTICAL)
		
func is_collision_direction(direction):
	var collision = get_slide_collision(0)
	if collision:
		match direction:
			LEFT: return collision.position.x < position.x && (collision.position.y - position.y) < 10
			RIGHT: return collision.position.x > position.x && (collision.position.y - position.y) < 10
	else:
		return false
		
func react():
	if is_collision_direction(LEFT) || is_collision_direction(RIGHT):
		var collision = get_slide_collision(0)
		print('cx: ', collision.position.x, ', x: ', position.x)
		print('Left: ', is_collision_direction(LEFT))
		print('Right: ', is_collision_direction(RIGHT))
	$AnimatedSprite.flip_h = is_collision_direction(LEFT) if is_on_wall() else is_moving(LEFT)
	if is_on_floor():
		var is_crouching = $CollisionShape2D.scale.y < height
		if is_on_wall():
			$AnimatedSprite.play('pushing')
		elif is_moving(HORIZONTAL):
			var is_walking = abs(velocity.x) <= base_speed
			if is_crouching:
				$AnimatedSprite.play('waddling' if is_walking else 'rolling')
			else:
				$AnimatedSprite.play('walking' if is_walking  else 'running')
		else:
			$AnimatedSprite.play('crouching' if is_crouching else 'standing')
	else:
		if is_moving(UP):
			if velocity.y < -10:
				$AnimatedSprite.play('jumping' if jump_count < 2 else 'rolling')
		elif is_moving(DOWN):
			if is_on_wall():
				$AnimatedSprite.play('wall_sliding')
			elif velocity.y > 10:
				$AnimatedSprite.play('falling' if jump_count < 2 else 'rolling')
		
	
func _physics_process(delta):
	if is_on_floor():
		jump_count = 0
		
	get_input()
	velocity = move_and_slide(velocity, Vector2(0, -1))

	react()
