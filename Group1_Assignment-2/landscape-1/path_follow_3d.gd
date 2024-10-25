extends PathFollow3D
var speed=0.07

func _physics_process(delta):
	progress_ratio+=delta*speed
