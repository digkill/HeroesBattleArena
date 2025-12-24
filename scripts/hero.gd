extends Unit
class_name Hero

signal level_changed(level: int)
signal gold_changed(gold: int)
signal xp_changed(xp: int, xp_to_next: int)

@export var hero_def: HeroDefinition

@export var hero_name := "Rakshasa"
var main_attribute: StringName = &""
@export var base_strength := 18.0
@export var base_agility := 22.0
@export var base_intelligence := 16.0
@export var strength_gain := 2.1
@export var agility_gain := 2.8
@export var intelligence_gain := 1.7
@export var base_attack_damage := 22.0
@export var base_attack_cooldown := 1.6
@export var base_move_speed := 6.0

var strength := 0.0
var agility := 0.0
var intelligence := 0.0
var bonus_strength := 0.0
var bonus_agility := 0.0
var bonus_intelligence := 0.0
var bonus_move_speed := 0.0
var bonus_attack_damage := 0.0
var bonus_attack_speed := 0.0
var flesh_heap_stacks: int = 0
var flesh_heap_bonus_strength: float = 0.0

var level := 1
var xp := 0
var xp_to_next := 200
var gold := 600

var inventory: Inventory = Inventory.new()
var ability_defs: Array[AbilityDefinition] = []

var ability_timers: Array[float] = [0.0, 0.0, 0.0, 0.0]
var last_mouse_pos := Vector2.ZERO
var attack_move_queued := false

var projectile_scene: PackedScene = preload("res://scenes/units/projectile.tscn")
var summon_scene: PackedScene = preload("res://scenes/units/summon.tscn")
var aoe_scene: PackedScene = preload("res://scenes/effects/aoe_zone.tscn")
var hook_projectile_scene: PackedScene = preload("res://scenes/effects/hook_projectile.tscn")

var channeling := false
var channel_timer := 0.0
var channel_tick_timer := 0.0
var channel_tick_interval := 0.5
var channel_damage_per_tick := 0.0
var channel_range := 0.0
var channel_target: Unit

var anim_idle: StringName = &""
var anim_move: StringName = &""
var anim_attack: StringName = &""
var anim_cast: StringName = &""
var anim_death: StringName = &""
var anim_hit: StringName = &""
var anim_jump: StringName = &""
var anim_skill1: StringName = &""
var anim_skill2: StringName = &""
var anim_skill3: StringName = &""
var anim_skill4: StringName = &""
var anim_ultimate: StringName = &""
var anim_teleportation: StringName = &""
var anim_stun: StringName = &""
var anim_won: StringName = &""
var anim_fall: StringName = &""
var anim_loss: StringName = &""
var anim_use_item: StringName = &""
var anim_player: AnimationPlayer
var current_anim: StringName = &""
var action_anim_timer := 0.0
var model_root: Node3D

func _ready() -> void:
	apply_hero_definition()
	recalculate_stats()
	super._ready()
	setup_animation()
	apply_model_transform()
	gold_changed.emit(gold)
	xp_changed.emit(xp, xp_to_next)
	level_changed.emit(level)
	set_process(true)
	set_process_unhandled_input(true)

