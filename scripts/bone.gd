extends Area2D

@onready var anim_bone: AnimatedSprite2D = $AnimatedSprite2D
@onready var bone_destruction: Timer = $SelfDestructionTimer

var speed = 100
var direction = 1

func _process(delta: float) -> void:
	position.x += speed * delta * direction

func set_direction(skeleton_direction):
	direction = skeleton_direction
	anim_bone.flip_h = direction < 0

func _on_self_destruction_timer_timeout() -> void:
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
