extends Node3D
class_name CameraController

@export var follow_speed := 10.0
@export var move_speed := 22.0
@export var edge_margin := 16.0
@export var drag_speed := 0.05
@export var min_zoom := 10.0
@export var max_zoom := 28.0
@export var zoom_step := 2.0
@export var zoom_smooth := 12.0
@export var use_bounds := true
@export var bounds_min := Vector3(-90, 0, -90)
@export var bounds_max := Vector3(90, 0, 90)

@onready var spring_arm: SpringArm3D = $SpringArm3D
var target: Node3D
var drag_active := false
var zoom_target: float = 0.0

func set_target(node: Node3D) -> void:
	target = node

func _ready() -> void:
	set_process_unhandled_input(true)
	if spring_arm != null:
		zoom_target = spring_arm.spring_length

func _process(delta: float) -> void:
	var move_vector: Vector3 = Vector3.ZERO
	if not drag_active:
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
			zoom_target = clamp(zoom_target - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_target = clamp(zoom_target + zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			drag_active = event.pressed
	elif event is InputEventMouseMotion and drag_active:
		var delta: Vector2 = event.relative
		var move: Vector3 = Vector3(delta.x, 0.0, delta.y) * drag_speed
		global_position += move
		clamp_to_bounds()

func clamp_to_bounds() -> void:
	if not use_bounds:
		return
	var pos: Vector3 = global_position
	pos.x = clamp(pos.x, bounds_min.x, bounds_max.x)
	pos.z = clamp(pos.z, bounds_min.z, bounds_max.z)
	global_position = pos
