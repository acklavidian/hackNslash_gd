extends KinematicBody2D

enum Direction { FORWARD BACKWARD UP DOWN HORIZONTAL VERTICAL }
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
		print('is on wall', velocity)
		print('is moving', is_moving(FORWARD))
		velocity.y = 0 if is_on_floor() else 10

	
func is_moving(direction):
	match direction:
		FORWARD: return velocity.x > 10
		BACKWARD: return velocity.x < -10
		UP: return velocity.y < 10
		DOWN: return velocity.y > -10
		VERTICAL: return is_moving(UP) || is_moving(DOWN)
		HORIZONTAL: return is_moving(FORWARD) || is_moving(BACKWARD)
		_: return is_moving(HORIZONTAL) || is_moving(VERTICAL)

	
func react():
	$AnimatedSprite.flip_h = is_moving(BACKWARD)
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
			$AnimatedSprite.play('jumping' if jump_count < 2 else 'rolling')
		elif is_moving(DOWN):
			$AnimatedSprite.play('falling' if jump_count < 2 else 'rolling')
		
	
func _physics_process(delta):
	if is_on_floor():
		jump_count = 0
		
	velocity = move_and_slide(velocity, Vector2(0, -1))
	print(velocity.x)

	react()
	get_input()