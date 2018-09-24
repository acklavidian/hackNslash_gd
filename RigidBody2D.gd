extends RigidBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

var velocity = Vector2()
var speed = 100

func get_input():
	velocity = Vector2()
	
	if Input.is_action_pressed('right'):
		velocity.x = speed
		print('right')
	if Input.is_action_pressed('left'):
		velocity.x = -speed
		print('left')
	if Input.is_action_pressed('down'):
		velocity.y = speed
		print('down')
	if Input.is_action_pressed('up'):
		velocity.y = -speed
		print('up')
		
func _physics_process(delta):
	get_input()
	linear_velocity = velocity