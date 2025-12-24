extends Area3D
class_name Projectile

@export var speed := 18.0
@export var lifetime := 2.5

var direction := Vector3.ZERO
var damage := 45.0
var team := 1
var source_unit: Unit

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body is Unit:
		if body.team != team:
			var source: Node = self
			if source_unit != null:
				source = source_unit
			body.take_damage(damage, source)
			queue_free()
