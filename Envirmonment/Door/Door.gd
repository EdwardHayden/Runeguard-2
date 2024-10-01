extends AnimatedSprite

func _physics_process(delta):
	if global.lever_pulled == true:
		animation = "Open"
