extends AnimatedSprite

var flipped = false

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_E:
			if global.player in $ActivateArea.get_overlapping_bodies():
				if flipped == false:
					global.push_text("Player flipped lever")
					self.animation = "On"
					global.lever_pulled = true
					flipped = true
