extends Sprite

var faded_in = false

func _ready():
	$AnimationPlayer.play("FadeOut")

func _physics_process(delta):
	global_position = global.player_position
	global.attack_area = self
	
func fade_in():
	if faded_in == false:
		global.push_text("fade in")
		$AnimationPlayer.play("FadeIn")
		faded_in = true
	
func fade_out():
	if faded_in == true:
		global.push_text("fade out")
		$AnimationPlayer.play("FadeOut")
		faded_in = false
