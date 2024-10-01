extends KinematicBody2D

const ACCELERATION = 1500
const MAX_SPEED = 200        #movement constants
const FRICTION = 1000

onready var navigation_2d = get_node("../../Navigation2D")
onready var character_animations = $CharacterAnimations
onready var melee_range = $MeleeRange
onready var DEBUG = $Debug
onready var health_bar = $HealthBar
onready var attack_effects = $AttackEffects

var rng = RandomNumberGenerator.new()
var debug_shown = false

var velocity = Vector2.ZERO
var direction_vector = Vector2.ZERO
var previous_position = Vector2.ZERO

var new_path
var move_distance = 0

const stamina_max = 80
var stamina = 80
var health = 10
var damage = 5
var prev_health = health

func _ready():
	health = int(health * global.difficultyMultiplier)
	damage = int(damage * global.difficultyMultiplier)
	health_bar.max_value = health

func _physics_process(delta):
	health_bar.value = health
	if prev_health > health:
		attack_effects.hit()
	prev_health = health
	
	DEBUG.text = "Name: " + str(self) + "\nStamina: " + str(stamina) + "\nHealth: " + str(health) + "\nPosition: " + str(global_position)
	if health <= 0: #checks if the enemy has died
		global.remove_from_turn_order(str(self))
		global.xp += 5
		global.gold += 1
		global.push_text(str(self) + " is dead")
		queue_free() #deletes enemy
		return
	if player_visible() == true and global.player in $InitiativeArea.get_overlapping_bodies():
		visible = true
		if global.turn_order.find(str(self)) != -1: #checks to see if the enemy is already in the turn order
			if global.active_turn == str(self): #checks if it is the enemys turn
				if stamina > 0: #checks if the enemy still has stamina
					if melee_range.get_overlapping_bodies().find(global.player) == -1: #checks to see if enemy is in range
						new_path = navigation_2d.get_simple_path(self.global_position, global.player_position) #gets path to player
						move_along_path(new_path, delta)
					elif stamina >= 40: #checks to see if enemy has enough stamina to attack
						var x = rng.randi_range(1, damage)
						global.health -= x
						stamina -= 40
						global.push_text(str(self) + " attacks player, does " + str(x) + " damage")
					else: #if the enemy is in range but doesnt have enough stamina to attack, its turn ends
						stamina = 0
				else: #enemy has run out of stamina
					velocity = Vector2.ZERO #sets velocity to 0 (stops little jolt at the start of next turn from inertia)
					change_direction(self.global_position) #stops the enemy from running on the spot when inactive
					
					global.cycle_turn_order()
					stamina = stamina_max #resets the stamina ready for next turn
		else:
			global.add_to_turn_order(str(self))
	else:
		if global.turn_order.find(str(self)) != -1:
			global.remove_from_turn_order(str(self))
		visible = false
	
func player_visible():
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(self.global_position, global.player_position, [global.player, self])
	if result:
		return(false)
	else:
		return(true)

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

func move_along_path(path, delta):
	previous_position = self.global_position
	velocity = self.global_position
	velocity = velocity.move_toward(path[1], ACCELERATION*delta) 
	velocity = self.global_position.direction_to(velocity)*MAX_SPEED
	move_and_slide(velocity) #moves to the first point in the path
	change_direction(previous_position) #changes the direction the enemy is facing
	move_distance = pow(pow((self.global_position - previous_position).x, 2)+pow((self.global_position - previous_position).y, 2), 0.5)
	stamina = stamina - (move_distance/10)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_BACKSPACE:
			if debug_shown == false:
				DEBUG.visible = true
				debug_shown = true
			else:
				DEBUG.visible = false
				debug_shown = false
