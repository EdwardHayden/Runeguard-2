extends Node2D

onready var slash = $Slash
onready var blood = $Blood

var rng = RandomNumberGenerator.new()

func hit():
	var x = rng.randi_range(1, 5)
	if x == 1:
		blood.animation = "BloodA"
	elif x == 2:
		blood.animation = "BloodB"
	elif x == 3:
		blood.animation = "BloodC"
	elif x == 4:
		blood.animation = "BloodD"
	elif x == 5:
		blood.animation = "BloodE"
	blood.frame = 0
	slash.frame = 0
