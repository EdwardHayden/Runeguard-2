extends KinematicBody2D


const ACCELERATION = 1800
const MAX_SPEED = 300        #movement constants
const FRICTION = 1200

var velocity = Vector2.ZERO  #keeps track of the velocity vector of the player
var direction_vector = Vector2.ZERO
var previous_position = Vector2.ZERO

onready var player_animations = $PlayerAnimations
onready var stamina_bar = $UI/StaminaBar
onready var stamina_counter = $UI/StaminaBar/StaminaCounter
onready var health_bar = $UI/HealthBar
onready var health_counter = $UI/HealthBar/HealthCounter
onready var mana_bar = $UI/ManaBar
onready var mana_counter = $UI/ManaBar/ManaCounter
onready var xp_bar = $UI/XpBar
onready var melee_range = $MeleeRange
onready var gold_label = $UI/Gold
onready var turn_order_display = $UI/TurnOrder
onready var level_counter = $UI/XpBar/LevelCounter
onready var vignette = $Canvas/Vignette
onready var animation_player = $Canvas/AnimationPlayer
onready var stats_display = $Canvas/StatsDisplay
onready var ui = $UI
onready var hand = $UI/Hotbar/Hand
onready var boon1 = $UI/BoonButtons/Boon1
onready var boon2 = $UI/BoonButtons/Boon2
onready var boon3 = $UI/BoonButtons/Boon3
onready var attack_effects = $AttackEffects

onready var DEBUG_CONSOLE = $UI/DEBUG_CONSOLE

var debug_shown = false

var rng = RandomNumberGenerator.new()

var inventory_shown = false

var vignette_shown = false
var vignette_red = false

var dead = false
var survived = false

var sword = {
	"name" : "Sword",
	"type" : "weapon",
	"damage" : 8,
	"stamina" : 40
}

var axe = {
	"name" : "Axe",
	"type" : "weapon",
	"damage" : 10,
	"stamina" : 20
}

var magic = {
	"name" : "Magic",
	"type" : "spell",
	"damage" : 10,
	"mana" : 2
}

var inventory = [sword, magic]
var equipped = sword

var stamina = 80
var stamina_max = 80
var health = 30
var health_max = 30
var mana = 10
var prev_health = health

var level_req = 10

var move_distance = 0

enum{ACTIVE, INACTIVE, FREE_MOVE} #state machine
var state = FREE_MOVE


func _ready():
	#checking to see if the player is being loaded into the boss level
	if global.prev_stats == true:
		health = global.health
		stamina = global.stamina
		mana = global.mana
		xp_bar.max_value = level_req
		if global.axe_unlocked == true:
			inventory = [sword, axe, magic]
	
	
	#initiating stat bars and global variables
	mana_bar.max_value = mana
	health_bar.max_value = health
	stamina_bar.max_value = stamina
	xp_bar.max_value = level_req
	global.turn_order = ["player"]
	global.active_turn = "player"
	global.player_position = self.global_position
	global.player = self
	global.health = health
	animation_player.current_animation = "Off"

