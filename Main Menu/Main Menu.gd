extends Control

onready var easy = $Easy      
onready var normal = $Normal  #assigning difficulty buttons variable names
onready var hard = $Hard      

var settingsToggle = false

func _on_StartNewGame_pressed():
	get_tree().change_scene("res://Game World/GameWorld.tscn") #changes the active scene to the game world


func _on_Settings_pressed():
	if settingsToggle == false:    #simple toggle to show the difficulty buttons
		easy.visible = true
		normal.visible = true
		hard.visible = true
		settingsToggle = true
	else:
		easy.visible = false
		normal.visible = false
		hard.visible = false
		settingsToggle = false


func _on_Quit_pressed():
	get_tree().quit() #exits the game


func _on_Easy_pressed():
	global.difficultyMultiplier = 0.75

func _on_Normal_pressed():
	global.difficultyMultiplier = 1

func _on_Hard_pressed():
	global.difficultyMultiplier = 1.25
