
# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var animation_name
var active_frames
var active_frames_offset
var is_passive

func _init(node, animation_name, is_passive = true, active_frames = 0, active_frames_offset = 0):
	self.animation_name = animation_name
	self.is_passive = is_passive
	self.active_frames = active_frames
	self.active_frames_offset = active_frames_offset
	
func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
