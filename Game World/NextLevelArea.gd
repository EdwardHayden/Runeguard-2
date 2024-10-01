extends Area2D

func _physics_process(delta):
	if global.lever_pulled == true:
		if global.player in self.get_overlapping_bodies():
			global.push_text("Next Level")
			global.prev_stats = true
			get_tree().change_scene("res://Game World/BossRoom.tscn")
			