func apply_hero_definition() -> void:
	if hero_def == null:
		ability_defs = []
		ability_timers.clear()
		return
	hero_name = hero_def.display_name
	main_attribute = hero_def.main_attribute
	base_strength = hero_def.base_strength
	base_agility = hero_def.base_agility
	base_intelligence = hero_def.base_intelligence
	strength_gain = hero_def.strength_gain
	agility_gain = hero_def.agility_gain
	intelligence_gain = hero_def.intelligence_gain
	base_attack_damage = hero_def.base_attack_damage
	base_attack_cooldown = hero_def.base_attack_cooldown
	base_move_speed = hero_def.base_move_speed
	ability_defs = hero_def.abilities.duplicate() as Array[AbilityDefinition]
	ability_timers.clear()
	for _i in range(ability_defs.size()):
		ability_timers.append(0.0)
	flesh_heap_stacks = 0
	flesh_heap_bonus_strength = 0.0

	anim_idle = hero_def.anim_idle
	anim_move = hero_def.anim_move
	anim_attack = hero_def.anim_attack
	anim_cast = hero_def.anim_cast
	anim_death = hero_def.anim_death
	anim_hit = hero_def.anim_hit
	anim_jump = hero_def.anim_jump
	anim_skill1 = hero_def.anim_skill1
	anim_skill2 = hero_def.anim_skill2
	anim_skill3 = hero_def.anim_skill3
	anim_skill4 = hero_def.anim_skill4
	anim_ultimate = hero_def.anim_ultimate
	anim_teleportation = hero_def.anim_teleportation
	anim_stun = hero_def.anim_stun
	anim_won = hero_def.anim_won
	anim_fall = hero_def.anim_fall
	anim_loss = hero_def.anim_loss
	anim_use_item = hero_def.anim_use_item

func setup_animation() -> void:
	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer

func apply_model_transform() -> void:
	if hero_def == null:
		return
	model_root = find_model_root()
	if model_root == null and hero_def.model_scene != null:
		var instance: Node = hero_def.model_scene.instantiate()
		var node: Node3D = instance as Node3D
		if node != null:
			add_child(node)
			model_root = node
	if model_root == null:
		return
	model_root.position = hero_def.model_offset
	model_root.rotation_degrees = hero_def.model_rotation_degrees
	model_root.scale = hero_def.model_scale

func find_model_root() -> Node3D:
	if hero_def != null and hero_def.model_node_path != NodePath():
		var node: Node = get_node_or_null(hero_def.model_node_path)
		var model: Node3D = node as Node3D
		if model != null:
			return model
	var fallback: Node3D
	for child in get_children():
		var node3d: Node3D = child as Node3D
		if node3d == null:
			continue
		if node3d is CollisionShape3D:
			continue
		var node_name := String(node3d.name).to_lower()
		if node_name.find("model") >= 0:
			return node3d
		if fallback == null:
			fallback = node3d
	return fallback

func _process(delta: float) -> void:
	for i in range(ability_timers.size()):
		ability_timers[i] = max(0.0, ability_timers[i] - delta)

	update_channeling(delta)
	if channeling:
		if Input.is_action_just_pressed("stop_command"):
			stop_actions()
		elif Input.is_action_just_pressed("attack_command"):
			queue_attack_command()
		elif Input.is_action_just_pressed("hold_position"):
			cancel_channel()
			set_hold_position(true)
		return

	if Input.is_action_just_pressed("ability_1"):
		cast_ability(0)
	if Input.is_action_just_pressed("ability_2"):
		cast_ability(1)
	if Input.is_action_just_pressed("ability_3"):
		cast_ability(2)
	if Input.is_action_just_pressed("ability_4"):
		cast_ability(3)

	if Input.is_action_just_pressed("item_1"):
		use_item(0)
	if Input.is_action_just_pressed("item_2"):
		use_item(1)
	if Input.is_action_just_pressed("item_3"):
		use_item(2)

	if Input.is_action_just_pressed("attack_command"):
		queue_attack_command()
	if Input.is_action_just_pressed("hold_position"):
		set_hold_position(true)
	if Input.is_action_just_pressed("stop_command"):
		stop_actions()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_animation_state(delta)

func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	if channeling:
		if event is InputEventMouseButton and event.pressed:
			cancel_channel()
		elif event is InputEventScreenTouch and event.pressed:
			cancel_channel()
	if event is InputEventMouseMotion:
		last_mouse_pos = event.position
	elif event is InputEventMouseButton and event.pressed:
		last_mouse_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			if attack_move_queued:
				issue_attack_move(event.position)
				attack_move_queued = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if attack_move_queued:
				issue_attack_move(event.position)
			else:
				issue_move_or_attack(event.position)
			attack_move_queued = false
	elif event is InputEventScreenTouch and event.pressed:
		last_mouse_pos = event.position
		if attack_move_queued:
			issue_attack_move(event.position)
		else:
			issue_move_or_attack(event.position)
		attack_move_queued = false

