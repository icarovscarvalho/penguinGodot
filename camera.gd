extends Camera2D

var target: Node2D

func _ready() -> void:
	get_target()
	make_current()

func _process(delta: float) -> void:
	if target:
		position = target.position

func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.is_empty():
		push_error("Player not Found")
		return
	
	target = nodes[0]
