extends CharacterBody3D
class_name Unit

signal died(unit: Unit)
signal health_changed(current: float, max_value: float)
signal mana_changed(current: float, max_value: float)

@export var team := 1
@export var move_speed := 6.0
@export var max_health := 200.0
@export var health_regen := 0.6
@export var max_mana := 100.0
@export var mana_regen := 0.4
@export var attack_damage := 20.0
@export var attack_range := 2.0
@export var attack_cooldown := 1.5
@export var aggro_range := 8.0
@export var gold_bounty := 20
@export var xp_bounty := 35
@export var navigation_enabled := true
@export var nav_agent_radius := 0.6
@export var nav_target_distance := 0.4
@export var nav_path_distance := 0.2

var health := 0.0
var mana := 0.0
var move_target := Vector3.ZERO
var has_move_target := false
var attack_target: Unit
var hold_position := false
var attack_move_active := false
var attack_move_target := Vector3.ZERO
var attack_timer := 0.0
var last_damager: Node
var is_dead := false
var slow_multiplier := 1.0
var slow_timer := 0.0
var stun_timer := 0.0
var nav_agent: NavigationAgent3D
var nav_target := Vector3.ZERO
var nav_has_target := false

func _ready() -> void:
    health = max_health
    mana = max_mana
    add_to_group("unit")
    add_to_group("team_%d" % team)
    emit_signal("health_changed", health, max_health)
    emit_signal("mana_changed", mana, max_mana)
    setup_navigation_agent()

func is_enemy(other: Unit) -> bool:
    return other != null and other.team != team

func set_move_target(point: Vector3) -> void:
    hold_position = false
    attack_move_active = false
    move_target = point
    has_move_target = true
    set_nav_target(point)
    face_point(point)

func stop() -> void:
    has_move_target = false
    attack_target = null
    attack_move_active = false
    hold_position = false
    nav_has_target = false

func set_attack_target(target: Unit) -> void:
    if target == null or target == self:
        return
    hold_position = false
    attack_move_active = false
    attack_target = target
    set_nav_target(target.global_position)
    face_point(target.global_position)

func set_attack_move_target(point: Vector3) -> void:
    hold_position = false
    attack_move_active = true
    attack_move_target = point
    move_target = point
    has_move_target = true
    set_nav_target(point)
    face_point(point)

func set_hold_position(enabled: bool) -> void:
    hold_position = enabled
    if hold_position:
        attack_move_active = false
        has_move_target = false

func take_damage(amount: float, source: Node) -> void:
    if is_dead:
        return
    health = max(0.0, health - amount)
    last_damager = source
    emit_signal("health_changed", health, max_health)
    if health <= 0.0:
        die()

func spend_mana(amount: float) -> bool:
    if mana < amount:
        return false
    mana -= amount
    emit_signal("mana_changed", mana, max_mana)
    return true

func apply_heal(amount: float) -> void:
    if is_dead:
        return
    health = min(max_health, health + amount)
    emit_signal("health_changed", health, max_health)

func apply_slow(multiplier: float, duration: float) -> void:
    slow_multiplier = min(slow_multiplier, multiplier)
    slow_timer = max(slow_timer, duration)

func apply_stun(duration: float) -> void:
    if duration <= 0.0:
        return
    stun_timer = max(stun_timer, duration)

func die() -> void:
    if is_dead:
        return
    is_dead = true
    emit_signal("died", self)
    if last_damager != null and last_damager.has_method("on_kill"):
        last_damager.on_kill(self)
    queue_free()

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if slow_timer > 0.0:
        slow_timer -= delta
        if slow_timer <= 0.0:
            slow_multiplier = 1.0

    attack_timer = max(0.0, attack_timer - delta)
    if health < max_health:
        health = min(max_health, health + health_regen * delta)
    if mana < max_mana:
        mana = min(max_mana, mana + mana_regen * delta)
    if nav_agent != null:
        nav_agent.max_speed = move_speed

    if stun_timer > 0.0:
        stun_timer = max(0.0, stun_timer - delta)
        velocity = Vector3.ZERO
        move_and_slide()
        return

    if attack_target == null and (attack_move_active or hold_position):
        var search_range: float = aggro_range if attack_move_active else attack_range
        var enemy: Unit = find_nearest_enemy_in_range(search_range)
        if enemy != null:
            attack_target = enemy

    var has_valid_attack := attack_target != null and is_instance_valid(attack_target) and not attack_target.is_dead
    if has_valid_attack:
        var distance := global_position.distance_to(attack_target.global_position)
        if distance <= attack_range:
            velocity = Vector3.ZERO
            face_point(attack_target.global_position)
            if attack_timer <= 0.0:
                do_attack()
        else:
            if hold_position:
                attack_target = null
                velocity = Vector3.ZERO
            else:
                set_nav_target(attack_target.global_position)
                move_towards(attack_target.global_position)
    elif has_move_target:
        var distance_to_goal := global_position.distance_to(move_target)
        if distance_to_goal <= 0.35:
            has_move_target = false
            if attack_move_active:
                attack_move_active = false
            nav_has_target = false
            velocity = Vector3.ZERO
        else:
            move_towards(move_target)
    else:
        velocity = Vector3.ZERO

    move_and_slide()

func move_towards(point: Vector3) -> void:
    var target_point := point
    if should_use_nav(point):
        target_point = nav_agent.get_next_path_position()
    var direction := (target_point - global_position)
    direction.y = 0.0
    if direction.length() > 0.001:
        direction = direction.normalized()
        velocity = direction * move_speed * slow_multiplier
        look_at(global_position + direction, Vector3.UP)
    elif point.distance_to(global_position) > 0.1:
        direction = (point - global_position)
        direction.y = 0.0
        if direction.length() > 0.001:
            direction = direction.normalized()
            velocity = direction * move_speed * slow_multiplier
            look_at(global_position + direction, Vector3.UP)

func should_use_nav(point: Vector3) -> bool:
    if not navigation_enabled or nav_agent == null:
        return false
    if not nav_has_target or nav_target.distance_to(point) > 0.5:
        set_nav_target(point)
    if nav_agent.is_navigation_finished():
        return false
    return true

func face_point(point: Vector3) -> void:
    var direction := point - global_position
    direction.y = 0.0
    if direction.length() <= 0.001:
        return
    look_at(global_position + direction.normalized(), Vector3.UP)

func do_attack() -> void:
    if attack_target == null:
        return
    attack_timer = attack_cooldown
    attack_target.take_damage(attack_damage, self)

func setup_navigation_agent() -> void:
    if not navigation_enabled:
        return
    nav_agent = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
    if nav_agent == null:
        nav_agent = NavigationAgent3D.new()
        nav_agent.name = "NavigationAgent3D"
        add_child(nav_agent)
    nav_agent.path_desired_distance = nav_path_distance
    nav_agent.target_desired_distance = nav_target_distance
    nav_agent.radius = nav_agent_radius
    nav_agent.max_speed = move_speed

func set_nav_target(point: Vector3) -> void:
    if nav_agent == null:
        return
    nav_target = point
    nav_has_target = true
    nav_agent.target_position = point

func find_nearest_enemy_in_range(range: float) -> Unit:
    var nearest: Unit
    var best_dist := range
    for node in get_tree().get_nodes_in_group("unit"):
        var unit: Unit = node as Unit
        if unit != null and is_enemy(unit) and not unit.is_dead:
            var dist := global_position.distance_to(unit.global_position)
            if dist <= best_dist:
                best_dist = dist
                nearest = unit
    return nearest
