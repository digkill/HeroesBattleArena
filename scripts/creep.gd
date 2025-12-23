extends Unit
class_name Creep

@export var waypoint_container: NodePath

var waypoints: Array[Vector3] = []
var waypoint_index := 0
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
    super._ready()
    update_team_material()
    cache_waypoints()
    if waypoints.size() > 0:
        set_move_target(waypoints[0])

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if attack_target == null or not is_instance_valid(attack_target):
        var enemy := find_nearest_enemy()
        if enemy != null:
            set_attack_target(enemy)

    super._physics_process(delta)

    if attack_target == null and not has_move_target and waypoints.size() > 0:
        waypoint_index = min(waypoint_index + 1, waypoints.size() - 1)
        set_move_target(waypoints[waypoint_index])

func cache_waypoints() -> void:
    waypoints.clear()
    if waypoint_container == NodePath():
        return
    var container := get_node_or_null(waypoint_container)
    if container == null:
        return
    for child in container.get_children():
        if child is Node3D:
            waypoints.append(child.global_position)

func update_team_material() -> void:
    if mesh_instance == null:
        return
    var mat := StandardMaterial3D.new()
    if team == 1:
        mat.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
    else:
        mat.albedo_color = Color(0.9, 0.2, 0.2, 1.0)
    mesh_instance.material_override = mat

func find_nearest_enemy() -> Unit:
    var nearest: Unit
    var best_dist := aggro_range
    for unit in get_tree().get_nodes_in_group("unit"):
        if unit is Unit and is_enemy(unit):
            var dist := global_position.distance_to(unit.global_position)
            if dist <= best_dist:
                best_dist = dist
                nearest = unit
    return nearest
