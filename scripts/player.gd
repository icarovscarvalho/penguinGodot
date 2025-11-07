extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	dead,
	grab,
	swinming,
}

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer
@onready var hitbox_collision_shape: CollisionShape2D = $hitbox/CollisionShape2D
@onready var leftWa_wall_detector: RayCast2D = $LeftWallDetector
@onready var rightWa_wall_detector: RayCast2D = $RightWallDetector

@export var max_speed = 100.0
@export var accel = 500
@export var decel = 500
@export var slide_decel = 50
@export var grab_decel = 45
@export var grab_gravity = 100
@export var grab_jump_reflect = 100
@export var water_accel = 100
@export var water_decel = 200
@export var water_fall_gravity = 200
@export var swimming_push = -50

const JUMP_VELOCITY = -300

var jump_count = 0
@export var max_jump = 2
var direction = 0
var status: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.dead:
			dead_state(delta)
		PlayerState.grab:
			grab_state(delta)
		PlayerState.swinming:
			swinming_state(delta)
	
	move_and_slide()

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
	
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return

func jump_state(delta):
	apply_gravity(delta)
	move(delta)
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	
	if (leftWa_wall_detector.is_colliding() or rightWa_wall_detector.is_colliding()) && is_on_wall():
		go_to_grab_state()
		return

func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func slide_state(delta):
	apply_gravity(delta)
	
	velocity.x = move_toward(velocity.x, 0, slide_decel * delta)
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
	
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return

func dead_state(_delta):
	pass

func grab_state(delta):
	velocity.y = grab_decel * (delta * grab_gravity)
	
	if leftWa_wall_detector.is_colliding():
		animation.flip_h = false
		direction = 1
	elif rightWa_wall_detector.is_colliding():
		animation.flip_h = true
		direction = -1
	else:
		go_to_fall_state()
		return
	
	if is_on_floor():
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.x = direction * grab_jump_reflect
		go_to_jump_state()

func swinming_state(delta):
	var vertical_direction = Input.get_axis("jump", "duck")
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, water_accel * direction, 200 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, water_decel * delta)
	
	#Player sofre ação da gravidade em Y
	velocity.y += water_accel * delta
	
	# Limita a velocidade máxima de queda ao entrar na água
	velocity.y = min(velocity.y, water_fall_gravity)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = swimming_push
	
	#Assume controle vertical(Y) do Player
	#if vertical_direction:
		#velocity.y = move_toward(velocity.y, water_accel * vertical_direction, 200 * delta)
	#else:
		#velocity.y = move_toward(velocity.y, 0, water_decel * delta)
	
	# Limita a velocidade máxima de queda ao entrar na água
	# velocity.y = min(velocity.y, water_fall_gravity)

#------------ go To --------------

func go_to_idle_state():
	status = PlayerState.idle
	animation.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	animation.play("walk")
	jump_count = 0

func go_to_jump_state():
	status = PlayerState.jump
	animation.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_fall_state():
	status = PlayerState.fall
	animation.play("fall")

func go_to_duck_state():
	status = PlayerState.duck
	animation.play("duck")
	set_small_collider()

func exit_from_duck_state():
	set_default_collider()

func go_to_slide_state():
	status = PlayerState.slide
	animation.play("slide")
	set_small_collider()

func exit_from_slide_state():
	set_default_collider()

func go_to_dead_state():
	if status == PlayerState.dead:
		return
	
	status = PlayerState.dead
	animation.play("dead")
	velocity.x = 0
	reload_timer.start()
	return

func go_to_grab_state():
	status = PlayerState.grab
	animation.play("grab")

func go_to_swinming_state():
	status = PlayerState.swinming
	animation.play("swiming")

# ------------ end go To ---------------

func update_direction():
	direction = Input.get_axis("left", "right")
	
	# Troca direção do personagem
	if direction > 0:
		animation.flip_h = false
	elif direction < 0:
		animation.flip_h = true

func move(delta):
	# Movimentação
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func can_jump() -> bool:
	return jump_count < max_jump

func set_small_collider():
	collision_shape.shape.height = 11
	collision_shape.position.y = 3
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3.5

func set_default_collider():
	collision_shape.shape.height = 15
	collision_shape.position.y = 0
	
	hitbox_collision_shape.shape.size.y = 16
	hitbox_collision_shape.position.y = 1

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_dead_state()
	elif body.is_in_group("Water"):
		go_to_swinming_state()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		jump_count = 0
		go_to_jump_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		#inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		go_to_dead_state()

func hit_lethal_area():
	go_to_dead_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
