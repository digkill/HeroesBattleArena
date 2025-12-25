extends Node3D
class_name CameraController

@export var follow_speed := 10.0
@export var move_speed := 22.0
@export var edge_margin := 16.0
@export var drag_speed := 0.05
@export var min_zoom := 10.0
@export var max_zoom := 28.0
@export var zoom_step := 4.0
@export var zoom_smooth := 12.0
@export var use_bounds := true
@export var bounds_min := Vector3(-120, 0, -120)
@export var bounds_max := Vector3(120, 0, 120)
@export var camera_collision_mask := 1
@export var camera_collision_radius := 0.4
@export var camera_collision_margin := 0.05
@export var zoom_block_on_collision := true
@export var zoom_block_ray_offset := 1.2
@export var zoom_block_margin := 0.2
@export var spring_collision_enabled := false
@export var rotation_speed := 2.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
var target: Node3D
var drag_active := false
var rotate_active := false
var zoom_target: float = 0.0

func set_target(node: Node3D) -> void:
	target = node

func _ready() -> void:
	set_process_unhandled_input(true)
	setup_spring_arm_collision()
	if spring_arm != null:
		zoom_target = spring_arm.spring_length

func _process(delta: float) -> void:
	var move_vector: Vector3 = Vector3.ZERO
	if not drag_active and not rotate_active:
		var viewport: Viewport = get_viewport()
		var mouse_pos: Vector2 = viewport.get_mouse_position()
		var size: Vector2 = viewport.get_visible_rect().size
		if mouse_pos.x <= edge_margin:
			move_vector.x -= 1.0
		elif mouse_pos.x >= size.x - edge_margin:
			move_vector.x += 1.0
		if mouse_pos.y <= edge_margin:
			move_vector.z -= 1.0
		elif mouse_pos.y >= size.y - edge_margin:
			move_vector.z += 1.0

	if move_vector.length() > 0.0:
		move_vector = move_vector.normalized() * move_speed * delta
		global_position += move_vector

	if Input.is_action_pressed("center_hero") and target != null:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

	if spring_arm != null:
		var t: float = clamp(zoom_smooth * delta, 0.0, 1.0)
		spring_arm.spring_length = lerp(spring_arm.spring_length, zoom_target, t)

	clamp_to_bounds()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var next_zoom: float = clamp(zoom_target - zoom_step, min_zoom, max_zoom)
			if not zoom_block_on_collision or can_zoom_to(next_zoom):
				zoom_target = next_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_target = clamp(zoom_target + zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				# При зажатии колесика - начинаем вращение
				rotate_active = true
				drag_active = false
			else:
				# При отпускании - останавливаем вращение
				rotate_active = false
	elif event is InputEventMouseMotion:
		if rotate_active and spring_arm != null:
			# Вращаем камеру вокруг вертикальной оси
			var delta: Vector2 = event.relative
			var rotation_delta: float = -delta.x * rotation_speed * 0.01
			spring_arm.rotation.y += rotation_delta
		elif drag_active:
			var delta: Vector2 = event.relative
			var move: Vector3 = Vector3(delta.x, 0.0, delta.y) * drag_speed
			global_position += move
			clamp_to_bounds()
	elif event is InputEventMagnifyGesture:
		var factor: float = event.factor
		if absf(factor - 1.0) < 0.001:
			return
		var next_zoom: float = clamp(zoom_target / factor, min_zoom, max_zoom)
		if not zoom_block_on_collision or can_zoom_to(next_zoom):
			zoom_target = next_zoom

func clamp_to_bounds() -> void:
	if not use_bounds:
		return
	var pos: Vector3 = global_position
	pos.x = clamp(pos.x, bounds_min.x, bounds_max.x)
	pos.z = clamp(pos.z, bounds_min.z, bounds_max.z)
	global_position = pos

func setup_spring_arm_collision() -> void:
	if spring_arm == null:
		return
	var has_shape := false
	var has_mask := false
	var has_margin := false
	for prop in spring_arm.get_property_list():
		var prop_name: String = str(prop.get("name", ""))
		if prop_name == "shape":
			has_shape = true
		elif prop_name == "collision_mask":
			has_mask = true
		elif prop_name == "margin":
			has_margin = true
	if has_mask:
		spring_arm.collision_mask = camera_collision_mask if spring_collision_enabled else 0
	if has_shape:
		var shape := SphereShape3D.new()
		shape.radius = camera_collision_radius
		spring_arm.shape = shape
	if has_margin:
		spring_arm.margin = camera_collision_margin

func can_zoom_to(length: float) -> bool:
	if spring_arm == null:
		return true
	var world: World3D = get_world_3d()
	if world == null:
		return true
	var origin: Vector3 = spring_arm.global_position + Vector3.UP * zoom_block_ray_offset
	var dir: Vector3 = -spring_arm.global_transform.basis.z
	if dir.length() <= 0.0001:
		return true
	dir = dir.normalized()
	var target_pos: Vector3 = origin + dir * length
	var query := PhysicsRayQueryParameters3D.create(origin, target_pos)
	query.collision_mask = camera_collision_mask
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
	var hit_dist: float = origin.distance_to(hit_pos)
	return hit_dist <= zoom_block_margin
