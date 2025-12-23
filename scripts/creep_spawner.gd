extends Node3D
class_name CreepSpawner

@export var creep_scene: PackedScene
@export var team := 2
@export var spawn_interval := 9.0
@export var max_alive := 6
@export var waypoint_container: NodePath

var spawn_timer := 0.0
var alive_creeps: Array[Node] = []

func _ready() -> void:
    spawn_timer = randf_range(0.0, spawn_interval)

func _process(delta: float) -> void:
    alive_creeps = alive_creeps.filter(func(c): return is_instance_valid(c))
    spawn_timer -= delta
    if spawn_timer <= 0.0 and alive_creeps.size() < max_alive:
        spawn_timer = spawn_interval
        spawn_creep()

func spawn_creep() -> void:
    if creep_scene == null:
        return
    var creep := creep_scene.instantiate()
    creep.team = team
    creep.global_position = global_position
    creep.waypoint_container = waypoint_container
    if get_parent() != null:
        get_parent().add_child(creep)
    else:
        add_child(creep)
    alive_creeps.append(creep)