func issue_move_or_attack(screen_pos: Vector2) -> void:
	if channeling:
		cancel_channel()
	var hit: Dictionary = get_mouse_hit(screen_pos)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider", null)
	var target_pos: Vector3 = hit.get("position", global_position)
	var unit: Unit = collider as Unit
	if unit != null and is_enemy(unit):
		set_attack_target(unit)
		has_move_target = false
	else:
		attack_target = null
		set_move_target(target_pos)

func issue_attack_move(screen_pos: Vector2) -> void:
	if channeling:
		cancel_channel()
	var hit: Dictionary = get_mouse_hit(screen_pos)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider", null)
	var target_pos: Vector3 = hit.get("position", global_position)
	var unit: Unit = collider as Unit
	if unit != null and is_enemy(unit):
		set_attack_target(unit)
		has_move_target = false
	else:
		set_attack_move_target(target_pos)

func issue_move_to_world(target_pos: Vector3) -> void:
	if channeling:
		cancel_channel()
	attack_target = null
	set_move_target(target_pos)

func queue_attack_command() -> void:
	if channeling:
		cancel_channel()
	attack_move_queued = true

func stop_actions() -> void:
	if channeling:
		cancel_channel()
	stop()
	attack_move_queued = false

func update_animation_state(delta: float) -> void:
	if is_dead:
		return
	if channeling:
		return
	if action_anim_timer > 0.0:
		action_anim_timer = max(0.0, action_anim_timer - delta)
		if action_anim_timer > 0.0:
			return
	if velocity.length() > 0.1 or has_move_target:
		play_animation(anim_move)
	else:
		play_animation(anim_idle)

func play_action_animation(name: StringName) -> void:
	var anim_name: StringName = name
	if anim_name == StringName():
		anim_name = anim_cast
	if anim_name == StringName():
		return
	var length: float = get_animation_length(anim_name)
	if length <= 0.0:
		length = 0.35
	action_anim_timer = max(action_anim_timer, length)
	play_animation(anim_name)

func play_animation(name: StringName) -> void:
	if anim_player == null or name == StringName():
		return
	if name == current_anim:
		return
	var anim_key: String = String(name)
	if not anim_player.has_animation(anim_key):
		return
	anim_player.play(anim_key)
	current_anim = name

func get_animation_length(name: StringName) -> float:
	if anim_player == null:
		return 0.0
	var anim_key: String = String(name)
	if not anim_player.has_animation(anim_key):
		return 0.0
	var anim: Animation = anim_player.get_animation(anim_key)
	if anim == null:
		return 0.0
	return anim.length

func get_mouse_hit(screen_pos: Vector2) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 2000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 3
	return get_world_3d().direct_space_state.intersect_ray(query)

func get_ability_fallback_anim(index: int) -> StringName:
	match index:
		0:
			return anim_skill1
		1:
			return anim_skill2
		2:
			return anim_skill3
		3:
			if anim_ultimate != StringName():
				return anim_ultimate
			return anim_skill4
	return StringName()

func cast_ability(index: int) -> void:
	if channeling:
		return
	var ability: AbilityDefinition = get_ability_def(index)
	if ability == null:
		return
	if index < 0 or index >= ability_timers.size():
		return
	if ability_timers[index] > 0.0:
		return
	var mana_cost: float = ability.mana_cost
	if not spend_mana(mana_cost):
		return
	ability_timers[index] = ability.cooldown

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var hit: Dictionary = get_mouse_hit(mouse_pos)
	var target_pos: Vector3 = hit.get("position", global_position)

	var cast_anim: StringName = ability.animation
	if cast_anim == StringName():
		cast_anim = get_ability_fallback_anim(index)
	if cast_anim == StringName():
		cast_anim = anim_cast
	play_action_animation(cast_anim)

	match ability.ability_id:
		&"shadow_slash":
			ability_shadow_slash(target_pos, ability)
		&"smoke_bomb":
			ability_smoke_bomb(target_pos, ability)
		&"razor_shuriken":
			ability_razor_shuriken(target_pos, ability)
		&"pack_call":
			ability_pack_call()
		&"meat_hook":
			ability_meat_hook(target_pos, ability)
		&"rot":
			ability_rot(ability)
		&"flesh_heap":
			ability_flesh_heap()
		&"dismember":
			ability_dismember(ability)

