

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var abilityQueue = []
func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass
func add(ability):
	abilityQueue.push(ability)
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
