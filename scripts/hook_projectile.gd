extends Node3D
class_name HookProjectile

@export var speed := 28.0
@export var return_speed := 30.0
@export var hook_height := 1.2
@export var chain_thickness := 0.08
@export var finish_distance := 1.4

@onready var chain: MeshInstance3D = $Chain

var caster: Node3D
var target_position := Vector3.ZERO
var hooked_unit: Unit
var state := 0

func _ready() -> void:
	if caster != null and is_instance_valid(caster):
		global_position = caster.global_position + Vector3.UP * hook_height

func _physics_process(delta: float) -> void:
	if caster == null or not is_instance_valid(caster):
		queue_free()
		return

	match state:
		0:
			move_outgoing(delta)
		1:
			move_returning(delta)
		2:
			update_attached()

	update_chain()

func move_outgoing(delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	var distance := to_target.length()
	if distance <= 0.001:
		state = 1 if hooked_unit == null else 2
		return
	var step: float = speed * delta
	if distance <= step:
		global_position = target_position
		state = 1 if hooked_unit == null else 2
	else:
		global_position += to_target.normalized() * step

func move_returning(delta: float) -> void:
	var return_pos: Vector3 = caster.global_position + Vector3.UP * hook_height
	var to_return: Vector3 = return_pos - global_position
	var distance := to_return.length()
	if distance <= 0.2:
		queue_free()
		return
	var step: float = return_speed * delta
	if distance <= step:
		global_position = return_pos
		queue_free()
		return
	global_position += to_return.normalized() * step

func update_attached() -> void:
	if hooked_unit == null or not is_instance_valid(hooked_unit) or hooked_unit.is_dead:
		queue_free()
		return
	global_position = hooked_unit.global_position + Vector3.UP * hook_height
	if global_position.distance_to(caster.global_position) <= finish_distance:
		queue_free()

func update_chain() -> void:
	if chain == null:
		return
	var start: Vector3 = caster.global_position + Vector3.UP * hook_height
	var end: Vector3 = global_position
	var direction: Vector3 = end - start
	var length := direction.length()
	if length <= 0.01:
		chain.visible = false
		return
	chain.visible = true
	var mid: Vector3 = start + direction * 0.5
	chain.global_position = mid
	chain.look_at(end, Vector3.UP)
	chain.scale = Vector3(chain_thickness, chain_thickness, length)