func _physics_process(delta):
	if global.prev_stats == false and global.xp >= level_req:  #checking for level up
		level_req += level_req
		xp_bar.max_value = level_req
		global.level+= 1
		
		#boons
		boon1.visible = true
		boon1.disabled = false
		boon2.visible = true
		boon2.disabled = false
		boon3.visible = true
		boon3.disabled = false

	if prev_health > health:
		attack_effects.hit()
	prev_health = health
	
	#hot bar item
	if equipped["type"] == "weapon":
		if hand.is_hovered():
			global.attack_area.fade_in()
		else:
			global.attack_area.fade_out()
	elif equipped["type"] == "spell":
		if hand.is_hovered():
			global.attack_area.fade_in()
		else:
			global.attack_area.fade_out()
	hand.text = equipped["name"]
	
	#turn order debug
	var y = "Turn Order: \n"
	for x in len(global.turn_order):
		y += str(x) + " - " + global.turn_order[x] + "\n"
	turn_order_display.text = y
	
	#UI setters
	gold_label.text = "Gold: " + str(global.gold)
	xp_bar.value = global.xp
	level_counter.text = "Level: " + str(global.level)
	health = global.health
	global.mana = mana
	global.stamina = stamina
	mana_bar.value = mana
	mana_counter.text = "Mana: " + str(mana) #update mana bar
	health_bar.value = health
	health_counter.text = "Health: " + str(int(health)) #update health bar
	stamina_bar.value = stamina
	stamina_counter.text = "Stamina: " + str(int(stamina)) #update stamina bar
	
	#checking if player is still alive
	if health < 1:
		state = INACTIVE
		if dead == false:
			stats_display.text = "Level : " + str(global.level) + "\nGold : " + str(global.gold)
			end_screen(true)
			dead = true
			ui.layer = 0
		return
	
	#keeping global position variable updated
	global.player_position = self.global_position
	#console_log(self.global_position)
	
	#setting state
	if len(global.turn_order) > 1:
		if vignette_shown == false:
			vignette_shown = true
			animation_player.play("on")
		if global.active_turn == "player":
			state = ACTIVE
			if vignette_red == true:
				vignette_red = false
				animation_player.play("RedToBlack")
		else:
			if vignette_red == false:
				vignette_red = true
				animation_player.play("BlackToRed")
			state = INACTIVE
	else:
		if vignette_shown == true:
			vignette_shown = false
			animation_player.play("Off")
		state = FREE_MOVE
		
	#state matching - what to do if in a particular state
	match state:
		ACTIVE:
			if stamina > 0:
				stamina_move(delta)
			else:
				state = INACTIVE
				global.cycle_turn_order()
				stamina = stamina_max
		INACTIVE:
			velocity = Vector2.ZERO #sets velocity to 0 (stops little jolt at the start of next turn from inertia)
			change_direction(self.global_position) #stops the enemy from running on the spot when inactive
		FREE_MOVE:
			stamina = stamina_max
			free_move(delta)

#player moves around freely
func free_move(delta):
	previous_position = self.global_position
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector*MAX_SPEED, ACCELERATION*delta)
		#if taking_action == true:
			#get_tree().call_group("HUD", "finish_selection")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	velocity = move_and_slide(velocity)
	change_direction(previous_position)

#player moves while depleting stamina
func stamina_move(delta):
	previous_position = self.global_position
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector*MAX_SPEED, ACCELERATION*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
	velocity = move_and_slide(velocity)
	change_direction(previous_position)
	move_distance = pow(pow((self.global_position - previous_position).x, 2)+pow((self.global_position - previous_position).y, 2), 0.5)
	stamina = stamina - (move_distance/10)

#changes the direction the player animation is facing
func change_direction(last_pos):
	direction_vector = self.global_position-last_pos
	if pow(pow((direction_vector).x, 2)+pow((direction_vector).y, 2), 0.5) > 1:
		direction_vector = direction_vector.normalized()
		if direction_vector.y > 0:
			if direction_vector.x > 0.5:
				player_animations.set_animation("WalkRight")
			elif direction_vector.x < -0.5:
				player_animations.set_animation("WalkLeft")
			else:
				player_animations.set_animation("WalkDown")
		elif direction_vector.y < 0:
			if direction_vector.x > 0.5:
				player_animations.set_animation("WalkRight")
			elif direction_vector.x < -0.5:
				player_animations.set_animation("WalkLeft")
			else:
				player_animations.set_animation("WalkUp")
		else:
			if direction_vector.x > 0:
				player_animations.set_animation("WalkRight")
			elif direction_vector.x < 0:
				player_animations.set_animation("WalkLeft")
	else: 
		if player_animations.get_animation() == "WalkRight":
			player_animations.set_animation("IdleRight")
		elif player_animations.get_animation() == "WalkLeft":
			player_animations.set_animation("IdleLeft")
		elif player_animations.get_animation() == "WalkUp":
			player_animations.set_animation("IdleUp")
		elif player_animations.get_animation() == "WalkDown":
			player_animations.set_animation("IdleDown")