func ability_shadow_slash(target_pos: Vector3, ability: AbilityDefinition) -> void:
	var range: float = ability.range
	var direction: Vector3 = target_pos - global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = -transform.basis.z
	var distance: float = min(range, direction.length())
	var dash_target: Vector3 = global_position + direction.normalized() * distance
	global_position = dash_target

	var radius: float = ability.radius
	var damage: float = ability.damage
	for unit in get_tree().get_nodes_in_group("unit"):
		if unit is Unit and is_enemy(unit):
			if unit.global_position.distance_to(global_position) <= radius:
				unit.take_damage(damage, self)

func ability_smoke_bomb(target_pos: Vector3, ability: AbilityDefinition) -> void:
	var aoe: AoEZone = aoe_scene.instantiate() as AoEZone
	if aoe == null:
		return
	aoe.global_position = target_pos
	aoe.team = team
	aoe.damage_per_tick = ability.damage
	aoe.source_unit = self
	get_parent().add_child(aoe)

func ability_razor_shuriken(target_pos: Vector3, ability: AbilityDefinition) -> void:
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		return
	projectile.global_position = global_position + Vector3.UP * 1.2
	var direction: Vector3 = target_pos - projectile.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = -transform.basis.z
	projectile.direction = direction.normalized()
	projectile.team = team
	projectile.damage = ability.damage
	projectile.source_unit = self
	get_parent().add_child(projectile)

func ability_pack_call() -> void:
	for i in range(3):
		var summon: Summon = summon_scene.instantiate() as Summon
		if summon == null:
			return
		summon.team = team
		summon.summoner = self
		var angle := deg_to_rad(120 * i)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * 2.0
		summon.global_position = global_position + offset
		get_parent().add_child(summon)

func ability_meat_hook(target_pos: Vector3, ability: AbilityDefinition) -> void:
	var range: float = ability.range
	var direction: Vector3 = target_pos - global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = -transform.basis.z
	var origin: Vector3 = global_position + Vector3.UP * 1.2
	var to: Vector3 = origin + direction.normalized() * range
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.exclude = [self]
	query.collision_mask = 3
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var hit_pos: Vector3 = to
	var hooked_unit: Unit
	if not hit.is_empty():
		hit_pos = hit.get("position", to)
		var unit: Unit = hit.get("collider", null) as Unit
		if unit != null and is_enemy(unit) and not (unit is Building):
			hooked_unit = unit
			unit.take_damage(ability.damage, self)
			pull_unit_to(unit, ability)
	spawn_hook_visual(origin, hit_pos, hooked_unit, ability)

func ability_rot(ability: AbilityDefinition) -> void:
	var aoe: AoEZone = aoe_scene.instantiate() as AoEZone
	if aoe == null:
		return
	aoe.team = team
	aoe.damage_per_tick = ability.damage
	aoe.source_unit = self
	if ability.duration > 0.0:
		aoe.duration = ability.duration
	if ability.tick_interval > 0.0:
		aoe.tick_interval = ability.tick_interval
	if ability.radius > 0.0:
		var scale_factor: float = ability.radius / 4.0
		aoe.scale = Vector3.ONE * scale_factor
	add_child(aoe)
	aoe.position = Vector3.ZERO

func ability_flesh_heap() -> void:
	return

