extends Node
var difficultyMultiplier = 1
var turn_order = []
var active_turn
var player_position
var player
var health
var stamina
var mana
var gold=0
var xp=0
var level = 1
var lever_pulled = false
var axe_unlocked = false

var prev_stats = false

var attack_area

func cycle_turn_order():
	turn_order.erase(active_turn)
	turn_order += [active_turn]
	active_turn = turn_order[0]
	push_text("Turn order cycled, active turn: " + active_turn)

func add_to_turn_order(target):
	turn_order += [target]
	push_text(target + " added to turn order")
	
func remove_from_turn_order(target):
	turn_order.erase(target)
	if active_turn == target:
		active_turn = turn_order[0]
	push_text(target + " removed from turn order")

func push_text(text):
	player.console_log(text)

