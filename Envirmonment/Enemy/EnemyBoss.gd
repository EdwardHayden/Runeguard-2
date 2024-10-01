extends KinematicBody2D

const ACCELERATION = 1500
const MAX_SPEED = 200        #movement constants
const FRICTION = 1000

onready var character_animations = $CharacterAnimations
onready var melee_range = $MeleeRange
onready var DEBUG = $Debug
onready var navigation_2d = get_node("../../Navigation2D")
onready var health_bar = $HealthBar
onready var attack_effects = $AttackEffects

var rng = RandomNumberGenerator.new()

var debug_shown = false

var health = 30
var stamina = 80
var stamina_max = stamina
var damage = 10
var prev_health = health

var dead = false

var new_path

var move_distance = 0

var velocity = Vector2.ZERO
var direction_vector = Vector2.ZERO
var previous_position = Vector2.ZERO

func _ready():
	health = int(health * global.difficultyMultiplier)
	damage = int(damage * global.difficultyMultiplier)
	health_bar.max_value = health
	
func _physics_process(delta):
	DEBUG.text = "Name: " + str(self) + "\nStamina: " + str(stamina) + "\nHealth: " + str(health) + "\nPosition: " + str(global_position)
	health_bar.value = health
	if prev_health > health:
		attack_effects.hit()
	prev_health = health
	
	#death checker
	if health <= 0:
		if dead == false:
			global.remove_from_turn_order(str(self))
			global.player.end_screen(false)
			stamina = 0
			dead = true
		else:
			return
	
	#choose what to do
	if str(self) in global.turn_order: #checking if enemy is in turn order
		if global.active_turn == str(self): #checking if it is the enemys turn
			if stamina > 0: #checking if they still have stamina
				if global.player in melee_range.get_overlapping_bodies(): #checking if player is in attack range
					if stamina > 40: #checking if enemy has enoguh stamina to attack
						var x = rng.randi_range(1, damage) #calculating and inflicting damage
						global.health -= x
						stamina -= 40
						global.push_text(str(self) + " attacks player, does " + str(x) + " damage")
					else:
						stamina = 0 #if enemy has reached player but doesnt have enough stamina to attack, stamina set to 0
				else:
					new_path = navigation_2d.get_simple_path(self.global_position, global.player_position) #gets path to player
					move_along_path(new_path, delta) #follows path
			else:
				velocity = Vector2.ZERO #destroys inertia at the end of turn
				change_direction(self.global_position) #stops walking animation
				global.cycle_turn_order()
				stamina = stamina_max #resets stamina ready for next round
	else:
		global.add_to_turn_order(str(self)) #adds self to turn order if not already in it.
	
			
	

func move_along_path(path, delta):
	previous_position = self.global_position #saved for use later when calculating distance moved
	velocity = self.global_position
	velocity = velocity.move_toward(path[1], ACCELERATION*delta) 
	velocity = self.global_position.direction_to(velocity)*MAX_SPEED
	move_and_slide(velocity) #moves to the first point in the path
	change_direction(previous_position) #changes the direction the enemy is facing
	move_distance = pow(pow((self.global_position - previous_position).x, 2)+pow((self.global_position - previous_position).y, 2), 0.5)
	stamina = stamina - (move_distance/10)

func change_direction(last_pos):
	direction_vector = self.global_position-last_pos
	direction_vector = direction_vector.normalized()
	if direction_vector != Vector2.ZERO:
		if direction_vector.y > 0:
			if direction_vector.x > 0.5:
				character_animations.set_animation("WalkRight")
			elif direction_vector.x < -0.5:
				character_animations.set_animation("WalkLeft")
			else:
				character_animations.set_animation("WalkDown")
		elif direction_vector.y < 0:
			if direction_vector.x > 0.5:
				character_animations.set_animation("WalkRight")
			elif direction_vector.x < -0.5:
				character_animations.set_animation("WalkLeft")
			else:
				character_animations.set_animation("WalkUp")
		else:
			if direction_vector.x > 0:
				character_animations.set_animation("WalkRight")
			elif direction_vector.x < 0:
				character_animations.set_animation("WalkLeft")
	else: 
		if character_animations.get_animation() == "WalkRight":
			character_animations.set_animation("IdleRight")
		elif character_animations.get_animation() == "WalkLeft":
			character_animations.set_animation("IdleLeft")
		elif character_animations.get_animation() == "WalkUp":
			character_animations.set_animation("IdleUp")
		elif character_animations.get_animation() == "WalkDown":
			character_animations.set_animation("IdleDown")

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_BACKSPACE:
			if debug_shown == false:
				DEBUG.visible = true
				debug_shown = true
			else:
				DEBUG.visible = false
				debug_shown = false