#pushing text to the debug console
func console_log(text):
	DEBUG_CONSOLE.text += "\n" + str(text)

#opening the debug menu
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_BACKSPACE:
			if debug_shown == false:
				turn_order_display.visible = true
				DEBUG_CONSOLE.visible = true
				debug_shown = true
			else:
				turn_order_display.visible = false
				DEBUG_CONSOLE.visible = false
				debug_shown = false
		if event.pressed and event.scancode == KEY_ENTER:
			if inventory_shown == false:
				$UI/Sword.visible = true
				$UI/Sword.disabled = false
				$UI/Axe.visible = true
				if axe in inventory:
					$UI/Axe.disabled = false
				$UI/Magic.visible = true
				$UI/Magic.disabled = false
				inventory_shown = true
			else:
				$UI/Sword.visible = false
				$UI/Sword.disabled = true
				$UI/Axe.visible = false
				$UI/Axe.disabled = true
				$UI/Magic.visible = false
				$UI/Magic.disabled = true
				inventory_shown = false


func _on_Restart_pressed():
	get_tree().change_scene("res://Game World/GameWorld.tscn")
	
func _on_Quit_pressed():
	get_tree().quit()

func _on_Sword_pressed():
	equipped = sword

func _on_Axe_pressed():
	equipped = axe

func _on_Magic_pressed():
	equipped = magic

func _on_Hand_pressed():
	if equipped["type"] == "weapon":
		if stamina >= equipped["stamina"]:
			if len(melee_range.get_overlapping_bodies()) != 0:
				stamina -= equipped["stamina"]
				for x in melee_range.get_overlapping_bodies():
					console_log(x)
					if str(x)[0] == "E": #selects all the enemys from the surrounding areas
						var z = rng.randi_range(1, equipped["damage"]) 
						x.health -= z
						console_log("player damaged " + str(x) + " for " + str(z) + " damage")
	elif equipped["type"] == "spell":
		if mana >= equipped["mana"]:
			if len(melee_range.get_overlapping_bodies()) != 0:
				mana -= equipped["mana"]
				for x in melee_range.get_overlapping_bodies():
					console_log(x)
					if str(x)[0] == "E": #selects all the enemys from the surrounding areas
						var z = rng.randi_range(1, equipped["damage"]) 
						x.health -= z
						console_log("player damaged " + str(x) + " for " + str(z) + " damage")

func _on_Boon1_pressed():
	health_max = health_max*1.5
	health_bar.max_value = health_max
	global.health = health_max
	boon1.visible = false
	boon1.disabled = true
	boon2.visible = false
	boon2.disabled = true
	boon3.visible = false
	boon3.disabled = true	

func _on_Boon2_pressed():
	stamina_max = stamina_max*1.5
	stamina_bar.max_value = stamina_max
	stamina = stamina_max
	boon1.visible = false
	boon1.disabled = true
	boon2.visible = false
	boon2.disabled = true
	boon3.visible = false
	boon3.disabled = true

func _on_Boon3_pressed():
	global.gold += 10
	boon1.visible = false
	boon1.disabled = true
	boon2.visible = false
	boon2.disabled = true
	boon3.visible = false
	boon3.disabled = true

func end_screen(death):
	if death == true: #checks to see if the function was called from the player death or player survival
		animation_player.play("Death")
	else:
		state = INACTIVE
		console_log("Survived")
		$Canvas/GameOver.text = "You Survived" #changes text
		stats_display.text = "Level : " + str(global.level) + "\nGold : " + str(global.gold)
		animation_player.play("Survived") #this animation is the same as the death animation with text colour changed to green
		ui.layer = 0
