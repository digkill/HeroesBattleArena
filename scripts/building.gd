extends Unit
class_name Building

@export var can_attack := false
@export var use_team_tint := true

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	navigation_enabled = false
	move_speed = 0.0
	hold_position = true
	super._ready()
	update_team_material()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	hold_position = true

	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0

	attack_timer = max(0.0, attack_timer - delta)
	if health < max_health:
		health = min(max_health, health + health_regen * delta)
	if mana < max_mana:
		mana = min(max_mana, mana + mana_regen * delta)
	if stun_timer > 0.0:
		stun_timer = max(0.0, stun_timer - delta)
		attack_target = null
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not can_attack:
		attack_target = null
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if attack_target == null or not is_instance_valid(attack_target):
		var enemy: Unit = find_nearest_enemy_in_range(aggro_range)
		if enemy != null:
			attack_target = enemy

	var has_valid_attack := attack_target != null and is_instance_valid(attack_target) and not attack_target.is_dead
	if has_valid_attack:
		var distance: float = global_position.distance_to(attack_target.global_position)
		if distance <= attack_range:
			velocity = Vector3.ZERO
			face_point(attack_target.global_position)
			if attack_timer <= 0.0:
				do_attack()
		else:
			attack_target = null
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func set_move_target(_point: Vector3) -> void:
	return

func set_attack_move_target(_point: Vector3) -> void:
	return

func set_hold_position(_enabled: bool) -> void:
	hold_position = true

func set_attack_target(target: Unit) -> void:
	if not can_attack:
		return
	if target == null or target == self:
		return
	attack_target = target
	face_point(target.global_position)
	hold_position = true

func update_team_material() -> void:
	if not use_team_tint or mesh_instance == null:
		return
	var mat := StandardMaterial3D.new()
	if team == 1:
		mat.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
	else:
		mat.albedo_color = Color(0.85, 0.2, 0.2, 1.0)
	mesh_instance.material_override = mat