func ability_dismember(ability: AbilityDefinition) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var hit: Dictionary = get_mouse_hit(mouse_pos)
	if hit.is_empty():
		return
	var unit: Unit = hit.get("collider", null) as Unit
	if unit == null or not is_enemy(unit):
		return
	if unit is Building:
		return
	if ability.range > 0.0 and global_position.distance_to(unit.global_position) > ability.range:
		return
	start_dismember_channel(unit, ability)

func start_dismember_channel(target: Unit, ability: AbilityDefinition) -> void:
	if target == null or not is_instance_valid(target):
		return
	stop()
	attack_move_queued = false
	channeling = true
	channel_target = target
	channel_range = max(ability.range, attack_range)
	channel_timer = max(0.1, ability.duration)
	if channel_timer <= 0.1 and ability.stun_duration > 0.0:
		channel_timer = max(0.1, ability.stun_duration)
	channel_tick_interval = ability.tick_interval if ability.tick_interval > 0.0 else 0.5
	channel_tick_timer = 0.0
	var ticks: int = max(1, int(ceil(channel_timer / channel_tick_interval)))
	channel_damage_per_tick = ability.damage / float(ticks) if ability.damage > 0.0 else 0.0
	apply_stun(channel_timer)
	target.apply_stun(max(channel_timer, ability.stun_duration))
	face_point(target.global_position)
	if anim_ultimate != StringName():
		action_anim_timer = max(action_anim_timer, channel_timer)
		play_animation(anim_ultimate)

func update_channeling(delta: float) -> void:
	if not channeling:
		return
	if channel_target == null or not is_instance_valid(channel_target) or channel_target.is_dead:
		cancel_channel()
		return
	if channel_target.global_position.distance_to(global_position) > channel_range + 0.5:
		cancel_channel()
		return
	channel_timer -= delta
	channel_tick_timer -= delta
	if channel_tick_timer <= 0.0:
		channel_tick_timer = channel_tick_interval
		if channel_damage_per_tick > 0.0:
			channel_target.take_damage(channel_damage_per_tick, self)
	face_point(channel_target.global_position)
	if channel_timer <= 0.0:
		cancel_channel()

func cancel_channel() -> void:
	if not channeling:
		return
	if channel_target != null and is_instance_valid(channel_target):
		channel_target.stun_timer = 0.0
	channeling = false
	channel_target = null
	channel_timer = 0.0
	channel_tick_timer = 0.0
	channel_damage_per_tick = 0.0
	channel_range = 0.0
	if stun_timer > 0.0:
		stun_timer = 0.0

