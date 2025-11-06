extends CharacterBody2D

enum SkeletonState {
	walk,
	dead,
	attack
}

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_position: Node2D = $BonePosition

const bone = preload("res://enties/bone.tscn")

const SPEED = 7.0
const JUMP_VELOCITY = -400.0

var status: SkeletonState

var direction = 1
var can_throw = true

func _ready() -> void:
	go_to_walk_state()
	return

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.dead:
			dead_state(delta)
		SkeletonState.attack:
			attack_state(delta)

	move_and_slide()

func walk_state(_delta):
	if animation.frame == 4 or animation.frame == 4:
		velocity.x = SPEED * direction
	else:
		velocity.x = 0
	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if !floor_detector.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if player_detector.is_colliding():
		go_to_attack_state()
		return

func dead_state(_delta):
	pass

func attack_state(_delta):
	if animation.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

#------------ go to -------------------

func go_to_walk_state():
	status = SkeletonState.walk
	animation.play("walk")
	return	

func go_to_dead_state():
	status = SkeletonState.dead
	animation.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	return

func go_to_attack_state():
	status = SkeletonState.attack
	animation.play("attack")
	velocity = Vector2.ZERO
	can_throw = true

#------------ go to end -------------------

func take_damage():
	go_to_dead_state()
	return

func throw_bone():
	var new_bone = bone.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_position.global_position
	new_bone.set_direction(self.direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animation.animation == "attack":
		go_to_walk_state()
		return
