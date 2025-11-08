extends StaticBody2D

@onready var area_2d: Area2D = $Area2D
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var broken_time: Timer = $BrokenTimer

var is_broken = false

func _ready() -> void:
	pass 

func _process(_delta: float) -> void:
	if is_broken:
		return
	
	var bodies = area_2d.get_overlapping_bodies()
	
	for body in bodies:
		# Verificação simples se o Oneway não estiver habilitado
		#if bodies.size() > 0:
			#animation.play("broken")
		
		var player: CharacterBody2D = body
		if player.is_on_floor():
			is_broken = true
			animation.play("broken")
			broken_time.start()


func _on_broken_timer_timeout() -> void:
	animation.play("falling")
	collision_layer = 0
	
	var final_position = global_position + Vector2.DOWN * 40
	var fall_tween = create_tween()
	fall_tween.set_trans(Tween.TRANS_QUAD)
	fall_tween.set_ease(Tween.EASE_IN)
	fall_tween.tween_property(self, "global_position", final_position, 0.5)
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(animation, "modulate:a", 0, 0.5)