func pull_unit_to(unit: Unit, ability: AbilityDefinition) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var pull_duration: float = max(0.05, ability.pull_duration)
	var pull_offset: float = ability.pull_offset
	var direction: Vector3 = unit.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = -transform.basis.z
	var target_pos: Vector3 = global_position + direction.normalized() * pull_offset
	unit.stop()
	unit.apply_stun(pull_duration)
	var tween := get_tree().create_tween()
	tween.tween_property(unit, "global_position", target_pos, pull_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func spawn_hook_visual(origin: Vector3, hit_pos: Vector3, hooked_unit: Unit, ability: AbilityDefinition) -> void:
	if hook_projectile_scene == null:
		return
	var hook: HookProjectile = hook_projectile_scene.instantiate() as HookProjectile
	if hook == null:
		return
	hook.caster = self
	hook.global_position = origin
	hook.target_position = hit_pos
	hook.hooked_unit = hooked_unit
	var height := origin.y - global_position.y
	if height > 0.0:
		hook.hook_height = height
	if ability.pull_offset > 0.0:
		hook.finish_distance = ability.pull_offset + 0.2
	get_parent().add_child(hook)

func get_ability_def(index: int) -> AbilityDefinition:
	if index < 0 or index >= ability_defs.size():
		return null
	return ability_defs[index]

func get_ability_def_by_id(id: StringName) -> AbilityDefinition:
	for ability in ability_defs:
		if ability != null and ability.ability_id == id:
			return ability
	return null

func get_ability_cooldown(index: int) -> float:
	if index < 0 or index >= ability_timers.size():
		return 0.0
	return ability_timers[index]

func get_ability_mana(index: int) -> float:
	var ability: AbilityDefinition = get_ability_def(index)
	if ability == null:
		return 0.0
	return ability.mana_cost

func get_ability_name(index: int) -> String:
	var ability: AbilityDefinition = get_ability_def(index)
	if ability == null:
		return ""
	return ability.display_name

func get_ability_hotkey(index: int) -> String:
	var ability: AbilityDefinition = get_ability_def(index)
	if ability == null:
		return ""
	return ability.hotkey_label

func get_main_attribute_label() -> String:
	if main_attribute == &"strength":
		return "STR"
	if main_attribute == &"agility":
		return "AGI"
	if main_attribute == &"intelligence":
		return "INT"
	return String(main_attribute)

func do_attack() -> void:
	play_action_animation(anim_attack)
	super.do_attack()

func recalculate_stats() -> void:
	strength = base_strength + bonus_strength + flesh_heap_bonus_strength
	agility = base_agility + bonus_agility
	intelligence = base_intelligence + bonus_intelligence

	max_health = 200.0 + strength * 20.0
	max_mana = 80.0 + intelligence * 12.0
	move_speed = base_move_speed + agility * 0.02 + bonus_move_speed
	attack_damage = base_attack_damage + agility * 1.4 + bonus_attack_damage
	attack_cooldown = max(0.35, base_attack_cooldown - (agility * 0.005) - bonus_attack_speed)

	health = clamp(health, 0.0, max_health)
	mana = clamp(mana, 0.0, max_mana)

func apply_item_mods(mods: Dictionary) -> void:
	for key in mods.keys():
		var value := float(mods[key])
		match key:
			"strength":
				bonus_strength += value
			"agility":
				bonus_agility += value
			"intelligence":
				bonus_intelligence += value
			"move_speed":
				bonus_move_speed += value
			"attack_damage":
				bonus_attack_damage += value
			"attack_speed":
				bonus_attack_speed += value
	recalculate_stats()

func buy_item(item_id: String) -> bool:
	var item: Dictionary = ItemDb.get_item(item_id)
	if item.is_empty():
		return false
	var cost: int = int(item.get("cost", 0))
	if gold < cost:
		return false
	if not inventory.add_item(item_id):
		return false

	gold -= cost
	gold_changed.emit(gold)
	var mods: Dictionary = item.get("mods", {}) as Dictionary
	if mods != null and not mods.is_empty():
		apply_item_mods(mods)
	return true

func use_item(slot_index: int) -> void:
	var item_id := inventory.get_item(slot_index)
	if item_id == "":
		return
	var item: Dictionary = ItemDb.get_item(item_id)
	if item.is_empty():
		return
	if not item.has("active"):
		return
	var active: Dictionary = item.get("active", {}) as Dictionary
	if active == null or active.is_empty():
		return
	if active.get("type", "") == "heal":
		apply_heal(float(active.get("amount", 0)))
		inventory.remove_item(slot_index)

func on_kill(victim: Unit) -> void:
	gold += victim.gold_bounty
	xp += victim.xp_bounty
	gold_changed.emit(gold)
	xp_changed.emit(xp, xp_to_next)

	var flesh_heap: AbilityDefinition = get_ability_def_by_id(&"flesh_heap")
	if flesh_heap != null and flesh_heap.stack_bonus > 0.0:
		flesh_heap_stacks += 1
		flesh_heap_bonus_strength += flesh_heap.stack_bonus
		recalculate_stats()

	while xp >= xp_to_next:
		level_up()

func level_up() -> void:
	level += 1
	xp -= xp_to_next
	xp_to_next = int(xp_to_next * 1.35)
	base_strength += strength_gain
	base_agility += agility_gain
	base_intelligence += intelligence_gain
	recalculate_stats()
	level_changed.emit(level)
	xp_changed.emit(xp, xp_to_next)
