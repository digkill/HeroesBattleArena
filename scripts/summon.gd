extends Unit
class_name Summon

@export var lifetime := 20.0
@export var follow_distance := 4.0

var summoner: Unit
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
    super._ready()
    update_team_material()
    gold_bounty = 5
    xp_bounty = 10

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    lifetime -= delta
    if lifetime <= 0.0:
        die()
        return

    if attack_target == null or not is_instance_valid(attack_target):
        var enemy := find_nearest_enemy()
        if enemy != null:
            set_attack_target(enemy)

    if attack_target == null and summoner != null and is_instance_valid(summoner):
        var desired := summoner.global_position + (-summoner.global_transform.basis.z) * follow_distance
        set_move_target(desired)

    super._physics_process(delta)

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

func update_team_material() -> void:
    if mesh_instance == null:
        return
    var mat := StandardMaterial3D.new()
    if team == 1:
        mat.albedo_color = Color(0.2, 0.9, 0.6, 1.0)
    else:
        mat.albedo_color = Color(0.9, 0.3, 0.3, 1.0)
    mesh_instance.material_override = mat
