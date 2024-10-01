extends AnimatedSprite

var opened = false

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_E:
			if global.player in $OpenArea.get_overlapping_bodies():
				if opened == false:
					global.push_text("Player opened the chest")
					self.animation = "Open"
					global.gold += 5
					global.player.inventory += [global.player.axe]
					global.axe_unlocked = true
					opened = true
