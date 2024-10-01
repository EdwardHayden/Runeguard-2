extends AnimatedSprite

onready var damage = 4 * global.difficultyMultiplier

func _on_Area2D_area_entered(area):
	if area.get_parent() == global.player:
		global.health -= randi() % int(damage) + 1
		self.frame = 0
