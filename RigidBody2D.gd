extends KinematicBody2D
var velocity = Vector2()
var speed = 50
var direction 

enum { FORWARD, BACKWARD, UP, DOWN, HORIZONTAL, VERTICAL }

func _ready():
	pass

func get_input():
	velocity = Vector2()
	velocity.y = 100
	
	if Input.is_action_pressed('right'):
		velocity.x = speed
	if Input.is_action_pressed('left'):
		velocity.x = -speed
	if Input.is_action_pressed('down'):
		velocity.y = speed
	if Input.is_action_pressed('up'):
		velocity.y = -speed
	
func is_moving(direction):
	print('direction', direction)
	match direction:
		FORWARD: return velocity.x > 0
		BACKWARD: return velocity.x < 0
		UP: return velocity.y > 0
		DOWN: return velocity < 0
		VERTICAL: return velocity.y != 0
		HORIZONTAL: return velocity.x != 0
		_: return is_moving(HORIZONTAL) || is_moving(VERTICAL)
		
	
func react():
	$AnimatedSprite.flip_h = is_moving(BACKWARD)
	if is_moving(HORIZONTAL) && is_on_floor():
		$AnimatedSprite.play('walking')
	else:
		$AnimatedSprite.play('standing')
		
	
func _physics_process(delta):
	get_input()
	move_and_slide(velocity, Vector2(0, -1))
	react()